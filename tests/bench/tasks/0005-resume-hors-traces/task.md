# Tâche 0005 — reprise à vérité terrain hors traces

## Prompt (donné à l'agent)

Inspecte le repo et identifie la feature `ai_context` active la plus probable à
reprendre maintenant. Utilise les fichiers de contexte repo-native s'ils existent.

Crée `BENCH_RESULT/resume-context.json` à la racine du repo avec exactement ces
clés JSON :

```json
{
  "feature": "<scope/id>",
  "step": "<progress.step>",
  "next": "<progress.resume_hint>"
}
```

Sélectionne la feature `status: active` dont `progress.updated` est le plus récent
et dont `progress.step` et `progress.resume_hint` sont non vides. En cas d'égalité,
choisis le scope/id lexicalement le plus petit. Reprends `step` et `next` sans
reformulation. N'ajoute aucun autre champ.

## Critère de succès (humain-lisible)

Le JSON existe, il est valide, et ses trois valeurs correspondent exactement à la
feature active la plus fraîche (avec `step` et `resume_hint` non vides) du feature
mesh source. Le grader objectif est `check.sh`.

## Garde de validité (spécifique à cette tâche)

En condition `without`, le grader vérifie d'abord que la vérité terrain (`step` et
`resume_hint` exacts) n'est **pas** reconstructible depuis la copie de travail
dépouillée : si l'un des deux textes apparaît hors mesh (docs, état projet, traces
quelconques), le grader sort en exit 3 (`failure_kind=task_invalid`) et le run est
invalidé comme preuve — la cellule ne compte ni comme succès ni comme échec d'agent.
C'est la réponse au constat des probes 0002/0004 : sans cette garde, un Δ nul peut
venir d'une fuite d'information, pas d'une capacité de l'agent.
