#!/bin/bash
# review-delta.sh — Synthèse review-friendly du delta courant.
#
# Usage :
#   bash .ai/scripts/review-delta.sh [--staged]
#   bash .ai/scripts/review-delta.sh [--base=<ref>] [--head=<ref>]
#   bash .ai/scripts/review-delta.sh [--committed-only]
#
# Par défaut : Delta committed reference (--staged si index non vide,
# sinon HEAD~1...HEAD) + Delta uncommitted (git status --short
# --untracked-files=all).
# Avec --committed-only : seule la section committed est produite
# (compat ascendante stricte).

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd git jq

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

mode="auto"
base_ref="HEAD~1"
head_ref="HEAD"
include_uncommitted=true

for arg in "$@"; do
  case "$arg" in
    --staged) mode="staged" ;;
    --base=*) mode="refs"; base_ref="${arg#--base=}" ;;
    --head=*) mode="refs"; head_ref="${arg#--head=}" ;;
    --committed-only) include_uncommitted=false ;;
    -h|--help)
      cat <<'USAGE'
Usage: bash .ai/scripts/review-delta.sh [--staged]
       bash .ai/scripts/review-delta.sh [--base=<ref>] [--head=<ref>]
       bash .ai/scripts/review-delta.sh [--committed-only]

Review Delta:
Produit un rapport Markdown court :
  - Delta committed reference : fichiers + features (touches/shared) +
    risques + checks
  - Delta uncommitted (working tree + index + untracked) : ajouté par
    défaut, omis avec --committed-only

Source de vérité uncommitted : git status --short --untracked-files=all
(couvre tracked modifié + staged + untracked + deletions/renames).
USAGE
      exit 0
      ;;
    *)
      echo "Argument inconnu: $arg" >&2
      exit 2
      ;;
  esac
done

# Source canonique uncommitted : `_lib.sh::collect_uncommitted_paths` (git status).

index_file=".ai/.feature-index.json"
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
if [[ ! -f "$index_file" ]]; then
  echo "index feature introuvable: $index_file" >&2
  exit 1
fi

if [[ "$mode" == "auto" ]]; then
  if [[ -n "$(git diff --cached --name-only 2>/dev/null || true)" ]]; then
    mode="staged"
  else
    mode="refs"
  fi
fi

changed_files=()
if [[ "$mode" == "staged" ]]; then
  while IFS= read -r f; do
    [[ -n "$f" ]] && changed_files+=("$f")
  done < <(git diff --cached --name-only --no-renames 2>/dev/null || true)
else
  while IFS= read -r f; do
    [[ -n "$f" ]] && changed_files+=("$f")
  done < <(git diff --name-only "$base_ref...$head_ref" 2>/dev/null || git diff --name-only "$base_ref" "$head_ref" 2>/dev/null || true)
fi

is_feature_doc_path() {
  local path="$1"
  [[ "$path" == "$AI_CONTEXT_FEATURES_DIR"/*".md" ]]
}

staged_docs=""
if [[ "$mode" == "staged" && "${#changed_files[@]}" -gt 0 ]]; then
  staged_docs=$(printf '%s\n' "${changed_files[@]}" | while IFS= read -r rel; do
    is_feature_doc_path "$rel" && printf '%s\n' "$rel"
  done || true)
fi

staged_has_doc_for_feature() {
  local feature_path="$1"
  local id="$2"
  local dir worklog_path
  dir="$(dirname "$feature_path")"
  worklog_path="$dir/$id.worklog.md"
  printf '%s\n' "$staged_docs" | grep -Fxq "$feature_path" && return 0
  printf '%s\n' "$staged_docs" | grep -Fxq "$worklog_path" && return 0
  return 1
}

direct_keys=()
related_keys=()
uncovered=()
multi_covered=()
shared_only=()
missing_docs=()

for f in ${changed_files[@]+"${changed_files[@]}"}; do
  is_feature_doc_path "$f" && continue
  direct="$(features_matching_path "$index_file" "$f" || true)"
  shared="$(features_matching_shared_path "$index_file" "$f" || true)"

  if [[ -z "$direct" ]]; then
    if [[ -z "$shared" ]]; then
      uncovered+=("$f")
    else
      shared_keys=""
      while IFS=$'\t' read -r scope id _path; do
        [[ -n "$scope" && -n "$id" ]] || continue
        key="$scope/$id"
        related_keys+=("$key")
        shared_keys+="$key "
      done <<< "$shared"
      shared_only+=("$f -> $shared_keys")
    fi
    continue
  fi

  count=0
  file_keys=""
  while IFS=$'\t' read -r scope id feature_path; do
    [[ -n "$scope" && -n "$id" ]] || continue
    key="$scope/$id"
    direct_keys+=("$key")
    file_keys+="$key "
    count=$((count + 1))
    if [[ "$mode" == "staged" ]] && ! staged_has_doc_for_feature "$feature_path" "$id"; then
      missing_docs+=("$key ($feature_path) <- $f")
    fi
  done <<< "$direct"

  if [[ "$count" -gt 1 ]]; then
    multi_covered+=("$f -> $file_keys")
  fi

  while IFS=$'\t' read -r scope id _path; do
    [[ -n "$scope" && -n "$id" ]] || continue
    related_keys+=("$scope/$id")
  done <<< "$shared"
done

print_unique_list() {
  if [[ "$#" -eq 0 ]]; then
    echo "- _(aucun)_"
    return 0
  fi
  printf '%s\n' "$@" | sort -u | while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      echo "- $item"
    fi
  done
}

uncommitted_files=()
uncommitted_direct_keys=()
uncommitted_related_keys=()
if $include_uncommitted; then
  while IFS= read -r f; do
    [[ -n "$f" ]] && uncommitted_files+=("$f")
  done < <(collect_uncommitted_paths)

  for f in ${uncommitted_files[@]+"${uncommitted_files[@]}"}; do
    is_feature_doc_path "$f" && continue
    direct="$(features_matching_path "$index_file" "$f" 2>/dev/null || true)"
    shared="$(features_matching_shared_path "$index_file" "$f" 2>/dev/null || true)"
    while IFS=$'\t' read -r scope id _path; do
      [[ -n "$scope" && -n "$id" ]] || continue
      uncommitted_direct_keys+=("$scope/$id")
    done <<< "$direct"
    while IFS=$'\t' read -r scope id _path; do
      [[ -n "$scope" && -n "$id" ]] || continue
      uncommitted_related_keys+=("$scope/$id")
    done <<< "$shared"
  done
fi

echo "## Review Delta"
echo
if [[ "$mode" == "staged" ]]; then
  echo "- Mode: staged"
else
  echo "- Base: \`$base_ref\`"
  echo "- Head: \`$head_ref\`"
fi
echo "- Fichiers modifiés: ${#changed_files[@]}"
if $include_uncommitted; then
  echo "- Section _Delta uncommitted_ ajoutée en suffixe (utiliser \`--committed-only\` pour l'omettre)."
fi
echo

echo "### Fichiers"
print_unique_list "${changed_files[@]+"${changed_files[@]}"}"
echo

echo "### Features directes"
print_unique_list "${direct_keys[@]+"${direct_keys[@]}"}"
echo

echo "### Features liées (shared)"
print_unique_list "${related_keys[@]+"${related_keys[@]}"}"
echo

echo "### Risques détectés"
risks=()
for x in ${uncovered[@]+"${uncovered[@]}"}; do risks+=("non couvert par touches: $x"); done
for x in ${shared_only[@]+"${shared_only[@]}"}; do risks+=("couvert seulement via touches_shared: $x"); done
for x in ${multi_covered[@]+"${multi_covered[@]}"}; do risks+=("multi-couvert: $x"); done
for x in ${missing_docs[@]+"${missing_docs[@]}"}; do risks+=("doc/worklog manquant en staged: $x"); done
print_unique_list "${risks[@]+"${risks[@]}"}"
echo

echo "### Checks recommandés"
if [[ "$mode" == "staged" ]]; then
  echo "- \`bash .ai/scripts/check-feature-freshness.sh --staged --strict\`"
fi
echo "- \`bash .ai/scripts/check-features.sh\`"
echo "- \`bash .ai/scripts/check-shims.sh\`"
echo "- \`bash .ai/scripts/measure-context-size.sh\`"

if $include_uncommitted; then
  echo
  echo "### Delta uncommitted (working tree + index + untracked)"
  echo
  echo "- Source: \`git status --porcelain=v1 -z --untracked-files=all\`"
  echo "- Fichiers uncommitted: ${#uncommitted_files[@]}"
  echo
  echo "#### Fichiers (uncommitted)"
  print_unique_list "${uncommitted_files[@]+"${uncommitted_files[@]}"}"
  echo
  echo "#### Features directes (uncommitted, best-effort)"
  print_unique_list "${uncommitted_direct_keys[@]+"${uncommitted_direct_keys[@]}"}"
  echo
  echo "#### Features liées (uncommitted, shared, best-effort)"
  print_unique_list "${uncommitted_related_keys[@]+"${uncommitted_related_keys[@]}"}"
fi
