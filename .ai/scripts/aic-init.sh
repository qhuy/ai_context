#!/bin/bash
# aic-init.sh — Parcours guidé post-scaffold (pilotage P12, successeur de
# l'ancien `ai-context.sh first-run` retiré en v0.13 sans remplacement).
#
# Idempotent : sûr à relancer. N'écrit que la config git hooks (si absente et
# vcs_provider=git) ; tout le reste est en lecture seule / diagnostic.
#
# Usage : bash .ai/scripts/aic.sh init

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"
repo_root="$(vcs_root 2>/dev/null || pwd)"
cd "$repo_root"

echo "═══ aic init ═══"
echo

echo "── 1. Diagnostic installation ──"
bash "$script_dir/doctor.sh"
echo

echo "── 2. Git hooks ──"
provider="$(vcs_provider 2>/dev/null || echo git)"
if [[ "$provider" != "git" ]]; then
  echo "  ℹ️  provider VCS = $provider : hooks git non applicables ici."
elif [[ ! -d .githooks ]]; then
  echo "  ℹ️  .githooks absent (mode lite ou hors git) : rien à activer."
else
  current_hooks_path="$(git config core.hooksPath 2>/dev/null || echo "")"
  if [[ "$current_hooks_path" == ".githooks" ]]; then
    echo "  ✓ core.hooksPath déjà configuré sur .githooks"
  else
    git config core.hooksPath .githooks
    chmod +x .githooks/* 2>/dev/null || true
    echo "  ✓ core.hooksPath configuré sur .githooks (commit-msg, pre-commit, post-checkout activés)"
  fi
fi
echo

echo "── 3. Feature mesh ──"
mesh_count=0
if [[ -d "$AI_CONTEXT_FEATURES_DIR" ]]; then
  mesh_count=$(find "$AI_CONTEXT_FEATURES_DIR" -mindepth 2 -maxdepth 2 -name "*.md" -not -name "*.worklog.md" 2>/dev/null | wc -l | tr -d ' ')
fi
if [[ "$mesh_count" -eq 0 ]]; then
  echo "  ℹ️  Mesh vide (normal au démarrage) — squelette : $AI_CONTEXT_DOCS_ROOT/FEATURE_TEMPLATE.md"
else
  echo "  ✓ $mesh_count fiche(s) déjà présente(s) dans $AI_CONTEXT_FEATURES_DIR"
fi
echo

cat <<'EOF'
── 4. Prochaine étape ──

Cadrer la première tâche :
  Claude/Codex : /aic-frame "<ton objectif>"
  CLI          : bash .ai/scripts/aic.sh frame "<ton objectif>"

Plusieurs constats/bugs/décisions à ne pas oublier plutôt qu'une tâche unique ?
  Claude/Codex : /aic-pilot

Une fois une vraie feature démarrée :
  /aic-document-feature (ou bash .ai/scripts/aic.sh document-feature <path>)

Où en est le travail à tout moment :
  Claude/Codex : /aic-status
  CLI          : bash .ai/scripts/aic.sh status
EOF
