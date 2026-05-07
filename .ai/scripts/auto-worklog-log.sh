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

# Matches enrichis (scope, id, feature_path) — garde feature_path pour
# is_structural_feature_edit (Phase 2 #5 stop-hook-idempotence).
matches_full=$(features_matching_path "$index_file" "$rel")

# Pour le logger context-relevance touch, collapse en scope/id (NE PAS
# filtrer ici : touch doit logger même les non-structurels pour mesurer
# touched_not_injected. Cf. contrainte 1 Codex Phase 2 #5).
matches=$(printf '%s' "$matches_full" | awk -F '\t' '{print $1 "/" $2}' | sort -u)

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

[[ -z "$matches_full" ]] && exit 0

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
mkdir -p "$(dirname "$log_file")"

# Filtre Phase 2 #5 stop-hook-idempotence : alimenter .session-edits.log
# seulement si l'édit est structurel pour la feature. is_structural_feature_edit
# exclut les fiches feature, worklogs, .lock, caches .ai/.* (helper #4).
# Le logger context-relevance touch (ci-dessus) reste agnostique du filtre :
# il logge tous les matches y compris les non-structurels.
seen_keys=""
while IFS=$'\t' read -r scope id feature_path; do
  [[ -z "$scope" || -z "$id" || -z "$feature_path" ]] && continue
  key="$scope/$id"
  case ":$seen_keys:" in *":$key:"*) continue;; esac
  seen_keys="$seen_keys:$key"

  if ! is_structural_feature_edit "$feature_path" "$rel"; then
    log_debug "auto-worklog-log skip $key : édit non-structurel ($rel)"
    continue
  fi

  # JSONL via jq pour échapper correctement quotes/backslashes/unicode dans key et rel
  jq -nc --arg feature "$key" --arg file "$rel" --arg ts "$ts" \
    '{feature: $feature, file: $file, ts: $ts}' >> "$log_file"
done <<< "$matches_full"

exit 0
