# tests/bench — Benchmark d'efficacité agent (maintainer-only)

Harnais pour prouver que `ai_context` améliore le **taux de succès de tâche**
d'un agent vs un repo nu. Protocole complet : [../../docs/benchmarks/PROTOCOL.md](../../docs/benchmarks/PROTOCOL.md).

> **v1 maintainer-only** : non rendu dans le template (comme les scripts de
> dogfooding). Les projets consommateurs ne reçoivent pas ce dossier.

## Structure

```
tests/bench/
├── run-bench.sh              # orchestrateur (seam AGENT_CMD ; --self-check)
└── tasks/<id>/
    ├── task.md               # prompt + critère humain-lisible
    └── check.sh              # grader OBJECTIF (exit 0/≠0), exécuté après l'agent
```

## Valider le plumbing (sans agent)

```bash
bash tests/bench/run-bench.sh --self-check
```

Vérifie que chaque tâche a `task.md` + `check.sh` exécutable, que les repos
(si `BENCH_REPOS`) existent, et affiche la matrice de runs. N'invoque aucun agent.

## Run réel (action mainteneur)

```bash
export AGENT_CMD='claude -p --output-format json'   # ou codex, ou runner maison
export BENCH_REPOS='/chemin/repo-a /chemin/repo-b'   # ≥2, dont ≥1 externe
export BENCH_N=5                                     # runs par cellule
export BENCH_AGENT_LABEL='claude-sonnet-...'
bash tests/bench/run-bench.sh
```

Coûteux + non-déterministe (vraies invocations d'agent). Rapports sous
`docs/benchmarks/reports/`, logs sous `docs/benchmarks/runs/<stamp>/`.

Le runner :

- copie chaque repo dans un dossier temporaire ;
- applique la condition `without` en retirant `.ai/`, `.docs/` et les shims agents ;
- envoie `task.md` sur `stdin` de `$AGENT_CMD` ;
- expose à l'agent uniquement `BENCH_TASK_ID` et `BENCH_WORKDIR` pour éviter de
  fuiter le chemin du repo source dans la condition `without` ;
- exécute ensuite `check.sh` dans la copie de travail ;
- expose au grader `BENCH_PROMPT_FILE`, `BENCH_TASK_DIR`, `BENCH_TASK_ID`,
  `BENCH_CONDITION`, `BENCH_RUN_INDEX`, `BENCH_REPO_NAME`,
  `BENCH_SOURCE_REPO`, `BENCH_WORKDIR` ;
- agrège Markdown + TSV + JSONL.

Exemple Codex CLI, prompt lu depuis `stdin` et travail dans le `cwd` de la copie :

```bash
export AGENT_CMD='codex exec --skip-git-repo-check --ephemeral --sandbox workspace-write -'
export BENCH_AGENT_LABEL='codex exec / workspace-write'
```

`AGENT_CMD` n'est pas écrit dans les rapports pour éviter de consigner un secret
accidentel ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner. Pour une
vérification non publiée, rediriger `BENCH_REPORT_DIR` et `BENCH_RUN_DIR` vers un
dossier temporaire.

## Ajouter une tâche

1. `tests/bench/tasks/<id>/task.md` — prompt + critère.
2. `tests/bench/tasks/<id>/check.sh` (`chmod +x`) — grader objectif (assertions).
3. `bash tests/bench/run-bench.sh --self-check` pour valider.

Préférer un grader par **assertion**. LLM-judge seulement si aucune assertion
possible, avec critères écrits + échantillon vérifié à la main (cf. PROTOCOL).

## Suite actuelle

- `0001-example-file` : tâche de fumée du format de tâche, non discriminante.
- `0002-feature-resume` : retrouve la feature active la plus fraîche depuis le
  feature mesh et écrit une reprise JSON objective.
- `0003-handoff-decision` : vérifie la décision de handoff cross-scope pour le
  branchement du benchmark dans le smoke-test.
