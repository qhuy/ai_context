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
echo "[1/6] copier copy (profil par défaut)"
copier copy --defaults --trust \
  --data project_name=smoke-project \
  "$REPO" "$OUT"

echo
echo "[2/6] check-shims"
bash "$OUT/.ai/scripts/check-shims.sh"

echo
echo "[3/6] pre-turn-reminder (text + json)"
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=text | head -3
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=json | jq -e '.hookSpecificOutput.additionalContext' > /dev/null \
  && echo "  ✓ json valide"

echo
echo "[4/6] check-features (attendu : aucune feature → warn mais PASS)"
bash "$OUT/.ai/scripts/check-features.sh"

echo
echo "[5/6] check-commit-features : Conventional Commits refusent un message invalide"
if CLAUDE_COMMIT_MSG="message invalide sans type" bash "$OUT/.ai/scripts/check-commit-features.sh" 2>/dev/null; then
  echo "  ✗ un message invalide a été accepté"
  exit 1
fi
echo "  ✓ message invalide rejeté"

echo
echo "[6/8] check-commit-features : 'fix: ...' passe sans toucher features/"
if ! CLAUDE_COMMIT_MSG="fix: bug quelconque" bash "$OUT/.ai/scripts/check-commit-features.sh"; then
  echo "  ✗ 'fix:' sans features/ a été rejeté"
  exit 1
fi
echo "  ✓ fix: accepté"

echo
echo "[7/8] features-for-path : silent si aucune feature, matche via touches:"
if ! bash "$OUT/.ai/scripts/features-for-path.sh" src/foo.ts >/dev/null 2>&1; then
  echo "  ✓ aucune feature → exit 1 (attendu)"
fi
mkdir -p "$OUT/.docs/features/back"
cat > "$OUT/.docs/features/back/sample.md" <<'FEAT'
---
id: sample
scope: back
title: Sample
status: active
depends_on: []
touches:
  - src/foo.ts
---
FEAT
mkdir -p "$OUT/src" && echo "// stub" > "$OUT/src/foo.ts"
( cd "$OUT" && bash .ai/scripts/features-for-path.sh src/foo.ts | grep -q 'back/sample' ) \
  && echo "  ✓ path→feature résolu"

echo
echo "[8/8] check-features : 'touches:' morte fait échouer"
cat > "$OUT/.docs/features/back/dead.md" <<'FEAT'
---
id: dead
scope: back
title: Dead touches
status: active
depends_on: []
touches:
  - this/path/does/not/exist
---
FEAT
if ( cd "$OUT" && bash .ai/scripts/check-features.sh ) >/dev/null 2>&1; then
  echo "  ✗ touches morte acceptée"
  exit 1
fi
echo "  ✓ touches morte rejetée"

echo
echo "✅ smoke-test PASS"
