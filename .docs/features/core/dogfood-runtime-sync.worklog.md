# Worklog — core/dogfood-runtime-sync

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` et `.docs/FEATURE_TEMPLATE.md` restent compatibles avec le runtime dogfood.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` ajoute une validation explicite avant écriture sans changer les invariants dogfood.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-features.sh` et `check-feature-docs.sh workflow/feature-new-approval-step` PASS.

## 2026-05-04 — dogfood
- `bash .ai/scripts/dogfood-update.sh --apply` exécuté après propagation des règles feature-new dans le template Copier.
- Drift initial détecté sur `.ai/workflows/feature-new.md` et `.docs/FEATURE_TEMPLATE.md`, puis résolu après mise à jour des fichiers `template/...`.
- Validations associées : `check-dogfood-drift.sh`, `check-shims.sh`, `check-features.sh` PASS.

## 2026-05-05 — freshness
- Impact transversal : l'overlay projet stable ajoute `.ai/OWNERSHIP.md`, `.ai/templates/project-overlay/README.md` et adapte les scripts dogfood pour préserver `.ai/project/**`.
- Validation associée : dogfood-update appliqué puis `check-dogfood-drift.sh`, `check-shims.sh`, `check-features.sh` PASS.

## 2026-05-06 — dogfood
- `bash .ai/scripts/dogfood-update.sh --apply` exécuté après ajout de `document-feature` au template.
- Runtime synchronisé : `.ai/workflows/document-feature.md`, `.claude/skills/aic-document-feature/**`, `.agents/skills/aic-document-feature/**`, `README_AI_CONTEXT.md`.
- Validation prévue : `check-dogfood-drift.sh`, `check-shims.sh`, `check-features.sh`.

## 2026-05-06 — freshness commit
- Impact couvert : runtime `.ai/workflows/**`, `.claude/skills/**`, `.agents/skills/**` et `README_AI_CONTEXT.md` synchronisés.
- Aucun changement sur le contrat source-only de dogfood.
- Validation associée : `check-dogfood-drift.sh`, `check-shims.sh`, smoke-test PASS.
## 2026-05-06 — freshness
- Intent : documenter l'impact du renommage runtime `ai-context.sh` -> `aic.sh` sur les surfaces dogfoodées.
- Validation : couvert par `check-shims`, `check-features` et `tests/smoke-test.sh`.

## 2026-05-06 — retours review
- Intent : garder le runtime dogfoodé aligné avec les corrections staged-delta et surface `aic`.
- Fichiers/surfaces : `.ai/scripts/aic.sh`, `.ai/scripts/review-delta.sh`, `.ai/scripts/check-feature-freshness.sh`.
- Décision : les suppressions et renommages staged restent visibles dans les rapports et contrôles du runtime source.
- Validation : prévue via `bash -n`, `check-shims`, `check-feature-freshness --staged --strict`.
