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
ANSWERS_FILE=".copier-answers.yml"

AGENTS_SELECTED=()
SHIMS=()

array_count() {
  local count=0
  local _item
  for _item in "$@"; do
    count=$((count + 1))
  done
  printf '%s' "$count"
}

add_agent() {
  local candidate="$1"
  local existing

  candidate="${candidate//\"/}"
  candidate="${candidate//\'/}"
  candidate="$(printf '%s' "$candidate" | tr -d '[:space:]')"

  case "$candidate" in
    claude|codex|cursor|gemini|copilot) ;;
    *) return 0 ;;
  esac

  for existing in ${AGENTS_SELECTED[@]+"${AGENTS_SELECTED[@]}"}; do
    [[ "$existing" == "$candidate" ]] && return 0
  done
  AGENTS_SELECTED+=("$candidate")
}

add_shim() {
  local candidate="$1"
  local existing

  for existing in ${SHIMS[@]+"${SHIMS[@]}"}; do
    [[ "$existing" == "$candidate" ]] && return 0
  done
  SHIMS+=("$candidate")
}

NATIVE_SUPPORT_FILE=".ai/native-context-support.tsv"
NATIVE_SKIPPED=()

# Lecture native d'AGENTS.md confirmée au registre pour cet agent ?
# (core/agents-md-native-collapse-path : un shim dédié ne devient optionnel
# que si le statut est "confirmed" — pending = shim toujours requis.)
native_confirmed() {
  local agent="$1"
  [[ -f "$NATIVE_SUPPORT_FILE" ]] || return 1
  awk -F'\t' -v a="$agent" '$1 == a && $3 == "confirmed" { found=1 } END { exit found ? 0 : 1 }' "$NATIVE_SUPPORT_FILE"
}

answers_agents() {
  local file="$1"
  local yq_out

  [[ -f "$file" ]] || return 0

  if command -v yq >/dev/null 2>&1; then
    yq_out="$(yq eval -r '.agents[]? // empty' "$file" 2>/dev/null || true)"
    if [[ -n "$yq_out" ]]; then
      printf '%s\n' "$yq_out"
      return 0
    fi
  fi

  awk '
    /^[[:space:]]*agents:[[:space:]]*\[/ {
      line=$0
      sub(/^[^[]*\[/, "", line)
      sub(/\].*$/, "", line)
      gsub(/[" \t]/, "", line)
      n=split(line, values, ",")
      for (i = 1; i <= n; i++) if (values[i] != "") print values[i]
      next
    }
    /^[[:space:]]*agents:[[:space:]]*$/ { in_agents=1; next }
    in_agents && /^[^[:space:]-]/ { in_agents=0 }
    in_agents && /^[[:space:]]*-/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]+#.*$/, "", line)
      gsub(/[" \t]/, "", line)
      if (line != "") print line
    }
  ' "$file"
}

load_agents() {
  local agent

  if [[ -f "$ANSWERS_FILE" ]]; then
    while IFS= read -r agent; do
      add_agent "$agent"
    done < <(answers_agents "$ANSWERS_FILE")
  fi

  # Le repo source dogfood n'a pas toujours de .copier-answers.yml. Dans ce cas,
  # conserver le comportement historique en validant les shims présents.
  if [[ "$(array_count ${AGENTS_SELECTED[@]+"${AGENTS_SELECTED[@]}"})" -eq 0 ]]; then
    [[ -f "CLAUDE.md" ]] && add_agent "claude"
    [[ -f "GEMINI.md" ]] && add_agent "gemini"
    [[ -f ".github/copilot-instructions.md" ]] && add_agent "copilot"
    [[ -d ".cursor" ]] && add_agent "cursor"
    [[ -d ".agents" ]] && add_agent "codex"
  fi

  return 0
}

shim_for_agent() {
  case "$1" in
    claude) printf 'CLAUDE.md' ;;
    gemini) printf 'GEMINI.md' ;;
    copilot) printf '.github/copilot-instructions.md' ;;
    *) return 1 ;;
  esac
}

build_shims() {
  local agent
  local shim

  add_shim "AGENTS.md"
  load_agents
  for agent in ${AGENTS_SELECTED[@]+"${AGENTS_SELECTED[@]}"}; do
    if shim="$(shim_for_agent "$agent")"; then
      # Shim dédié absent + lecture native confirmée => optionnel (opt-out).
      # S'il existe (compat, ex enable_copilot_shim), on le valide normalement.
      if [[ ! -f "$shim" ]] && native_confirmed "$agent"; then
        NATIVE_SKIPPED+=("$agent")
        continue
      fi
      add_shim "$shim"
    fi
  done
}

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

build_shims

fail=0
ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1"; fail=1; }

echo "═══ check-shims ═══"

echo "[1/4] Index $INDEX"
if [[ -f "$INDEX" ]]; then ok "$INDEX présent"; else ko "$INDEX manquant"; fi

echo "[2/4] Shims ($(array_count ${SHIMS[@]+"${SHIMS[@]}"}) fichiers)"
for shim in ${SHIMS[@]+"${SHIMS[@]}"}; do
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
for agent in ${NATIVE_SKIPPED[@]+"${NATIVE_SKIPPED[@]}"}; do
  ok "$agent : shim dédié absent — AGENTS.md natif confirmé (registre)"
done

# AGENTS.md doit rester AUTO-SUFFISANT : porter les hard rules inline (pas un
# simple pointeur vers .ai/index.md), pour que l'indirection devienne optionnelle
# si un agent lit AGENTS.md nativement (#34235 ; core/agents-md-native-collapse-path).
if [[ -f "AGENTS.md" ]]; then
  if grep -qiE 'hard rules|règles dures' AGENTS.md; then
    ok "AGENTS.md auto-suffisant (hard rules inline)"
  else
    ko "AGENTS.md doit porter les hard rules inline (self-suffisance collapse-path, pas un simple pointeur)"
  fi
fi

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
