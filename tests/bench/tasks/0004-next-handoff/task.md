# Tâche 0004 — prochain handoff depuis le feature mesh

## Prompt (donné à l'agent)

Inspecte le repo et identifie la prochaine passation cross-scope encore ouverte
pour l'initiative produit de benchmark d'efficacité agent. Utilise les fichiers de
contexte repo-native s'ils existent ; ne déduis pas la cible depuis le nom de cette
tâche.

Crée `BENCH_RESULT/next-handoff.json` à la racine du repo avec exactement ces clés
JSON :

```json
{
  "source": "<scope/id de la feature source>",
  "target": "<scope/id de la feature cible>",
  "next": "<action exacte de passation>",
  "evidence": "<chemin relatif du fichier source>"
}
```

La valeur `next` doit reprendre l'action de passation sans reformulation. N'ajoute
aucun autre champ.

## Critère de succès (humain-lisible)

Le JSON existe, il est valide, et ses quatre valeurs correspondent exactement au
handoff restant documenté dans le feature mesh source pour l'initiative produit de
benchmark. Le grader objectif est `check.sh`.
