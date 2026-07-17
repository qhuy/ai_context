#!/bin/bash
# check-commit-features.sh — Valide qu'un commit respecte Conventional Commits
# et que les commits `feat:` touchent au moins un fichier features/.
#
# Trois modes d'appel :
#   - Git commit-msg hook    : $1 = chemin vers le fichier de commit message.
#   - Claude PreToolUse hook : JSON Claude sur stdin (tool_name=Bash, .tool_input.command).
#   - Explicite              : var env CLAUDE_COMMIT_MSG.
#
# Exit 0 = OK, 1 = BLOCK.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

# jq n'est requis qu'en mode stdin JSON ; vérif différée plus bas.

repo_root="$(vcs_root)"
cd "$repo_root"

FEATURES_DIR="$AI_CONTEXT_FEATURES_DIR"
FEATURE_TEMPLATE="$AI_CONTEXT_DOCS_ROOT/FEATURE_TEMPLATE.md"

# ─── Extraction du message ───
msg=""

read_commit_message_file() {
  local message_file="$1"
  [[ -n "$message_file" && -f "$message_file" ]] || return 1
  msg=$(head -n1 "$message_file")
}

if [[ -n "${1:-}" && -f "$1" ]]; then
  msg=$(head -n1 "$1")
elif [[ -n "${CLAUDE_COMMIT_MSG:-}" ]]; then
  msg=$(echo "$CLAUDE_COMMIT_MSG" | head -n1)
elif [[ ! -t 0 ]]; then
  # JSON Claude sur stdin
  require_cmd jq
  payload=$(cat)
  tool_name=$(echo "$payload" | jq -r '.tool_name // ""')
  [[ "$tool_name" != "Bash" ]] && exit 0

  cmd=$(echo "$payload" | jq -r '.tool_input.command // ""')
  case "$cmd" in *git*commit*) ;; *) exit 0 ;; esac

  # Extraction best-effort du message :
  #   -m "simple"        → capture interne
  #   -m 'simple'        → capture interne
  #   --message=...      → capture interne
  #   -F/-Fpath/--file <path>/--file=path → 1ère ligne du fichier message
  #   -m "$(cat <<'EOF'  → 1ère ligne entre les marqueurs EOF
  # Ordre important : -m est testé avant --message= pour qu'un message -m "..."
  # contenant littéralement la sous-chaîne --message= ne soit pas mal-extrait.
  if [[ "$cmd" == *"<<'EOF'"* ]]; then
    msg=$(echo "$cmd" | awk "/<<'EOF'/{f=1; next} f && /^EOF/{exit} f" | head -n1)
  elif [[ "$cmd" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
    msg="${BASH_REMATCH[1]}"
  elif [[ "$cmd" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
    msg="${BASH_REMATCH[1]}"
  elif [[ "$cmd" =~ --message=\"([^\"]+)\" ]]; then
    msg="${BASH_REMATCH[1]}"
  elif [[ "$cmd" =~ --message=\'([^\']+)\' ]]; then
    msg="${BASH_REMATCH[1]}"
  elif [[ "$cmd" =~ --message=([^[:space:]\;\&\|]+) ]]; then
    msg="${BASH_REMATCH[1]}"
  elif [[ "$cmd" =~ -F[[:space:]]+\"([^\"]+)\" ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ -F[[:space:]]+\'([^\']+)\' ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ -F[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ -F([^[:space:]\;\&\|]+) ]]; then
    # Forme collée (option courte sans espace, ex: -Fmsg.txt) — valide en git.
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ --file=\"([^\"]+)\" ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ --file=\'([^\']+)\' ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ --file=([^[:space:]\;\&\|]+) ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ --file[[:space:]]+\"([^\"]+)\" ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ --file[[:space:]]+\'([^\']+)\' ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  elif [[ "$cmd" =~ --file[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
    read_commit_message_file "${BASH_REMATCH[1]}" || true
  fi

  # Si on n'a rien pu extraire : laisser passer, le git commit-msg hook rattrapera.
  [[ -z "$msg" ]] && exit 0
else
  # Pas de source → laisser passer.
  exit 0
fi

# ─── Validation Conventional Commits ───
valid_types='^(feat|fix|refactor|chore|test|docs|style|perf|ci|build|revert)(\([a-z0-9_/-]+\))?!?:'

if ! echo "$msg" | grep -qE "$valid_types"; then
  echo "❌ Message de commit invalide." >&2
  echo "   Format attendu : <type>[(scope)]: <description>" >&2
  echo "   Types autorisés : feat, fix, refactor, chore, test, docs, style, perf, ci, build, revert" >&2
  echo "   Reçu : $msg" >&2
  exit 1
fi

# ─── feat: → fiche feature obligatoire ET pertinente ───
type=$(echo "$msg" | sed -E 's/^([a-z]+).*/\1/')
if [[ "$type" == "feat" ]]; then
  staged=$(vcs_staged_paths)
  staged_feature_docs=""
  staged_non_feature=""
  while IFS= read -r staged_path; do
    [[ -n "$staged_path" ]] || continue
    if is_canonical_feature_doc "$staged_path" "$FEATURES_DIR" \
       || is_feature_worklog "$staged_path" "$FEATURES_DIR"; then
      staged_feature_docs="${staged_feature_docs}${staged_path}"$'\n'
    elif is_reserved_feature_doc "$staged_path" "$FEATURES_DIR"; then
      # Les index/logs du mesh ne prouvent pas la documentation d'une feature,
      # mais ne sont pas non plus du code à couvrir par touches:.
      continue
    else
      staged_non_feature="${staged_non_feature}${staged_path}"$'\n'
    fi
  done <<< "$staged"
  if [[ -z "$staged_feature_docs" ]]; then
    echo "❌ Commit 'feat:' sans fichier feature dans le delta $(vcs_staged_label) ($FEATURES_DIR/)" >&2
    echo "   Toute nouvelle feature DOIT avoir son fichier dans $FEATURES_DIR/<scope>/<id>.md" >&2
    echo "   Utiliser $FEATURE_TEMPLATE comme squelette." >&2
    echo "   Si ce n'est pas une feature, utiliser un autre type : fix/refactor/chore/..." >&2
    exit 1
  fi

  if [[ -n "$staged_non_feature" ]]; then
    index_tmp="$(mktemp "${TMPDIR:-/tmp}/aic-commit-features.XXXXXX")"
    trap 'rm -f "$index_tmp"' EXIT
    if ! bash "$script_dir/build-feature-index.sh" > "$index_tmp" 2>/dev/null; then
      echo "❌ Commit 'feat:' : impossible de générer l'index temporaire pour vérifier la fiche liée." >&2
      echo "   Corrige les fiches feature puis relance le commit." >&2
      exit 1
    fi

    relevant_doc=0
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      while IFS=$'\t' read -r scope id feature_path; do
        [[ -z "$scope" || -z "$id" || -z "$feature_path" ]] && continue
        worklog_path="$(dirname "$feature_path")/$id.worklog.md"
        if printf '%s\n' "$staged_feature_docs" | grep -Fxq "$feature_path" \
          || printf '%s\n' "$staged_feature_docs" | grep -Fxq "$worklog_path"; then
          relevant_doc=1
          break 2
        fi
      done < <(features_matching_path "$index_tmp" "$rel")
    done <<< "$staged_non_feature"

    if [[ "$relevant_doc" -ne 1 ]]; then
      echo "❌ Commit 'feat:' avec fiche feature $(vcs_staged_label), mais aucune ne couvre les fichiers non-doc du commit." >&2
      echo "   Mets à jour la fiche dont touches: couvre le fichier modifié, ou corrige touches:." >&2
      echo "   Si le changement est purement documentaire, utiliser docs: plutôt que feat:." >&2
      exit 1
    fi
  fi
fi

bash "$script_dir/check-feature-freshness.sh" --staged --strict

exit 0
