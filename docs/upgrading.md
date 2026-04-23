# Upgrading

Quand le template évolue sur GitHub (nouvelles règles, nouveaux checks, fixes), les projets qui l'ont appliqué peuvent remonter les changements.

## Update standard

```bash
cd mon-projet
copier update
```

Copier lit `.copier-answers.yml` pour retrouver les réponses initiales. Il te montre un **diff** pour chaque fichier modifié et te demande quoi faire :

- `y` : appliquer le changement.
- `n` : ignorer.
- `d` : voir le diff en détail.

## Si tu as personnalisé un fichier généré

Copier détecte les modifications locales. Il propose un **merge à 3 voies** (template ancien / template nouveau / version locale). Tu arbitres conflit par conflit.

## Rebase "clean" (repartir d'un scaffold frais)

Si la dérive est trop grosse :

```bash
# sauvegarder tes éditions
git stash

# régénérer
copier copy --overwrite gh:qhuy/ai_context .

# réappliquer tes éditions
git stash pop
# résoudre les conflits si besoin
```

⚠️ `--overwrite` écrase les fichiers générés — sauvegarder avant.

## Épingler une version

Par défaut `copier update` remonte à la dernière version. Pour cibler un tag :

```bash
copier update --vcs-ref v0.2.0
```

## Quand NE PAS update

- Le template a un changement major (v1 → v2) non annoncé dans CHANGELOG comme "safe". Lire le CHANGELOG avant.
- Tu es en freeze avant release.
