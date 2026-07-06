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

## 2026-06-26 17:25 — auto
- Fichiers modifiés :
  - .claude/settings.json

## 2026-07-03 — HANDOFF depuis core/vcs-provider-abstraction
- Surface partagée touchée : `stop-doc-gate.sh` utilise le provider VCS pour lister les changements locaux. Comportement bloquant inchangé.
- Validation portée par `core/vcs-provider-abstraction`.

## 2026-07-03 — done
- Intent : clôturer `workflow/stop-turn-doc-gate` après validation du gate Stop, du mode `--worktree` et du sequencer gate -> archivage.
- Fichiers/surfaces : `.docs/features/workflow/stop-turn-doc-gate.md`, `.docs/features/workflow/stop-turn-doc-gate.worklog.md`.
- Décision : statut `done`; aucune action immédiate, réouverture seulement si le contrat Stop, la fraîcheur `--worktree` ou l'ordre gate -> archivage change.
- Validation : `bash tests/unit/test-stop-turn-doc-gate.sh`; `bash tests/unit/test-read-only-checks-contract.sh`; `bash -n .ai/scripts/stop-doc-gate.sh .ai/scripts/stop-sequence.sh .ai/scripts/check-feature-freshness.sh template/.ai/scripts/stop-doc-gate.sh.jinja template/.ai/scripts/stop-sequence.sh.jinja template/.ai/scripts/check-feature-freshness.sh.jinja`; `bash .ai/scripts/check-dogfood-drift.sh`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-06 — HANDOFF depuis workflow/codex-hooks-parity
- `stop-doc-gate.sh` (+ miroir jinja) : header seul requalifié — le protocole `stop_hook_active` + `decision:block` est partagé par Claude et Codex (doc officielle vérifiée 2026-07-06) ; le gate est désormais branché opt-in côté Codex via `.codex/hooks.json` généré. Aucun changement de logique.
- Validation portée par `workflow/codex-hooks-parity` (tests stop-hook inchangés dans la boucle unitaire).

## 2026-07-06 — requalification Claude-only → protocole partagé (suite HANDOFF)
- Corps de fiche + `QUALITY_GATE.md` (+ jinja) : le gate Stop n'est plus décrit « Claude-only » — protocole `decision:block` partagé, branché par défaut côté Claude et opt-in côté Codex via `.codex/hooks.json`. Warn orphelins : canal Claude, ignoré par Codex. Aucun changement de logique.
- Validation portée par `workflow/codex-hooks-parity`.
