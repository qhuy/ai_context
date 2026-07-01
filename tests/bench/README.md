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
bash tests/bench/run-bench.sh
```

Coûteux + non-déterministe (vraies invocations d'agent). Rapports sous
`docs/benchmarks/reports/`.

## Ajouter une tâche

1. `tests/bench/tasks/<id>/task.md` — prompt + critère.
2. `tests/bench/tasks/<id>/check.sh` (`chmod +x`) — grader objectif (assertions).
3. `bash tests/bench/run-bench.sh --self-check` pour valider.

Préférer un grader par **assertion**. LLM-judge seulement si aucune assertion
possible, avec critères écrits + échantillon vérifié à la main (cf. PROTOCOL).
