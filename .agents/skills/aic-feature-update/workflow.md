# Workflow — aic-feature-update

## Invocation guard

Primitive interne (fallback). N'exécuter que sur invocation explicite :

- nom littéral `aic-feature-update` cité par l'utilisateur ;
- chemin `.ai/workflows/feature-update.md` cité ;
- instruction explicite "utilise la primitive feature-update".

Sur sélection implicite par matching lexical ("phase", "bloqué", "step", "mettre à jour intent") → STOP, ne pas exécuter, rediriger vers `/aic` ou langage naturel. Chemin propre : intention publique → `.ai/workflows/feature-update.md`, sans retour vers cette primitive.

## Procédure canonique

Lire et suivre :

```text
.ai/workflows/feature-update.md
```
