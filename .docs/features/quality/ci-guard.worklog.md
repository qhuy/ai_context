# Worklog — quality/ci-guard


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - .github/workflows/template-smoke-test.yml

## 2026-05-08 — couverture dogfood source
- Intent : eviter qu'un drift runtime dogfoode puisse passer hors CI source.
- Changement : `template-smoke-test.yml` se declenche aussi sur `.agents/**`, `.ai/**`, `.claude/**`, `.githooks/**`, `AGENTS.md`, `CLAUDE.md`, `README_AI_CONTEXT.md`, `.docs/FEATURE_TEMPLATE.md` et `tests/unit/**`.
- Ajout : etape explicite `bash .ai/scripts/check-dogfood-drift.sh` avant le smoke test.
- Validation : `check-dogfood-drift.sh` PASS local.
