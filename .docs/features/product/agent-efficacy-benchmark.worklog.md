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

## 2026-07-02 — incrément 2 : boucle réelle du runner

- Livré : `run-bench.sh` exécute maintenant la matrice repos × tâches × conditions × N : copies isolées, condition `without` dépouillée, randomisation par `BENCH_SEED`, appel `$AGENT_CMD`, grader, rapports Markdown par repo, TSV + JSONL globaux, logs par cellule.
- Contrat seam précisé : `task.md` est fourni sur `stdin`; wrappers possibles via `BENCH_PROMPT_FILE`, `BENCH_TASK_ID`, `BENCH_CONDITION`, `BENCH_RUN_INDEX`, `BENCH_REPO_NAME`, `BENCH_REPO_PATH`, `BENCH_WORKDIR`. `AGENT_CMD` n'est pas loggé pour éviter les secrets ; `BENCH_AGENT_LABEL` trace le runner/modèle.
- Vérifié : `bash -n tests/bench/run-bench.sh`, `bash tests/bench/run-bench.sh --self-check`, run d'intégration déterministe sur 2 repos temporaires (`BENCH_N=1`, 4/4 PASS, rapports + TSV + JSONL générés hors repo), `check-features`, `check-feature-docs`, `check-feature-freshness --worktree --strict`, `git diff --check`, `check-shims`, `measure-context-size`.
- Probe agent réel : `codex exec --skip-git-repo-check --ephemeral --sandbox workspace-write -` fonctionne sur repo temporaire isolé pour la tâche `HELLO.txt`, mais la tâche triviale a consommé beaucoup de tokens ; pas de run complet Codex × 2 repos × 2 conditions tant que la suite n'est pas discriminante.
- Follow-ups : écrire/choisir les tâches discriminantes, sélectionner ≥2 repos de référence (dont 1 externe avec condition `with` honnête), calibrer `N`, puis produire le premier rapport publiable sous `docs/benchmarks/reports/`. HANDOFF qualité inchangé : brancher `run-bench.sh --self-check` dans le smoke.

## 2026-07-02 — incrément 3 : suite discriminante initiale

- Livré : tâches `0002-feature-resume` et `0003-handoff-decision`, avec graders objectifs exécutables.
- Décision : `$AGENT_CMD` ne reçoit plus les chemins source (`BENCH_REPOS`, `BENCH_SOURCE_REPO`, `BENCH_REPO_PATH`, etc.) afin de ne pas contaminer la condition `without`; les métadonnées source sont exposées uniquement au grader.
- Intent des tâches : mesurer deux apports concrets d'ai_context — reprise depuis le feature mesh, et respect de la règle cross-scope ⇒ HANDOFF.
- Validation : `bash -n` runner + graders, `run-bench.sh --self-check`, probe env agent (seuls `BENCH_TASK_ID`/`BENCH_WORKDIR` visibles), matrice temporaire 2 repos ai_contextisés × 3 tâches × 2 conditions × N=1 avec agent déterministe honnête (8/12 succès, échecs `without` attendus sur les tâches dépendantes du contexte, sans fuite source vers l'agent), `check-features`, `check-feature-docs`, `check-feature-freshness --worktree --strict`, `git diff --check`, `check-shims`, `measure-context-size`, `review-delta`, `check-feature-coverage`.
- Next : préparer un premier run agent réel sur repos ai_contextisés si budget accepté, puis publier le premier rapport sous `docs/benchmarks/reports/`.

## 2026-07-02 — run réel N=1 : fuite détectée puis correction

- Premier run réel Codex sur `ai_context` + `ai_debate`, sous-suite portable `0001`/`0002`, `N=1`, stamp `2026-07-02-codex-n1-portable`.
- Résultat brut initial : `ai_context` 100%/100%, `ai_debate` 100%/50%. Inspection des logs : la copie `without` de `ai_context` conservait encore `.agents`, `.claude/skills`, `tests/bench/` et les artefacts `docs/benchmarks/*`; le résultat `ai_context without` était donc contaminé.
- Correction runner : exclure `tests/bench/` + `docs/benchmarks/{reports,runs}` de toutes les copies, et retirer `.agents` + `.claude/skills` dans `without`.
- Correction runner complémentaire : ajout de `BENCH_TIMEOUT_SECONDS` par cellule (`agent_exit=124`) après blocage prolongé de `ai_context/0002/without` avec le harnais corrigé.
- Correction publication : les logs, TSV et JSONL sont produits dans un répertoire temporaire puis copiés vers `docs/benchmarks/*` uniquement en fin de run, pour éviter de conserver des artefacts partiels.
- Décision appliquée : les runs contaminés/partiels ont été supprimés avant publication ; relancer avec le même stamp après correction.
- Validation : `bash -n` runner + graders, `run-bench.sh --self-check`, matrice déterministe 2 repos × 3 tâches × 2 conditions × N=1 (8/12 succès attendus), test timeout `BENCH_TIMEOUT_SECONDS=1` (`agent_exit=124` sur 2/2 cellules), puis gate projet avant commit.
