#!/bin/bash
# check-release-coherence.sh — Vérifie la cohérence CHANGELOG.md ↔ PROJECT_STATE.md
# ↔ copier.yml (script source-only, mainteneur ai_context uniquement — ces trois
# fichiers ne sont jamais rendus dans un projet consommateur).
#
# Recommandé par l'audit du 2026-07-07 après deux récidives constatées de
# PROJECT_STATE.md périmé face au CHANGELOG (finding DOC-E), jamais implémenté
# jusqu'au pilotage du 2026-07-24 (item P18a).
#
# Vérifie :
#   1. La version « Dernière version publiée » de PROJECT_STATE.md correspond
#      au dernier tag CHANGELOG.md (première section ## [x.y.z] après
#      ## [Unreleased], le cas échéant).
#   2. Chaque question top-level de copier.yml apparaît dans la table de
#      docs/variables.md.
#
# Usage : bash .ai/scripts/check-release-coherence.sh

set -euo pipefail

cd "$(dirname "$0")/../.."

fail=0
ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; fail=1; }

echo "═══ check-release-coherence ═══"

# --- 1. Version CHANGELOG vs PROJECT_STATE ---
changelog_version=$(grep -m1 -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/')
state_version=$(grep -m1 -E '\*\*Dernière version publiée\*\*' PROJECT_STATE.md | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^v//')

if [[ -z "$changelog_version" ]]; then
  ko "Aucune section ## [x.y.z] trouvée dans CHANGELOG.md"
elif [[ -z "$state_version" ]]; then
  ko "Aucune ligne 'Dernière version publiée : vX.Y.Z' trouvée dans PROJECT_STATE.md"
elif [[ "$changelog_version" != "$state_version" ]]; then
  ko "PROJECT_STATE.md annonce v$state_version mais CHANGELOG.md est à v$changelog_version — mettre à jour PROJECT_STATE.md"
else
  ok "PROJECT_STATE.md et CHANGELOG.md s'accordent sur v$changelog_version"
fi

# --- 2. Questions copier.yml présentes dans docs/variables.md ---
questions=$(awk '
  /^# ─{3,} Questions ─{3,}$/ { in_q=1; next }
  /^# ─{3,} Variables calculées ─{3,}$/ { in_q=0 }
  in_q && /^[a-z][a-z0-9_]*:[[:space:]]*$/ { sub(/:[[:space:]]*$/, ""); print }
' copier.yml)

missing_vars=""
while IFS= read -r q; do
  [[ -z "$q" ]] && continue
  grep -qE "\`$q\`" docs/variables.md || missing_vars="${missing_vars}${q} "
done <<< "$questions"

if [[ -n "$missing_vars" ]]; then
  ko "Question(s) copier.yml absente(s) de docs/variables.md : $missing_vars"
else
  ok "Toutes les questions copier.yml sont documentées dans docs/variables.md"
fi

if [[ "$fail" -eq 0 ]]; then
  echo "✅ PASS"
  exit 0
else
  echo "❌ FAIL"
  exit 1
fi
