#!/bin/bash
# features-for-path.sh — Trouve les features qui référencent un path donné.
#
# Lit `.ai/.feature-index.json` (compilé par build-feature-index.sh) et retourne
# les features dont au moins une entrée `touches:` matche le path.
#
# Modes :
#   - CLI : bash features-for-path.sh <path>
#           Sortie texte, exit 0 si trouvé, exit 1 sinon.
#           Option : --with-docs injecte les fiches liées (utile hors Claude).
#   - Claude PreToolUse hook : JSON sur stdin {tool_name, tool_input.file_path},
#           écrit un JSON avec hookSpecificOutput.additionalContext.
#
# Globs supportés : * ? [abc] et ** (si bash ≥4 ; sinon ** = *).
#
# Debug : AI_CONTEXT_DEBUG=1 bash features-for-path.sh <path>
#
# Bornes d'injection :
#   AI_CONTEXT_INJECT_FEATURE_DOCS=0       désactive les extraits docs en hook.
#   AI_CONTEXT_FEATURE_DOC_MAX_CHARS=10000 budget total des extraits.
#   AI_CONTEXT_FEATURE_DOC_PER_DOC_CHARS=3000 budget par fiche.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq
enable_globstar

repo_root="$(cd "$script_dir/../.." && pwd)"
features_dir="$repo_root/$AI_CONTEXT_FEATURES_DIR"
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

feature_keys=""
feature_context=""
feature_context_truncated=0
feature_doc_max_chars="${AI_CONTEXT_FEATURE_DOC_MAX_CHARS:-10000}"
feature_doc_per_doc_chars="${AI_CONTEXT_FEATURE_DOC_PER_DOC_CHARS:-3000}"

seen_feature_key() {
  local key="$1"
  printf '%s\n' "$feature_keys" | grep -Fxq "$key"
}

add_feature_key() {
  local key="$1"
  [[ -z "$key" ]] && return 0
  if seen_feature_key "$key"; then
    return 0
  fi
  feature_keys+="$key"$'\n'

  local dep
  while IFS= read -r dep; do
    [[ -z "$dep" || "$dep" == "null" ]] && continue
    add_feature_key "$dep"
  done < <(jq -r --arg key "$key" '
    .features[]
    | select((.scope + "/" + .id) == $key)
    | (.depends_on // [])[]
  ' "$index_file" 2>/dev/null || true)
}

load_feature_context() {
  feature_context=""
  feature_context_truncated=0

  [[ "${AI_CONTEXT_INJECT_FEATURE_DOCS:-1}" == "0" ]] && return 0
  [[ -f "$index_file" ]] || return 0
  [[ "$feature_doc_max_chars" =~ ^[0-9]+$ ]] || feature_doc_max_chars=10000
  [[ "$feature_doc_per_doc_chars" =~ ^[0-9]+$ ]] || feature_doc_per_doc_chars=3000
  [[ "$feature_doc_max_chars" -gt 0 && "$feature_doc_per_doc_chars" -gt 0 ]] || return 0

  local key path abs_path header excerpt remaining doc_budget excerpt_len current_len
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    current_len=$(printf '%s' "$feature_context" | wc -c | tr -d ' ')
    remaining=$((feature_doc_max_chars - current_len))
    if [[ "$remaining" -le 200 ]]; then
      feature_context_truncated=1
      break
    fi

    path=$(jq -r --arg key "$key" '
      .features[]
      | select((.scope + "/" + .id) == $key)
      | .path // empty
    ' "$index_file" 2>/dev/null | head -1)
    [[ -n "$path" ]] || continue
    if ! is_path_within_repo "$path"; then
      continue
    fi
    abs_path="$repo_root/$path"
    [[ -f "$abs_path" ]] || continue

    header=$'\n''--- '"$key"' ('"$path"$') ---\n'
    doc_budget="$feature_doc_per_doc_chars"
    if [[ "$doc_budget" -gt "$remaining" ]]; then
      doc_budget="$remaining"
    fi
    excerpt=$(LC_ALL=C head -c "$doc_budget" "$abs_path" 2>/dev/null || true)
    excerpt_len=$(printf '%s' "$excerpt" | wc -c | tr -d ' ')
    if [[ -n "$excerpt" ]]; then
      feature_context+="$header$excerpt"$'\n'
      if [[ "$excerpt_len" -ge "$doc_budget" ]]; then
        feature_context+=$'[... extrait tronqué ...]\n'
        feature_context_truncated=1
      fi
    fi
  done <<< "$feature_keys"

  if [[ -n "$feature_context" ]]; then
    feature_context=$'\nContexte feature injecté juste-à-temps (features directes + depends_on ; borné) :\n'"$feature_context"
    if [[ "$feature_context_truncated" == "1" ]]; then
      feature_context+=$'\nNote : contexte tronqué par budget. Si la décision dépend du détail, lis la fiche complète avant d'\''écrire.\n'
    fi
  fi
}

# ─── Détection du mode ───
target_path=""
mode="cli"
with_docs=0
strict_flag=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-docs|--docs)
      with_docs=1
      shift
      ;;
    --no-docs)
      AI_CONTEXT_INJECT_FEATURE_DOCS=0
      shift
      ;;
    --strict)
      strict_flag=1
      shift
      ;;
    -*)
      echo "Usage : $0 [--with-docs] [--no-docs] [--strict] <path>" >&2
      exit 2
      ;;
    *)
      target_path="$1"
      shift
      ;;
  esac
done

# Mappe --strict ou env var vers _FEATURES_MATCHING_POLICY (Niveau 2 wrapper :
# best-effort par défaut, strict opt-in).
if [[ "$strict_flag" == "1" || "${AI_CONTEXT_FEATURES_STRICT:-0}" == "1" ]]; then
  export _FEATURES_MATCHING_POLICY=strict
fi

if [[ -n "$target_path" ]]; then
  mode="cli"
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

# ─── Lookup dans l'index avec ranking par spécificité ───
matches=""
omitted_count=0
top_k="${AI_CONTEXT_FEATURES_TOP_K:-3}"
[[ "$top_k" =~ ^[0-9]+$ ]] || top_k=3

if [[ -f "$index_file" ]]; then
  # Récupère matches enrichis (scope, id, feature_path, touch_matched), score chaque
  # touch, garde le meilleur par feature, trie globalement, top-K.
  ranked_lines=""
  declare_feature_key_seen=""
  best_per_feature=""
  ranked_rc=0

  # Capture la sortie ET le code retour de features_matching_path_ranked
  # (rc=2 si pattern unsupported en mode strict, propagé par le matcher).
  ranked_output=$(features_matching_path_ranked "$index_file" "$rel_path"); ranked_rc=$?

  while IFS=$'\t' read -r scope id fpath touch; do
    [[ -z "$scope" ]] && continue
    score_line=$(_score_touch_pattern "$touch")
    IFS=$'\t' read -r tier plen wcs <<< "$score_line"
    # ligne intermédiaire : tier\tplen\twcs\tscope\tid\tfpath\ttouch
    best_per_feature+="$tier"$'\t'"$plen"$'\t'"$wcs"$'\t'"$scope"$'\t'"$id"$'\t'"$fpath"$'\t'"$touch"$'\n'
  done <<< "$ranked_output"

  if [[ -n "$best_per_feature" ]]; then
    # Garde le meilleur score par feature (scope/id) : tri sur score puis dédup par scope/id.
    # Tri : tier desc, plen desc, wcs asc, scope/id asc (tie-break stable).
    ranked_lines=$(printf '%s' "$best_per_feature" \
      | sort -t$'\t' -k1,1nr -k2,2nr -k3,3n -k4,4 -k5,5 \
      | awk -F'\t' '!seen[$4 "/" $5]++')

    # Compte total avant top-K
    total_count=$(printf '%s' "$ranked_lines" | grep -c '^' || true)
    [[ -z "$total_count" ]] && total_count=0

    # Top-K
    kept_lines=$(printf '%s' "$ranked_lines" | head -n "$top_k")
    if [[ "$total_count" -gt "$top_k" ]]; then
      omitted_count=$((total_count - top_k))
    fi

    # Construit la sortie matches + add_feature_key sur chaque feature gardée
    while IFS=$'\t' read -r tier plen wcs scope id fpath touch; do
      [[ -z "$scope" ]] && continue
      matches+="  • ${scope}/${id} (${fpath})"$'\n'
      add_feature_key "${scope}/${id}"
    done <<< "$kept_lines"

    if [[ "$omitted_count" -gt 0 ]]; then
      matches+="  • _(${omitted_count} feature(s) supplémentaire(s) omise(s) par ranking top-${top_k})_"$'\n'
    fi
  fi
fi

end_ts=$(date +%s 2>/dev/null || echo 0)
log_debug "durée lookup touches : $((end_ts - start_ts))s"

# ─── Output ───
if [[ "$mode" == "hook" ]]; then
  if [[ -z "$matches" ]]; then
    exit 0
  fi
  load_feature_context
  ctx=$'⚠️  Features concernées par ce fichier — relis-les AVANT d\'écrire, mets à jour leur section Historique APRÈS :\n'"$matches"
  if [[ -n "$feature_context" ]]; then
    ctx+="$feature_context"
  fi
  jq -n --arg c "$ctx" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: $c
    }
  }'
else
  if [[ -z "$matches" ]]; then
    # Mode strict : pattern unsupported propagé via ranked_rc → exit ≠ 0.
    if [[ "${_FEATURES_MATCHING_POLICY:-warn}" == "strict" && "${ranked_rc:-0}" -eq 2 ]]; then
      echo "Pattern unsupported détecté en mode strict pour '$rel_path'." >&2
      exit 2
    fi
    echo "Aucune feature ne référence '$rel_path' via touches:."
    exit 1
  fi
  echo "Features concernées par '$rel_path' :"
  printf '%s' "$matches"
  if [[ "$with_docs" == "1" ]]; then
    load_feature_context
    printf '%s' "$feature_context"
  fi
  # En mode strict, exit ≠ 0 même si des matches existent, pour signaler
  # le pattern cassé au caller (CI/doctor).
  if [[ "${_FEATURES_MATCHING_POLICY:-warn}" == "strict" && "${ranked_rc:-0}" -eq 2 ]]; then
    echo "Pattern unsupported détecté en mode strict (au moins un touches: cassé)." >&2
    exit 2
  fi
fi
