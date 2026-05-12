# AI Context — ai_context

Ce projet a été scaffoldé depuis le template [`ai_context`](https://github.com/qhuy/ai_context). Le setup cross-agent (Claude / Codex / Cursor / Gemini / Copilot) est industrialisé.

## Premier pas

1. **Lire [`AGENTS.md`](AGENTS.md)** puis **[`.ai/index.md`](.ai/index.md)**.
2. **Activer les git hooks** (une fois par clone) :
   ```bash
   git config core.hooksPath .githooks
   chmod +x .githooks/*
   ```
3. Si le projet a des règles locales durables, créer `.ai/project/index.md` puis y référencer uniquement les fichiers projet utiles. Garder `.ai/rules/<scope>.md` pour les règles génériques de scope.
4. **Cadrer avant d'implémenter** (recommandé) : dans Claude Code, lancer `/aic-frame` pour produire objectif, plan, spécificités métier/technique, validation et non-goals éventuels. Peut créer `.ai/guardrails.md` si le cadrage projet le justifie.
5. Vérifier l'intégrité :
   ```bash
   bash .ai/scripts/check-shims.sh
   bash .ai/scripts/check-features.sh
   bash .ai/scripts/check-feature-docs.sh
   ```
6. Lancer le parcours de démarrage :
   ```bash
   bash .ai/scripts/aic.sh frame "première tâche"
   ```

## Agents activés

- claude
- codex


## Scopes

- `core` → `.ai/rules/core.md`
- `quality` → `.ai/rules/quality.md`
- `workflow` → `.ai/rules/workflow.md`
- `product` → `.ai/rules/product.md` + features `.docs/features/product/`




## Feature mesh (systématique)

Toute feature ajoute ou met à jour un fichier `.docs/features/<scope>/<id>.md` basé sur `.docs/FEATURE_TEMPLATE.md`.

- Organisation par scope (`product/`, `back/`, `front/`, `architecture/`, `security/`).
- Le scope `product` trace les initiatives et décisions ; les features dev les relient via `product.initiative`, et les specs/stories/tickets externes via `external_refs`.
- Cross-refs via `depends_on` (ex : une feature front liste les features back consommées).
- Enforcement : `.githooks/commit-msg` bloque tout commit `feat:` sans fichier feature.

## Mettre à jour depuis le template

Quand le template évolue sur GitHub :

```bash
copier update --vcs-ref=HEAD
```

Les réponses déjà données sont relues depuis `.copier-answers.yml`. Tu contrôles le diff appliqué.

`.ai/project/**` est réservé au projet : `copier update` ne doit ni supprimer ni écraser ce dossier. Voir `.ai/OWNERSHIP.md` et l'exemple `.ai/templates/project-overlay/README.md`.

`--vcs-ref=HEAD` évite que Copier choisisse le dernier tag publié si le HEAD GitHub est plus récent.

Si `.copier-answers.yml` manque ou ne contient pas `_src_path` / `_commit` :

```bash
bash .ai/scripts/aic.sh repair-copier-metadata
# relire la proposition, puis :
bash .ai/scripts/aic.sh repair-copier-metadata --apply
```

Pour prévisualiser une update sans toucher au repo courant, même si le worktree est sale :

```bash
bash .ai/scripts/aic.sh template-diff
```

## Runtime

- Claude Code : hooks `UserPromptSubmit` (reminder) + `PreToolUse` sur `git commit` (feature mesh guard) configurés dans `.claude/settings.json` — activer avec `/hooks` au premier démarrage.
- Git : hook `commit-msg` sous `.githooks/` (active via `git config core.hooksPath .githooks`). Bloque les `feat:` sans feature doc, même hors Claude.
- Contenu du reminder : `.ai/reminder.md` (éditable librement).

## Workflow quotidien

| Intention | Commande |
|---|---|
| Cadrer avant action | Claude : `/aic-frame` ; CLI : `bash .ai/scripts/aic.sh frame "<objectif>"` |
| Voir où j'en suis | `bash .ai/scripts/aic.sh status` |
| Diagnostiquer un blocage | Claude : `/aic-diagnose` ; CLI : `bash .ai/scripts/aic.sh diagnose "<symptôme>"` |
| Préparer une édition avec Codex | `bash .ai/scripts/aic.sh document-feature <path>` |
| Vérifier les docs du delta | `bash .ai/scripts/aic.sh document-feature` |
| Documenter une feature | Claude : `/aic-document-feature` ; Codex : skill local `aic-document-feature` ou langage naturel |
| Réparer le mesh | `bash .ai/scripts/aic.sh repair` |
| Réparer les métadonnées Copier | `bash .ai/scripts/aic.sh repair-copier-metadata` |
| Prévisualiser le template | `bash .ai/scripts/aic.sh template-diff` |
| Relire mon delta | `bash .ai/scripts/aic.sh review` |
| Préparer le ship | `bash .ai/scripts/aic.sh ship` |
| Tracer les initiatives produit | `bash .ai/scripts/aic.sh product-status` puis `bash .ai/scripts/aic.sh product-portfolio` |
| Vérifier avant commit | `bash .ai/scripts/aic.sh doctor` puis `bash .ai/scripts/aic.sh check` |

Claude reçoit le contexte feature automatiquement via hooks. Codex et les autres agents peuvent cadrer avec `frame`, obtenir le même contexte juste-à-temps avec `document-feature <path>` avant d'éditer, puis vérifier la sortie avec `document-feature` et `ship`.

## Contrats avancés

- Subagents : utiliser `.ai/workflows/subagent-contract.md` avant toute délégation parallèle. Un `explorer` reste lecture seule ; un `worker` reçoit un write-set explicite et disjoint.
- Hooks Codex : `.ai/workflows/codex-hooks-parity.md` décrit un pilote opt-in, déterministe et non LLM. Les hooks Git restent la garantie stable.
- MCP : `.ai/workflows/mcp-policy.md` garde MCP opt-in, avec allowlist explicite, pas de secrets et fallback sans MCP.

## Checks

- `bash .ai/scripts/check-shims.sh` — garde-fou structure shims.
- `bash .ai/scripts/check-agent-config.sh` — validation non destructive des configs Claude/Codex et scripts référencés.
- `bash .ai/scripts/check-features.sh` — maillage feature (frontmatter + scope + depends_on).
- `bash .ai/scripts/check-feature-docs.sh` — sections "bible feature" ; utiliser `--strict <scope/id>` avant DONE.
- `bash .ai/scripts/check-product-links.sh` — liens `product.initiative` + initiatives product.
- `bash .ai/scripts/check-ai-references.sh` — vérifie les liens markdown internes.
- `bash .ai/scripts/check-commit-features.sh` — Conventional Commits + feat: touche features/.
