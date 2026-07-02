# Benchmark agent — ai_context

- Date : 2026-07-02-codex-n3-portable-rerun
- Repo : `ai_context`
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
| `without` | 6 | 6 | 100.0% |

Δ succès (`with` - `without`) : **0.0 points**.

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 6 | 247229 | 41205 |
| `without` | 6 | 371459 | 61910 |

## Détail

| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |
|---|---|---:|---|---|---:|---:|---:|---|
| `0002-feature-resume` | `without` | 1 | PASS | `none` | 0 | 0 | 125450 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0002-feature-resume-without-1/check.log` |
| `0001-example-file` | `with` | 1 | PASS | `none` | 0 | 0 | 38321 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0001-example-file-with-1/check.log` |
| `0001-example-file` | `without` | 2 | PASS | `none` | 0 | 0 | 32360 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0001-example-file-without-2/check.log` |
| `0001-example-file` | `without` | 3 | PASS | `none` | 0 | 0 | 14923 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0001-example-file-without-3/check.log` |
| `0002-feature-resume` | `with` | 3 | PASS | `none` | 0 | 0 | 46050 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0002-feature-resume-with-3/check.log` |
| `0001-example-file` | `with` | 2 | PASS | `none` | 0 | 0 | 40377 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0001-example-file-with-2/check.log` |
| `0002-feature-resume` | `without` | 2 | PASS | `none` | 0 | 0 | 97300 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0002-feature-resume-without-2/check.log` |
| `0001-example-file` | `without` | 1 | PASS | `none` | 0 | 0 | 16082 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0001-example-file-without-1/check.log` |
| `0002-feature-resume` | `with` | 1 | PASS | `none` | 0 | 0 | 44599 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0002-feature-resume-with-1/check.log` |
| `0001-example-file` | `with` | 3 | PASS | `none` | 0 | 0 | 21946 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0001-example-file-with-3/check.log` |
| `0002-feature-resume` | `without` | 3 | PASS | `none` | 0 | 0 | 85344 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0002-feature-resume-without-3/check.log` |
| `0002-feature-resume` | `with` | 2 | PASS | `none` | 0 | 0 | 55936 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/ai_context-1982850439-0002-feature-resume-with-2/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `failure_kind=agent_infra_error` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark.
