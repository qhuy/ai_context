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

  mkdir -p "$d/.ai/scripts" "$d/.ai/rules" "$d/.ai/quality" "$d/.ai/workflows"
  cp "$repo_root/.ai/scripts/check-shims.sh" "$d/.ai/scripts/check-shims.sh"
  cp "$repo_root/.ai/index.md" "$d/.ai/index.md"
  cp "$repo_root/.ai/reminder.md" "$d/.ai/reminder.md"
  cp "$repo_root/.ai/context-ignore.md" "$d/.ai/context-ignore.md"
  cp "$repo_root/.ai/quality/QUALITY_GATE.md" "$d/.ai/quality/QUALITY_GATE.md"
  for rule in core quality workflow product; do
    cp "$repo_root/.ai/rules/$rule.md" "$d/.ai/rules/$rule.md"
  done
  printf '# feature-new\n' > "$d/.ai/workflows/feature-new.md"

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

write_skill() {
  local d="$1"
  local root="$2"
  local name="${3:-aic-demo}"

  mkdir -p "$d/$root/$name"
  cat > "$d/$root/$name/SKILL.md" <<'MD'
# Skill demo

Référence interne : .ai/workflows/feature-new.md
MD
  cat > "$d/$root/$name/workflow.md" <<'MD'
# Workflow demo

Voir .ai/workflows/feature-new.md.
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

# Registre natif confirmed : shim copilot absent devient optionnel (opt-out)
repo_native="$tmp/native"
make_repo "$repo_native"
write_claude "$repo_native"
cat > "$repo_native/.copier-answers.yml" <<'YAML'
agents: ["claude", "copilot"]
YAML
cat > "$repo_native/.ai/native-context-support.tsv" <<'TSV'
# agent	shared_entrypoint	status	checked_at	evidence	note
copilot	AGENTS.md	confirmed	2026-07-06	https://example.invalid/copilot-agents-md	Coding agent lit AGENTS.md nativement.
TSV
(
  cd "$repo_native"
  out="$(bash .ai/scripts/check-shims.sh 2>&1)" \
    || { echo "$out"; fail "copilot confirmed + shim absent devrait passer (AGENTS.md natif)"; }
  echo "$out" | grep -q "copilot : shim dédié absent" \
    || { echo "$out"; fail "message de skip natif attendu pour copilot"; }
)

# Registre pending (ou absent) : le shim copilot reste requis
cat > "$repo_native/.ai/native-context-support.tsv" <<'TSV'
# agent	shared_entrypoint	status	checked_at	evidence	note
copilot	AGENTS.md	pending	2026-07-06	https://example.invalid/copilot-agents-md	Non confirme.
TSV
(
  cd "$repo_native"
  set +e
  out="$(bash .ai/scripts/check-shims.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] \
    || { echo "$out"; fail "copilot pending + shim absent devrait echouer"; }
  echo "$out" | grep -q "copilot-instructions.md manquant" \
    || { echo "$out"; fail "message de shim copilot manquant attendu (pending)"; }
)

# Shim compat present : valide normalement meme si confirmed
write_copilot "$repo_native"
cat > "$repo_native/.ai/native-context-support.tsv" <<'TSV'
# agent	shared_entrypoint	status	checked_at	evidence	note
copilot	AGENTS.md	confirmed	2026-07-06	https://example.invalid/copilot-agents-md	Coding agent lit AGENTS.md nativement.
TSV
(
  cd "$repo_native"
  out="$(bash .ai/scripts/check-shims.sh 2>&1)" \
    || { echo "$out"; fail "shim compat present + confirmed devrait passer"; }
  echo "$out" | grep -q "copilot-instructions.md OK" \
    || { echo "$out"; fail "le shim compat present doit etre valide normalement"; }
)

# Skills : une surface seule est valide ; la parité stricte ne s'applique que
# quand Claude et Codex sont tous deux générés.
repo_claude_skill="$tmp/claude-skill"
make_repo "$repo_claude_skill"
write_claude "$repo_claude_skill"
write_skill "$repo_claude_skill" ".claude/skills"
cat > "$repo_claude_skill/.copier-answers.yml" <<'YAML'
agents: ["claude"]
YAML
(
  cd "$repo_claude_skill"
  out="$(bash .ai/scripts/check-shims.sh 2>&1)" \
    || { echo "$out"; fail "skill Claude seul devrait passer sans surface Codex"; }
  echo "$out" | grep -q ".claude/skills/aic-demo présent" \
    || { echo "$out"; fail "skill Claude seul doit etre valide comme surface unique"; }
)

repo_pair_skill="$tmp/pair-skill"
make_repo "$repo_pair_skill"
write_claude "$repo_pair_skill"
write_skill "$repo_pair_skill" ".claude/skills"
mkdir -p "$repo_pair_skill/.agents/skills"
cat > "$repo_pair_skill/.copier-answers.yml" <<'YAML'
agents: ["claude", "codex"]
YAML
(
  cd "$repo_pair_skill"
  set +e
  out="$(bash .ai/scripts/check-shims.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] \
    || { echo "$out"; fail "skill non paire devrait echouer quand Claude+Codex sont presents"; }
  echo "$out" | grep -q "sans pair .agents/skills" \
    || { echo "$out"; fail "message de skill non paire attendu"; }
)

# Résidu de désélection : codex a été retiré de .copier-answers.yml après un
# scaffold Claude+Codex, mais .agents/skills/* reste physiquement présent
# (copier update ne supprime pas les fichiers retirés du rendu). require_skill_pairs
# ne doit plus se baser sur la seule présence disque : le résidu doit être signalé.
repo_residue="$tmp/residue"
make_repo "$repo_residue"
write_claude "$repo_residue"
write_skill "$repo_residue" ".claude/skills"
write_skill "$repo_residue" ".agents/skills"
cat > "$repo_residue/.copier-answers.yml" <<'YAML'
agents: ["claude"]
YAML
(
  cd "$repo_residue"
  set +e
  out="$(bash .ai/scripts/check-shims.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] \
    || { echo "$out"; fail "résidu .agents/skills après désélection codex devrait échouer"; }
  echo "$out" | grep -q "résidu de désélection" \
    || { echo "$out"; fail "message de résidu de désélection attendu pour .agents/skills"; }
  if echo "$out" | grep -q ".claude/skills/aic-demo pairé"; then
    fail ".claude/skills ne doit pas être validé comme pairé face à un résidu codex non sélectionné"
  fi
)

echo "PASS test-check-shims-dynamic-agents"
