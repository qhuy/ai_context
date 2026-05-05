# Upgrading

Quand le template évolue sur GitHub (nouvelles règles, nouveaux checks, fixes), les projets qui l'ont appliqué peuvent remonter les changements.

## Update standard

```bash
cd mon-projet
copier update --vcs-ref=HEAD
```

Copier lit `.copier-answers.yml` pour retrouver les réponses initiales. Il te montre un **diff** pour chaque fichier modifié et te demande quoi faire :

- `y` : appliquer le changement.
- `n` : ignorer.
- `d` : voir le diff en détail.

Pourquoi `--vcs-ref=HEAD` : Copier cible souvent le dernier tag publié par défaut. Si `main` contient une version plus récente que le dernier tag, `copier update` seul peut proposer une mise à jour vers une version plus ancienne que le HEAD GitHub.

## Prévisualiser sans toucher au repo

Sur un worktree sale, `copier update` refuse de démarrer. C'est sain pour éviter les merges implicites, mais pénible pour estimer l'effort. Utilise plutôt :

```bash
bash .ai/scripts/ai-context.sh template-diff
```

La commande rend le template dans `/tmp`, liste les fichiers template à ajouter ou modifier, et ne modifie pas le projet courant. Tu peux cibler une source ou une ref précise :

```bash
bash .ai/scripts/ai-context.sh template-diff --src-path gh:qhuy/ai_context --vcs-ref HEAD
```

## Réparer `.copier-answers.yml`

Si le projet a été scaffoldé sans `.copier-answers.yml`, Copier ne connaît plus `_src_path` ni `_commit`, donc `copier update` ne peut pas fonctionner proprement.

Preview :

```bash
bash .ai/scripts/ai-context.sh repair-copier-metadata
```

Écriture explicite :

```bash
bash .ai/scripts/ai-context.sh repair-copier-metadata --apply
```

Si le projet vient d'une source ou d'un tag précis :

```bash
bash .ai/scripts/ai-context.sh repair-copier-metadata --src-path gh:qhuy/ai_context --commit v0.11.0 --apply
```

La commande infère `project_name`, `docs_root`, le profil de scopes, les agents et le mode d'adoption depuis les fichiers présents. Relis le YAML proposé avant `--apply` si le projet a été fortement customisé.

## Si tu as personnalisé un fichier généré

Copier détecte les modifications locales. Il propose un **merge à 3 voies** (template ancien / template nouveau / version locale). Tu arbitres conflit par conflit.

## Overlay projet stable

Les règles locales propres au repo doivent vivre sous `.ai/project/**`. Ce dossier est project-owned : le template ne le scaffold pas par défaut et `copier update` ne doit ni le supprimer ni l'écraser.

Entrée unique :

```text
.ai/project/index.md
```

L'index principal lit `.ai/project/index.md` seulement s'il existe. Ne pas charger récursivement `.ai/project/**` ; l'index projet décide quels fichiers locaux lire selon la tâche.

Migration recommandée :

- créer `.ai/project/index.md` si le repo a des règles locales ;
- déplacer les règles métier depuis d'anciens fichiers gérés par le template, par exemple `.ai/rules/<scope>.md` ou `.ai/workflow/L1_*`, vers `.ai/project/**` ;
- laisser dans les fichiers upstream-managed uniquement les règles génériques et, si nécessaire, un pointeur court vers l'overlay.

Voir aussi `.ai/OWNERSHIP.md` dans les repos générés.

## Migration vers le contexte lean Codex

Pour les projets existants, accepter en priorité les mises à jour de :

- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`
- `.ai/index.md`
- `.ai/context-ignore.md`
- `.ai/rules/core.md`, `.ai/rules/workflow.md`, `.ai/rules/quality.md`
- `.ai/scripts/check-shims.sh`
- `.ai/scripts/check-feature-docs.sh`

Après update, vérifier que Pack A ne charge plus au démarrage :

- `.ai/quality/QUALITY_GATE.md`
- `.ai/agent/*`
- catalogues docs, références, worklogs, changelogs, skills Claude
- listings récursifs, caches générés, full diffs

Les anciens fichiers locaux ou legacy restent possibles, mais doivent devenir des
pointeurs concis chargés seulement si leurs globs matchent les fichiers touchés.
La quality gate reste bloquante avant DONE ; elle est simplement déplacée du
démarrage vers la sortie de tâche.

Check recommandé :

```bash
bash .ai/scripts/check-shims.sh
bash .ai/scripts/measure-context-size.sh
bash .ai/scripts/check-feature-docs.sh
```

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

Pour cibler un tag au lieu de `HEAD` :

```bash
copier update --vcs-ref v0.2.0
```

## Quand NE PAS update

- Le template a un changement major (v1 → v2) non annoncé dans CHANGELOG comme "safe". Lire le CHANGELOG avant.
- Tu es en freeze avant release.
