#!/bin/bash
# auto-worklog-log.sh — Hook PostToolUse Write/Edit/MultiEdit.
#
# Reçoit le JSON du hook Claude sur stdin. Extrait tool_input.file_path.
# Résout les features impactées via .feature-index.json et append une ligne
# JSONL à .ai/.session-edits.log. N'écrit PAS dans les fiches ni worklogs ici
# (trop chaud pour le chemin critique). Le flush se fait au Stop hook.
#
# Silencieux et best-effort : ne bloque jamais un Write/Edit.

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

repo_root="$(cd "$script_dir/../.." && pwd)"
index_file="$repo_root/.ai/.feature-index.json"
log_file="$repo_root/.ai/.session-edits.log"

input=$(cat 2>/dev/null || true)
[[ -z "$input" ]] && exit 0

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[[ -z "$file_path" ]] && exit 0

# Chemin relatif au repo
rel="$file_path"
case "$file_path" in
  /*) rel="${file_path#"$repo_root/"}" ;;
esac

[[ ! -f "$index_file" ]] && exit 0

# Matche les features dont un glob touches: couvre ce path
matches=$(features_matching_path "$index_file" "$rel" | awk -F '\t' '{print $1 "/" $2}' | sort -u)

# ─── Log event "touch" pour le tracker de pertinence (best-effort) ───
# Logue même si matches vide (utile pour repérer touched_not_injected = 0).
{
  touched_json='[]'
  if [[ -n "$matches" ]]; then
    touched_json=$(printf '%s' "$matches" | jq -Rsc 'split("\n") | map(select(length > 0))' 2>/dev/null) || touched_json='[]'
  fi
  tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null) || tool_name=""
  bash "$script_dir/context-relevance-log.sh" touch \
    "$tool_name" \
    "$rel" \
    "$touched_json" \
    >/dev/null 2>&1 || true
} 2>/dev/null || true

[[ -z "$matches" ]] && exit 0

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
mkdir -p "$(dirname "$log_file")"
while IFS= read -r key; do
  [[ -z "$key" ]] && continue
  # JSONL via jq pour échapper correctement quotes/backslashes/unicode dans key et rel
  jq -nc --arg feature "$key" --arg file "$rel" --arg ts "$ts" \
    '{feature: $feature, file: $file, ts: $ts}' >> "$log_file"
done <<< "$matches"

exit 0
