# Synthèse benchmark — Codex N=3 ai_context next-handoff

- Stamp : `2026-07-02-codex-n3-ai-context-next-handoff`
- Repo : `ai_context`
- Agent : `codex exec / workspace-write / cli 0.139.0`
- Tâche : `0004-next-handoff`
- Classe : `handoff`
- Verdict : tâche techniquement valide, mais signal succès nul ; ne pas rerun telle quelle.

## Résultat

| Condition | Succès | Total | Taux | IC 95% Wilson |
|---|---:|---:|---:|---:|
| `with` | 2 | 3 | 66.7% | [20.8% ; 93.9%] |
| `without` | 2 | 3 | 66.7% | [20.8% ; 93.9%] |

Δ succès (`with` - `without`) : **0.0 point** (IC 95% approx. Newcombe :
**[-73.1 ; 73.1] points**).

## Coût tokens

| Condition | Runs avec mesure | Moyenne tokens/run |
|---|---:|---:|
| `with` | 2 | 49432 |
| `without` | 2 | 131940 |

Δ tokens/run `handoff` : **-82508** (**-62.5%**) avec ai_context. Cette lecture
reste secondaire : le signal de succès est nul et les deux timeouts empêchent une
comparaison propre sur toutes les cellules.

## Lecture

`0004-next-handoff` masque bien la cible et l'action dans le prompt, et le grader
dérive la vérité terrain depuis le feature mesh source. Le run réel montre pourtant
que la condition `without` reconstruit aussi la réponse sur 2 runs sur 3. La tâche
est donc conservable comme diagnostic, mais insuffisante comme preuve de valeur.

Le prochain probe `ai_context` doit utiliser une vérité terrain qui n'est pas
reconstructible depuis les traces non-mesh ou les artefacts de benchmark déjà
publiés.

## Hygiène

- JSONL : 6 lignes.
- `agent_infra_error` : 0.
- `task_fail` : 0.
- Timeouts : 2, un par condition.
- Artefacts : rapport repo, TSV, JSONL et logs sous
  `docs/benchmarks/runs/2026-07-02-codex-n3-ai-context-next-handoff/`.
