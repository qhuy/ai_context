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

## 2026-05-14 — implement / rapports product read-only

- Intent : rendre effectif le contrat déjà documenté "les scripts produit sont read-only".
- Fichiers/surfaces : `check-product-links.sh`, `product-status.sh`, `product-portfolio.sh`, `product-review.sh` et leurs templates.
- Décision : les scripts product génèrent un index temporaire via stdout de `build-feature-index.sh`; en cas d'échec, ils peuvent lire un cache existant avec warning, mais ne lancent plus `--write`.
- Test : ajout de `tests/unit/test-product-reports-read-only.sh`.
- Validation : `test-product-reports-read-only` PASS, `check-product-links --strict` PASS, `aic.sh product-status` PASS, `aic.sh product-portfolio` PASS, `aic.sh product-review product/ai-context-stability-migration` PASS.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - copier.yml

## 2026-06-19 12:39 — auto
- Fichiers modifiés :
  - .ai/index.md
  - .ai/scripts/check-dogfood-drift.sh
  - template/.ai/index.md.jinja

## 2026-06-19 14:24 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh

## 2026-06-19 14:53 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-19 17:52 — auto
- Fichiers modifiés :
  - .ai/scripts/dogfood-update.sh
  - tests/smoke-test.sh

## 2026-06-19 18:03 — auto
## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/schema/feature.schema.json
  - template/.ai/scripts/aic.sh.jinja
  - template/.ai/scripts/build-feature-index.sh.jinja
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja

## 2026-06-26 11:34 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-26 — couverture incidente (workflow/auto-worklog fix churn date)
- Surface partagée touchée (tests/smoke-test.sh, gabarit flush, ou tests/unit) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-26 16:56 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
