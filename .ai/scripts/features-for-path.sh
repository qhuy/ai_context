#!/bin/bash
# features-for-path.sh — Trouve les features qui référencent un path donné.
#
# Lit `.ai/.feature-index.json` (compilé par build-feature-index.sh) et retourne
# les features dont au moins une entrée `touches:` matche le path.
#
# Modes :
#   - CLI : bash features-for-path.sh <path>
#           Sortie texte, exit 0 si trouvé, exit 1 sinon.
#   - Claude PreToolUse hook : JSON sur stdin {tool_name, tool_input.file_path},
#           écrit un JSON avec hookSpecificOutput.additionalContext.
#
# Globs supportés : * ? [abc] et ** (si bash ≥4 ; sinon ** = *).
#
# Debug : AI_CONTEXT_DEBUG=1 bash features-for-path.sh <path>

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq
enable_globstar

repo_root="$(cd "$script_dir/../.." && pwd)"
features_dir="$repo_root/.docs/features"
index_file="$repo_root/.ai/.feature-index.json"

ensure_index() {
  if [[ ! -f "$index_file" ]]; then
    log_debug "index absent, rebuild"
    bash "$script_dir/build-feature-index.sh" --write
    return
  fi
  if [[ -d "$features_dir" ]]; then
    if find "$features_dir" -name '*.md' -newer "$index_file" -print -quit 2>/dev/null | grep -q .; then
      log_debug "index obsolète (feature plus récente), rebuild"
      bash "$script_dir/build-feature-index.sh" --write
    fi
  fi
}

# ─── Détection du mode ───
target_path=""
mode="cli"
if [[ $# -ge 1 ]]; then
  target_path="$1"
elif [[ ! -t 0 ]]; then
  mode="hook"
  payload=$(cat)
  tool_name=$(echo "$payload" | jq -r '.tool_name // ""')
  case "$tool_name" in
    Write|Edit|MultiEdit) ;;
    *) exit 0 ;;
  esac
  target_path=$(echo "$payload" | jq -r '.tool_input.file_path // .tool_input.path // ""')
fi

if [[ -z "$target_path" ]]; then
  [[ "$mode" == "cli" ]] && { echo "Usage : $0 <path>" >&2; exit 2; }
  exit 0
fi

rel_path="${target_path#"$repo_root/"}"
log_debug "mode=$mode rel_path=$rel_path"

start_ts=$(date +%s 2>/dev/null || echo 0)
ensure_index

# ─── Lookup dans l'index ───
matches=""
count=0
if [[ -f "$index_file" ]]; then
  while IFS='|' read -r scope id path entry; do
    [[ -z "$entry" ]] && continue
    [[ "$entry" == "[]" ]] && continue
    count=$((count + 1))
    # shellcheck disable=SC2053
    if [[ "$rel_path" == $entry ]] || [[ "$rel_path" == $entry/* ]]; then
      matches+="  • ${scope}/${id} (${path})"$'\n'
    fi
  done < <(jq -r '.features[] | . as $f | ($f.touches // [])[] | [$f.scope, $f.id, $f.path, .] | join("|")' "$index_file")

  if [[ -n "$matches" ]]; then
    matches=$(printf '%s' "$matches" | awk '!seen[$0]++')
    matches="${matches}"$'\n'
  fi
fi

end_ts=$(date +%s 2>/dev/null || echo 0)
log_debug "touches testés : $count, durée : $((end_ts - start_ts))s"

# ─── Output ───
if [[ "$mode" == "hook" ]]; then
  if [[ -z "$matches" ]]; then
    exit 0
  fi
  ctx=$'⚠️  Features concernées par ce fichier — relis-les AVANT d\'écrire, mets à jour leur section Historique APRÈS :\n'"$matches"
  jq -n --arg c "$ctx" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: $c
    }
  }'
else
  if [[ -z "$matches" ]]; then
    echo "Aucune feature ne référence '$rel_path' via touches:."
    exit 1
  fi
  echo "Features concernées par '$rel_path' :"
  printf '%s' "$matches"
fi
