# Worklog — workflow/stop-turn-doc-gate

## 2026-06-26 — création + implémentation

- Cadrage `aic-frame` (niveau high). Cause racine corrigée : `check-feature-freshness.sh` sans `--staged` compare des timestamps de commits (mode historique), pas le working tree — aveugle aux édits non commités. Vérifié empiriquement.
- 3 décisions tranchées avec l'utilisateur : (1) nouvelle feature `workflow/stop-turn-doc-gate` cross-scope + HANDOFF `quality` ; (2) blocage jusqu'à résolution ; (3) anti-bruit via `coverage.roots+extensions`.
- Implémenté :
  - `_lib.sh` : `coverage_config_file`, `read_coverage_list`, `path_in_coverage_scope` (+ jinja).
  - `check-feature-freshness.sh` : mode `--worktree` présence-based via `collect_uncommitted_paths`, filtré « substantiel » (+ jinja, copie identique).
  - `stop-doc-gate.sh` : orchestrateur read-only, `decision:block`, `stop_hook_active`, `AIC_DOC_GATE=off`, warn orphelins (+ jinja).
  - `stop-sequence.sh` : hook Stop unique sérialisant gate → archivage (+ jinja).
  - `.claude/settings.json` : Stop ramené à `stop-sequence.sh` (timeout 20) (+ jinja).
  - Docs : `QUALITY_GATE.md` section « Fraîcheur en fin de tour » (+ jinja).
  - Tests : `tests/unit/test-stop-turn-doc-gate.sh` (7 cas) + extension `test-read-only-checks-contract.sh` + enregistrement `tests/smoke-test.sh`.
- Découverte clé : les hooks Stop tournent **en parallèle** (doc officielle). D'où le sequencer : sans lui, `auto-worklog-flush` auto-touche le worklog et neutralise le gate.
- Reste avant DONE : `tests/smoke-test.sh` complet + `check-dogfood-drift.sh` ; traiter les obligations freshness staged multi-features (`_lib.sh` couvert par ~8 fiches).

## 2026-06-26 — couverture incidente (workflow/feature-consolidation-nudge)
- Surface partagée touchée (.claude/settings.json, jinjas template, ou .ai/workflows/feature-update.md) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.
