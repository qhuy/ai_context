#!/bin/bash
# check-feature-freshness.sh — Verifie que la doc feature suit les edits code.
#
# Trois controles complementaires :
#   - --staged : compare les fichiers stages avec les features dont `touches:`
#     les couvre. Si du code couvert change, la fiche feature ou son worklog
#     doit etre stage dans le meme commit.
#   - --worktree : meme logique de presence que --staged, mais sur tout le
#     working tree (staged + non-stage + untracked), restreinte aux chemins
#     "substantiels" (perimetre coverage). Sert au gate Stop de fin de tour :
#     du code couvert modifie sans fiche/worklog modifie => echec en --strict.
#     Presence-based, jamais base sur des timestamps de commit (cf. --worktree
#     vs historique : l'historique ne voit pas les edits non commites).
#   - historique : compare le dernier commit des fichiers couverts par `touches:`
#     avec le dernier commit de la fiche/worklog.
#
# Usage :
#   bash .ai/scripts/check-feature-freshness.sh --staged --strict
#   bash .ai/scripts/check-feature-freshness.sh --worktree --strict
#   bash .ai/scripts/check-feature-freshness.sh --warn
#   bash .ai/scripts/check-feature-freshness.sh --strict

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd git jq
enable_globstar

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

index_file=".ai/.feature-index.json"
mode="--warn"
staged_mode=0
worktree_mode=0
index_tmp=""

cleanup_index_tmp() {
  [[ -n "$index_tmp" ]] && rm -f "$index_tmp"
}
trap cleanup_index_tmp EXIT

for arg in "$@"; do
  case "$arg" in
    --warn|--strict) mode="$arg" ;;
    --staged) staged_mode=1 ;;
    --worktree) worktree_mode=1 ;;
    *)
      echo "Usage: bash .ai/scripts/check-feature-freshness.sh [--staged|--worktree] [--warn|--strict]" >&2
      exit 2
      ;;
  esac
done

strict=0
[[ "$mode" == "--strict" ]] && strict=1

index_tmp=$(mktemp "${TMPDIR:-/tmp}/ai-context-feature-index.XXXXXX")
if bash "$script_dir/build-feature-index.sh" > "$index_tmp" 2>/dev/null; then
  index_file="$index_tmp"
elif [[ -f "$index_file" ]]; then
  echo "  ⚠️  index temporaire impossible à générer, fallback lecture du cache existant" >&2
else
  echo "  ⚠️  pas d'index feature, rien a verifier" >&2
  exit 0
fi

feature_doc_paths() {
  local feature_path="$1"
  local scope="$2"
  local id="$3"
  local dir
  dir="$(dirname "$feature_path")"
  printf '%s\n' "$feature_path"
  printf '%s\n' "$dir/$id.worklog.md"
}

is_feature_doc_path() {
  local path="$1"
  [[ "$path" == "$AI_CONTEXT_FEATURES_DIR"/*".md" ]]
}

staged_has_doc_for_feature() {
  local staged_docs="$1"
  local feature_path="$2"
  local scope="$3"
  local id="$4"
  local dir worklog_path
  dir="$(dirname "$feature_path")"
  worklog_path="$dir/$id.worklog.md"

  printf '%s\n' "$staged_docs" | grep -Fxq "$feature_path" && return 0
  printf '%s\n' "$staged_docs" | grep -Fxq "$worklog_path" && return 0
  return 1
}

# blocking_coverers <rel> — contrat (a') : parmi les coverers DIRECTS (touches:)
# d'un fichier, seul le rang de spécificité le plus élevé est BLOQUANT.
#   - primaire unique (plus spécifique) → lui seul doit être documenté ;
#   - tie de rang (ex-aequo, ex. plusieurs revendications exactes) → tous les
#     ex-aequo (bloque tant que non documentés ou reclassés en touches_shared) ;
#   - coverers moins spécifiques (glob large) → advisory, NON bloquants ;
#   - 0 coverer direct → rien (orphelin traité ailleurs).
# Tue la cascade sur l'infra partagée sans rendre muet le vrai co-ownership
# (audit D + arbitrage Codex). Spécificité = _score_touch_pattern (tier,
# prefix_len, wildcards). Émet scope\tid\tfeature_path du rang max.
blocking_coverers() {
  local rel="$1"
  features_matching_path_ranked "$index_file" "$rel" 2>/dev/null \
  | while IFS=$'\t' read -r scope id fpath touch; do
      [[ -z "$scope" ]] && continue
      local tier plen wc
      IFS=$'\t' read -r tier plen wc < <(_score_touch_pattern "$touch")
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$tier" "$plen" "$wc" "$scope" "$id" "$fpath"
    done \
  | awk -F'\t' '
      { rows[NR]=$0; t=$1+0; p=$2+0; w=$3+0
        if (NR==1 || t>bt || (t==bt && p>bp) || (t==bt && p==bp && w<bw)) { bt=t; bp=p; bw=w } }
      END { for (i=1;i<=NR;i++){ split(rows[i],f,"\t")
              if (f[1]+0==bt && f[2]+0==bp && f[3]+0==bw) print f[4]"\t"f[5]"\t"f[6] } }
    '
}

run_staged_check() {
  local staged
  staged=$(git diff --cached --name-only --no-renames 2>/dev/null || true)
  if [[ -z "$staged" ]]; then
    echo "═══ check-feature-freshness (staged) ═══"
    echo "  aucun fichier stage"
    echo
    echo "✅ OK"
    return 0
  fi

  local failures
  failures=$(mktemp "${TMPDIR:-/tmp}/ai-context-freshness.XXXXXX")
  trap 'rm -f "$failures"' RETURN

  local staged_docs
  staged_docs=$(printf '%s\n' "$staged" | while IFS= read -r rel; do
    if is_feature_doc_path "$rel"; then
      printf '%s\n' "$rel"
    fi
  done)

  local rel scope id feature_path
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    is_feature_doc_path "$rel" && continue

    while IFS=$'\t' read -r scope id feature_path; do
      [[ -z "$scope" || -z "$id" || -z "$feature_path" ]] && continue
      if ! staged_has_doc_for_feature "$staged_docs" "$feature_path" "$scope" "$id"; then
        printf '%s\t%s/%s\t%s\n' "$rel" "$scope" "$id" "$feature_path" >> "$failures"
      fi

    done < <(blocking_coverers "$rel")
  done <<< "$staged"

  echo "═══ check-feature-freshness (staged) ═══"

  if [[ ! -s "$failures" ]]; then
    echo "  fichiers stages couverts : OK"
    echo
    echo "✅ OK"
    return 0
  fi

  echo "  Features couvertes par du code stage sans fiche/worklog stage :"
  sort -u "$failures" | while IFS=$'\t' read -r file feature feature_path; do
    echo "    - $feature ($feature_path) ← $file"
  done

  if [[ "$strict" -eq 1 ]]; then
    echo
    echo "❌ FAIL (--strict)"
    return 1
  fi

  echo
  echo "✅ OK (--warn)"
  return 0
}

run_worktree_check() {
  local changed
  changed=$(collect_uncommitted_paths)

  echo "═══ check-feature-freshness (worktree) ═══"

  if [[ -z "$changed" ]]; then
    echo "  aucun fichier modifie dans le working tree"
    echo
    echo "✅ OK"
    return 0
  fi

  local failures
  failures=$(mktemp "${TMPDIR:-/tmp}/ai-context-freshness-wt.XXXXXX")
  trap 'rm -f "$failures"' RETURN

  # Fiches/worklogs feature presents dans le change set (staged ou non).
  local changed_docs
  changed_docs=$(printf '%s\n' "$changed" | while IFS= read -r rel; do
    if is_feature_doc_path "$rel"; then
      printf '%s\n' "$rel"
    fi
  done)

  local rel scope id feature_path
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    is_feature_doc_path "$rel" && continue
    # Anti-bruit : seuls les chemins "substantiels" (perimetre coverage)
    # declenchent l'obligation. Evite de bloquer sur config/doc/non-code.
    path_in_coverage_scope "$rel" || continue

    while IFS=$'\t' read -r scope id feature_path; do
      [[ -z "$scope" || -z "$id" || -z "$feature_path" ]] && continue
      if ! staged_has_doc_for_feature "$changed_docs" "$feature_path" "$scope" "$id"; then
        printf '%s\t%s/%s\t%s\n' "$rel" "$scope" "$id" "$feature_path" >> "$failures"
      fi
    done < <(blocking_coverers "$rel")
  done <<< "$changed"

  if [[ ! -s "$failures" ]]; then
    echo "  fichiers working-tree couverts : OK"
    echo
    echo "✅ OK"
    return 0
  fi

  echo "  Features couvertes par du code modifie (working tree) sans fiche/worklog modifie :"
  sort -u "$failures" | while IFS=$'\t' read -r file feature feature_path; do
    echo "    - $feature ($feature_path) ← $file"
  done

  if [[ "$strict" -eq 1 ]]; then
    echo
    echo "❌ FAIL (--strict)"
    return 1
  fi

  echo
  echo "✅ OK (--warn)"
  return 0
}

git_path_ts() {
  local path="$1"
  git log -1 --format=%ct -- "$path" 2>/dev/null | head -n1
}

git_path_ts_cached() {
  local path="$1"
  local cached ts
  if [[ -n "${ts_cache_file:-}" && -f "$ts_cache_file" ]]; then
    cached=$(awk -F '\t' -v p="$path" '$1 == p { print $2; found=1; exit } END { exit found ? 0 : 1 }' "$ts_cache_file" 2>/dev/null) && {
      echo "$cached"
      return 0
    }
  fi
  ts=$(git_path_ts "$path")
  [[ -z "$ts" ]] && ts=0
  if [[ -n "${ts_cache_file:-}" ]]; then
    printf '%s\t%s\n' "$path" "$ts" >> "$ts_cache_file"
  fi
  echo "$ts"
}

latest_doc_ts() {
  local feature_path="$1"
  local scope="$2"
  local id="$3"
  local max_ts=0
  local doc_path ts
  while IFS= read -r doc_path; do
    [[ -z "$doc_path" ]] && continue
    ts=$(git_path_ts_cached "$doc_path")
    [[ -z "$ts" ]] && ts=0
    if [[ "$ts" -gt "$max_ts" ]]; then
      max_ts="$ts"
    fi
  done < <(feature_doc_paths "$feature_path" "$scope" "$id")
  echo "$max_ts"
}

latest_code_ts_for_feature() {
  local scope="$1"
  local id="$2"
  local touch ts
  local touches=()

  while IFS= read -r touch; do
    [[ -z "$touch" ]] && continue
    touches+=("$touch")
  done < <(jq -r --arg scope "$scope" --arg id "$id" '
    .features[]
    | select(.scope == $scope and .id == $id)
    | .touches[]?
  ' "$index_file")

  if [[ -z "${touches[*]-}" ]]; then
    echo 0
    return 0
  fi

  ts=$(git log -1 --format=%ct -- "${touches[@]}" 2>/dev/null | head -n1)
  [[ -z "$ts" ]] && ts=0
  echo "$ts"
}

run_history_check() {
  local stale
  stale=$(mktemp "${TMPDIR:-/tmp}/ai-context-stale.XXXXXX")
  ts_cache_file=$(mktemp "${TMPDIR:-/tmp}/ai-context-ts-cache.XXXXXX")
  trap 'rm -f "$stale" "$ts_cache_file"' RETURN

  local scope id feature_path doc_ts code_ts
  while IFS=$'\t' read -r scope id feature_path; do
    [[ -z "$scope" || -z "$id" || -z "$feature_path" ]] && continue
    doc_ts=$(latest_doc_ts "$feature_path" "$scope" "$id")
    code_ts=$(latest_code_ts_for_feature "$scope" "$id")
    [[ -z "$doc_ts" ]] && doc_ts=0
    [[ -z "$code_ts" ]] && code_ts=0

    if [[ "$code_ts" -gt "$doc_ts" ]]; then
      printf '%s/%s\t%s\t%s\t%s\n' "$scope" "$id" "$feature_path" "$code_ts" "$doc_ts" >> "$stale"
    fi
  done < <(jq -r '.features[] | [.scope, .id, .path] | @tsv' "$index_file")

  echo "═══ check-feature-freshness ═══"
  echo "  mode historique : compare uniquement l'historique Git committe"
  echo "  pour le prochain commit : bash .ai/scripts/check-feature-freshness.sh --staged --strict"

  if [[ ! -s "$stale" ]]; then
    echo "  aucune feature stale detectee"
    echo
    echo "✅ OK"
    return 0
  fi

  echo "  Features potentiellement stale (code plus recent que fiche/worklog) :"
  sort -u "$stale" | while IFS=$'\t' read -r feature feature_path code_ts doc_ts; do
    echo "    - $feature ($feature_path) code=$code_ts doc=$doc_ts"
  done

  if [[ "$strict" -eq 1 ]]; then
    echo
    echo "❌ FAIL (--strict)"
    return 1
  fi

  echo
  echo "✅ OK (--warn)"
  return 0
}

if [[ "$worktree_mode" -eq 1 ]]; then
  run_worktree_check
elif [[ "$staged_mode" -eq 1 ]]; then
  run_staged_check
else
  run_history_check
fi
