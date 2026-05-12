# Worklog — workflow/subagent-contract

## 2026-05-12 — création
- Feature créée via `.ai/workflows/document-feature.md`.
- Scope : workflow.
- Intent initial : formaliser un contrat subagents multi-agent sans couplage runtime.

## 2026-05-12 10:20 — update
- Intent : ajout du contrat subagents dans les règles workflow et workflow on-demand.
- Fichiers/surfaces : `.ai/rules/workflow.md`, `.ai/workflows/subagent-contract.md`, README.
- Décision : ne pas modifier Pack A ; le contrat reste chargé à la demande.
- Validation : checks structurels à lancer en fin de chantier.
- Next : vérifier que `check-shims` garde Pack A lean.

## 2026-05-12 10:21 — HANDOFF → core

### What delivered
- Contrat workflow prêt côté runtime.
- Besoin de miroir template identifié pour éviter `check-dogfood-drift`.

### What next needs
- Propager les fichiers workflow/rules/docs vers `template/`.
- Vérifier le rendu Copier via dogfood drift.

### Blockers
- aucun

### Status
DONE
Source session : automation veille-techno

## 2026-05-12 10:35 — validation
- Validation : `check-feature-docs --strict workflow/subagent-contract` PASS, `check-shims` PASS, `check-features` PASS, `check-dogfood-drift` PASS, `tests/smoke-test.sh` PASS.
- Décision : feature en `review`, aucun blocker.
