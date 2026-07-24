#!/bin/bash
# check-skills-parity.sh — Vérifie que .claude/skills/ et .agents/skills/
# restent en parité de contenu (pilotage P8, 2026-07-24).
#
# Contrat (workflow/intentional-skills) : les mêmes skills publics existent,
# identiques, côté Claude et Codex. Une divergence silencieuse entre les deux
# arbres est un bug — ce check la bloque au lieu de compter sur la discipline
# du mainteneur.
#
# Exception intentionnelle connue et documentée : `disable-model-invocation:
# true` dans le frontmatter de `aic/SKILL.md`, uniquement pertinent côté
# Claude (contrôle l'auto-invocation par le modèle) — absent côté Codex,
# retiré des deux copies avant comparaison.
#
# Si un seul des deux arbres est présent (agent non sélectionné), le check
# passe silencieusement : rien à comparer.
#
# Usage : bash .ai/scripts/check-skills-parity.sh

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

fail=0
ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; fail=1; }

echo "═══ check-skills-parity ═══"

CLAUDE_DIR=".claude/skills"
AGENTS_DIR=".agents/skills"

if [[ ! -d "$CLAUDE_DIR" || ! -d "$AGENTS_DIR" ]]; then
  ok "un seul agent (ou aucun) sélectionné — rien à comparer"
  echo "✅ PASS"
  exit 0
fi

# Retire la seule exception intentionnelle connue avant comparaison.
normalize() {
  grep -v '^disable-model-invocation:[[:space:]]*true[[:space:]]*$' "$1" 2>/dev/null
}

diff_count=0
while IFS= read -r rel; do
  claude_file="$CLAUDE_DIR/$rel"
  agents_file="$AGENTS_DIR/$rel"
  if [[ ! -f "$agents_file" ]]; then
    ko "$rel présent côté Claude, absent côté Codex ($agents_file)"
    diff_count=$((diff_count + 1))
    continue
  fi
  if ! diff -q <(normalize "$claude_file") <(normalize "$agents_file") >/dev/null 2>&1; then
    ko "$rel diverge entre .claude/skills et .agents/skills"
    diff_count=$((diff_count + 1))
  fi
done < <(cd "$CLAUDE_DIR" && find . -type f | sed 's#^\./##' | sort)

while IFS= read -r rel; do
  [[ -f "$CLAUDE_DIR/$rel" ]] || { ko "$rel présent côté Codex, absent côté Claude ($CLAUDE_DIR/$rel)"; diff_count=$((diff_count + 1)); }
done < <(cd "$AGENTS_DIR" && find . -type f | sed 's#^\./##' | sort)

if [[ "$diff_count" -eq 0 ]]; then
  ok "les deux arbres de skills sont en parité (hors exception documentée)"
  echo "✅ PASS"
  exit 0
else
  echo "❌ FAIL — $diff_count divergence(s)"
  exit 1
fi
