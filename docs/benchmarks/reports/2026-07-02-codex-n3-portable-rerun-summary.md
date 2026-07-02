# Benchmark agent — synthèse 2026-07-02 Codex N=3 portable

## Verdict

Signal positif confirmé sur repo externe, mais suite encore trop facile sur le repo porteur.

| Condition | Succès | Total | Taux |
|---|---:|---:|---:|
| `with` | 12 | 12 | 100.0% |
| `without` | 9 | 12 | 75.0% |

Δ succès (`with` - `without`) : **+25.0 points**.

## Périmètre

- Agent : `codex exec / workspace-write / portable-suite-0001-0002 / timeout-300s`
- Repos : `ai_context`, `ai_debate`
- Source `ai_debate` : worktree propre à `HEAD`, pour éviter l'état local sale/ahead du repo de travail
- Tâches : `0001-example-file`, `0002-feature-resume`
- Runs : `N=3`
- Seed : `42`
- Timeout : `300s` par cellule

## Lecture

- `0001-example-file` passe dans toutes les conditions : le pipeline agent/édition/grader est stable.
- `ai_debate/0002-feature-resume` est discriminant : `with` 3/3, `without` 0/3.
- `ai_context/0002-feature-resume` ne discrimine pas sur ce run : `with` 3/3, `without` 3/3.
- Le signal exploitable vient donc du repo externe : l'overlay aide l'agent à reprendre la bonne feature sur un projet distinct, mais la suite doit être renforcée pour mesurer `ai_context` sur lui-même.

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 12 | 470109 | 39176 |
| `without` | 12 | 697632 | 58136 |

Lecture prudente : les coûts dépendent du runner Codex et des logs bruts ; ils sont utiles pour comparer cette matrice, pas comme coût absolu durable.

## Hygiène

- Le runner a d'abord classé à tort une cellule `agent_infra_error` parce que le stderr contenait du texte de repo mentionnant du `rate limiting`, malgré `agent_exit=0`.
- Le classifieur a été corrigé : `agent_infra_error` requiert désormais une commande agent sortie non-zéro.
- Après correction, le TSV/JSONL/rapport ne contiennent aucun `agent_infra_error`; les trois échecs `without` restants sont des `task_fail`.

## Artefacts

- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-rerun-results.tsv`
- JSONL : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-rerun-results.jsonl`
- Rapport `ai_context` : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-rerun-ai_context-1982850439.md`
- Rapport `ai_debate` : `docs/benchmarks/reports/2026-07-02-codex-n3-portable-rerun-ai_debate-1947685239.md`
- Logs : `docs/benchmarks/runs/2026-07-02-codex-n3-portable-rerun/`
