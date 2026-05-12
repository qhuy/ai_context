# Worklog — workflow/mcp-policy

## 2026-05-12 — création
- Feature créée via `.ai/workflows/document-feature.md`.
- Scope : workflow.
- Intent initial : fixer une politique MCP opt-in, vérifiable et multi-agent.

## 2026-05-12 10:21 — update
- Intent : ajout de la politique MCP minimale dans les règles workflow et workflow on-demand.
- Fichiers/surfaces : `.ai/rules/workflow.md`, `.ai/workflows/mcp-policy.md`, README.
- Décision : aucun serveur MCP par défaut ; scripts locaux prioritaires pour les checks déterministes.
- Validation : checks structurels à lancer en fin de chantier.
- Next : vérifier les références markdown.

## 2026-05-12 10:22 — HANDOFF → core

### What delivered
- Politique MCP prête côté runtime.
- Besoin de miroir template identifié pour éviter `check-dogfood-drift`.

### What next needs
- Propager le workflow MCP et README_AI_CONTEXT vers `template/`.
- Vérifier le rendu Copier via dogfood drift.

### Blockers
- aucun

### Status
DONE
Source session : automation veille-techno

## 2026-05-12 10:35 — validation
- Validation : `check-feature-docs --strict workflow/mcp-policy` PASS, `check-ai-references` PASS, `check-shims` PASS, `check-features` PASS, `tests/smoke-test.sh` PASS.
- Décision : feature en `review`, MCP reste opt-in.
