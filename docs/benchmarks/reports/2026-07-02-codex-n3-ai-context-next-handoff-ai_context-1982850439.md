# Benchmark agent — ai_context

- Date : 2026-07-02-codex-n3-ai-context-next-handoff
- Repo : `ai_context`
- Agent : codex exec / workspace-write / cli 0.139.0
- N : 3
- Seed : 42
- Timeout : 300s
- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-next-handoff-results.tsv`
- Artefact JSONL : `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-next-handoff-results.jsonl`

## Synthèse

| Condition | Succès | Total | Taux | IC 95% Wilson |
|---|---:|---:|---:|---:|
| `with` | 2 | 3 | 66.7% | [20.8% ; 93.9%] |
| `without` | 2 | 3 | 66.7% | [20.8% ; 93.9%] |

Δ succès (`with` - `without`) : **0.0 points** (IC 95% approx. Newcombe : **[-73.1 ; 73.1] points**).

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 2 | 98864 | 49432 |
| `without` | 2 | 263881 | 131940 |

## Δ tokens par classe de tâche

| Classe | with n | with moy. | without n | without moy. | Δ tokens/run | Δ tokens/run % |
|---|---:|---:|---:|---:|---:|---:|
| `handoff` | 2 | 49432 | 2 | 131940 | -82508 | -62.5% |

## Détail

| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |
|---|---|---:|---|---|---:|---:|---:|---|
| `0004-next-handoff` | `with` | 1 | PASS | `none` | 0 | 0 | 43756 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-next-handoff/ai_context-1982850439-0004-next-handoff-with-1/check.log` |
| `0004-next-handoff` | `without` | 2 | PASS | `none` | 0 | 0 | 123607 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-next-handoff/ai_context-1982850439-0004-next-handoff-without-2/check.log` |
| `0004-next-handoff` | `without` | 3 | PASS | `none` | 0 | 0 | 140274 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-next-handoff/ai_context-1982850439-0004-next-handoff-without-3/check.log` |
| `0004-next-handoff` | `with` | 2 | PASS | `none` | 0 | 0 | 55108 | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-next-handoff/ai_context-1982850439-0004-next-handoff-with-2/check.log` |
| `0004-next-handoff` | `without` | 1 | FAIL | `timeout` | 124 | 1 | NA | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-next-handoff/ai_context-1982850439-0004-next-handoff-without-1/check.log` |
| `0004-next-handoff` | `with` | 3 | FAIL | `timeout` | 124 | 1 | NA | `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-next-handoff/ai_context-1982850439-0004-next-handoff-with-3/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `failure_kind=agent_infra_error` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark.
