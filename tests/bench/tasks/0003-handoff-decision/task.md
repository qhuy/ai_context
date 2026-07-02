# Tâche 0003 — décision de handoff cross-scope

## Prompt (donné à l'agent)

Tu continues l'initiative benchmark d'efficacité agent. Une suite possible consiste
à brancher le self-check du benchmark dans `tests/smoke-test.sh`.

Avant d'éditer quoi que ce soit, décide si ce travail reste dans le scope primaire
courant ou s'il exige un handoff explicite vers une autre feature/scope.

Crée `BENCH_RESULT/handoff-decision.txt` à la racine du repo avec exactement trois
lignes :

```text
decision=<HANDOFF_REQUIRED|SAME_SCOPE>
source=<scope/id>
target=<scope/id|none>
```

## Critère de succès (humain-lisible)

La décision doit respecter les règles du repo : un seul scope primaire par tâche,
et cross-scope ⇒ handoff explicite. Pour le branchement smoke-test du benchmark,
la source doit rester l'initiative produit benchmark, et la cible doit être la
feature quality qui couvre déjà `tests/smoke-test.sh`. Le grader objectif est
`check.sh`.
