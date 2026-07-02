# Benchmark agent — synthèse 2026-07-02 Codex N=1 portable

## Verdict

Premier calibrage réel publié : signal positif mais non statistique.

| Condition | Succès | Total | Taux |
|---|---:|---:|---:|
| `with` | 4 | 4 | 100.0% |
| `without` | 2 | 4 | 50.0% |

Δ succès (`with` - `without`) : **+50.0 points**.

## Périmètre

- Agent : `codex exec / workspace-write / portable-suite-0001-0002 / timeout-300s`
- Repos : `ai_context`, `ai_debate`
- Tâches : `0001-example-file`, `0002-feature-resume`
- Runs : `N=1`
- Seed : `42`
- Timeout : `300s` par cellule

## Lecture

- `0001-example-file` passe dans toutes les conditions : le pipeline agent/édition/grader fonctionne.
- `0002-feature-resume` passe avec ai_context sur les 2 repos et échoue sans ai_context sur les 2 repos.
- Le signal utile vient donc de la reprise feature mesh : le contexte repo-native transforme une tâche de reprise ambiguë en tâche objectivement réussie.

## Coût tokens

| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |
|---|---:|---:|---:|
| `with` | 4 | 163997 | 40999 |
| `without` | 3 | 89804 | 29935 |

Lecture prudente : une cellule `without` finit en timeout sans bloc `tokens used`, donc la comparaison tokens est partielle.

## Limites

- `N=1` : aucun intervalle de confiance, pas de significativité.
- Sous-suite portable uniquement : `0003-handoff-decision` est exclue du run externe car elle cible le smoke-test de `ai_context`.
- Coût tokens extrait depuis les logs Codex quand le bloc `tokens used` est présent ; 1 cellule timeout sans mesure exploitable.
- Ce rapport remplace un premier run contaminé supprimé : le runner a depuis été corrigé pour exclure `tests/bench/`, les anciens rapports/logs et les skills repo-locales de la condition `without`.
- Les artefacts versionnés masquent les chemins absolus locaux ; les logs restent des sorties brutes d'agent et doivent être relus avant publication externe.

## Artefacts

- Résultats bruts : `docs/benchmarks/reports/2026-07-02-codex-n1-portable-results.tsv`
- JSONL : `docs/benchmarks/reports/2026-07-02-codex-n1-portable-results.jsonl`
- Rapport `ai_context` : `docs/benchmarks/reports/2026-07-02-codex-n1-portable-ai_context-1982850439.md`
- Rapport `ai_debate` : `docs/benchmarks/reports/2026-07-02-codex-n1-portable-ai_debate-3412434117.md`
- Logs : `docs/benchmarks/runs/2026-07-02-codex-n1-portable/`
