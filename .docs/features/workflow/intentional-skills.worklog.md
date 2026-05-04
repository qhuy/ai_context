# Worklog — workflow/intentional-skills

## 2026-05-04 — freshness
- Impact direct : la surface intentionnelle `aic-frame/status/diagnose/review/ship` est aussi générée sous `.agents/skills/` pour Codex.
- Les workflows canoniques restent sous `.ai/workflows/`.
- Validation associée : smoke-test complet PASS.

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` reçoit un check anti fourre-tout sans changer la mécanique des skills intentionnels.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact documentaire : `feature-new` devient explicitement validable avant écriture, sans changer les autres skills intentionnels.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-features.sh` et `check-feature-docs.sh workflow/feature-new-approval-step` PASS.
