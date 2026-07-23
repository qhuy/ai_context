# Référence des variables du template

Les questions posées par `copier copy` et leurs effets.

Cette page distingue deux familles :

- variables Copier : réponses persistées dans `.copier-answers.yml` et utilisées au rendu du template ;
- variables runtime `AI_CONTEXT_*` : overrides d'exécution lus par les scripts générés, non posés par Copier.

| Variable | Type | Défaut | Effet |
|---|---|---|---|
| `project_name` | str | — (requis) | Nom injecté dans les shims et `.ai/index.md` |
| `project_description` | str | "" | Description 1 ligne dans l'index |
| `scope_profile` | choice | `fullstack` | Détermine la liste `scopes` (voir profils) |
| `adoption_mode` | choice | `standard` | Module l'enforcement scaffoldé : `lite`, `standard` ou `strict` |
| `tech_profile` | choice | `generic` | Ajoute des règles stack optionnelles (`dotnet-clean-cqrs`, `react-next`, `fullstack-dotnet-react`) |
| `commit_language` | choice | `fr` | Langue des commits imposée par les règles |
| `docs_root` | str | `.docs` | Dossier racine de la doc métier (`.docs` ou `docs`) |
| `agents` | multiselect | `[claude, codex]` | Shims / hooks générés |
| `enable_ci_guard` | bool | `true` | Ajoute `.github/workflows/ai-context-check.yml` |

## Variables runtime `AI_CONTEXT_*`

Ces variables ne sont pas des questions Copier. Elles peuvent être exportées ponctuellement dans le shell ou préfixer une commande pour ajuster le comportement des scripts.

| Variable | Défaut | Surface | Effet |
|---|---|---|---|
| `AI_CONTEXT_AUTO_PROGRESS_FILTER_EXT` | vide | `.ai/scripts/_lib.sh` | Ajoute des extensions à exclure du filtre d'auto-progression structurelle, au format liste séparée par virgules, par exemple `.md,.txt`. |
| `AI_CONTEXT_CONFIG_FILE` | `.ai/config.yml` | `.ai/scripts/_lib.sh` | Force le fichier de configuration lu par `read_config`. |
| `AI_CONTEXT_DEBUG` | `0` | `_lib.sh`, `features-for-path.sh`, `pre-turn-reminder.sh`, `build-feature-index.sh`, `resume-features.sh` | Active les logs debug des scripts qui l'exposent. |
| `AI_CONTEXT_DOCS_ROOT` | valeur rendue de `docs_root` (`.docs` par défaut) | `.ai/scripts/_lib.sh`, `check-commit-features.sh` | Override runtime du dossier racine documentaire. Sert notamment à dériver `AI_CONTEXT_FEATURES_DIR`. |
| `AI_CONTEXT_FEATURES_DIR` | `${AI_CONTEXT_DOCS_ROOT}/features` | scripts feature mesh | Override runtime du dossier contenant les fiches features. Utilisé par les checks, l'index, l'audit, la reprise et les rapports. |
| `AI_CONTEXT_FEATURES_STRICT` | `0` | `features-for-path.sh` | Rend l'absence de feature correspondante bloquante sans passer `--strict`. |
| `AI_CONTEXT_FEATURES_TOP_K` | `3` | `features-for-path.sh` | Nombre maximal de fiches injectées après ranking. |
| `AI_CONTEXT_FEATURE_DOC_MAX_CHARS` | `10000` | `features-for-path.sh` | Budget total des extraits de fiches injectés avec `--with-docs`. |
| `AI_CONTEXT_FEATURE_DOC_PER_DOC_CHARS` | `3000` | `features-for-path.sh` | Budget maximal par fiche injectée avec `--with-docs`. |
| `AI_CONTEXT_FOCUS` | vide | `pre-turn-reminder.sh` | Limite l'inventaire du reminder à un scope et ses voisins, équivalent à `--focus=<scope>`. |
| `AI_CONTEXT_INJECT_FEATURE_DOCS` | `1` | `features-for-path.sh` | Mettre à `0` pour désactiver l'injection des extraits de fiches, même avec un hook qui demande les docs. |
| `AI_CONTEXT_LOCK_DIR` | `/tmp/.ai-context-<uid>-index-lock` | `.ai/scripts/_lib.sh` | Override du répertoire de lock utilisé par `with_index_lock`. |
| `AI_CONTEXT_RELEVANCE_DISABLED` | `0` | `context-relevance-log.sh` | Mettre à `1` pour désactiver le logging de pertinence contexte. |
| `AI_CONTEXT_RELEVANCE_ROTATION_MB` | `10` | `context-relevance-log.sh` | Taille de rotation du fichier de logs de pertinence, en Mo. |
| `AI_CONTEXT_SCHEMA_FILE` | `.ai/schema/feature.schema.json` | `.ai/scripts/_lib.sh` | Override du schéma utilisé pour lire les enums de validation. |
| `AI_CONTEXT_SHOW_ALL_STATUS` | `0` | `_lib.sh`, `pre-turn-reminder.sh`, `measure-context-size.sh` | Affiche ou mesure aussi les features `done`, `deprecated` et `archived`. |

Les variables `AI_CONTEXT_DOCS_ROOT`, `AI_CONTEXT_FEATURES_DIR` et `AI_CONTEXT_SCHEMA_FILE` sont initialisées par `_lib.sh` et héritées par les scripts qui le sourcent. Les autres variables sont lues directement par les scripts indiqués.

## Profils `scope_profile`

| Profil | Scopes |
|---|---|
| `minimal` | core, quality, workflow, product |
| `backend` | core, quality, workflow, product, back, architecture, security, handoff |
| `fullstack` | backend + front |
| `custom` | minimal (tu ajoutes tes scopes à la main après scaffold) |

## Profils `tech_profile`

| Profil | Règles générées |
|---|---|
| `generic` | aucune règle stack spécifique |
| `dotnet-clean-cqrs` | `.ai/rules/tech-dotnet.md` |
| `react-next` | `.ai/rules/tech-react.md` |
| `fullstack-dotnet-react` | `.ai/rules/tech-dotnet.md`, `.ai/rules/tech-react.md`, `.ai/rules/stack-fullstack-dotnet-react.md` |

## Agents disponibles

| Agent | Fichiers générés |
|---|---|
| `claude` | `CLAUDE.md`, `.claude/settings.json`, `.claude/skills/aic-*` |
| `codex` | `AGENTS.md` (toujours généré) + `.agents/skills/aic-*` si `codex` est sélectionné |
| `cursor` | `.cursor/rules/back.mdc` / `front.mdc` scopés par globs, si les scopes existent (sinon rien — AGENTS.md est lu nativement) |
| `gemini` | `GEMINI.md` |
| `copilot` | `.github/copilot-instructions.md` seulement si `enable_copilot_shim=true` (sinon rien — AGENTS.md est lu nativement par le coding agent) |

`AGENTS.md` est toujours généré : c'est l'entrée canonique cross-agent (standard émergent).

## Fichiers toujours générés

- `AGENTS.md`
- `.ai/index.md`
- `.ai/OWNERSHIP.md`
- `.ai/reminder.md`
- `.ai/context-ignore.md`
- `.ai/quality/QUALITY_GATE.md`
- `.ai/rules/core.md`, `quality.md`, `workflow.md`, `product.md` (scopes minimum)
- `.ai/scripts/pre-turn-reminder.sh`, `check-shims.sh`, `check-ai-references.sh`, `check-feature-docs.sh`
- `.ai/templates/project-overlay/README.md` (exemple, pas un overlay actif)
- `README_AI_CONTEXT.md`
- `{{docs_root}}/.gitkeep`
- `.copier-answers.yml` (tracking du template appliqué ; doit être versionné pour permettre `copier update`)
