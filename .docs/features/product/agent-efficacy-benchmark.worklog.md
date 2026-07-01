# Worklog — product/agent-efficacy-benchmark

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-06-30 — création (pilot ze-solution, P1)

- Fiche créée via `aic-pilot` (pilot `.docs/pilots/2026-06-30-ze-solution.md`, item P1).
- Axe directeur retenu : « prouver & positionner ».
- Décision : métrique primaire = **taux de succès de tâche** ; coût tokens = leading indicator.
- Cadres : v1 maintainer-only, >=2 repos de référence, N runs pour la significativité.
- Phase : spec. Prochaine étape : concevoir le protocole (suite de tâches figée, grader objectif, choix du runner sous `tests/bench/`).
- Prochaine décision produit : 2026-07-15.

## 2026-07-01 — incrément 1 : scaffold exécutable

- Livré : `docs/benchmarks/PROTOCOL.md`, `tests/bench/run-bench.sh` (seam `AGENT_CMD`, `--self-check`), tâche exemple `tests/bench/tasks/0001-example-file/` (task.md + check.sh objectif exécutable), `tests/bench/README.md`.
- **Décision runner** : seam externe `AGENT_CMD` (le runner n'embarque aucun agent) → tranche la décision « runner ouvert » sans dépendance ni secret ; reproductible et versionné.
- Conditions `with`/`without` = copie du repo, dépouillée de la couche (`.ai/`, shims, `.docs/`) pour `without`. Grader = `check.sh` par tâche (exit 0/≠0). Rapport → `docs/benchmarks/reports/`.
- Vérifié : `run-bench.sh --self-check` OK (happy-path + matrice) ET détecte une tâche cassée (check.sh non exécutable → FAIL). `check-features` PASS.
- **Runs réels NON exécutés** : action mainteneur (clés/coût/non-déterminisme). Le harnais est le livrable ; pas de résultats fabriqués.
- `v1 maintainer-only` : `tests/bench/` non rendu dans le template (comme le dogfooding).
- Follow-ups : câbler `AGENT_CMD`, choisir ≥2 repos (dont 1 externe), calibrer N, 1er rapport ; suite de tâches discriminantes ; HANDOFF `quality/smoke-test` (brancher `--self-check` dans le smoke) ; réconcilier le registre pilot après merge (P1 non tracé côté registre pour éviter le conflit avec la branche P6).
