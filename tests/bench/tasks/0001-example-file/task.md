# Tâche 0001 — exemple de format (grader objectif)

> **Rôle** : démontrer le format de tâche + un grader objectif, et servir de tâche
> de fumée pour `run-bench.sh`. **Ce n'est pas** une tâche discriminante de
> benchmark — les vraies tâches viendront avec les repos de référence.

## Prompt (donné à l'agent)

Crée, à la racine du repo, un fichier `HELLO.txt` contenant exactement la ligne :

```
hello ai_context
```

## Critère de succès (humain-lisible)

`HELLO.txt` existe à la racine et son contenu est exactement `hello ai_context`
(une ligne, sans espace superflu). Le grader objectif est `check.sh`.
