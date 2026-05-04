#!/bin/bash
# check-shims.sh — Guard anti-dérive AI context (ai_context).
#
# Vérifie :
# 1. L'index .ai/index.md existe.
# 2. Les shims activés existent, référencent .ai/index.md, sont impératifs,
#    et restent minces (≤ MAX_LINES).
# 3. Les cibles canoniques référencées existent.
# 4. Le Pack A reste lean et ne réintroduit pas les charges coûteuses.
#
# Usage : bash .ai/scripts/check-shims.sh

set -euo pipefail

cd "$(dirname "$0")/../.."

MAX_LINES=15
MAX_PACK_A_WORDS=520
INDEX=".ai/index.md"

# Shims à vérifier (dérivés des agents activés au scaffold)
SHIMS=(
  "AGENTS.md"
  "CLAUDE.md"
)

CANONICAL=(
  ".ai/index.md"
  ".ai/reminder.md"
  ".ai/context-ignore.md"
  ".ai/quality/QUALITY_GATE.md"
  ".ai/rules/core.md"
  ".ai/rules/quality.md"
  ".ai/rules/workflow.md"
  ".ai/rules/product.md"
)

fail=0
ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1"; fail=1; }

echo "═══ check-shims ═══"

echo "[1/4] Index $INDEX"
if [[ -f "$INDEX" ]]; then ok "$INDEX présent"; else ko "$INDEX manquant"; fi

echo "[2/4] Shims (${#SHIMS[@]} agents)"
for shim in "${SHIMS[@]}"; do
  if [[ ! -f "$shim" ]]; then
    ko "$shim manquant"
    continue
  fi
  grep -q "\.ai/index\.md" "$shim" || ko "$shim ne référence pas .ai/index.md"
  grep -qE "DOIS|MUST|MANDATORY" "$shim" || ko "$shim n'a pas de langage impératif"
  lines=$(wc -l < "$shim" | tr -d ' ')
  if [[ "$lines" -gt "$MAX_LINES" ]]; then
    ko "$shim dépasse $MAX_LINES lignes ($lines)"
  else
    ok "$shim OK ($lines lignes)"
  fi
done

echo "[3/4] Cibles canoniques"
for target in "${CANONICAL[@]}"; do
  if [[ -f "$target" ]]; then ok "$target"; else ko "$target manquant"; fi
done

echo "[4/4] Pack A lean"
if [[ -f "$INDEX" ]]; then
  pack_a=$(awk '
    /^## Pack A/ {capture=1; next}
    /^## / && capture {exit}
    capture {print}
  ' "$INDEX")
  words=$(printf '%s\n' "$pack_a" | wc -w | tr -d ' ')
  if [[ "$words" -gt "$MAX_PACK_A_WORDS" ]]; then
    ko "Pack A dépasse $MAX_PACK_A_WORDS mots ($words)"
  else
    ok "Pack A OK ($words mots)"
  fi
  if printf '%s\n' "$pack_a" | grep -qE '\.ai/quality/QUALITY_GATE\.md|\.ai/agent/|guardrails\.md|ls .*features|docs/reference|\.claude/skills'; then
    ko "Pack A réintroduit des charges on-demand (quality gate, agent docs, guardrails, listings, références, skills)"
  else
    ok "Pack A ne référence pas de charges on-demand"
  fi
  if grep -q "charge \`.ai/agent/\\*\`" "$INDEX"; then
    ko "Index impose encore .ai/agent/*"
  else
    ok ".ai/agent/* reste optionnel"
  fi
fi

echo
if [[ "$fail" -eq 0 ]]; then
  echo "✅ PASS"
  exit 0
else
  echo "❌ FAIL"
  exit 1
fi
