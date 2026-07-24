#!/bin/bash
# test-check-skills-parity.sh — core/dogfood-runtime-sync (pilotage P8).
#
# check-skills-parity.sh doit BLOQUER sur une divergence réelle entre
# .claude/skills et .agents/skills, PASSER sur l'exception documentée
# (disable-model-invocation), et PASSER (skip silencieux) si un seul des
# deux arbres existe (agent non sélectionné).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-skills-parity.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts"
cp "$repo_root/.ai/scripts/check-skills-parity.sh" "$tmp/.ai/scripts/check-skills-parity.sh"

run_check() { ( cd "$tmp" && bash .ai/scripts/check-skills-parity.sh ); }

# --- Cas 1 : un seul arbre présent → PASS silencieux ---
mkdir -p "$tmp/.claude/skills/foo"
printf '# Foo\n' > "$tmp/.claude/skills/foo/SKILL.md"
run_check >/dev/null 2>&1 || fail "un seul arbre présent devrait passer"

# --- Cas 2 : deux arbres identiques → PASS ---
mkdir -p "$tmp/.agents/skills/foo"
cp "$tmp/.claude/skills/foo/SKILL.md" "$tmp/.agents/skills/foo/SKILL.md"
run_check >/dev/null 2>&1 || fail "deux arbres identiques devraient passer"

# --- Cas 3 : exception documentée (disable-model-invocation) → PASS ---
printf '# Foo\ndisable-model-invocation: true\n' > "$tmp/.claude/skills/foo/SKILL.md"
run_check >/dev/null 2>&1 || fail "l'exception disable-model-invocation devrait être tolérée"

# --- Cas 4 : divergence réelle → FAIL ---
printf '# Foo\nrogue line\n' > "$tmp/.claude/skills/foo/SKILL.md"
set +e
out="$(run_check 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "une divergence réelle aurait dû faire échouer le check"; }
echo "$out" | grep -q "diverge" || { echo "$out"; fail "message 'diverge' attendu absent"; }

# --- Cas 5 : fichier présent d'un seul côté (les deux arbres existent) → FAIL ---
printf '# Foo\n' > "$tmp/.claude/skills/foo/SKILL.md"
printf '# Foo\n' > "$tmp/.agents/skills/foo/SKILL.md"
mkdir -p "$tmp/.claude/skills/bar"
printf '# Bar\n' > "$tmp/.claude/skills/bar/SKILL.md"
set +e
out="$(run_check 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "un fichier absent d'un côté aurait dû faire échouer le check"; }
echo "$out" | grep -q "absent côté Codex" || { echo "$out"; fail "message d'asymétrie attendu absent"; }

echo "✅ test-check-skills-parity PASS"
