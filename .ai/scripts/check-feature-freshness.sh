#!/bin/bash
# check-feature-freshness.sh — Verifie que la doc feature suit les edits code.
#
# Deux controles complementaires :
#   - --staged : compare les fichiers stages avec les features dont `touches:`
#     les couvre. Si du code couvert change, la fiche feature ou son worklog
#     doit etre stage dans le meme commit.
#   - historique : compare le dernier commit des fichiers couverts par `touches:`
#     avec le dernier commit de la fiche/worklog.
#
# Usage :
#   bash .ai/scripts/check-feature-freshness.sh --staged --strict
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

for arg in "$@"; do
  case "$arg" in
    --warn|--strict) mode="$arg" ;;
    --staged) staged_mode=1 ;;
    *)
      echo "Usage: bash .ai/scripts/check-feature-freshness.sh [--staged] [--warn|--strict]" >&2
      exit 2
      ;;
  esac
done

strict=0
[[ "$mode" == "--strict" ]] && strict=1

bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
if [[ ! -f "$index_file" ]]; then
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

    done < <(features_matching_path "$index_file" "$rel")
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

git_path_ts() {
  local path="$1"
  if [[ -e "$path" ]] && ! git diff --quiet -- "$path" 2>/dev/null; then
    date +%s
    return 0
  fi
  git log -1 --format=%ct -- "$path" 2>/dev/null | head -n1
}

latest_doc_ts() {
  local feature_path="$1"
  local scope="$2"
  local id="$3"
  local max_ts=0
  local doc_path ts
  while IFS= read -r doc_path; do
    [[ -z "$doc_path" ]] && continue
    ts=$(git_path_ts "$doc_path")
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
  local max_ts=0
  local touch tracked_file ts

  while IFS= read -r touch; do
    [[ -z "$touch" ]] && continue
    while IFS= read -r tracked_file; do
      [[ -z "$tracked_file" ]] && continue
      if path_matches_touch "$tracked_file" "$touch"; then
        ts=$(git_path_ts "$tracked_file")
        [[ -z "$ts" ]] && ts=0
        if [[ "$ts" -gt "$max_ts" ]]; then
          max_ts="$ts"
        fi
      fi
    done < <(git ls-files)
  done < <(jq -r --arg scope "$scope" --arg id "$id" '
    .features[]
    | select(.scope == $scope and .id == $id)
    | .touches[]?
  ' "$index_file")

  echo "$max_ts"
}

run_history_check() {
  local stale
  stale=$(mktemp "${TMPDIR:-/tmp}/ai-context-stale.XXXXXX")
  trap 'rm -f "$stale"' RETURN

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

if [[ "$staged_mode" -eq 1 ]]; then
  run_staged_check
else
  run_history_check
fi
