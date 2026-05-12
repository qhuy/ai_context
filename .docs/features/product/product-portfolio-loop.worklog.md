# Worklog — product/product-portfolio-loop

## 2026-05-04 — freshness
- Impact indirect : `copier.yml` et `tests/smoke-test.sh` restent compatibles avec la traceability product.
- Aucun changement de contrat product.
- Validation associée : smoke-test complet PASS.

## 2026-05-04 — freshness
- Impact documentaire : `.docs/FEATURE_TEMPLATE.md` garde le lien product inchangé tout en précisant la granularité des features dev.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact template : `template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja` garde le contrat product inchangé après propagation de la granularité.
- Changement porté par dogfood runtime sync.
- Validation associée : `check-dogfood-drift.sh` PASS.
## 2026-05-05 — freshness
- Impact transversal : l'overlay projet stable touche l'index et les messages template déjà couverts par cette feature produit.
- Validation associée : `check-features.sh`, `check-shims.sh`, `check-dogfood-drift.sh` PASS.

## 2026-05-06 — freshness
- Impact indirect : les scripts source-only de dogfooding synchronisent désormais `.agents/**`.
- Aucun changement sur les commandes product-status/product-portfolio/product-review ni sur la traceability produit.

## 2026-05-06 — freshness
- Impact indirect : `README_AI_CONTEXT.md`, `copier.yml`, le template README et le smoke-test évoluent pour exposer `/aic-document-feature`.
- Aucun changement sur le contrat initiative/roadmap/traceability produit.
- Validation associée : smoke-test PASS.

## 2026-05-06 — retours review
- Intent : aligner le contrat product avec la migration publique `aic`.
- Fichiers/surfaces : `.docs/features/product/product-portfolio-loop.md`.
- Décision : la surface commune Claude/Codex product passe par `aic.sh product-*`, sans ancien wrapper.
- Validation : prévue via `check-feature-docs product/product-portfolio-loop` et `check-ai-references`.

## 2026-05-06 22:50 — freshness
- Impact indirect : `copier.yml` mis à jour pendant le durcissement post-cross-check (round 4 workflow/intentional-skills).
- Aucun changement sur le contrat initiative/roadmap/traceability produit.
- Validation associée : `check-feature-freshness.sh` (staged) PASS attendu.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh

## 2026-05-08 — freshness
- Impact indirect : nettoyage drift README runtime/template + note mainteneur PROJECT_STATE (driver core/dogfood-runtime-sync).
- Aucun changement de contrat propre a cette feature.

## 2026-05-12 — impact partagé test lock index

- Fichiers/surfaces : `tests/smoke-test.sh`.
- Contexte : `quality/index-lock-contract` renforce la suite smoke commune.
- Impact : aucun changement du portfolio produit ; validation commune etendue au lock d'index.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — impact partagé conventions commit

- Fichiers/surfaces : `.ai/index.md`, `template/.ai/index.md.jinja`.
- Contexte : l'item AI Debate `0013/Q3` documente les conventions de type de commit et de niveau documentaire.
- Impact : aucun changement du product loop ; l'index precise seulement comment choisir entre feature, correction, maintenance et documentation.
- Validation portée par les checks Q3.

## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `tests/smoke-test.sh`.
- Impact : ajout d'une prevalidation Q4 dans le smoke global ; les assertions product portfolio existantes restent inchangées.
- Validation : `bash tests/smoke-test.sh` PASS.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : README runtime/template et smoke-test restent compatibles avec la traceability product pendant l'ajout des contrats workflow/quality.
- Aucun changement sur `product-status`, `product-portfolio`, `product-review` ni sur les contrats initiative/roadmap.
- Validation : `check-features` et smoke-test PASS.
