# Project Overlay

Ce fichier est un exemple. Ne le déplace pas automatiquement : `.ai/project/**` doit rester créé et maintenu par le projet consommateur.

## Entrée projet

Créer `.ai/project/index.md` seulement si le projet a des règles locales à charger.

Exemple minimal :

```md
# Project Overlay

Règles locales du projet. Charger seulement les fichiers listés ici quand ils sont utiles à la tâche.

## Toujours utile après routage

- `.ai/project/domain.md` pour vocabulaire métier durable.

## Selon les chemins touchés

- `src/payments/**` -> `.ai/project/payments.md`
- `infra/**` -> `.ai/project/deployment.md`
```

## Règles de chargement

- `.ai/project/index.md` est la seule entrée projet.
- `.ai/project/**` est project-owned : `copier update` ne doit ni supprimer ni écraser ce dossier.
- Les agents ne doivent pas précharger récursivement `.ai/project/**`.
- `index.md` décide quoi charger selon l'intention, les chemins touchés et le scope primaire.

## Migration

Si des règles locales vivent dans un ancien fichier template, par exemple `.ai/rules/<scope>.md` ou un fichier legacy de type `.ai/workflow/L1_*`, déplacer la partie spécifique au projet vers `.ai/project/**`.

Garder dans le fichier upstream-managed uniquement :

- les règles génériques utiles à tous les repos ;
- un pointeur court vers `.ai/project/index.md` si nécessaire ;
- aucune copie longue de contexte métier.
