# Worklog — workflow/feature-consolidation-nudge

## 2026-06-26 — création + implémentation (MVP nudge)

- Cadrage `aic-frame` (high) après fan-out de la surface : la discipline anti-prolifération n'existait qu'à la création (`feature-new` + `feature-granularity`) ; aucun re-questionnement edit-time. Le hook `features-for-path.sh` ne se déclenche pas sur une édition de fiche (47/51 fiches n'ont pas de `touches:` sur elles-mêmes).
- Décisions confirmées : MVP = nudge seul ; signal = même scope + famille d'id ; advisory (honore la décision no-blocking de `workflow/feature-granularity`).
- Livré :
  - `.ai/scripts/fiche-consolidation-nudge.sh` (+ jinja) : hook `PreToolUse(Write|Edit|MultiEdit)`, early-exit hors fiche, émet question + sœurs (famille d'id en tête, cap 12), `file_path` absolu (robuste symlinks).
  - `.claude/settings.json` (+ jinja) : 2ᵉ hook sous `Write|Edit|MultiEdit`.
  - `.ai/workflows/feature-update.md` (+ jinja) : règle « réinterroger la raison d'être » (paire avec « splitter »), + correction de la note `progress.updated` (stale depuis le fix anti-churn auto-worklog).
  - `tests/unit/test-fiche-consolidation-nudge.sh` (4 cas) + enregistrement smoke [0k].
- Vérif live : édition de `core/feature-mesh.md` → `feature-mesh-contract-alignment` marquée famille d'id, `feature-index-cache` correctement NON-famille ; worklog/code → rien.
- Suivi laissé : détecteur d'overlap `touches:` (Jaccard hors boilerplate) comme mode `consolidate` de `workflow/feature-audit`.

## 2026-07-03 — done
- Intent : clôturer le MVP `feature-consolidation-nudge` après validation du hook advisory et de la propagation dogfood.
- Fichiers/surfaces : `.docs/features/workflow/feature-consolidation-nudge.md`, `.docs/features/workflow/feature-consolidation-nudge.worklog.md`.
- Décision : statut `done`; le détecteur d'overlap `touches:` reste hors périmètre et devra être cadré séparément s'il devient prioritaire.
- Validation : `bash tests/unit/test-fiche-consolidation-nudge.sh`; `bash -n .ai/scripts/fiche-consolidation-nudge.sh template/.ai/scripts/fiche-consolidation-nudge.sh.jinja`; `bash .ai/scripts/check-feature-docs.sh --strict workflow/feature-consolidation-nudge`; `bash .ai/scripts/check-dogfood-drift.sh`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-16 — HANDOFF index réservés
- Propriété directe du nudge et de son test conservée ; la feature d'index progressifs devient consommatrice partagée.
- Le nudge refuse les index/logs/worklogs et compare des chemins physiques cohérents sur macOS.
- Validation : `test-fiche-consolidation-nudge.sh` et scénario index dédié PASS.
