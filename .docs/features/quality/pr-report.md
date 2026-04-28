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
  step: "v0.10 — exclusions par défaut + format JSON + warnings enrichis"
  blockers: []
  resume_hint: "ajouter une intégration CI (commentaire PR automatique) — passer en review une fois le wrapper ai-context-bot stabilisé"
  updated: 2026-04-28
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
- 2026-04-27 : compatibilité Bash 3.2 renforcée : suppression de `mapfile` et des tableaux associatifs (`declare -A`) pour éviter les erreurs runtime sur macOS par défaut.
- 2026-04-28 : enrichissement v0.10 du script `template/.ai/scripts/pr-report.sh.jinja`. Ajouts : `--format=json` (markdown reste défaut), `--include-docs` pour lever les exclusions, exclusions par défaut sur fichiers documentaires (README/CHANGELOG/MIGRATION/PROJECT_STATE/LICENSE/.github/.ai/docs/.docs/features), warnings nouveaux : `feature done modifiée`, fichier `multi-couvert`, `depends_on deprecated/archived`, feature `stale` (>14j sans update). Fallback shallow-clone : si `--base` n'est pas atteignable, retombe sur HEAD~1 et l'annonce dans la note. Aucune logique modifiée pour `--format=markdown` sans options : le rapport reste lisible avec ces deux nouveautés ajoutées en pied (compteur `Fichiers analysés`, ligne `Exclus par défaut`).
- 2026-04-28 : `tests/smoke-test.sh` enrichi avec assertions `--format=json` (jq parse), `--include-docs` (`docs_excluded=0`) et exclusion par défaut (`docs_excluded ≥ 1` quand un README est modifié).
- 2026-04-28 (impl) : commit dédié de l'implémentation `pr-report.sh.jinja` après que la documentation des entries précédentes soit déjà landée — split en deux commits pour séparer la trace décisionnelle de l'implémentation Bash.
