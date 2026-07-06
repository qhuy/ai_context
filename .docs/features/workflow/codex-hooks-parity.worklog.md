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

## 2026-07-03 — done
- Intent : clôturer `codex-hooks-parity` après clôture de `git-hooks` et confirmation du choix opt-in.
- Fichiers/surfaces : `.docs/features/workflow/codex-hooks-parity.md`, `.docs/features/workflow/codex-hooks-parity.worklog.md`.
- Décision : statut `done`; pas de `.codex/` par défaut, parité documentée via hooks Git universels + recette Codex opt-in.
- Validation : `bash .ai/scripts/check-feature-docs.sh --strict workflow/codex-hooks-parity`; `bash .ai/scripts/check-agent-config.sh`; `bash .ai/scripts/check-features.sh --no-write`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-06 — génération opt-in .codex/hooks.json (P1, commit ②)
- Intent : combler le gap « injection auto / gate fin de turn : Non » côté Codex (P0 audit 2026-05-06, chantier P1 d'ANALYSE.md) en générant la config que le contrat spécifiait.
- Fichiers/surfaces : `copier.yml` (question `enable_codex_hooks` défaut false + `_exclude` .codex), `template/.codex/hooks.json.jinja` (nouveau), `.ai/workflows/codex-hooks-parity.md` (+ miroir jinja), `.ai/scripts/stop-doc-gate.sh` (+ miroir, header requalifié protocole partagé), `tests/smoke-test.sh` (étape [28d/28]).
- Décisions : format hooks.json (jq-validable, pas de collision config.toml consommateur) ; `stop-doc-gate.sh` réutilisé tel quel sur `Stop` (contrat vérifié identique à Claude, doc officielle 2026-07-06) ; reminder borné via `pre-turn-reminder.sh --format=text` sur `UserPromptSubmit` ; ANTI-EXEMPLE documenté — le primitive brut sur `Stop` est non bloquant (exit 1 = erreur ignorée) ; injection par édition et auto-worklog Codex explicitement hors périmètre (pas de canal / payload apply_patch non validé).
- Trust model : hooks projet chargés seulement si la couche `.codex/` est trustée ; fallback = commit-msg + CI (inchangés).
- Validation : smoke [28d/28] (opt-in respecté, hooks.json conforme, check-agent-config PASS sur scaffold) ; suite complète au commit.
- Next : commit ③ — README table Honnêteté runtime + `_message_after_copy`, puis clôture.
