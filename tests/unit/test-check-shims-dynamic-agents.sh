#!/bin/bash
# test-check-shims-dynamic-agents.sh — core/agents-md-shim-canonical.
#
# Verrouille le contrat: check-shims lit les agents actives depuis
# .copier-answers.yml et echoue si un shim active manque.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-shims-agents.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "X $*" >&2
  exit 1
}

make_repo() {
  local d="$1"
  local rule

  mkdir -p "$d/.ai/scripts" "$d/.ai/rules" "$d/.ai/quality"
  cp "$repo_root/.ai/scripts/check-shims.sh" "$d/.ai/scripts/check-shims.sh"
  cp "$repo_root/.ai/index.md" "$d/.ai/index.md"
  cp "$repo_root/.ai/reminder.md" "$d/.ai/reminder.md"
  cp "$repo_root/.ai/context-ignore.md" "$d/.ai/context-ignore.md"
  cp "$repo_root/.ai/quality/QUALITY_GATE.md" "$d/.ai/quality/QUALITY_GATE.md"
  for rule in core quality workflow product; do
    cp "$repo_root/.ai/rules/$rule.md" "$d/.ai/rules/$rule.md"
  done

  cat > "$d/AGENTS.md" <<'MD'
# AGENTS.md
> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

Hard rules :
- Un scope primaire par tache ; cross-scope => HANDOFF.
- Avant DONE : quality gate + docs impactees.

Source unique : `.ai/`.
MD
}

write_claude() {
  cat > "$1/CLAUDE.md" <<'MD'
# CLAUDE.md
> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

@AGENTS.md
MD
}

write_gemini() {
  cat > "$1/GEMINI.md" <<'MD'
# GEMINI.md
> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

@AGENTS.md
MD
}

write_copilot() {
  mkdir -p "$1/.github"
  cat > "$1/.github/copilot-instructions.md" <<'MD'
# Copilot Instructions
> **Tu DOIS lire [`../.ai/index.md`](../.ai/index.md) avant toute action.**

Hard rules :
- Un scope primaire par tache ; cross-scope => HANDOFF.
MD
}

repo_fallback="$tmp/fallback"
make_repo "$repo_fallback"
write_claude "$repo_fallback"
(
  cd "$repo_fallback"
  out="$(bash .ai/scripts/check-shims.sh 2>&1)" \
    || { echo "$out"; fail "fallback sans .copier-answers.yml devrait passer"; }
  echo "$out" | grep -q "Shims (2 fichiers)" \
    || { echo "$out"; fail "fallback doit verifier AGENTS.md + CLAUDE.md"; }
)

repo_multi="$tmp/multi"
make_repo "$repo_multi"
write_claude "$repo_multi"
write_gemini "$repo_multi"
write_copilot "$repo_multi"
cat > "$repo_multi/.copier-answers.yml" <<'YAML'
agents:
  - claude
  - codex
  - cursor
  - gemini
  - copilot
YAML
(
  cd "$repo_multi"
  out="$(bash .ai/scripts/check-shims.sh 2>&1)" \
    || { echo "$out"; fail "agents actives avec shims presents devrait passer"; }
  echo "$out" | grep -q "Shims (4 fichiers)" \
    || { echo "$out"; fail "agents actives doivent verifier AGENTS/CLAUDE/GEMINI/Copilot"; }
)

rm "$repo_multi/GEMINI.md"
(
  cd "$repo_multi"
  set +e
  out="$(bash .ai/scripts/check-shims.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] \
    || { echo "$out"; fail "GEMINI.md manquant devrait faire echouer check-shims"; }
  echo "$out" | grep -q "GEMINI.md manquant" \
    || { echo "$out"; fail "message attendu pour le shim Gemini manquant"; }
)

repo_flow="$tmp/flow"
make_repo "$repo_flow"
write_claude "$repo_flow"
write_gemini "$repo_flow"
write_copilot "$repo_flow"
cat > "$repo_flow/.copier-answers.yml" <<'YAML'
agents: ["claude", "gemini", "copilot"]
YAML
(
  cd "$repo_flow"
  out="$(bash .ai/scripts/check-shims.sh 2>&1)" \
    || { echo "$out"; fail "agents en liste YAML inline devrait passer"; }
  echo "$out" | grep -q "Shims (4 fichiers)" \
    || { echo "$out"; fail "liste inline doit verifier les trois shims derives"; }
)

echo "PASS test-check-shims-dynamic-agents"
