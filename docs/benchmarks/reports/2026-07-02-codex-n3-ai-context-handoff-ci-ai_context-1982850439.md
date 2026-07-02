# Benchmark agent — ai_context

- Date : 2026-07-02-codex-n3-ai-context-handoff-ci
- Repo : `ai_context`
- Agent : codex exec / workspace-write / cli 0.139.0
- N : 3
- Seed : 42
- Timeout : 300s
- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-handoff-ci-results.tsv`
- Artefact JSONL : `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-handoff-ci-results.jsonl`

## Synthèse

| Condition | Succès | Total | Taux | IC 95% Wilson |
|---|---:|---:|---:|---:|
| `with` | 3 | 3 | 100.0% | [43.9% ; 100.0%] |
| `without` | 2 | 3 | 66.7% | [20.8% ; 93.9%] |

Δ succès (`with` - `without`) : **33.3 points** (IC 95% approx. Newcombe : **[-50.0 ; 79.2] points**).

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 3 | 182536 | 60845 |
| `without` | 3 | 180443 | 60148 |

## Δ tokens par classe de tâche

| Classe | with n | with moy. | without n | without moy. | Δ tokens/run | Δ tokens/run % |
|---|---:|---:|---:|---:|---:|---:|
| `handoff` | 3 | 60845 | 3 | 60148 | +698 | +1.2% |

## Détail

| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |
|---|---|---:|---|---|---:|---:|---:|---|
| `0003-handoff-decision` | `with` | 1 | PASS | `none` | 0 | 0 | 52277 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/ai_context-1982850439-0003-handoff-decision-with-1/check.log` |
| `0003-handoff-decision` | `without` | 2 | FAIL | `task_fail` | 0 | 1 | 46855 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/ai_context-1982850439-0003-handoff-decision-without-2/check.log` |
| `0003-handoff-decision` | `without` | 3 | PASS | `none` | 0 | 0 | 44757 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/ai_context-1982850439-0003-handoff-decision-without-3/check.log` |
| `0003-handoff-decision` | `with` | 2 | PASS | `none` | 0 | 0 | 87672 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/ai_context-1982850439-0003-handoff-decision-with-2/check.log` |
| `0003-handoff-decision` | `without` | 1 | PASS | `none` | 0 | 0 | 88831 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/ai_context-1982850439-0003-handoff-decision-without-1/check.log` |
| `0003-handoff-decision` | `with` | 3 | PASS | `none` | 0 | 0 | 42587 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/ai_context-1982850439-0003-handoff-decision-with-3/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `failure_kind=agent_infra_error` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark.
