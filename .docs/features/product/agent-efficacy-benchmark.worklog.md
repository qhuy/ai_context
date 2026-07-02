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

## 2026-07-02 — premier rapport réel publié

- Run : repos locaux `ai_context` + `ai_debate`, sous-suite portable `0001-example-file` + `0002-feature-resume`, `BENCH_N=1`, `BENCH_SEED=42`, `BENCH_TIMEOUT_SECONDS=300`, agent `codex exec / workspace-write`.
- Résultat global : `with` 4/4 (100%) vs `without` 2/4 (50%), Δ +50 points.
- Résultat discriminant `0002-feature-resume` : `with` 2/2 vs `without` 0/2, Δ +100 points sur la reprise feature mesh.
- Coût tokens extrait depuis les logs Codex : `with` 163997 tokens sur 4 runs mesurés (moyenne 40999), `without` 89804 tokens sur 3 runs mesurés (moyenne 29935) ; `ai_context/0002/without` timeout sans bloc exploitable.
- Artefacts publiés : rapports par repo, TSV, JSONL, logs sous `docs/benchmarks/reports/` et `docs/benchmarks/runs/2026-07-02-codex-n1-portable/`; synthèse `docs/benchmarks/reports/2026-07-02-codex-n1-portable-summary.md`.
- Hygiène publication : les rapports/résultats versionnés utilisent des refs repo/chemins relatifs ; scan logs sans secret brut détecté (seulement noms de variables/env et contenu repo).
- Limites : `N=1`, sous-suite portable seulement, pas d'intervalle de confiance, mesure tokens partielle sur timeout.
- Validation finale : `bash -n tests/bench/run-bench.sh`, run minimal agent factice `0001`, `run-bench.sh --self-check`, JSONL valide, `git diff --check`, `git show --check HEAD`, `check-feature-docs product/agent-efficacy-benchmark`, `check-feature-freshness --worktree --strict`, `check-shims`, `check-agent-config`, `check-ai-references`, `check-features --no-write`, `check-feature-coverage`, `check-touches-breadth`, `measure-context-size`.
- Warnings acceptés : deux anciennes fiches sans champ OKF `type`, 6 tests unitaires orphelins, advisory touches breadth sur surfaces partagées ; hors delta de ce run.
- Next : augmenter N, généraliser `0003` pour repos externes ou garder cette tâche en run repo-spécifique, stabiliser la lecture tokens sur runs timeout, puis brancher `run-bench.sh --self-check` dans le smoke via HANDOFF `quality/smoke-test`.

## 2026-07-02 — tentative N=3 invalide, durcissement infra

- Run tenté : Codex `N=3`, repos `ai_context` + `ai_debate`, sous-suite portable `0001-example-file` + `0002-feature-resume`, `BENCH_SEED=42`, `BENCH_TIMEOUT_SECONDS=300`.
- Résultat : run invalide comme preuve benchmark, car deux cellules `with` finales ont échoué sur limite d'usage Codex (`agent_exit=1`, message `You've hit your usage limit`).
- Signal partiel : `ai_debate/0002/without` échoue 3/3 tandis que `ai_debate/0002/with` passe 2/2 avant quota ; `ai_context/0002/without` passe 2/3 et timeout 1/3, donc `0002` est trop facile sur `ai_context` sans contexte.
- Correction runner : ajout de `failure_kind` (`none`, `task_fail`, `timeout`, `agent_error`, `agent_infra_error`, `unknown`), détection quota/auth/provider, sortie non-zéro si `agent_infra_error` contamine un run, et parsing tokens sur le dernier bloc exact `tokens used`.
- Décision publication : artefacts N=3 invalides supprimés du working tree ; ne pas publier comme rapport benchmark.
- Validation : `bash -n tests/bench/run-bench.sh`, `run-bench.sh --self-check`, run factice succès avec parsing dernier bloc tokens, run factice quota avec `failure_kind=agent_infra_error` et exit `2`.
- Next : relancer N=3 après reset quota avec le runner durci, puis renforcer la suite discriminante pour `ai_context` si le partiel se confirme.

## 2026-07-02 — rerun N=3 complet, faux positif infra corrigé

- Run : Codex `N=3`, repos `ai_context` + worktree propre `ai_debate` à `HEAD` (`ai_debate` local étant sale/ahead), sous-suite portable `0001-example-file` + `0002-feature-resume`, `BENCH_SEED=42`, `BENCH_TIMEOUT_SECONDS=300`, stamp `2026-07-02-codex-n3-portable-rerun`.
- Résultat brut : 24 cellules terminées, aucun quota bloquant ; le runner a toutefois classé à tort `ai_debate/0002/without/run 1` en `agent_infra_error` parce que le stderr contenait du contenu repo avec le texte `rate limiting` alors que `agent_exit=0`.
- Correction runner : `agent_infra_error` requiert désormais `agent_exit != 0`, le motif `rate limit` est resserré, et le self-check couvre le cas "contenu repo infra + agent OK + check KO" qui doit rester `task_fail`.
- Résultat corrigé : global `with` 12/12 vs `without` 9/12 ; `ai_debate/0002` fait `with` 3/3 vs `without` 0/3 ; `ai_context/0002` fait `with` 3/3 vs `without` 3/3.
- Décision : publier les artefacts N=3 corrigés avec les logs du run complet ; ne pas relancer immédiatement les 24 cellules car le bug était une classification post-run et les logs/checks sont complets.
- Next : renforcer la tâche discriminante côté `ai_context` ou ajouter une tâche repo-spécifique, puis brancher `run-bench.sh --self-check` dans le smoke via HANDOFF `quality/smoke-test`.

## 2026-07-02 — R4 : garde rm -rf et tie-break matrice

- Contexte : R4 priorisé avant R1 pour sécuriser le prochain run Codex `N=3` au reset quota. Scope primaire maintenu sur `product/agent-efficacy-benchmark`.
- Correction runner : ajout d'une suppression sûre (`safe_rm_rf`) qui refuse cible vide, racine, repo root, home et racines temporaires ; la publication remplace `BENCH_RUN_DIR` seulement s'il reste sous `docs/benchmarks/runs` ou sous `TMPDIR`, avec un basename `BENCH_STAMP`.
- Correction matrice : randomisation par seed conservée, mais tri explicite `clé pseudo-aléatoire + ordre d'entrée`, pour rendre le tie-break déterministe sans dépendre du contenu des lignes.
- Correction grader 0002 : le prompt demandait de départager par `id`, alors que le grader trie par `scope/id`. Le libellé est aligné sur la vérité terrain du grader : `scope/id` lexicalement le plus petit.
- Documentation : `tests/bench/README.md`, `docs/benchmarks/PROTOCOL.md` et fiche feature mis à jour avec le contrat `BENCH_RUN_DIR`.
- Validation : `bash -n tests/bench/run-bench.sh` ; `bash tests/bench/run-bench.sh --self-check` PASS avec assertions garde `rm -rf` + tie-break ; tests négatifs `BENCH_RUN_DIR` non stampé et hors racine autorisée rejetés avant run ; test ciblé `0002-feature-resume` sur égalité `core/zzz` vs `product/aaa` attendu PASS/FAIL.
- Next : R1 peut reprendre ensuite en scope `workflow/pre-turn-reminder`, avec HANDOFF séparé depuis ce scope produit.

## 2026-07-02 — R3 : Δ tokens par classe de tâche

- Intent : rendre le leading indicator exploitable par classe de tâche, car un delta tokens global masque le surcoût des tâches triviales et l'économie des tâches contextuelles.
- Changement runner : ajout de `task.class` par tâche, colonne TSV/JSONL `task_class`, variable grader `BENCH_TASK_CLASS`, et tableau Markdown `Δ tokens par classe de tâche` (`with` - `without`) dans chaque rapport repo.
- Suite actuelle : `0001-example-file` = `trivial`, `0002-feature-resume` = `contextual`, `0003-handoff-decision` = `handoff`.
- Self-check : assertions synthétiques sur les chiffres observés qui ont motivé R3 (`trivial` +34695 tokens/run, +289.4% ; `contextual` -24622 tokens/run, -40.7%).
- Validation : `bash -n tests/bench/run-bench.sh` ; `bash tests/bench/run-bench.sh --self-check` ; run d'intégration local avec agent factice sur `0001` vérifiant header TSV `task_class`, JSONL `task_class:"trivial"` et ligne rapport `trivial` à +0 tokens ; `check-feature-docs --strict product/agent-efficacy-benchmark` ; `check-feature-freshness --worktree --strict` ; `check-features --no-write` ; `check-feature-docs` ; `check-feature-coverage` ; `check-touches-breadth` ; `measure-context-size` ; `git diff --check`. Warnings inchangés : 2 fiches historiques sans `type`, 6 tests unitaires orphelins, advisory touches breadth.
- Next : relancer le run mainteneur attendu avec ce rapport enrichi ; puis renforcer la suite côté `ai_context` si `0002` reste non discriminante.

## 2026-07-02 — run N=3 R3 tokens publié

- Run : Codex `N=3`, repos `ai_context` (`789fd76`) + worktree propre `ai_debate` (`d6cdc17`), sous-suite portable `0001-example-file` + `0002-feature-resume`, `BENCH_SEED=42`, `BENCH_TIMEOUT_SECONDS=300`, stamp `2026-07-02-codex-n3-portable-r3-tokens`.
- Résultat global : `with` 12/12 (100.0%) vs `without` 8/12 (66.7%), Δ +33.3 points.
- Résultat par tâche : `0001` passe partout ; `ai_debate/0002` réplique le signal externe (`with` 3/3, `without` 0/3) ; `ai_context/0002` devient partiellement discriminant (`with` 3/3, `without` 2/3).
- Leading indicator R3 : `contextual` = `with` 59386 tokens/run vs `without` 94235, soit -34848 (-37.0%) ; `trivial` = `with` 33854 vs `without` 22924, soit +10929 (+47.7%). Le tableau par classe confirme que le delta global masquerait deux réalités opposées.
- Hygiène : JSONL valide (24 lignes), `agent_infra_error=0`, `task_fail=4` tous sur `0002` en condition `without`, scan simple des rapports/logs sans secret brut détecté.
- Artefacts : synthèse `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-summary.md`, rapports par repo, TSV/JSONL et logs sous `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/`.
- Next : renforcer la suite côté `ai_context` et ajouter l'intervalle de confiance avant de considérer la preuve publiable hors contexte mainteneur.

## 2026-07-02 — incrément 11 : IC succès + probe handoff ai_context

- Changement runner : synthèse succès enrichie avec IC Wilson 95% par condition et IC approximatif Newcombe sur le Δ `with` - `without`; `--self-check` couvre le cas 12/12 vs 8/12.
- Run ciblé : Codex `N=3` sur `ai_context` seul, tâche `0003-handoff-decision`, `BENCH_SEED=42`, `BENCH_TIMEOUT_SECONDS=300`, stamp `2026-07-02-codex-n3-ai-context-handoff-ci`.
- Résultat : `with` 3/3 (IC Wilson [43.9% ; 100.0%]) vs `without` 2/3 (IC Wilson [20.8% ; 93.9%]), Δ +33.3 points avec IC approx. Newcombe [-50.0 ; 79.2].
- Coût tokens `handoff` : `with` 60845 tokens/run vs `without` 60148, soit +698 (+1.2%).
- Hygiène : JSONL valide (6 lignes), `agent_infra_error=0`, `task_fail=1` en condition `without`, scan simple des rapports/logs sans secret brut détecté.
- Validation : `bash -n tests/bench/run-bench.sh` ; `bash tests/bench/run-bench.sh --self-check` ; run d'intégration local agent factice vérifiant le rendu IC ; `check-feature-docs --strict product/agent-efficacy-benchmark` ; `check-feature-freshness --worktree --strict` ; `check-features --no-write` ; `check-feature-docs` ; `check-feature-coverage` ; `check-touches-breadth` ; `measure-context-size` ; `git diff --check` hors logs bruts. Logs bruts conservés tels que produits par l'agent, avec quelques espaces finaux. Warnings inchangés : 2 fiches historiques sans `type`, 6 tests unitaires orphelins, advisory touches breadth.
- Décision : `0003` renforce légèrement le côté `ai_context`, mais le prompt suggère trop la décision attendue pour en faire une preuve forte ; prochaine tâche à concevoir avec moins d'indices dans le prompt et un grader objectif.
- Artefacts : synthèse `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-handoff-ci-summary.md`, rapports/TSV/JSONL et logs sous `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/`.
