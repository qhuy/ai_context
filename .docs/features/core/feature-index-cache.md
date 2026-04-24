---
id: feature-index-cache
scope: core
title: Cache JSON déterministe du feature mesh
status: active
depends_on:
  - core/feature-mesh
touches:
  - template/.ai/scripts/build-feature-index.sh.jinja
  - template/.ai/scripts/_lib.sh.jinja
---

# Cache JSON du feature mesh

## Objectif

Éviter de re-parser le markdown à chaque appel de hook : `build-feature-index.sh` agrège tous les frontmatter en un `.ai/.feature-index.json` reconstruit déterministiquement, gitignoré.

## Comportement attendu

- Trigger : `post-checkout` git hook + `pre-turn-reminder` (rebuild si manquant).
- Lecture YAML via `yq v4` si dispo, sinon fallback awk/sed (bash 3.2 compatible).
- Échappement JSON sûr (paths avec quotes/backslashes via `jq -nc --arg`).
- Lock atomique `mkdir` (pas `flock`, portable macOS).

## Contrats

- Sortie : tableau JSON `[{id, scope, title, status, depends_on, touches, progress?, path}]`.
- Idempotent : 2 builds successifs produisent un JSON byte-identique.
- Tolérance : feature au frontmatter invalide → exclue + warning, pas d'arrêt.

## Cross-refs

- Source consommée par tous les hooks d'injection (`pre-turn-reminder`, `features-for-path`, `resume-features`).
- Validation post-build via `cycle-detection`.

## Historique / décisions

- v0.7.2 : fix bug silencieux d'escaping JSON (paths avec quotes corrompaient le JSONL).
