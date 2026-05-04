# Worklog — core/dogfood-runtime-sync

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` et `.docs/FEATURE_TEMPLATE.md` restent compatibles avec le runtime dogfood.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` ajoute une validation explicite avant écriture sans changer les invariants dogfood.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-features.sh` et `check-feature-docs.sh workflow/feature-new-approval-step` PASS.
