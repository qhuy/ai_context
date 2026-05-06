# Worklog — workflow/agent-behavior

## 2026-05-03 — création

- Feature créée pour tracer la couche comportementale agent.
- Scope : workflow.
- Intent initial : améliorer la posture, l'initiative, le style de réponse et le diagnostic sans gonfler les shims ni le reminder.

## 2026-05-04 — freshness
- Impact indirect : les nouveaux wrappers Codex restent on-demand et ne changent pas le Pack A.
- Validation associée : check-shims et smoke-test complet PASS.
## 2026-05-05 — freshness
- Impact transversal : l'index principal ajoute le chargement optionnel `.ai/project/index.md` sans élargir Pack A.
- Validation associée : `check-shims.sh` PASS.

## 2026-05-06 — freshness
- Impact indirect : le nouveau skill documente les fiches feature sans modifier la posture agent ni le Pack A.
- `legacy` y est traité comme scope custom seulement si le repo l'active.
- Validation associée : `check-shims.sh`, smoke-test PASS.
## 2026-05-06 — freshness
- Intent : tracer l'impact Copier indirect sur la couche comportementale et `aic-diagnose`.
- Validation : couvert par `check-shims`, `measure-context-size` et `tests/smoke-test.sh`.
