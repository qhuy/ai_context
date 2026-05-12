# Worklog — workflow/codex-hooks-parity

## 2026-05-12 — création
- Feature créée via `.ai/workflows/document-feature.md`.
- Scope : workflow.
- Intent initial : cadrer des hooks Codex opt-in et déterministes, sans injection de contexte ni gate LLM.

## 2026-05-12 10:20 — HANDOFF → quality

### What delivered
- Contrat workflow du pilote hooks Codex : opt-in, déterministe, non LLM.
- Limites explicites : pas d'Auto-review comme garantie, pas d'injection contexte Codex par défaut.

### What next needs
- Ajouter un check non destructif pour valider les configs agents présentes.
- Brancher ce check dans la quality gate, doctor et CI.

### Blockers
- aucun

### Status
DONE
Source session : automation veille-techno

## 2026-05-12 10:35 — validation
- Validation : `check-feature-docs --strict workflow/codex-hooks-parity` PASS, `check-agent-config` PASS, `check-shims` PASS, `check-features` PASS, `check-dogfood-drift` PASS, `tests/smoke-test.sh` PASS.
- Décision : feature en `review`, aucun `.codex/` généré par défaut.
