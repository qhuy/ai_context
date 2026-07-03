# Lecture Produit — Benchmark d'efficacité agent

- Date de préparation : 2026-07-03
- Décision visée : 2026-07-15
- Feature : `product/agent-efficacy-benchmark`
- Agent mesuré : `codex exec / workspace-write / cli 0.139.0`
- Repos de référence : `ai_context`, `ai_debate`

## Verdict Proposé

Recommandation pour le 2026-07-15 : **passer de `explore` à `commit`**, avec
réserves. Ne pas passer en `scale` public.

Le benchmark donne maintenant une preuve positive sur les tâches contextuelles :
la couche `ai_context` améliore fortement la reprise de travail depuis le mesh et
réduit le coût tokens mesuré sur ces tâches. La preuve reste maintainer-only,
sur Codex uniquement, avec `N=3` par cellule et deux repos proches de l'écosystème
du projet.

## Signal Principal

Agrégat retenu : `0002-feature-resume` + `0005-resume-hors-traces`.

Ces deux tâches mesurent le coeur de valeur : retrouver la bonne feature active et
reprendre exactement le contexte utile depuis le mesh. Elles excluent la tâche
triviale `0001` et les probes handoff `0003`/`0004`.

| Condition | Succès | Total | Taux | IC 95% Wilson |
|---|---:|---:|---:|---:|
| `with` | 12 | 12 | 100.0% | [75.8% ; 100.0%] |
| `without` | 4 | 12 | 33.3% | [13.8% ; 60.9%] |

Δ succès (`with` - `without`) : **+66.7 points** (IC 95% approx. Newcombe :
**[14.8 ; 86.2] points**).

## Par Repo

| Repo | `with` | `without` | Δ succès | Lecture |
|---|---:|---:|---:|---|
| `ai_context` | 6/6 | 4/6 | +33.3 pts | Signal partiel : le repo natif reste souvent reconstructible sans mesh. |
| `ai_debate` | 6/6 | 0/6 | +100.0 pts | Signal fort hors repo source, mais encore dans l'écosystème mainteneur. |

## Coût Tokens

Sur les tâches contextuelles agrégées :

| Condition | Runs avec mesure | Moyenne tokens/run |
|---|---:|---:|
| `with` | 12 | 53566 |
| `without` | 11 | 88752 |

Δ tokens/run : **-35186** (**-39.6%**) avec `ai_context`.

Lecture : la couche a un coût sur les tâches triviales, mais elle économise des
tokens sur les tâches où le contexte évite l'exploration. C'est le signal produit
à retenir, pas une promesse de coût universel.

## Ce Que Cela Prouve

- Sur deux tâches de reprise contextuelle, avec deux repos et `N=3`, `ai_context`
  améliore nettement le taux de succès.
- Le signal ne dépend pas uniquement du repo `ai_context` : `ai_debate` échoue 0/6
  sans couche sur les tâches contextuelles et passe 6/6 avec couche.
- Le run `0005` ajoute une garde de fuite : `task_invalid=0`, donc la vérité
  terrain exacte `step`/`resume_hint` n'a pas été retrouvée hors mesh en condition
  `without`.
- Le leading indicator tokens va dans le bon sens sur les tâches contextuelles :
  moins d'exploration, moins de tokens.

## Ce Que Cela Ne Prouve Pas

- Pas une preuve de performance sur tâches triviales : `0001` passe partout et
  coûte plus cher avec la couche.
- Pas une preuve large multi-modèles : seul Codex CLI 0.139.0 a été mesuré.
- Pas encore une preuve publique indépendante : `ai_debate` est un second repo,
  mais reste proche de l'écosystème mainteneur.
- Pas une preuve forte sur les handoffs : `0003` est faible et `0004` est nul ;
  ces probes ont surtout servi à durcir la conception de tâches.

## Décision Recommandée

Pour le 2026-07-15 :

- `decision_state: commit`
- Continuer le positionnement "valeur mesurée sur reprise contextuelle".
- Ne pas formuler un claim général du type "améliore toutes les tâches agent".
- Avant `scale` public : ajouter au moins un repo vraiment indépendant, augmenter
  `N`, et si possible rejouer avec un second agent/modèle.

## Sources

- `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-summary.md`
- `docs/benchmarks/reports/2026-07-03-codex-n3-0005-hors-traces-summary.md`
- `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-handoff-ci-summary.md`
- `docs/benchmarks/reports/2026-07-02-codex-n3-ai-context-next-handoff-summary.md`
