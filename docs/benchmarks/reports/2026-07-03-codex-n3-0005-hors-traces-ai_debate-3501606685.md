# Benchmark agent — ai_debate

- Date : 2026-07-03-codex-n3-0005-hors-traces
- Repo : `ai_debate`
- Agent : codex exec / workspace-write / cli 0.139.0
- N : 3
- Seed : 42
- Timeout : 300s
- Résultats bruts : `docs/benchmarks/reports/2026-07-03-codex-n3-0005-hors-traces-results.tsv`
- Artefact JSONL : `docs/benchmarks/reports/2026-07-03-codex-n3-0005-hors-traces-results.jsonl`

## Synthèse

| Condition | Succès | Total | Taux | IC 95% Wilson |
|---|---:|---:|---:|---:|
| `with` | 3 | 3 | 100.0% | [43.9% ; 100.0%] |
| `without` | 0 | 3 | 0.0% | [0.0% ; 56.1%] |

Δ succès (`with` - `without`) : **100.0 points** (IC 95% approx. Newcombe : **[-12.3 ; 100.0] points**).

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 3 | 124652 | 41551 |
| `without` | 3 | 198490 | 66163 |

## Δ tokens par classe de tâche

| Classe | with n | with moy. | without n | without moy. | Δ tokens/run | Δ tokens/run % |
|---|---:|---:|---:|---:|---:|---:|
| `contextual` | 3 | 41551 | 3 | 66163 | -24613 | -37.2% |

## Détail

| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |
|---|---|---:|---|---|---:|---:|---:|---|
| `0005-resume-hors-traces` | `without` | 1 | FAIL | `task_fail` | 0 | 1 | 68231 | `docs/benchmarks/runs/2026-07-03-codex-n3-0005-hors-traces/ai_debate-3501606685-0005-resume-hors-traces-without-1/check.log` |
| `0005-resume-hors-traces` | `with` | 3 | PASS | `none` | 0 | 0 | 41088 | `docs/benchmarks/runs/2026-07-03-codex-n3-0005-hors-traces/ai_debate-3501606685-0005-resume-hors-traces-with-3/check.log` |
| `0005-resume-hors-traces` | `without` | 2 | FAIL | `task_fail` | 0 | 1 | 71186 | `docs/benchmarks/runs/2026-07-03-codex-n3-0005-hors-traces/ai_debate-3501606685-0005-resume-hors-traces-without-2/check.log` |
| `0005-resume-hors-traces` | `with` | 1 | PASS | `none` | 0 | 0 | 30083 | `docs/benchmarks/runs/2026-07-03-codex-n3-0005-hors-traces/ai_debate-3501606685-0005-resume-hors-traces-with-1/check.log` |
| `0005-resume-hors-traces` | `without` | 3 | FAIL | `task_fail` | 0 | 1 | 59073 | `docs/benchmarks/runs/2026-07-03-codex-n3-0005-hors-traces/ai_debate-3501606685-0005-resume-hors-traces-without-3/check.log` |
| `0005-resume-hors-traces` | `with` | 2 | PASS | `none` | 0 | 0 | 53481 | `docs/benchmarks/runs/2026-07-03-codex-n3-0005-hors-traces/ai_debate-3501606685-0005-resume-hors-traces-with-2/check.log` |

## Notes

- `AGENT_CMD` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner.
- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec.
- `failure_kind=agent_infra_error` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark.
- `failure_kind=task_invalid` (check exit 3) signale que la vérité terrain de la tâche est reconstructible dans la copie `without` (fuite hors mesh) : la cellule ne prouve rien et le run sort en non-zéro.
