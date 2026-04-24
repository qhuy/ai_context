---
id: cycle-detection
scope: quality
title: Détection de cycles dans depends_on (DFS jq)
status: active
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
touches:
  - template/.ai/scripts/check-features.sh.jinja
progress:
  phase: review
  step: "bootstrap dog-fooding (v0.9 historique)"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-04-24
---

# Détection de cycles

## Objectif

Refuser tout mesh qui contient un cycle dans le graphe `depends_on` (A → B → A). Un cycle non détecté entraîne des boucles infinies à l'injection contextuelle (chargement récursif des deps).

## Comportement attendu

- DFS implémenté en `jq` (pur, pas de dépendance Python/Node).
- Sortie : liste des cycles détectés, exit non-zéro si > 0.
- Invoqué par `check-features.sh` (script unique appelé en CI et `/aic-quality-gate`).

## Contrats

- Complexité O(V+E), acceptable jusqu'à ~10⁴ features.
- Tolère les arêtes vers features inexistantes (warning séparé, pas une erreur de cycle).

## Cross-refs

Validation côté `feature-mesh` ; rejoué par `smoke-test` et `ci-guard`.

## Historique / décisions

- Choix `jq` plutôt que Python : zéro runtime supplémentaire, déjà requis par `feature-index-cache`.
