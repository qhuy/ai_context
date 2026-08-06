#!/bin/bash
# test-check-skills-parity.sh — core/dogfood-runtime-sync (pilotage P8).
#
# check-skills-parity.sh doit BLOQUER sur une divergence réelle entre
# .claude/skills et .agents/skills, PASSER sur l'exception documentée
# (disable-model-invocation), et PASSER (skip silencieux) si un seul des
# deux arbres existe (agent non sélectionné).
#
# Le périmètre est le namespace réservé du template (`aic` / `aic-*`) : les
# fixtures de parité utilisent donc des noms `aic-*`. Les skills project-owned
# d'un consommateur sont hors contrat — cas 6 et 7 (régression v1.0.0 : le check
# exigeait un pair Codex pour chaque skill projet et rendait `doctor` rouge sur
# un repo sain).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-skills-parity.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts"
cp "$repo_root/.ai/scripts/check-skills-parity.sh" "$tmp/.ai/scripts/check-skills-parity.sh"

run_check() { ( cd "$tmp" && bash .ai/scripts/check-skills-parity.sh ); }

# --- Cas 1 : un seul arbre présent → PASS silencieux ---
mkdir -p "$tmp/.claude/skills/aic-foo"
printf '# Foo\n' > "$tmp/.claude/skills/aic-foo/SKILL.md"
run_check >/dev/null 2>&1 || fail "un seul arbre présent devrait passer"

# --- Cas 2 : deux arbres identiques → PASS ---
mkdir -p "$tmp/.agents/skills/aic-foo"
cp "$tmp/.claude/skills/aic-foo/SKILL.md" "$tmp/.agents/skills/aic-foo/SKILL.md"
run_check >/dev/null 2>&1 || fail "deux arbres identiques devraient passer"

# --- Cas 3 : exception documentée (disable-model-invocation) → PASS ---
printf '# Foo\ndisable-model-invocation: true\n' > "$tmp/.claude/skills/aic-foo/SKILL.md"
run_check >/dev/null 2>&1 || fail "l'exception disable-model-invocation devrait être tolérée"

# --- Cas 4 : divergence réelle → FAIL ---
printf '# Foo\nrogue line\n' > "$tmp/.claude/skills/aic-foo/SKILL.md"
set +e
out="$(run_check 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "une divergence réelle aurait dû faire échouer le check"; }
echo "$out" | grep -q "diverge" || { echo "$out"; fail "message 'diverge' attendu absent"; }

# --- Cas 5 : fichier présent d'un seul côté (les deux arbres existent) → FAIL ---
printf '# Foo\n' > "$tmp/.claude/skills/aic-foo/SKILL.md"
printf '# Foo\n' > "$tmp/.agents/skills/aic-foo/SKILL.md"
mkdir -p "$tmp/.claude/skills/aic-bar"
printf '# Bar\n' > "$tmp/.claude/skills/aic-bar/SKILL.md"
set +e
out="$(run_check 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "un fichier absent d'un côté aurait dû faire échouer le check"; }
echo "$out" | grep -q "absent côté Codex" || { echo "$out"; fail "message d'asymétrie attendu absent"; }

# --- Cas 6 : skills project-owned non pairés → PASS, comptés ---
# Un consommateur ajoute ses propres skills Claude (aucun pair Codex voulu, pas
# de workflow.md). Ils ne doivent pas peser sur le contrat de parité.
rm -rf "$tmp/.claude/skills/aic-bar"
mkdir -p "$tmp/.claude/skills/bmad-dev-story" "$tmp/.claude/skills/bobv3-plan"
printf '# bmad\n' > "$tmp/.claude/skills/bmad-dev-story/SKILL.md"
printf '# bobv3\n' > "$tmp/.claude/skills/bobv3-plan/SKILL.md"
set +e
out="$(run_check 2>&1)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || { echo "$out"; fail "des skills project-owned non pairés ne doivent pas faire échouer le check"; }
echo "$out" | grep -q "2 skill(s) project-owned" \
  || { echo "$out"; fail "le nombre de skills project-owned ignorés doit rester visible"; }

# --- Cas 7 : project-owned divergents des deux côtés → PASS ---
# Même dupliqué, un skill projet reste la propriété du consommateur.
mkdir -p "$tmp/.agents/skills/bmad-dev-story"
printf '# bmad divergent\n' > "$tmp/.agents/skills/bmad-dev-story/SKILL.md"
run_check >/dev/null 2>&1 \
  || fail "une divergence sur un skill project-owned ne relève pas du contrat template"

# --- Cas 8 : le namespace template reste bloquant malgré les skills projet ---
# Garde-fou anti-régression : le fix ne doit pas désarmer le check.
mkdir -p "$tmp/.claude/skills/aic-review"
printf '# Review\n' > "$tmp/.claude/skills/aic-review/SKILL.md"
set +e
out="$(run_check 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "un skill aic-* non pairé doit toujours faire échouer le check"; }
echo "$out" | grep -q "aic-review/SKILL.md présent côté Claude" \
  || { echo "$out"; fail "le message d'asymétrie sur un skill template attendu absent"; }

echo "✅ test-check-skills-parity PASS"
