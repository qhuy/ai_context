---
id: pr-report
scope: quality
title: Rapport PR markdown (features impactées + warnings)
status: active
depends_on:
  - core/feature-index-cache
  - core/feature-mesh
touches:
  - template/.ai/scripts/pr-report.sh.jinja
  - README.md
  - PROJECT_STATE.md
  - CHANGELOG.md
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "MVP script pr-report basé sur git diff + features_matching_path"
  blockers: []
  resume_hint: "ajouter enrichissements warnings deps deprecated + ownership optionnel quand le frontmatter sera étendu"
  updated: 2026-04-27
---

# PR report

## Objectif

Rendre visible la valeur du mesh dans les PRs via un rapport markdown simple: features impactées et signaux de drift.

## Comportement attendu

- `bash .ai/scripts/pr-report.sh --base=<ref> --head=<ref>`
- Produit :
  - entête base/head et volume de fichiers modifiés ;
  - liste des features impactées via matching `touches` ;
  - warnings pour fichiers non couverts.

## Contrats

- Non destructif (lecture git + index).
- Sortie markdown stable.
- Compatible CI.

## Cross-refs

- Précurseur d’un futur commentaire PR automatique.
- Repose sur `core/feature-index-cache` et `path_matches_touch`.

## Historique / décisions

- 2026-04-27 : MVP initial introduit (features + warnings orphelins).
