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
  - .ai/scripts/_lib.sh
progress:
  phase: review
  step: "bootstrap dog-fooding (v0.9 historique)"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-04-28
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
- 2026-04-24 : centralisation du matching `touches:` dans `_lib.sh` (`path_matches_touch` + `features_matching_path`). Les hooks/scripts consommateurs partagent désormais la même sémantique exact/dossier/glob/`/**`.
- 2026-04-24 : `AI_CONTEXT_DOCS_ROOT` et `AI_CONTEXT_FEATURES_DIR` ajoutés dans `_lib.sh` pour que les scripts runtime suivent le `docs_root` rendu par Copier au lieu de réencoder `.docs/features`.
- 2026-04-28 : ajout `is_valid_phase()` dans `.ai/scripts/_lib.sh` (dogfoodé) **et** `template/.ai/scripts/_lib.sh.jinja` (la doc d'en-tête le promettait déjà via `PHASE_ENUM`). Suppression de la définition locale dupliquée dans `template/.ai/scripts/check-features.sh.jinja`. Aucun changement de comportement runtime — la fonction délègue à `PHASE_ENUM` (lui-même dérivé du schema). Smoke-test [11/28] couvre toujours le warning `progress.phase='typo'`.
