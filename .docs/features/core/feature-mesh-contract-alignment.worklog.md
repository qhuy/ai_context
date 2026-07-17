# Worklog — core/feature-mesh-contract-alignment

## 2026-05-14 — création

- Feature créée via `.ai/workflows/document-feature.md`.
- Scope : core.
- Intent initial : aligner le parser fallback sans `yq` sur les champs `product.portfolio.*` définis par le schema et consommés par les rapports product.
- HANDOFF product -> core : `product/product-portfolio-loop` consomme les champs portfolio, mais le contrat de parsing appartient au feature mesh et à l'index core.
- Validation prévue : test fallback sans `yq`, test contrat index, `check-features --no-write`, `check-feature-docs --strict`.
- next : implémenter le parser fallback ciblé et le test unitaire.

## 2026-05-14 — implement / fallback product portfolio

- `build-feature-index.sh` runtime/template extrait maintenant `product.portfolio.appetite`, `confidence`, `expected_impact`, `urgency` et `strategic_fit` en fallback sans `yq`.
- Ajout de `tests/unit/test-build-feature-index-fallback.sh`, qui masque `yq` via `PATH` tout en gardant `jq`.
- CI source : handoff vers `quality/ci-guard` pour lancer ce test dans `.github/workflows/ai-context-check.yml`.
- Documentation release : `CHANGELOG.md` mentionne l'amélioration du fallback.
- Validations : `test-build-feature-index-fallback` PASS, `test-build-feature-index-contract` PASS, `test-read-only-checks-contract` PASS, `test-product-reports-read-only` PASS, `check-features --no-write` PASS, `check-feature-docs --strict core/feature-mesh-contract-alignment` PASS, `check-ai-references` PASS, `check-dogfood-drift` PASS.
- next : revue du delta et décision sur `kill_criteria` ; non bloquant car aucun rapport ne le consomme aujourd'hui.

## 2026-06-19 15:14 — auto
- Fichiers modifiés :
  - CHANGELOG.md
## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - template/.ai/scripts/build-feature-index.sh.jinja

## 2026-06-26 15:48 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-06-26 — couverture incidente (core/feature-index-cache fix robustesse)
- Surface partagée touchée (build-feature-index.sh + jinja, tests, ou tests/smoke-test.sh) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-28 20:51 — auto
- Fichiers modifiés :
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja

## 2026-06-26 — couverture incidente (CHANGELOG clôture session)
- `CHANGELOG.md` (entrées [Unreleased] des features de la session) couvert par le glob `touches:` de cette feature. Aucun changement de comportement propre. (CHANGELOG.md = candidat touches_shared, cf. quality/touches-breadth-guard.)

## 2026-06-28 21:09 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-06-28 — couverture incidente (A1 : fix fallback build-feature-index)
- `build-feature-index.sh.jinja` touché via glob `touches:`. Aucun changement propre à cette feature. (Taxe sur-couverture `touches:` — cf. quality/touches-breadth-guard.)

## 2026-06-29 — couverture incidente (clôture A1 : résiduel fallback build-feature-index)
- `build-feature-index.sh` + `.jinja` touchés via glob `touches:` (bornage external_refs/product/progress du parseur fallback). Aucun changement propre à cette feature ni à l'alignement du contrat mesh. (Taxe sur-couverture `touches:` — cf. quality/touches-breadth-guard.)

## 2026-07-03 — done
- Intent : clôture documentaire de `core/feature-mesh-contract-alignment`.
- Fichiers/surfaces : `.docs/features/core/feature-mesh-contract-alignment.md`, `.docs/features/core/feature-mesh-contract-alignment.worklog.md`.
- Décision : statut `done` ; le fallback sans `yq` couvre les champs `product.portfolio.*` consommés par le scoring produit. `kill_criteria` reste hors fallback car aucun rapport/check actuel ne le consomme ; l'ajouter serait du parsing non utilisé.
- Doc Impact Decision : C — fiche feature et worklog mis à jour.
- Validation prévue : `test-build-feature-index-fallback`, `test-build-feature-index-contract`, `test-product-reports-read-only`, `check-feature-docs --strict core/feature-mesh-contract-alignment`, checks feature/freshness et dogfood avant commit.
- Next : aucune action immédiate ; rouvrir si un rapport consomme `kill_criteria` ou un nouveau champ product absent du fallback.

## 2026-07-07 — couverture incidente audit
- `build-feature-index.sh` touché pour durcir le fallback frontmatter (inline comments) et ignorer les ids/scopes invalides au lieu de les indexer.
- Aucun nouveau champ mesh ; contrat aligné sur le schéma existant.
- Validation ciblée : `test-build-feature-index-fallback-frontmatter`, `test-build-feature-index-robust`, `check-features --no-write`.

## 2026-07-07 18:51 — auto
- Fichiers modifiés :
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja

## 2026-07-16 — HANDOFF classification réservée
- Co-propriété directe de `build-feature-index.sh` conservée conformément à la décision du 2026-06-28.
- Le parser exclut désormais centralement `index.md`, `log.md` et `*.worklog.md` sans changer le schéma du mesh.
- Validation : index JSON limité aux fiches canoniques dans `test-feature-markdown-indexes.sh`.
