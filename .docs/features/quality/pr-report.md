---
id: pr-report
scope: quality
title: Rapport PR markdown (features impactées + warnings)
status: done
depends_on:
  - core/feature-index-cache
  - core/feature-mesh
touches:
  - .ai/scripts/pr-report.sh
  - .ai/scripts/review-delta.sh
  - template/.ai/scripts/pr-report.sh.jinja
  - template/.ai/scripts/review-delta.sh.jinja
  - tests/unit/test-review-delta-shared.sh
  - tests/unit/test-pr-report-glob-match.sh
touches_shared:
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - README.md
  - PROJECT_STATE.md
  - CHANGELOG.md
  - tests/smoke-test.sh
progress:
  phase: done
  step: "pr-report/review-delta livrés : markdown, JSON, exclusions docs, aic review/ship et no-write validés"
  blockers: []
  resume_hint: "aucune action immédiate ; cadrer une feature séparée pour le commentaire PR automatique si nécessaire"
  updated: 2026-07-03
type: feature
---

# PR report

## Résumé

Génère un rapport markdown (ou JSON) à partir d'un delta git : features impactées via `touches`, features liées via `touches_shared`, et warnings de drift (orphelins, fiche done modifiée, multi-couverture, dépendance dépréciée, feature stale). Rend visible la valeur du mesh au moment de la review/PR sans rien modifier.

## Objectif

Rendre visible la valeur du mesh dans les PRs via un rapport markdown simple: features impactées et signaux de drift.

## Périmètre

### Inclus

- `pr-report.sh` (rapport `--base`/`--head`, formats `--format=markdown` par défaut et `--format=json`, option `--include-docs`).
- `review-delta.sh` (rapport de review du delta `--staged` : fichiers, features directes, features liées shared, risques, checks recommandés).
- Le wrapper `aic.sh` qui route vers ces rapports (et leurs équivalents template `.jinja`).
- Les exclusions documentaires par défaut (README/CHANGELOG/MIGRATION/PROJECT_STATE/LICENSE/.github/.ai/docs/.docs/features) et le fallback shallow-clone vers `HEAD~1`.

### Hors périmètre

- L'intégration CI (commentaire PR automatique) : précurseur seulement, pas encore implémenté.
- La construction de l'index features et `path_matches_touch` (portés par `core/feature-index-cache` et `core/feature-mesh`).
- Les rapports product (`product-status`, `product-portfolio`, `product-review`) : juste recommandés quand le delta touche `scope: product`.

## Invariants

- Lecture seule : aucun écrit dans le repo ni dans l'index (git + index uniquement).
- La sortie `--format=markdown` sans option reste stable et lisible : les nouveautés (compteur `Fichiers analysés`, ligne `Exclus par défaut`) s'ajoutent en pied sans casser le format historique.
- Compatible Bash 3.2 (macOS par défaut) : pas de `mapfile`, pas de `declare -A`.
- Compatible CI : déterministe, sans secret.
- Si `--base` n'est pas atteignable (shallow clone), fallback sur `HEAD~1` annoncé dans la note.

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

## Décisions

- `markdown` reste le format par défaut ; `--format=json` est opt-in pour les intégrations machine.
- Les fichiers documentaires sont exclus par défaut (bruit faible côté mesh), `--include-docs` lève l'exclusion à la demande.
- Renoncement aux features Bash 4 (`mapfile`, `declare -A`) pour garantir le runtime macOS par défaut plutôt que d'exiger un Bash récent.
- L'implémentation et la trace décisionnelle ont été splittées en deux commits (doc landée avant le code) pour garder l'historique lisible.
- Le commentaire PR automatique est reporté : on stabilise d'abord la surface review/ship (`aic`) avant d'ajouter l'intégration CI.

## Validation

- `tests/smoke-test.sh` : assertions `--format=json` (parse `jq`), `--include-docs` (`docs_excluded=0`) et exclusion par défaut (`docs_excluded ≥ 1` quand un README est modifié).
- `tests/unit/test-review-delta-shared.sh` couvre le rapport `review-delta` (features directes/shared, risques, checks).
- `bash .ai/scripts/pr-report.sh --base=<ref> --head=<ref>` produit un markdown stable (entête base/head, features impactées, warnings) ; idem `review-delta.sh --staged`.
- Le smoke partagé rejoue les tests unitaires de régression avant les scénarios Copier.
- Clôture 2026-07-03 : `test-review-delta-shared` PASS ; `pr-report.sh --base=HEAD~1 --head=HEAD` PASS ; `pr-report.sh --format=json` parsé par `jq` ; `review-delta.sh --committed-only` PASS.

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
- 2026-05-04 : `ai-context.sh` expose `check-docs` et le smoke partagé couvre `check-feature-docs.sh` (warning legacy, strict ciblé, wrapper). Aucun changement de `pr-report.sh`.
- 2026-07-03 : DONE documentaire. La surface rapport est stable et non destructive ; l'intégration CI en commentaire PR reste hors périmètre et devra être cadrée séparément.
