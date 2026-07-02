# Benchmark agent — ai_context

- Date : 2026-07-02-codex-n3-portable-r3-tokens
- Repo : `ai_context`
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
| `without` | 5 | 6 | 83.3% |

Δ succès (`with` - `without`) : **16.7 points**.

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 6 | 293227 | 48871 |
| `without` | 6 | 388564 | 64761 |

## Δ tokens par classe de tâche

| Classe | with n | with moy. | without n | without moy. | Δ tokens/run | Δ tokens/run % |
|---|---:|---:|---:|---:|---:|---:|
| `contextual` | 3 | 65877 | 3 | 102095 | -36217 | -35.5% |
| `trivial` | 3 | 31865 | 3 | 27427 | +4438 | +16.2% |

## Détail

| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |
|---|---|---:|---|---|---:|---:|---:|---|
| `0002-feature-resume` | `without` | 1 | PASS | `none` | 0 | 0 | 115373 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0002-feature-resume-without-1/check.log` |
| `0001-example-file` | `with` | 1 | PASS | `none` | 0 | 0 | 37819 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0001-example-file-with-1/check.log` |
| `0001-example-file` | `without` | 2 | PASS | `none` | 0 | 0 | 31647 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0001-example-file-without-2/check.log` |
| `0001-example-file` | `without` | 3 | PASS | `none` | 0 | 0 | 17884 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0001-example-file-without-3/check.log` |
| `0002-feature-resume` | `with` | 3 | PASS | `none` | 0 | 0 | 30957 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0002-feature-resume-with-3/check.log` |
| `0001-example-file` | `with` | 2 | PASS | `none` | 0 | 0 | 37557 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0001-example-file-with-2/check.log` |
| `0002-feature-resume` | `without` | 2 | FAIL | `task_fail` | 0 | 1 | 58020 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0002-feature-resume-without-2/check.log` |
| `0001-example-file` | `without` | 1 | PASS | `none` | 0 | 0 | 32749 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0001-example-file-without-1/check.log` |
| `0002-feature-resume` | `with` | 1 | PASS | `none` | 0 | 0 | 91870 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0002-feature-resume-with-1/check.log` |
| `0001-example-file` | `with` | 3 | PASS | `none` | 0 | 0 | 20219 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0001-example-file-with-3/check.log` |
| `0002-feature-resume` | `without` | 3 | PASS | `none` | 0 | 0 | 132891 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0002-feature-resume-without-3/check.log` |
| `0002-feature-resume` | `with` | 2 | PASS | `none` | 0 | 0 | 74805 | `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/ai_context-1982850439-0002-feature-resume-with-2/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `failure_kind=agent_infra_error` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark.
