---
id: pr-report
scope: quality
title: Rapport PR markdown (features impactées + warnings)
status: active
depends_on:
  - core/feature-index-cache
  - core/feature-mesh
touches:
  - .ai/scripts/pr-report.sh
  - .ai/scripts/review-delta.sh
  - .ai/scripts/ai-context.sh
  - template/.ai/scripts/pr-report.sh.jinja
  - template/.ai/scripts/review-delta.sh.jinja
  - template/.ai/scripts/ai-context.sh.jinja
  - tests/unit/test-review-delta-shared.sh
touches_shared:
  - README.md
  - PROJECT_STATE.md
  - CHANGELOG.md
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "ai-context expose mission/document-delta/repair/ship-report"
  blockers: []
  resume_hint: "ajouter une intégration CI (commentaire PR automatique) — passer en review une fois le wrapper ai-context-bot stabilisé"
  updated: 2026-04-28
---

# PR report

## Objectif

Rendre visible la valeur du mesh dans les PRs via un rapport markdown simple: features impactées et signaux de drift.

## Comportement attendu

- `bash .ai/scripts/pr-report.sh --base=<ref> --head=<ref>`
- `bash .ai/scripts/review-delta.sh --staged`
- Produit :
  - entête base/head et volume de fichiers modifiés ;
  - liste des features impactées via matching `touches` et liées via `touches_shared` ;
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
- 2026-05-03 : `tests/smoke-test.sh` lance désormais les tests unitaires de régression avant les scénarios Copier. Pas de changement de `pr-report.sh`, mais la feature reste dans le périmètre smoke partagé.
- 2026-05-03 : ajout de `review-delta.sh` (runtime + template + wrapper `ai-context review`) pour produire un rapport stable de review : fichiers, features directes, features liées shared, risques et checks recommandés. `pr-report.sh` expose aussi `related_features` et `warnings.shared_only`.
- 2026-05-03 : `ai-context.sh` gagne deux commandes UX : `status` (état humain actionnable + prochaine action minimale) et `brief <path>` (route vers `features-for-path --with-docs` pour Codex/agents non-hookés). Les routes existantes restent compatibles.
- 2026-05-03 : extension UX du wrapper avec `mission`, `document-delta`, `repair` et `ship-report`. Ces commandes composent les checks/reports existants, restent non destructives par défaut, et donnent une prochaine action concrète aux agents Claude/Codex.
- 2026-05-03 : le wrapper expose aussi les rapports product (`product-status`, `product-portfolio`, `product-review`) ; `pr-report` reste inchangé mais la surface review/ship peut recommander ces checks quand le delta touche `scope: product`.
- 2026-05-04 : `ai-context.sh first-run` ajouté au wrapper. Aucun changement de `pr-report.sh`, mais la surface CLI de sortie/review reste documentée dans cette fiche partagée.
- 2026-05-04 : `ai-context.sh` ajoute `repair-copier-metadata` et `template-diff`; aucun changement de `pr-report.sh`, mais le smoke partagé et la surface CLI documentée sont étendus.
