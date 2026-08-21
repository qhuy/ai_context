# Upgrading

Quand le template évolue sur GitHub (nouvelles règles, nouveaux checks, fixes), les projets qui l'ont appliqué peuvent remonter les changements.

## Update standard

Avant l'update, le projet doit être versionné par Git, propre, et contenir un
`.copier-answers.yml` valide. Les scaffolds historiques, notamment ceux créés en
v0.13 ou avant, peuvent ne pas avoir matérialisé ce fichier : suis d'abord
[Réparer `.copier-answers.yml`](#réparer-copier-answersyml), relis le résultat,
puis committe cette métadonnée avant de continuer.

```bash
cd mon-projet
copier update --conflict=rej
```

Une mise à jour qui part de v0.13 ou d'une version antérieure traverse la
migration native v0.14.0. Autorise cette migration de diagnostic, qui exécute
uniquement `aic migrate plan` en lecture seule :

```bash
copier update --trust --conflict=rej
```

En CI ou dans tout environnement non interactif, ajoute aussi `--defaults` :

```bash
copier update --trust --defaults --conflict=rej
```

Copier lit `.copier-answers.yml` pour retrouver les réponses initiales, cible
par défaut le dernier tag publié, puis fusionne le rendu historique, le nouveau
rendu et les modifications locales. Il peut poser les nouvelles questions du
template en mode interactif ; `--defaults` conserve les réponses connues et
utilise les valeurs par défaut pour les nouvelles.

Depuis la reprise d'une cadence de tags réguliers (voir `RELEASE.md`), le dernier tag reflète l'état courant du template : `copier update` sans `--vcs-ref` est la recommandation par défaut.

`--vcs-ref=HEAD` reste disponible pour suivre `main` sans attendre le prochain tag, mais expose au risque inverse : si le dernier tag prend du retard sur `main` (ce qui s'est déjà produit), il peut appliquer des changements pas encore stabilisés en release. À utiliser en connaissance de cause, pas par défaut.

Pourquoi `--conflict=rej` : Copier met à jour le fichier sans y insérer de
marqueurs `<<<<<<<` et place chaque différence non résolue dans un fichier
`.rej` séparé. Réapplique manuellement ces différences dans le fichier mis à
jour, puis supprime tous les `.rej` avant commit. Ce comportement correspond à
la [procédure officielle Copier](https://copier.readthedocs.io/en/stable/updating/).

## Profil OKF — backfill du champ `type`

Depuis le profil strict OKF (`core/okf-strict-profile`), les fiches feature portent un champ `type` (`feature | contract | workflow | reference`). Il est **optionnel** dans un premier temps : après `copier update`, `check-features.sh` se contente d'avertir si une fiche n'a pas de `type` — la CI ne casse pas.

Aligner les fiches existantes (non destructif, idempotent) :

```bash
bash .ai/scripts/aic.sh migrate okf-type            # dry-run : liste les fiches sans type
bash .ai/scripts/aic.sh migrate okf-type --apply    # ajoute `type: feature` là où il manque
```

`type` deviendra **requis** dans une version ultérieure (`check-features` échouera alors si absent). Rollback : `git revert` du commit de backfill (les fiches t'appartiennent). Commande identique sous Claude et Codex.

## Profil OKF — index Markdown progressifs

`copier update` apporte le générateur et le contrôle de fraîcheur, mais ne touche
pas aux index project-owned. Cette séparation évite toute réécriture silencieuse
de `<docs_root>/features/**`.

```bash
bash .ai/scripts/aic.sh migrate okf-indexes            # dry-run
bash .ai/scripts/aic.sh migrate okf-indexes --apply    # écrit les index gérés
```

Les fichiers générés portent un marqueur, utilisent des liens relatifs et ne
contiennent aucun timestamp : une seconde exécution sur un mesh inchangé produit
zéro diff. Un `index.md` manuel sans marqueur provoque un conflit explicite et
n'est jamais écrasé.

La version d'introduction reste non cassante : `check-features.sh --no-write`
signale les index absents ou périmés en warning. Pour tester dès maintenant le
futur enforcement :

```bash
bash .ai/scripts/check-feature-indexes.sh --strict
```

Après `--apply`, relis puis committe `<docs_root>/features/index.md` et les index
des scopes non vides. Rollback : `git revert` de ce commit ; aucun rollback Copier
n'est requis pour retirer uniquement la projection Markdown.

## Prévisualiser sans toucher au repo

Sur un worktree sale, `copier update` refuse de démarrer. C'est sain pour éviter les merges implicites, mais pénible pour estimer l'effort. Utilise plutôt :

```bash
bash .ai/scripts/aic.sh template-diff
```

La commande rend le template dans `/tmp`, liste les fichiers template à ajouter ou modifier, et ne modifie pas le projet courant. Tu peux cibler une source ou une ref précise :

```bash
bash .ai/scripts/aic.sh template-diff --src-path gh:qhuy/ai_context --vcs-ref HEAD
```

## Réparer `.copier-answers.yml`

Si le projet a été scaffoldé sans `.copier-answers.yml`, Copier ne connaît plus `_src_path` ni `_commit`, donc `copier update` ne peut pas fonctionner proprement.

Preview :

```bash
bash .ai/scripts/aic.sh repair-copier-metadata
```

Écriture explicite :

```bash
bash .ai/scripts/aic.sh repair-copier-metadata --apply
```

Relis ensuite `.copier-answers.yml`, ajoute-le au dépôt et committe-le :
`copier update` exige un sous-projet Git propre avant de démarrer.

Si le projet vient d'une source ou d'un tag précis :

```bash
bash .ai/scripts/aic.sh repair-copier-metadata --src-path gh:qhuy/ai_context --commit v0.11.0 --apply
```

La commande infère `project_name`, `docs_root`, le profil de scopes, les agents et le mode d'adoption depuis les fichiers présents. Relis le YAML proposé avant `--apply` si le projet a été fortement customisé.

## Si tu as personnalisé un fichier généré

Copier effectue un **merge à 3 voies** (template ancien / template nouveau /
version locale). Avec `--conflict=rej`, il applique le nouveau rendu et écrit
les différences qu'il n'a pas pu fusionner dans les fichiers `.rej`
correspondants. Réapplique-les manuellement dans les fichiers mis à jour, puis
supprime les `.rej` ; il n'y a pas d'arbitrage inline.

## Migration vers les checks read-only

Les diagnostics et rapports récents ne doivent plus modifier le repo par défaut.
Après update, accepte en priorité les changements sur :

- `.ai/scripts/build-feature-index.sh`
- `.ai/scripts/check-features.sh`
- `.ai/scripts/check-feature-freshness.sh`
- `.ai/scripts/check-feature-coverage.sh`
- `.ai/scripts/review-delta.sh`
- `.ai/scripts/pr-report.sh`
- `.ai/scripts/doctor.sh`
- `.ai/scripts/check-product-links.sh`
- `.ai/scripts/product-status.sh`
- `.ai/scripts/product-portfolio.sh`
- `.ai/scripts/product-review.sh`
- `.ai/workflows/quality-gate.md`
- `.github/workflows/ai-context-check.yml`

Nouveau contrat :

- `check-features.sh --no-write` valide le mesh sans écrire `.ai/.feature-index.json`.
- `doctor`, `quality-gate`, `review-delta`, `pr-report`, `check-feature-freshness`, `check-feature-coverage` et les rapports product utilisent un index temporaire.
- `check-features.sh` sans option garde provisoirement le comportement historique et peut rafraîchir le cache.
- Un rebuild de cache reste explicite :

```bash
bash .ai/scripts/build-feature-index.sh --write
# ou
bash .ai/scripts/aic.sh index --write
```

À faire dans les projets existants :

- remplacer les gates CI/custom par `bash .ai/scripts/check-features.sh --no-write` quand elles ne doivent pas modifier le workspace ;
- garder `build-feature-index.sh --write` seulement dans les hooks ou scripts qui ont explicitement besoin d'un cache local ;
- ne pas dépendre du `mtime` de `.ai/.feature-index.json` : `--write` ne réécrit plus le fichier si le contrat JSON est inchangé hors `generated_at`.

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

## Overlay projet : registre de scopes (`aic-onboard`)

À partir de cette version, `.ai/project/**` peut être structuré en **registre de scopes** : un dossier `.ai/project/<scope>/` par app/couche/préoccupation (`bo-front`, `bo-back`, `sql`, `infra`…), chacun avec un `index.md` privé (routeur + manifeste). Le contrat de forme est documenté dans `.ai/templates/project-overlay/README.md`. Le skill `aic-onboard` peuple et maintient cette structure.

### Migration en deux temps

`copier update` ne peut pas migrer `.ai/project/**` : ce dossier est project-owned (`_skip_if_exists`). La migration est donc **séparée et opt-in** :

1. **`copier update`** apporte le skill `aic-onboard`, le contrat de forme et cet upgrade — sans toucher à ton overlay existant.
2. **Lancer `aic-onboard`** (Claude ou Codex) qui détecte l'état de `.ai/project/` et choisit le mode :
   - `init` : pas d'overlay → détecte les scopes, interroge les conventions, scaffolde.
   - `sync` : overlay déjà au format registre → enrichit/affûte par scope.
   - `migrate` : overlay ancien (plat `.ai/project/<x>.md`, `config.yml` seul, ou règles legacy) → réorganise vers le registre.

### Garde-fous

- **Non bloquant** : un overlay plat ou absent continue de fonctionner. Migre quand tu veux.
- **Non destructif** : `migrate` relocalise le contenu curé (il ne le régénère pas), propose un diff et reste réversible par git.
- **Idempotent** : le stamp `overlay_contract_version` (front-matter de `.ai/project/index.md`) rend une seconde exécution sans effet.
- **État volatile** (sprint courant, environnement actif) : jamais figé en prose — dérivé à la demande ou posé comme valeur unique dans `.ai/project/config.yml`.

## Migration vers le contexte lean Codex

Pour les projets existants, accepter en priorité les mises à jour de :

- `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`
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

### Shims agents et AGENTS.md auto-suffisant

Les shims deviennent plus stricts et moins dupliqués :

- `AGENTS.md` reste toujours présent et porte les hard rules minimales inline.
- `CLAUDE.md` peut importer `@AGENTS.md` ; le shim Copilot est devenu opt-in (`enable_copilot_shim`, défaut false). Le coding agent et Copilot Code Review lisent `AGENTS.md` nativement ; GitHub a annoncé ce support pour Code Review le 2026-06-18 ([GitHub Changelog](https://github.blog/changelog/2026-06-18-copilot-code-review-agents-md-support-and-ui-improvements/)).
- `check-shims.sh` lit `agents` dans `.copier-answers.yml` quand ce fichier existe, et consulte le registre `.ai/native-context-support.tsv` : un shim dédié absent est accepté si l'agent y est `confirmed` (copilot, cursor) ; sinon (`pending` — claude) il doit exister et rester lean. Un shim présent est toujours validé.
- Sans `.copier-answers.yml`, le check garde un fallback compatible avec les anciens scaffolds et valide les shims présents.
- `copier update` ne supprime pas automatiquement les fichiers retirés du template. Après l'élagage, `.cursor/rules/protocol-reminder.mdc` et `.github/copilot-instructions.md` peuvent donc rester dans un projet ancien comme fichiers utilisateur. Supprime-les manuellement si tu veux adopter le modèle lean ; garde `enable_copilot_shim=true` seulement si tu veux conserver un canal de consignes spécifiques à Copilot en complément d'`AGENTS.md`.

Après `copier update`, accepte en priorité les changements sur `AGENTS.md`,
`CLAUDE.md`, `.github/copilot-instructions.md` et
`.ai/scripts/check-shims.sh`, puis lance :

```bash
bash .ai/scripts/check-shims.sh
bash .ai/scripts/check-agent-native-context.sh
```

Si tu as un `CLAUDE.md` custom, garde tes instructions spécifiques mais conserve
le pointeur vers `.ai/index.md` ou l'import `@AGENTS.md`. La lecture native
d'`AGENTS.md` par Claude Code reste traitée prudemment : `CLAUDE.md` n'est pas
supprimé par cette migration. Avant de le rendre optionnel, le registre doit
passer le kill criterion :

```bash
bash .ai/scripts/check-agent-native-context.sh --require-confirmed claude
```

## Tes propres skills Claude (namespace projet)

Le template livre 10 skills dans le namespace réservé **`aic` / `aic-*`**, en
double : `.claude/skills/` (Claude) et `.agents/skills/` (Codex). `check-shims`
et `check-skills-parity` exigent que ces deux arbres restent identiques **sur ce
namespace uniquement**.

Tes propres skills (tout dossier hors `aic`/`aic-*`) sont **hors contrat** :

- aucun pair Codex n'est attendu — un skill Claude-only est normal ;
- aucun `workflow.md` n'est exigé — c'est une convention interne au template ;
- une divergence entre tes deux arbres, si tu en maintiens deux, ne concerne pas
  le gate.

Ils sont comptés dans la sortie (`N skill(s) project-owned … hors contrat`) pour
rester visibles, jamais bloquants. Tu n'as donc **rien** à dupliquer, à exclure à
la main, ni à désélectionner :

```bash
bash .ai/scripts/check-skills-parity.sh   # doit passer avec tes skills projet
```

> Depuis v1.0.1. En v1.0.0, ces deux checks parcouraient les arbres entiers : un
> repo avec 50 skills projet sortait `❌ FAIL` et `doctor` concluait « corriger
> les shims » sans que rien ne soit cassé. Si tu as contourné en dupliquant tes
> skills vers `.agents/skills/`, tu peux retirer les copies.

Corollaire : si tu nommes un skill projet `aic-<quelque-chose>`, il entre dans le
namespace réservé et sera exigé en parité. Choisis un autre préfixe.

## Mettre à jour un workspace TFVC (sans `.git`)

`copier update` **refuse** de tourner hors d'un sous-projet git-tracké — vérifié :
il sort avec « Updating is only supported in git-tracked subprojects. » C'est une
contrainte de Copier, pas d'ai_context : l'update calcule un diff entre deux
rendus via Git.

Chemin supporté (vérifié end-to-end) — **copie Git jetable hors du workspace**,
puis application contrôlée du delta. Ne jamais `git init` dans le workspace TFVC
lui-même : un `.git` résident y crée un risque de check-in accidentel et peut
interférer avec `tf`.

```bash
# 1. Copier le workspace vers un emplacement jetable, HORS du mapping TFVC
rsync -a /chemin/workspace-tfvc/ /tmp/aic-upgrade/

# 2. En faire un dépôt Git temporaire (dans la copie uniquement)
cd /tmp/aic-upgrade
git init -q && git add -A && git commit -qm "snapshot workspace"

# 3. Update Copier normalement dans la copie
copier update --defaults --trust --conflict=rej

# 4. Inspecter le delta AVANT de toucher au workspace
git --no-pager diff --stat HEAD
git diff --name-only HEAD          # liste des fichiers à rendre éditables

# 5. Rendre ces fichiers éditables côté TFVC, puis appliquer
cd /chemin/workspace-tfvc
tf checkout <chaque-fichier-de-la-liste>
rsync -a --exclude='.git' /tmp/aic-upgrade/ /chemin/workspace-tfvc/

# 6. Vérifier, puis check-in via TFVC
bash .ai/scripts/check-shims.sh
bash .ai/scripts/check-features.sh --no-write
```

Ce que le test end-to-end prouve sur ce chemin : le `_commit` de
`.copier-answers.yml` avance bien, le code métier local est préservé, aucun `.rej`
n'est produit sur un scaffold sain, aucun `.git` n'atterrit dans le workspace, et
`check-shims` / `check-features` passent sur le résultat.

Étape 5 : `tf checkout` avant écriture est nécessaire car TFVC garde les fichiers
en lecture seule hors pending change. Si un fichier est déjà en pending change, le
`checkout` est un no-op.

Alternative si la copie jetable n'est pas praticable : `aic template-diff` rend le
template dans `/tmp` et liste les écarts sans rien modifier — utile pour évaluer
l'ampleur d'un update avant de l'engager.

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
