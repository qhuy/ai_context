#!/bin/bash
# test-check-shims-project-owned-skills.sh — core/agents-md-shim-canonical.
#
# check-shims [5/5] parcourait TOUS les dossiers de .claude/skills et .agents/skills
# en exigeant de chacun un pair sur l'autre arbre, un SKILL.md et un workflow.md.
# Sur un consommateur qui a ses propres skills Claude (50 `bmad-*`/`bobv3-*` sans
# équivalent Codex ni workflow.md), le gate échouait et `doctor` concluait
# « corriger les shims » sur un repo sain.
#
# Contrat vérifié ici : le périmètre est le namespace réservé du template
# (`aic` / `aic-*`). Les skills project-owned sont ignorés et comptés, jamais
# bloquants — MAIS le namespace template reste strictement pairé (cas 3 et 4,
# garde-fous anti-désarmement).
#
# Discriminant : les cas 1 et 2 échouent sur le code v1.0.0 (vérifié).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-shims-project-skills.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

d="$tmp/repo"
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

cat > "$d/CLAUDE.md" <<'MD'
# CLAUDE.md
> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

@AGENTS.md
MD

cat > "$d/.copier-answers.yml" <<'YAML'
_src_path: gh:qhuy/ai_context
agents:
  - claude
  - codex
YAML

# Skills livrés par le template : pairés Claude/Codex, avec workflow.md.
for s in aic aic-review; do
  for root in .claude/skills .agents/skills; do
    mkdir -p "$d/$root/$s"
    printf '# %s\n' "$s" > "$d/$root/$s/SKILL.md"
    printf 'Voir .ai/workflows/feature-new.md\n' > "$d/$root/$s/workflow.md"
  done
done

# Skills project-owned : côté Claude uniquement, sans workflow.md.
for s in bmad-dev-story bobv3-plan bobv3-review; do
  mkdir -p "$d/.claude/skills/$s"
  printf '# %s\n' "$s" > "$d/.claude/skills/$s/SKILL.md"
done

run_check() { ( cd "$d" && bash .ai/scripts/check-shims.sh 2>&1 ); }

# --- Cas 1 : repo sain avec skills projet → PASS ---
set +e
out="$(run_check)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || { echo "$out"; fail "check-shims doit passer sur un repo dont les skills projet ne sont pas pairés"; }

# --- Cas 2 : les skills ignorés restent visibles (pas de silence) ---
echo "$out" | grep -q "3 dossier(s) de skills project-owned ignoré(s)" \
  || { echo "$out"; fail "le décompte des skills project-owned ignorés est attendu dans la sortie"; }

# --- Cas 3 : un skill template non pairé reste bloquant ---
rm -rf "$d/.agents/skills/aic-review"
set +e
out="$(run_check)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "un skill aic-* sans pair Codex doit rester bloquant"; }
echo "$out" | grep -q "aic-review sans pair" \
  || { echo "$out"; fail "message de pair manquant attendu pour aic-review"; }

# --- Cas 4 : un skill template sans workflow.md reste bloquant ---
for root in .claude/skills .agents/skills; do
  mkdir -p "$d/$root/aic-review"
  printf '# aic-review\n' > "$d/$root/aic-review/SKILL.md"
  printf 'Voir .ai/workflows/feature-new.md\n' > "$d/$root/aic-review/workflow.md"
done
rm -f "$d/.claude/skills/aic-review/workflow.md"
set +e
out="$(run_check)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "un skill aic-* sans workflow.md doit rester bloquant"; }
echo "$out" | grep -q "workflow.md manquant" \
  || { echo "$out"; fail "message workflow.md manquant attendu"; }

echo "✅ test-check-shims-project-owned-skills PASS"
