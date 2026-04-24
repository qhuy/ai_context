#!/bin/bash
# _lib.sh — Helpers partagés pour les scripts .ai/scripts/* (ai_context).
#
# Sourcé par les scripts :
#   . "$(dirname "$0")/_lib.sh"
#
# Expose :
#   require_cmd <bin...>        — échoue si une commande manque (stderr + exit 1)
#   log_debug "msg"             — stderr si $AI_CONTEXT_DEBUG=1, sinon silencieux
#   enable_globstar             — active ** (bash ≥4) ou no-op (bash 3.2 macOS)
#   with_index_lock <cmd...>    — acquiert un lock exclusif via mkdir (portable)
#   path_matches_touch <path> <touch>
#                               — 0 si un chemin repo matche une entrée touches:
#   features_matching_path <index> <path>
#                               — liste scope/id/path des features couvrant un path
#   STATUS_ENUM                 — liste des status valides (space-separated)
#   is_valid_status "s"         — 0 si valide, 1 sinon

STATUS_ENUM="draft active done deprecated archived"
AI_CONTEXT_DOCS_ROOT="${AI_CONTEXT_DOCS_ROOT:-.docs}"
AI_CONTEXT_FEATURES_DIR="$AI_CONTEXT_DOCS_ROOT/features"

# Retourne la liste JSON des status visibles dans le reminder.
# Par défaut : active + draft (les features en cours / à venir).
# Override : AI_CONTEXT_SHOW_ALL_STATUS=1 → tous les status.
# Le fallback '?' (status absent) reste toujours visible pour ne rien masquer
# par accident si le frontmatter est incomplet.
visible_statuses_jq() {
  if [[ "${AI_CONTEXT_SHOW_ALL_STATUS:-0}" == "1" ]]; then
    echo '["draft","active","done","deprecated","archived","?"]'
  else
    echo '["active","draft","?"]'
  fi
}

require_cmd() {
  local missing=()
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "❌ Dépendance(s) manquante(s) : ${missing[*]}" >&2
    echo "   Installe-les et relance. Sur macOS : brew install ${missing[*]}" >&2
    exit 1
  fi
}

log_debug() {
  [[ "${AI_CONTEXT_DEBUG:-0}" == "1" ]] || return 0
  echo "[debug $(basename "${BASH_SOURCE[1]:-$0}")] $*" >&2
}

enable_globstar() {
  shopt -s globstar 2>/dev/null || true
}

is_valid_status() {
  local s="$1"
  for valid in $STATUS_ENUM; do
    [[ "$s" == "$valid" ]] && return 0
  done
  return 1
}

# Matching canonique pour les entrées `touches:`.
# Supporte :
#   - fichier exact : src/foo.ts
#   - dossier      : src/auth couvre src/auth/service.ts
#   - glob bash    : src/**/*.ts, app/*/page.tsx, lib/[ab].js
#   - suffixe /**  : src/auth/** couvre src/auth et ses descendants
path_matches_touch() {
  local path="$1"
  local touch="$2"
  local normalized="${touch%/}"

  [[ -z "$path" || -z "$touch" ]] && return 1
  [[ "$path" == "$touch" ]] && return 0
  # shellcheck disable=SC2053
  [[ "$path" == $touch ]] && return 0

  if [[ "${touch: -3}" == "/**" ]]; then
    local prefix="${touch%/**}"
    [[ "$path" == "$prefix" || "$path" == "$prefix"/* ]] && return 0
  fi

  if [[ "$touch" != *[\*\?\[]* ]]; then
    [[ "$path" == "$normalized"/* ]] && return 0
  fi

  return 1
}

features_matching_path() {
  local index_file="$1"
  local rel_path="$2"

  [[ -f "$index_file" ]] || return 0

  while IFS=$'\t' read -r scope id feature_path touch; do
    [[ -z "$scope" || -z "$touch" ]] && continue
    if path_matches_touch "$rel_path" "$touch"; then
      printf '%s\t%s\t%s\n' "$scope" "$id" "$feature_path"
    fi
  done < <(jq -r '.features[] | . as $f | ($f.touches // [])[] | [$f.scope, $f.id, $f.path, .] | @tsv' "$index_file" 2>/dev/null) \
    | awk '!seen[$0]++'
}

# Lock basé sur mkdir (atomique, portable — pas de flock sur macOS par défaut).
# Usage : with_index_lock bash build-feature-index.sh --write
with_index_lock() {
  local lock_dir="${AI_CONTEXT_LOCK_DIR:-/tmp/.ai-context-$USER-$$-lock}"
  lock_dir="${AI_CONTEXT_LOCK_DIR:-/tmp/.ai-context-$(id -u 2>/dev/null || echo user)-index-lock}"
  local tries=0
  local max_tries=30  # 3s max (30 × 0.1s)
  while ! mkdir "$lock_dir" 2>/dev/null; do
    tries=$((tries + 1))
    if [[ $tries -ge $max_tries ]]; then
      log_debug "lock timeout sur $lock_dir, on procède sans"
      break
    fi
    sleep 0.1
  done
  # shellcheck disable=SC2064
  trap "rmdir '$lock_dir' 2>/dev/null || true" EXIT INT TERM
  "$@"
  local rc=$?
  rmdir "$lock_dir" 2>/dev/null || true
  trap - EXIT INT TERM
  return $rc
}
