# Upgrading

Quand le template évolue sur GitHub (nouvelles règles, nouveaux checks, fixes), les projets qui l'ont appliqué peuvent remonter les changements.

## Update standard

```bash
cd mon-projet
copier update --conflict=rej
```

Copier lit `.copier-answers.yml` pour retrouver les réponses initiales et cible par défaut le dernier tag publié. Il te montre un **diff** pour chaque fichier modifié et te demande quoi faire :

- `y` : appliquer le changement.
- `n` : ignorer.
- `d` : voir le diff en détail.

Depuis la reprise d'une cadence de tags réguliers (voir `RELEASE.md`), le dernier tag reflète l'état courant du template : `copier update` sans `--vcs-ref` est la recommandation par défaut.

`--vcs-ref=HEAD` reste disponible pour suivre `main` sans attendre le prochain tag, mais expose au risque inverse : si le dernier tag prend du retard sur `main` (ce qui s'est déjà produit), il peut appliquer des changements pas encore stabilisés en release. À utiliser en connaissance de cause, pas par défaut.

Pourquoi `--conflict=rej` : en cas de merge difficile, Copier écrit des fichiers `.rej` à arbitrer au lieu d'insérer des marqueurs `<<<<<<<` directement dans les scripts. Inspecte puis supprime les `.rej` avant commit.

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

Si le projet vient d'une source ou d'un tag précis :

```bash
bash .ai/scripts/aic.sh repair-copier-metadata --src-path gh:qhuy/ai_context --commit v0.11.0 --apply
```

La commande infère `project_name`, `docs_root`, le profil de scopes, les agents et le mode d'adoption depuis les fichiers présents. Relis le YAML proposé avant `--apply` si le projet a été fortement customisé.

## Si tu as personnalisé un fichier généré

Copier détecte les modifications locales. Il propose un **merge à 3 voies** (template ancien / template nouveau / version locale). Tu arbitres conflit par conflit.

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

### Shims agents et AGENTS.md auto-suffisant

Les shims deviennent plus stricts et moins dupliqués :

- `AGENTS.md` reste toujours présent et porte les hard rules minimales inline.
- `CLAUDE.md` et `GEMINI.md` peuvent importer `@AGENTS.md` ; le shim Copilot est devenu opt-in (`enable_copilot_shim`, défaut false — le coding agent lit `AGENTS.md` nativement).
- `check-shims.sh` lit `agents` dans `.copier-answers.yml` quand ce fichier existe, et consulte le registre `.ai/native-context-support.tsv` : un shim dédié absent est accepté si l'agent y est `confirmed` (copilot, cursor) ; sinon (`pending` — claude, gemini) il doit exister et rester lean. Un shim présent est toujours validé.
- Sans `.copier-answers.yml`, le check garde un fallback compatible avec les anciens scaffolds et valide les shims présents.
- `copier update` ne supprime pas automatiquement les fichiers retirés du template. Après l'élagage, `.cursor/rules/protocol-reminder.mdc` et `.github/copilot-instructions.md` peuvent donc rester dans un projet ancien comme fichiers utilisateur. Supprime-les manuellement si tu veux adopter le modèle lean, sauf si tu utilises encore Copilot Chat/review IDE et que tu as choisi `enable_copilot_shim=true`.

Après `copier update`, accepte en priorité les changements sur `AGENTS.md`,
`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` et
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
