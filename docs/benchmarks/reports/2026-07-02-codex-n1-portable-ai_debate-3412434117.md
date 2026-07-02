# Benchmark agent — ai_debate

- Date : 2026-07-02-codex-n1-portable
- Repo : `ai_debate`
- Agent : codex exec / workspace-write
- N : 1
- Seed : 42
- Timeout : 300s
- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n1-portable-results.tsv`
- Artefact JSONL : `docs/benchmarks/reports/2026-07-02-codex-n1-portable-results.jsonl`

## Synthèse

| Condition | Succès | Total | Taux |
|---|---:|---:|---:|
| `with` | 2 | 2 | 100.0% |
| `without` | 1 | 2 | 50.0% |

Δ succès (`with` - `without`) : **50.0 points**.

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 2 | 81030 | 40515 |
| `without` | 2 | 77815 | 38908 |

## Détail

| Tâche | Condition | Run | Résultat | Agent | Check | Tokens | Logs |
|---|---|---:|---|---:|---:|---:|---|
| `0001-example-file` | `with` | 1 | PASS | 0 | 0 | 45157 | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_debate-3412434117-0001-example-file-with-1/check.log` |
| `0001-example-file` | `without` | 1 | PASS | 0 | 0 | 17320 | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_debate-3412434117-0001-example-file-without-1/check.log` |
| `0002-feature-resume` | `with` | 1 | PASS | 0 | 0 | 35873 | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_debate-3412434117-0002-feature-resume-with-1/check.log` |
| `0002-feature-resume` | `without` | 1 | FAIL | 0 | 1 | 60495 | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_debate-3412434117-0002-feature-resume-without-1/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `tokens_used` est extrait des logs Codex quand le bloc `tokens used` est présent ; `NA` signifie qu'aucune mesure exploitable n'a été trouvée.
