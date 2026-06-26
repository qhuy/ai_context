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
