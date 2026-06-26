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

## 2026-06-26 — parité fraîcheur fin de turn (stop-turn-doc-gate)
- Ajout d'une section « Parité fraîcheur fin de turn » dans `.ai/workflows/codex-hooks-parity.md` (+ jinja) : garantie universelle `commit-msg --staged --strict` + recette opt-in (hook Codex de fin de turn → primitive agnostique `check-feature-freshness.sh --worktree --strict`, code retour 1 = bloque). Bullet « Autorisé » + ligne de validation ajoutés.
- `stop-doc-gate.sh` reste Claude-only (protocole `decision:block` / `stop_hook_active`). Surface Codex `Stop` (config.toml `[hooks]`, ~/.codex/hooks.json) documentée « à valider contre la surface live » ; pas de `.codex/` livré par défaut (décision inchangée).
- Cross-ref ajouté vers `workflow/stop-turn-doc-gate` (pas de `depends_on` réciproque pour éviter un cycle).
- Validation : voir commit (check-features, check-feature-docs --strict, check-agent-config, dogfood-drift, smoke-test).

## 2026-06-26 15:03 — auto
- Fichiers modifiés :
  - .ai/workflows/codex-hooks-parity.md
