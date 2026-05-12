# Worklog — quality/ci-guard


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - .github/workflows/template-smoke-test.yml

## 2026-05-08 — couverture dogfood source
- Intent : eviter qu'un drift runtime dogfoode puisse passer hors CI source.
- Changement : `template-smoke-test.yml` se declenche aussi sur `.agents/**`, `.ai/**`, `.claude/**`, `.githooks/**`, `AGENTS.md`, `CLAUDE.md`, `README_AI_CONTEXT.md`, `.docs/FEATURE_TEMPLATE.md` et `tests/unit/**`.
- Ajout : etape explicite `bash .ai/scripts/check-dogfood-drift.sh` avant le smoke test.
- Validation : `check-dogfood-drift.sh` PASS local.

## 2026-05-12 — veille Claude/Codex
- Impact direct : le workflow CI source lance `bash .ai/scripts/check-agent-config.sh` avant le smoke-test.
- Parite template : `template/.github/workflows/ai-context-check.yml.jinja` alignee.
- Validation locale : `check-agent-config`, `doctor` et smoke-test PASS.
