# Benchmark agent — synthèse 2026-07-02 Codex N=3 ai_context handoff CI

## Verdict

Signal faible mais utile sur la tâche repo-spécifique `0003-handoff-decision`.

| Condition | Succès | Total | Taux | IC 95% Wilson |
|---|---:|---:|---:|---:|
| `with` | 3 | 3 | 100.0% | [43.9% ; 100.0%] |
| `without` | 2 | 3 | 66.7% | [20.8% ; 93.9%] |

Δ succès (`with` - `without`) : **+33.3 points** (IC 95% approx. Newcombe : **[-50.0 ; 79.2] points**).

## Périmètre

- Agent : `codex exec / workspace-write / cli 0.139.0`
- Repo : `ai_context` (`f08f95b`)
- Tâche : `0003-handoff-decision` (`handoff`)
- Runs : `N=3`
- Seed : `42`
- Timeout : `300s` par cellule

## Lecture

- `with` passe 3/3 : l'agent retrouve la décision attendue de handoff `product/agent-efficacy-benchmark` -> `quality/smoke-test`.
- `without` passe 2/3 : la tâche discrimine moins fortement que prévu, probablement parce que le prompt contient déjà une partie de la décision attendue.
- L'intervalle de confiance reste très large à `N=3`; ce run renforce la suite côté `ai_context`, mais ne suffit pas à lui seul comme preuve statistique.

## Coût Tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 3 | 182536 | 60845 |
| `without` | 3 | 180443 | 60148 |

| Classe | with moy. | without moy. | Δ tokens/run | Δ tokens/run % |
|---|---:|---:|---:|---:|
| `handoff` | 60845 | 60148 | +698 | +1.2% |

## Hygiène

- JSONL parsé : 6 lignes.
- `agent_infra_error` : 0.
- `task_fail` : 1, sur `0003-handoff-decision` en condition `without`.
- Scan simple des rapports/logs pour secrets bruts (`sk-*` long, `ghp_*`, `*_API_KEY`, private keys) : aucun match.

## Artefacts

- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-handoff-ci-results.tsv`
- JSONL : `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-handoff-ci-results.jsonl`
- Rapport `ai_context` : `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-handoff-ci-ai_context-1982850439.md`
- Logs : `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-handoff-ci/`
