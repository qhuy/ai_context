#!/bin/bash
# pr-report.sh — Génère un rapport d'impact feature depuis un diff git.
#
# Usage :
#   bash .ai/scripts/pr-report.sh [--base=<ref>] [--head=<ref>]
#                                 [--format=markdown|json] [--include-docs]
#                                 [--help]
#
# Refs :
#   --base / --head acceptent n'importe quel ref git (sha, branch, tag).
#   En CI sur un shallow clone, si le ref n'est pas atteignable on retombe
#   sur un fallback explicite et on l'affiche dans le rapport.
#
# Ex:
#   bash .ai/scripts/pr-report.sh --base=origin/main --head=HEAD
#   bash .ai/scripts/pr-report.sh --format=json > report.json
#
# Exclusions par défaut (rapport plus focalisé sur le code applicatif) :
#   - README.md, CHANGELOG.md, MIGRATION.md, PROJECT_STATE.md, LICENSE
#   - .github/**, .ai/**, docs/**, .docs/features/** (mesh lui-même)
#
# --include-docs lève ces exclusions.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq git
enable_globstar

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

base_ref="HEAD~1"
head_ref="HEAD"
format="markdown"
include_docs=0

for arg in "$@"; do
  case "$arg" in
    --base=*) base_ref="${arg#--base=}" ;;
    --head=*) head_ref="${arg#--head=}" ;;
    --format=*) format="${arg#--format=}" ;;
    --include-docs) include_docs=1 ;;
    -h|--help)
      cat <<'USAGE'
Usage: bash .ai/scripts/pr-report.sh [options]

Options :
  --base=<ref>     ref git de base   (défaut: HEAD~1)
  --head=<ref>     ref git de tête   (défaut: HEAD)
  --format=<fmt>   markdown (défaut) | json
  --include-docs   inclut README/CHANGELOG/.ai/.github/docs dans l'analyse
  -h, --help       affiche cette aide

Exit codes :
  0   rapport généré (avec ou sans warnings)
  1   erreur d'invocation ou repo absent
USAGE
      exit 0
      ;;
    *)
      echo "Argument inconnu: $arg" >&2
      echo "Voir: bash .ai/scripts/pr-report.sh --help" >&2
      exit 1
      ;;
  esac
done

case "$format" in
  markdown|json) ;;
  *) echo "Format inconnu: $format (markdown|json)" >&2; exit 1 ;;
esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ ce script doit être lancé dans un repo git" >&2
  exit 1
fi

index_file=".ai/.feature-index.json"
if [[ ! -f "$index_file" ]]; then
  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
fi
if [[ ! -f "$index_file" ]]; then
  echo "❌ index feature introuvable: $index_file" >&2
  exit 1
fi

# ─── Résolution de refs (shallow clone friendly) ──────────────────────────
fallback_note=""
if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    fallback_note="base '$base_ref' introuvable (shallow clone ?), fallback HEAD~1"
    base_ref="HEAD~1"
  else
    fallback_note="base '$base_ref' introuvable et HEAD~1 absent, fallback HEAD"
    base_ref="HEAD"
  fi
fi
if ! git rev-parse --verify "$head_ref" >/dev/null 2>&1; then
  fallback_note="${fallback_note}${fallback_note:+ ; }head '$head_ref' introuvable, fallback HEAD"
  head_ref="HEAD"
fi

# ─── Exclusions par défaut ────────────────────────────────────────────────
is_doc_path() {
  local p="$1"
  [[ "$include_docs" -eq 1 ]] && return 1
  case "$p" in
    README.md|CHANGELOG.md|MIGRATION.md|PROJECT_STATE.md|LICENSE|README_AI_CONTEXT.md) return 0 ;;
    .github/*|.ai/*|docs/*|.claude/*|.githooks/*) return 0 ;;
    .docs/FEATURE_TEMPLATE.md) return 0 ;;
    .docs/features/*) return 0 ;;
  esac
  return 1
}

# ─── Récup diff ───────────────────────────────────────────────────────────
changed_files=()
while IFS= read -r f; do
  [[ -n "$f" ]] && changed_files+=("$f")
done < <(git diff --name-only "$base_ref...$head_ref" 2>/dev/null || git diff --name-only "$base_ref" "$head_ref" 2>/dev/null || true)

filtered=()
docs_excluded=0
if [[ "${#changed_files[@]}" -gt 0 ]]; then
  for f in "${changed_files[@]}"; do
    if is_doc_path "$f"; then
      docs_excluded=$((docs_excluded + 1))
      continue
    fi
    filtered+=("$f")
  done
fi

# ─── Analyse impact ───────────────────────────────────────────────────────
warnings=()
shared_only=()
impacted_keys=()
related_keys=()
done_modified=()
multi_covered=()
stale_threshold=14
today_epoch=$(date +%s 2>/dev/null || echo 0)

for f in ${filtered[@]+"${filtered[@]}"}; do
  matched="$(features_matching_path "$index_file" "$f" || true)"
  shared_matched="$(features_matching_shared_path "$index_file" "$f" || true)"
  if [[ -z "$matched" ]]; then
    if [[ -n "$shared_matched" ]]; then
      shared_keys=""
      while IFS=$'\t' read -r scope id _path; do
        [[ -n "$scope" && -n "$id" ]] || continue
        key="$scope/$id"
        related_keys+=("$key")
        shared_keys+="$key "
      done <<< "$shared_matched"
      shared_only+=("\`$f\` lié via touches_shared: $shared_keys")
    else
      warnings+=("fichier non couvert par touches: \`$f\`")
    fi
    continue
  fi

  count=0
  file_keys=""
  while IFS=$'\t' read -r scope id _path; do
    [[ -n "$scope" && -n "$id" ]] || continue
    key="$scope/$id"
    impacted_keys+=("$key")
    file_keys+="$key "
    count=$((count + 1))

    # feature done modifiée
    feat_status=$(jq -r --arg s "$scope" --arg i "$id" '.features[] | select(.scope == $s and .id == $i) | .status // ""' "$index_file")
    if [[ "$feat_status" == "done" ]]; then
      done_modified+=("$key (\`$f\`)")
    fi
  done <<< "$matched"

  while IFS=$'\t' read -r scope id _path; do
    [[ -n "$scope" && -n "$id" ]] || continue
    related_keys+=("$scope/$id")
  done <<< "$shared_matched"

  if [[ "$count" -gt 1 ]]; then
    multi_covered+=("\`$f\` couvert par $count features: $file_keys")
  fi
done

# Active dépend de deprecated/archived (parmi les features impactées)
deprecated_links=()
if [[ "${#impacted_keys[@]}" -gt 0 ]]; then
  uniq_keys=$(printf '%s\n' "${impacted_keys[@]}" | sort -u)
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    scope="${key%%/*}"
    id="${key##*/}"
    line=$(jq -r --arg s "$scope" --arg i "$id" '
      .features[] | select(.scope == $s and .id == $i)
      | (.depends_on // [])[]
    ' "$index_file" | while IFS= read -r dep; do
      [[ -z "$dep" ]] && continue
      dep_scope="${dep%%/*}"
      dep_id="${dep##*/}"
      dep_status=$(jq -r --arg s "$dep_scope" --arg i "$dep_id" '.features[] | select(.scope == $s and .id == $i) | .status // ""' "$index_file")
      [[ "$dep_status" == "deprecated" || "$dep_status" == "archived" ]] && echo "$key dépend de $dep ($dep_status)"
    done)
    [[ -n "$line" ]] && deprecated_links+=("$line")
  done <<< "$uniq_keys"
fi

# Stale (>14j sans update)
stale_features=()
if [[ "${#impacted_keys[@]}" -gt 0 ]] && [[ "$today_epoch" != "0" ]]; then
  uniq_keys=$(printf '%s\n' "${impacted_keys[@]}" | sort -u)
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    scope="${key%%/*}"
    id="${key##*/}"
    updated=$(jq -r --arg s "$scope" --arg i "$id" '.features[] | select(.scope == $s and .id == $i) | .progress.updated // ""' "$index_file")
    [[ -z "$updated" ]] && continue
    upd_epoch=$(date -j -f "%Y-%m-%d" "$updated" +%s 2>/dev/null || date -d "$updated" +%s 2>/dev/null || echo 0)
    [[ "$upd_epoch" == "0" ]] && continue
    days=$(( (today_epoch - upd_epoch) / 86400 ))
    if [[ "$days" -gt "$stale_threshold" ]]; then
      stale_features+=("$key (updated=$updated, $days j)")
    fi
  done <<< "$uniq_keys"
fi

# ─── Sortie ───────────────────────────────────────────────────────────────
emit_markdown() {
  echo "## AI Context Report"
  echo
  echo "- Base: \`$base_ref\`"
  echo "- Head: \`$head_ref\`"
  echo "- Fichiers modifiés (bruts): ${#changed_files[@]}"
  echo "- Fichiers analysés (hors docs): ${#filtered[@]}"
  if [[ "$docs_excluded" -gt 0 ]]; then
    echo "- Exclus par défaut (docs/CI/.ai): $docs_excluded — utilise \`--include-docs\` pour les inclure"
  fi
  if [[ -n "$fallback_note" ]]; then
    echo "- ⚠️  $fallback_note"
  fi
  echo

  if [[ "${#filtered[@]}" -eq 0 ]]; then
    echo "_Aucun fichier de code modifié sur ce diff._"
    return 0
  fi

  echo "### Features impactées"
  if [[ "${#impacted_keys[@]}" -eq 0 ]]; then
    echo "- _(aucune feature trouvée)_"
  else
    printf '%s\n' "${impacted_keys[@]}" | sort -u | while IFS= read -r key; do
      echo "- $key"
    done
  fi

  if [[ "${#related_keys[@]}" -gt 0 ]]; then
    echo
    echo "### Features liées (shared)"
    printf '%s\n' "${related_keys[@]}" | sort -u | while IFS= read -r key; do
      echo "- $key"
    done
  fi

  echo
  echo "### Warnings"
  local total_warn=$((${#warnings[@]} + ${#shared_only[@]} + ${#done_modified[@]} + ${#multi_covered[@]} + ${#deprecated_links[@]} + ${#stale_features[@]}))
  if [[ "$total_warn" -eq 0 ]]; then
    echo "- _(aucun)_"
  else
    for w in ${warnings[@]+"${warnings[@]}"}; do echo "- $w"; done
    for w in ${shared_only[@]+"${shared_only[@]}"}; do echo "- ℹ️ $w"; done
    for w in ${done_modified[@]+"${done_modified[@]}"}; do echo "- ⚠️ feature \`done\` modifiée : $w"; done
    for w in ${multi_covered[@]+"${multi_covered[@]}"}; do echo "- ℹ️ $w"; done
    for w in ${deprecated_links[@]+"${deprecated_links[@]}"}; do echo "- ⚠️ $w"; done
    for w in ${stale_features[@]+"${stale_features[@]}"}; do echo "- ⏳ feature stale : $w"; done
  fi
}

emit_json() {
  jq -n \
    --arg base "$base_ref" \
    --arg head "$head_ref" \
    --arg fallback "$fallback_note" \
    --argjson changed "$(printf '%s\n' ${changed_files[@]+"${changed_files[@]}"} | jq -R . | jq -s .)" \
    --argjson filtered "$(printf '%s\n' ${filtered[@]+"${filtered[@]}"} | jq -R . | jq -s .)" \
    --argjson docs_excluded "$docs_excluded" \
    --argjson impacted "$(printf '%s\n' ${impacted_keys[@]+"${impacted_keys[@]}"} | jq -R . | jq -s 'unique')" \
    --argjson related "$(printf '%s\n' ${related_keys[@]+"${related_keys[@]}"} | jq -R . | jq -s 'unique')" \
    --argjson warnings "$(printf '%s\n' ${warnings[@]+"${warnings[@]}"} | jq -R . | jq -s .)" \
    --argjson shared_only "$(printf '%s\n' ${shared_only[@]+"${shared_only[@]}"} | jq -R . | jq -s .)" \
    --argjson done_modified "$(printf '%s\n' ${done_modified[@]+"${done_modified[@]}"} | jq -R . | jq -s .)" \
    --argjson multi_covered "$(printf '%s\n' ${multi_covered[@]+"${multi_covered[@]}"} | jq -R . | jq -s .)" \
    --argjson deprecated_links "$(printf '%s\n' ${deprecated_links[@]+"${deprecated_links[@]}"} | jq -R . | jq -s .)" \
    --argjson stale_features "$(printf '%s\n' ${stale_features[@]+"${stale_features[@]}"} | jq -R . | jq -s .)" \
    '{
      base: $base,
      head: $head,
      fallback_note: $fallback,
      changed_files: $changed,
      filtered_files: $filtered,
      docs_excluded: $docs_excluded,
      impacted_features: $impacted,
      related_features: $related,
      warnings: {
        uncovered: $warnings,
        shared_only: $shared_only,
        done_modified: $done_modified,
        multi_covered: $multi_covered,
        deprecated_links: $deprecated_links,
        stale: $stale_features
      }
    }'
}

case "$format" in
  markdown) emit_markdown ;;
  json) emit_json ;;
esac
