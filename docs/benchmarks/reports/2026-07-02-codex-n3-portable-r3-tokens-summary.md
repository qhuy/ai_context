# Benchmark agent — synthèse 2026-07-02 Codex N=3 portable R3 tokens

## Verdict

Signal positif confirmé, avec rapport tokens désormais lisible par classe de tâche.

| Condition | Succès | Total | Taux |
|---|---:|---:|---:|
| `with` | 12 | 12 | 100.0% |
| `without` | 8 | 12 | 66.7% |

Δ succès (`with` - `without`) : **+33.3 points**.

## Périmètre

- Agent : `codex exec / workspace-write / cli 0.139.0`
- Repos : `ai_context` (`789fd76`), `ai_debate` (`d6cdc17`)
- Source `ai_debate` : worktree propre temporaire à `HEAD`, pour éviter l'état local sale/ahead du repo de travail
- Tâches : `0001-example-file` (`trivial`), `0002-feature-resume` (`contextual`)
- Runs : `N=3`
- Seed : `42`
- Timeout : `300s` par cellule

## Lecture Succès

- `0001-example-file` passe dans toutes les conditions : le pipeline agent/édition/grader reste stable.
- `ai_debate/0002-feature-resume` réplique le signal externe : `with` 3/3, `without` 0/3.
- `ai_context/0002-feature-resume` devient partiellement discriminant sur ce run : `with` 3/3, `without` 2/3.
- Les quatre échecs sont des `task_fail` avec `agent_exit=0` ; aucune erreur quota/provider/auth n'a contaminé la preuve.

## Coût Tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 12 | 559440 | 46620 |
| `without` | 12 | 702957 | 58580 |

Lecture prudente : les coûts dépendent du runner Codex et des logs bruts ; ils sont utiles pour comparer cette matrice, pas comme coût absolu durable.

## Δ Tokens Par Classe

| Classe | with moy. | without moy. | Δ tokens/run | Δ tokens/run % |
|---|---:|---:|---:|---:|
| `contextual` | 59386 | 94235 | -34848 | -37.0% |
| `trivial` | 33854 | 22924 | +10929 | +47.7% |

Lecture : le delta global masquerait deux réalités opposées. La couche coûte plus cher sur la tâche triviale, mais économise fortement sur la reprise contextuelle.

## Hygiène

- JSONL parsé : 24 lignes.
- `agent_infra_error` : 0.
- `task_fail` : 4, tous sur `0002-feature-resume` en condition `without`.
- Scan simple des rapports/logs pour secrets bruts (`sk-*`, `ghp_*`, `*_API_KEY`, private keys) : aucun match.

## Artefacts

- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-results.tsv`
- JSONL : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-results.jsonl`
- Rapport `ai_context` : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-ai_context-1982850439.md`
- Rapport `ai_debate` : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-ai_debate-1480666810.md`
- Logs : `docs/benchmarks/runs/2026-07-02-codex-n3-portable-r3-tokens/`
