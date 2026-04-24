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

cd "$(git rev-parse --show-toplevel)"

FEATURES_DIR="$AI_CONTEXT_FEATURES_DIR"
FEATURE_TEMPLATE="$AI_CONTEXT_DOCS_ROOT/FEATURE_TEMPLATE.md"

# ─── Extraction du message ───
msg=""

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
  #   -m "$(cat <<'EOF'  → 1ère ligne entre les marqueurs EOF
  if [[ "$cmd" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
    msg="${BASH_REMATCH[1]}"
  elif [[ "$cmd" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
    msg="${BASH_REMATCH[1]}"
  elif [[ "$cmd" == *"<<'EOF'"* ]]; then
    msg=$(echo "$cmd" | awk "/<<'EOF'/{f=1; next} f && /^EOF/{exit} f" | head -n1)
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

# ─── feat: → features/ obligatoire ───
type=$(echo "$msg" | sed -E 's/^([a-z]+).*/\1/')
if [[ "$type" == "feat" ]]; then
  staged=$(git diff --cached --name-only 2>/dev/null || git diff --name-only)
  if ! echo "$staged" | grep -qE "^$FEATURES_DIR/"; then
    echo "❌ Commit 'feat:' sans fichier touché dans $FEATURES_DIR/" >&2
    echo "   Toute nouvelle feature DOIT avoir son fichier dans $FEATURES_DIR/<scope>/<id>.md" >&2
    echo "   Utiliser $FEATURE_TEMPLATE comme squelette." >&2
    echo "   Si ce n'est pas une feature, utiliser un autre type : fix/refactor/chore/..." >&2
    exit 1
  fi
fi

exit 0
