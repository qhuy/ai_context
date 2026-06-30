#!/bin/bash
# test-feature-docs-placeholder-heuristic.sh — core/feature-mesh.
#
# Garde le heuristique has_placeholder() de check-feature-docs.sh :
#   - une comparaison « x < y … z > n » (espace juste après `<`) N'est PAS un
#     placeholder → une fiche done/strict complète passe (régression : la ligne
#     de clôture « ratio … < 1:1 et 0 draft gelé > 30 j » bloquait à tort) ;
#   - un vrai placeholder à libellé collé au `<` (`<Titre court…>`, même avec des
#     espaces internes comme `<product | back | …>`) reste BLOQUANT (anti-relâche).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-placeholder.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.docs/features/back"
for s in check-feature-docs.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
printf 'docs_root: ".docs"\nproject_id: "placeholder-test"\n' > "$tmp/.ai/config.yml"

# Fiche brief complète ; seul le corps de l'Historique varie (placé tel quel).
mkfeat() { # id status body_line
  local id="$1" status="$2" body="$3"
  cat > "$tmp/.docs/features/back/$id.md" <<EOF
---
id: $id
scope: back
title: $id
status: $status
type: feature
depends_on: []
touches: []
touches_shared: []
doc:
  level: brief
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
---

## Résumé
Fiche de test du heuristique placeholder.

## Objectif
Vérifier la détection des placeholders sans faux positif sur les comparaisons.

## Décisions
Le corps porte une seule ligne sous test.

## Validation
Couvert par ce test unitaire.

## Historique / décisions
- 2026-06-30 : $body
EOF
}

run() { local rc; set +e; bash "$tmp/.ai/scripts/check-feature-docs.sh" "$@" >"$tmp/out" 2>&1; rc=$?; set -e; echo "$rc"; }

# Cas 1 (régression) : comparaison avec span de code → AUCUN placeholder → PASS en strict.
mkfeat comparaison active 'ratio `fix:feat(quality)` < 1:1 et 0 draft gelé > 30 j.'
[[ "$(run --strict back/comparaison)" == 0 ]] \
  || { cat "$tmp/out"; fail "une comparaison « < 1:1 … > 30 j » ne doit pas être lue comme placeholder"; }

# Cas 2 : vrai placeholder à libellé collé → BLOQUE en strict.
mkfeat titre active 'reste à écrire : <Titre court de la feature>'
[[ "$(run --strict back/titre)" == 1 ]] \
  || { cat "$tmp/out"; fail "un placeholder <Titre court…> doit rester bloquant"; }

# Cas 3 (anti-relâche) : placeholder avec espaces/pipes internes mais collé au `<` → BLOQUE.
mkfeat enum active 'scope : <product | back | front | architecture | security>'
[[ "$(run --strict back/enum)" == 1 ]] \
  || { cat "$tmp/out"; fail "un placeholder <product | … > (espaces internes) doit rester bloquant"; }

# Cas 4 : même comparaison sur une fiche done (chemin status=done, pas seulement --strict) → PASS.
mkfeat closed done 'ratio `fix:feat(quality)` < 1:1 et 0 draft gelé > 30 j.'
[[ "$(run back/closed)" == 0 ]] \
  || { cat "$tmp/out"; fail "fiche done avec comparaison « < … > » ne doit pas bloquer"; }

echo "✅ test-feature-docs-placeholder-heuristic PASS"
