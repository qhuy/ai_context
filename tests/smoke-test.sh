#!/bin/bash
# smoke-test.sh — Génère un projet de test et vérifie qu'il est cohérent.
#
# Usage : bash tests/smoke-test.sh
# Requiert : copier installé dans le PATH.

set -euo pipefail

cd "$(dirname "$0")/.."
REPO="$PWD"
OUT="/tmp/ai-context-smoke-$$"

trap 'rm -rf "$OUT"' EXIT

echo "═══ smoke-test ═══"
echo "repo  = $REPO"
echo "out   = $OUT"

if ! command -v copier >/dev/null 2>&1; then
  echo "❌ copier introuvable. Installer : pip install --user copier" >&2
  exit 1
fi

echo
echo "[1/3] copier copy (profil par défaut)"
copier copy --defaults --trust \
  --data project_name=smoke-project \
  "$REPO" "$OUT"

echo
echo "[2/3] check-shims sur la sortie"
bash "$OUT/.ai/scripts/check-shims.sh"

echo
echo "[3/3] pre-turn-reminder (les 2 modes)"
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=text | head -3
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=json | jq -e '.hookSpecificOutput.additionalContext' > /dev/null \
  && echo "  ✓ json valide"

echo
echo "✅ smoke-test PASS"
