# Synthèse benchmark — Codex N=3 0005 hors-traces

- Stamp : `2026-07-03-codex-n3-0005-hors-traces`
- Repos : `ai_context`, `ai_debate` (worktree propre détaché à `d6cdc17`)
- Agent : `codex exec / workspace-write / cli 0.139.0`
- Tâche : `0005-resume-hors-traces`
- Classe : `contextual`
- Verdict : signal positif publiable, avec réserve statistique liée à `N=3`.

## Résultat Global

| Condition | Succès | Total | Taux | IC 95% Wilson |
|---|---:|---:|---:|---:|
| `with` | 6 | 6 | 100.0% | [61.0% ; 100.0%] |
| `without` | 2 | 6 | 33.3% | [9.7% ; 70.0%] |

Δ succès (`with` - `without`) : **+66.7 points** (IC 95% approx. Newcombe :
**[-9.0 ; 90.3] points**).

## Par Repo

| Repo | `with` | `without` | Δ succès | Lecture |
|---|---:|---:|---:|---|
| `ai_context` | 3/3 | 2/3 | +33.3 pts | Partiel ; un timeout en condition `without`. |
| `ai_debate` | 3/3 | 0/3 | +100.0 pts | Signal externe fort, sans erreur infra. |

Les trois échecs `ai_debate/without` sont des `task_fail` : l'agent a répondu
avec la feature produit d'`ai_context` au lieu de la feature attendue du repo
`ai_debate`. C'est un échec métier exploitable.

## Coût Tokens

| Périmètre | `with` moy. | `without` moy. | Δ tokens/run | Δ % |
|---|---:|---:|---:|---:|
| Global mesuré | 47746 | 82171 | -34425 | -41.9% |
| `ai_context` | 53942 | 106184 | -52241 | -49.2% |
| `ai_debate` | 41551 | 66163 | -24613 | -37.2% |

La moyenne globale `without` ne compte que 5 runs mesurés, car
`ai_context/without/run 3` a timeout sans bloc tokens exploitable.

## Hygiène

- JSONL : 12 lignes.
- `agent_infra_error` : 0.
- `task_invalid` : 0.
- `task_fail` : 3, tous sur `ai_debate/without`.
- `timeout` : 1, sur `ai_context/without`.
- Artefacts : rapports par repo, TSV, JSONL et logs sous
  `docs/benchmarks/runs/2026-07-03-codex-n3-0005-hors-traces/`.

## Lecture

`0005` corrige le problème principal des probes 0002/0004 : si la vérité terrain
apparaît hors mesh en condition `without`, le run est invalidé au lieu de créer
un faux signal. Ici, `task_invalid=0`, donc aucun leak exact `step`/`resume_hint`
n'a été détecté.

Le signal est exploitable pour la décision produit, surtout côté `ai_debate`.
Il reste insuffisant comme preuve définitive : `N=3` laisse des intervalles larges
et `ai_context` passe encore 2/3 en condition `without`.
