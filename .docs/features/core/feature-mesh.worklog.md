# Worklog — core/feature-mesh


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - template/.ai/scripts/check-features.sh.jinja

## 2026-05-04 — freshness
- Impact documentaire : `.docs/FEATURE_TEMPLATE.md` précise la granularité et le nommage des fiches feature.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact template : `template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja` conserve la règle de granularité pour les projets générés.
- Changement porté par dogfood runtime sync.
- Validation associée : `check-dogfood-drift.sh` PASS.
