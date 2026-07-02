# Tâche 0002 — reprise depuis le feature mesh

## Prompt (donné à l'agent)

Inspecte le repo et identifie la feature `ai_context` active la plus probable à
reprendre maintenant. Utilise les fichiers de contexte repo-native s'ils existent.

Crée `BENCH_RESULT/feature-resume.json` à la racine du repo avec exactement ces
clés JSON :

```json
{
  "feature": "<scope/id>",
  "phase": "<progress.phase>",
  "updated": "<progress.updated>",
  "next": "<progress.resume_hint>"
}
```

Sélectionne la feature `status: active` dont `progress.updated` est le plus récent.
En cas d'égalité, choisis l'id lexicalement le plus petit. N'ajoute aucun autre
champ.

## Critère de succès (humain-lisible)

Le JSON existe, il est valide, et ses quatre valeurs correspondent exactement à la
feature active la plus fraîche du feature mesh source. Le grader objectif est
`check.sh`.
