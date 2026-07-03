#!/bin/bash
# _vcs.sh — Abstraction source-control minimale pour ai_context.
#
# Providers supportes :
#   - git  : comportement historique, staging area distincte.
#   - tfvc : pending changes TFVC/TFS via `tf status` (pas de staging area).
#   - none : fallback read-only quand aucun VCS n'est detecte.

_vcs_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_vcs_config_file() {
  local root="${AI_CONTEXT_REPO_ROOT:-}"
  if [[ -z "$root" ]]; then
    root="$(_vcs_find_ai_root "$PWD" 2>/dev/null || true)"
  fi
  if [[ -z "$root" ]]; then
    root="$(cd "$_vcs_script_dir/../.." && pwd)"
  fi

  if [[ -f "$root/.ai/project/config.yml" ]]; then
    printf '%s\n' "$root/.ai/project/config.yml"
  elif [[ -f "$root/.ai/config.yml" ]]; then
    printf '%s\n' "$root/.ai/config.yml"
  else
    return 1
  fi
}

_vcs_config_provider() {
  if [[ -n "${AI_CONTEXT_VCS_PROVIDER:-}" ]]; then
    printf '%s\n' "$AI_CONTEXT_VCS_PROVIDER"
    return 0
  fi

  local config_file
  config_file="$(_vcs_config_file 2>/dev/null || true)"
  [[ -n "$config_file" && -f "$config_file" ]] || return 1

  awk '
    function clean(v) {
      sub(/[[:space:]]+#.*/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      gsub(/^["'\''"]|["'\''"]$/, "", v)
      return v
    }
    /^vcs_provider:[[:space:]]*/ {
      v=$0
      sub(/^vcs_provider:[[:space:]]*/, "", v)
      v=clean(v)
      if (length(v) > 0) { print v; exit }
    }
    /^vcs:[[:space:]]*$/ { in_vcs=1; next }
    in_vcs && /^[^[:space:]]/ { in_vcs=0 }
    in_vcs && /^[[:space:]]*provider:[[:space:]]*/ {
      v=$0
      sub(/^[[:space:]]*provider:[[:space:]]*/, "", v)
      v=clean(v)
      if (length(v) > 0) { print v; exit }
    }
  ' "$config_file"
}

_vcs_find_ai_root() {
  local dir="${1:-$PWD}"
  while [[ "$dir" != "/" && -n "$dir" ]]; do
    if [[ -f "$dir/.ai/index.md" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

_vcs_tf_cmd() {
  command -v tf 2>/dev/null || command -v tf.exe 2>/dev/null || true
}

_vcs_normalize_path() {
  local path="$1"
  path="${path//$'\r'/}"
  path="$(printf '%s' "$path" | tr '\\' '/')"
  while [[ "$path" == *'//'* ]]; do
    path="${path//\/\//\/}"
  done
  path="${path#./}"
  printf '%s\n' "$path"
}

_vcs_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

_vcs_relativize_path() {
  local root="$1"
  local path="$2"
  local root_norm path_norm
  root_norm="$(_vcs_normalize_path "$root")"
  path_norm="$(_vcs_normalize_path "$path")"
  case "$path_norm" in
    "$root_norm"/*) printf '%s\n' "${path_norm#"$root_norm"/}" ;;
    *) printf '%s\n' "${path_norm#./}" ;;
  esac
}

vcs_provider() {
  local configured
  configured="$(_vcs_config_provider 2>/dev/null || true)"
  configured="${configured:-auto}"

  case "$configured" in
    auto|"")
      if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf '%s\n' "git"
      elif [[ -n "$(_vcs_tf_cmd)" ]]; then
        printf '%s\n' "tfvc"
      else
        printf '%s\n' "none"
      fi
      ;;
    git|tfvc|none) printf '%s\n' "$configured" ;;
    *)
      printf '%s\n' "none"
      ;;
  esac
}

vcs_root() {
  local provider
  provider="$(vcs_provider)"
  case "$provider" in
    git)
      git rev-parse --show-toplevel 2>/dev/null || _vcs_find_ai_root "$PWD" || pwd
      ;;
    tfvc|none|*)
      if [[ -n "${AI_CONTEXT_REPO_ROOT:-}" ]]; then
        printf '%s\n' "$AI_CONTEXT_REPO_ROOT"
      else
        _vcs_find_ai_root "$PWD" || printf '%s\n' "$(cd "$_vcs_script_dir/../.." && pwd)"
      fi
      ;;
  esac
}

vcs_has_staging_area() {
  [[ "$(vcs_provider)" == "git" ]]
}

vcs_staged_label() {
  if vcs_has_staging_area; then
    printf '%s\n' "staged"
  else
    printf '%s\n' "pending"
  fi
}

vcs_changes_label() {
  case "$(vcs_provider)" in
    tfvc) printf '%s\n' "pending changes" ;;
    git) printf '%s\n' "working tree" ;;
    *) printf '%s\n' "local changes" ;;
  esac
}

_vcs_git_status_paths() {
  local field status path consume_old=0
  while IFS= read -r -d '' field; do
    if [[ $consume_old -eq 1 ]]; then
      consume_old=0
      continue
    fi
    status="${field:0:2}"
    path="${field:3}"
    case "${status:0:1}" in
      R|C) consume_old=1 ;;
    esac
    [[ -n "$path" ]] && printf '%s\n' "$path"
  done < <(git status --porcelain=v1 -z --untracked-files=all 2>/dev/null) | sort -u
}

_vcs_tf_status_output() {
  local tf_cmd
  tf_cmd="$(_vcs_tf_cmd)"
  [[ -n "$tf_cmd" ]] || return 1

  "$tf_cmd" status /recursive /format:detailed 2>/dev/null \
    || "$tf_cmd" status -recursive -format:detailed 2>/dev/null \
    || "$tf_cmd" status /recursive 2>/dev/null \
    || "$tf_cmd" status -recursive 2>/dev/null \
    || "$tf_cmd" status 2>/dev/null
}

_vcs_tfvc_pending_paths() {
  local root line value rel
  root="$(vcs_root)"
  _vcs_tf_status_output 2>/dev/null | while IFS= read -r line; do
    line="${line%$'\r'}"
    case "$line" in
      *"Local item"*:*|*"Local path"*:*|*"Source local item"*:*|*"Target local item"*:*|*"local item"*:*|*"local path"*:*)
        value="${line#*:}"
        value="$(_vcs_trim "$value")"
        [[ -z "$value" || "$value" == "<null>" || "$value" == "(null)" ]] && continue
        rel="$(_vcs_relativize_path "$root" "$value")"
        [[ -n "$rel" ]] && printf '%s\n' "$rel"
        ;;
    esac
  done | sort -u
}

vcs_pending_paths() {
  case "$(vcs_provider)" in
    git) _vcs_git_status_paths ;;
    tfvc) _vcs_tfvc_pending_paths ;;
    none|*) return 0 ;;
  esac
}

vcs_staged_paths() {
  case "$(vcs_provider)" in
    git) git diff --cached --name-only --no-renames 2>/dev/null || true ;;
    tfvc) vcs_pending_paths ;;
    none|*) return 0 ;;
  esac
}

vcs_diff_paths() {
  local base_ref="${1:-HEAD~1}"
  local head_ref="${2:-HEAD}"
  case "$(vcs_provider)" in
    git)
      git diff --name-only "$base_ref...$head_ref" 2>/dev/null \
        || git diff --name-only "$base_ref" "$head_ref" 2>/dev/null \
        || true
      ;;
    tfvc|none|*) return 0 ;;
  esac
}

vcs_ref_exists() {
  local ref="$1"
  case "$(vcs_provider)" in
    git) git rev-parse --verify "$ref" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

vcs_path_ts() {
  local path="$1"
  case "$(vcs_provider)" in
    git) git log -1 --format=%ct -- "$path" 2>/dev/null | head -n1 ;;
    *) echo 0 ;;
  esac
}

vcs_paths_latest_ts() {
  case "$(vcs_provider)" in
    git) git log -1 --format=%ct -- "$@" 2>/dev/null | head -n1 ;;
    *) echo 0 ;;
  esac
}
