# Benchmark agent — ai_context

- Date : 2026-07-02-codex-n1-portable
- Repo : `ai_context`
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
| `with` | 2 | 82967 | 41484 |
| `without` | 1 | 11989 | 11989 |

## Détail

| Tâche | Condition | Run | Résultat | Agent | Check | Tokens | Logs |
|---|---|---:|---|---:|---:|---:|---|
| `0001-example-file` | `with` | 1 | PASS | 0 | 0 | 46684 | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_context-1982850439-0001-example-file-with-1/check.log` |
| `0001-example-file` | `without` | 1 | PASS | 0 | 0 | 11989 | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_context-1982850439-0001-example-file-without-1/check.log` |
| `0002-feature-resume` | `without` | 1 | FAIL | 124 | 1 | NA | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_context-1982850439-0002-feature-resume-without-1/check.log` |
| `0002-feature-resume` | `with` | 1 | PASS | 0 | 0 | 36283 | `docs/benchmarks/runs/2026-07-02-codex-n1-portable/ai_context-1982850439-0002-feature-resume-with-1/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `tokens_used` est extrait des logs Codex quand le bloc `tokens used` est présent ; `NA` signifie qu'aucune mesure exploitable n'a été trouvée.
