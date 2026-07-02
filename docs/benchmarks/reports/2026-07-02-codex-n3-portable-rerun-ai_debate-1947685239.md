# Benchmark agent — ai_debate

- Date : 2026-07-02-codex-n3-portable-rerun
- Repo : `ai_debate`
- Agent : codex exec / workspace-write
- N : 3
- Seed : 42
- Timeout : 300s
- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-rerun-results.tsv`
- Artefact JSONL : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-rerun-results.jsonl`

## Synthèse

| Condition | Succès | Total | Taux |
|---|---:|---:|---:|
| `with` | 6 | 6 | 100.0% |
| `without` | 3 | 6 | 50.0% |

Δ succès (`with` - `without`) : **50.0 points**.

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 6 | 222880 | 37147 |
| `without` | 6 | 326173 | 54362 |

## Détail

| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |
|---|---|---:|---|---|---:|---:|---:|---|
| `0001-example-file` | `without` | 2 | PASS | `none` | 0 | 0 | 33821 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0001-example-file-without-2/check.log` |
| `0001-example-file` | `with` | 3 | PASS | `none` | 0 | 0 | 36455 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0001-example-file-with-3/check.log` |
| `0001-example-file` | `with` | 2 | PASS | `none` | 0 | 0 | 15815 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0001-example-file-with-2/check.log` |
| `0002-feature-resume` | `without` | 1 | FAIL | `task_fail` | 0 | 1 | 66714 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0002-feature-resume-without-1/check.log` |
| `0001-example-file` | `with` | 1 | PASS | `none` | 0 | 0 | 20474 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0001-example-file-with-1/check.log` |
| `0002-feature-resume` | `without` | 2 | FAIL | `task_fail` | 0 | 1 | 82584 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0002-feature-resume-without-2/check.log` |
| `0002-feature-resume` | `without` | 3 | FAIL | `task_fail` | 0 | 1 | 79487 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0002-feature-resume-without-3/check.log` |
| `0001-example-file` | `without` | 3 | PASS | `none` | 0 | 0 | 30832 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0001-example-file-without-3/check.log` |
| `0002-feature-resume` | `with` | 1 | PASS | `none` | 0 | 0 | 57713 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0002-feature-resume-with-1/check.log` |
| `0002-feature-resume` | `with` | 2 | PASS | `none` | 0 | 0 | 46476 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0002-feature-resume-with-2/check.log` |
| `0001-example-file` | `without` | 1 | PASS | `none` | 0 | 0 | 32735 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0001-example-file-without-1/check.log` |
| `0002-feature-resume` | `with` | 3 | PASS | `none` | 0 | 0 | 45947 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_debate-1947685239-0002-feature-resume-with-3/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `failure_kind=agent_infra_error` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark.
