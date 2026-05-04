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
