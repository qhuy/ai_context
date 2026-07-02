# Benchmark agent — ai_debate

- Date : 2026-07-02-codex-n3-portable-r3-tokens
- Repo : `ai_debate`
- Agent : codex exec / workspace-write / cli 0.139.0
- N : 3
- Seed : 42
- Timeout : 300s
- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-results.tsv`
- Artefact JSONL : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-results.jsonl`

## Synthèse

| Condition | Succès | Total | Taux |
|---|---:|---:|---:|
| `with` | 6 | 6 | 100.0% |
| `without` | 3 | 6 | 50.0% |

Δ succès (`with` - `without`) : **50.0 points**.

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 6 | 266213 | 44369 |
| `without` | 6 | 314393 | 52399 |

## Δ tokens par classe de tâche

| Classe | with n | with moy. | without n | without moy. | Δ tokens/run | Δ tokens/run % |
|---|---:|---:|---:|---:|---:|---:|
| `contextual` | 3 | 52896 | 3 | 86375 | -33480 | -38.8% |
| `trivial` | 3 | 35842 | 3 | 18422 | +17420 | +94.6% |

## Détail

| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |
|---|---|---:|---|---|---:|---:|---:|---|
| `0001-example-file` | `without` | 2 | PASS | `none` | 0 | 0 | 28537 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0001-example-file-without-2/check.log` |
| `0001-example-file` | `with` | 3 | PASS | `none` | 0 | 0 | 37056 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0001-example-file-with-3/check.log` |
| `0001-example-file` | `with` | 2 | PASS | `none` | 0 | 0 | 19927 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0001-example-file-with-2/check.log` |
| `0002-feature-resume` | `without` | 1 | FAIL | `task_fail` | 0 | 1 | 119026 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0002-feature-resume-without-1/check.log` |
| `0001-example-file` | `with` | 1 | PASS | `none` | 0 | 0 | 50543 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0001-example-file-with-1/check.log` |
| `0002-feature-resume` | `without` | 2 | FAIL | `task_fail` | 0 | 1 | 58489 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0002-feature-resume-without-2/check.log` |
| `0002-feature-resume` | `without` | 3 | FAIL | `task_fail` | 0 | 1 | 81611 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0002-feature-resume-without-3/check.log` |
| `0001-example-file` | `without` | 3 | PASS | `none` | 0 | 0 | 16546 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0001-example-file-without-3/check.log` |
| `0002-feature-resume` | `with` | 1 | PASS | `none` | 0 | 0 | 45905 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0002-feature-resume-with-1/check.log` |
| `0002-feature-resume` | `with` | 2 | PASS | `none` | 0 | 0 | 45907 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0002-feature-resume-with-2/check.log` |
| `0001-example-file` | `without` | 1 | PASS | `none` | 0 | 0 | 10184 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0001-example-file-without-1/check.log` |
| `0002-feature-resume` | `with` | 3 | PASS | `none` | 0 | 0 | 66875 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_debate-1480666810-0002-feature-resume-with-3/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `failure_kind=agent_infra_error` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark.
