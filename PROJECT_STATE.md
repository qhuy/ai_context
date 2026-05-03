# PROJECT_STATE — ai_context

**But** : template `copier` qui industrialise le setup AI context (multi-agent : Claude / Codex / Cursor / Gemini / Copilot) d'un nouveau projet.
**Remote** : [github.com/qhuy/ai_context](https://github.com/qhuy/ai_context) (public)
**Local** : chemin de développement local, non versionné.
**Dernière version publiée** : v0.11.0 — « Project guardrails & doctor hotfix » (voir [CHANGELOG.md](CHANGELOG.md))

> Ce fichier est un **point d'entrée rapide**. Pour l'historique détaillé des versions, consulter [CHANGELOG.md](CHANGELOG.md). Pour adopter le template sur un projet existant, [MIGRATION.md](MIGRATION.md). Pour l'architecture visuelle, diagramme mermaid dans [README.md](README.md).

## Comment reprendre le dev

1. Ouvrir Claude Code dans le dossier local du dépôt `ai_context`.
2. Lire [CHANGELOG.md](CHANGELOG.md) — les dernières breaking/nouveautés.
3. Lancer le smoke-test : `export PATH="$HOME/Library/Python/3.9/bin:$PATH" && bash tests/smoke-test.sh` (28 étapes, attendu `✅ PASS`).
4. Consommer le template : `copier copy gh:qhuy/ai_context ./mon-projet`. Mettre à jour : `cd mon-projet && copier update`.
5. Dogfooder le repo source après évolution du template. Le repo source n'a pas de `.copier-answers.yml` et ne doit pas être mis à jour via `copier update` :
   - preview : `bash .ai/scripts/dogfood-update.sh`
   - apply : `bash .ai/scripts/dogfood-update.sh --apply`
   - drift : `bash .ai/scripts/check-dogfood-drift.sh`

## Architecture (vue d'ensemble)

- `copier.yml` — questions utilisateur (project_name, scope_profile, tech_profile, commit_language, docs_root, agents, enable_ci_guard) + `_exclude` conditionnel.
- `template/` — racine du template (`_subdirectory: template`, `_templates_suffix: .jinja`).
- `template/AGENTS.md.jinja` = entrée canonique cross-agent ; `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/*.mdc` = shims vers `.ai/index.md`.
- `template/.ai/` = source unique de vérité (rules, QUALITY_GATE, scripts, reminder, skills).
- `template/.ai/config.yml` — configuration runtime scaffoldée (coverage/progress/context), avec fallback defaults côté scripts.
- `resume-features.sh` consomme `progress.stale_after_days` depuis cette config (si présent) ; défaut conservé à 14 jours.
- `template/.ai/schema/feature.schema.json` — contrat frontmatter de référence (alignement progressif des checks Bash).
- `template/.ai/scripts/doctor.sh` — diagnostic non destructif (dépendances, hooks, checks).
- `template/.ai/scripts/audit-features.sh` — audit agent-agnostique (`discover`, dry-run par défaut, `--apply` explicite).
- `template/.ai/scripts/migrate-features.sh` — migration frontmatter (`schema_version`, status legacy, champs manquants) en dry-run/apply.
- `template/.ai/scripts/pr-report.sh` — rapport markdown/json d'impact features depuis un diff git.
- `template/.ai/scripts/review-delta.sh` — synthèse review-friendly du delta courant (fichiers, features, risques, checks).
- `.ai/scripts/dogfood-update.sh` + `check-dogfood-drift.sh` — scripts source-only pour appliquer / contrôler le runtime rendu dans ce repo sans utiliser `copier update` sur le repo mainteneur.
- Le drift dogfood contrôle aussi les fichiers destination-only ; `dogfood-update.sh --apply` supprime le runtime obsolète sauf caches et scripts source-only explicitement exclus.
- CI : `yq` versionnée et `shellcheck` sur `.ai/scripts/*.sh` dans les workflows de garde.
- CI check : matrix `ubuntu-latest` + `macos-latest` sur le workflow principal.
- `copier.yml` expose `adoption_mode` (`lite`, `standard`, `strict`) pour calibrer hooks/CI dès le scaffold.
- `template/{{docs_root}}/features/<scope>/` = maillage feature par scope (back, front, architecture, security).
- `template/.githooks/commit-msg` + `post-checkout` — enforcement Conventional Commits et rebuild index au switch de branche.
- `template/.claude/settings.json.jinja` — hooks UserPromptSubmit / PreToolUse / PostToolUse / Stop.
- `template/.claude/skills/aic-*/` — 9 skills (`aic`, `feature-new`, `feature-resume`, `feature-update`, `feature-handoff`, `feature-audit`, `quality-gate`, `feature-done`, `project-guardrails`) avec distinction exposés/internes.
- `tests/smoke-test.sh` — 28 assertions end-to-end.

## État actuel (v0.11.0)

- **Feature mesh** — frontmatter validé, détection cycles, warn si active dépend de deprecated, scope enum, touches morte bloquante, `touches_shared` pour surfaces de review non bloquantes.
- **Continuité inter-session** — frontmatter `progress:` + worklog append-only par feature + `resume-features.sh` 4 buckets.
- **Auto-worklog** — hooks `PostToolUse` + `Stop` logguent automatiquement les éditions, bumpent `progress.updated`.
- **Coût tokens maîtrisé** — reminder compressé, filtrage par status, `measure-context-size.sh`, **graph-aware injection** via `AI_CONTEXT_FOCUS=<scope>` (scope + voisins 1-hop).
- **i18n** — reminder FR/EN selon `commit_language`.
- **Presets techniques** — règles stack optionnelles via `tech_profile` (`dotnet-clean-cqrs`, `react-next`, `fullstack-dotnet-react`).
- **Fiabilité** — `_lib.sh` helpers, matching `touches:` / `touches_shared:` centralisé, lock atomique sur index, globstar, dépendances vérifiées, JSON escaping via jq.
- **Tags versionnés** — `v0.7.2`, `v0.8.0`, `v0.9.0`, `v0.10.0`, `v0.11.0` — `copier update --vcs-ref=v0.11.0` possible.
- **Documentation** — README avec mermaid + FAQ + use cases, MIGRATION.md progressif, skills self-contained.
- **Guardrails projet** — `/aic-project-guardrails` cadre les non-goals + glossaire métier dans `.ai/guardrails.md` (référencé via Pack A, coût tokens nul à chaque tour). Comble le trou « contexte général projet » que ne couvraient ni les rules ni le feature mesh.

## Roadmap — pistes ouvertes

**P1 — stabilisation v0.10** *(largement traité dans Unreleased)*
- ✅ `progress.auto_transitions.spec_to_implement` consommé par `auto-progress.sh` (vrai opt-out).
- ✅ `context.max_tokens_warn` consommé par `pre-turn-reminder.sh` (warning stderr).
- ✅ `adoption_mode=strict` renforcé : CI ajoute `doctor --strict` + `coverage --strict`.
- ✅ `feature-index.json` expose `schema_version` + `project_id`.
- 🚧 Reste à faire : consommer `context.show_statuses` et `context.default_focus` (aujourd'hui via env vars `AI_CONTEXT_*`).
- CI source repo : workflow GitHub Actions sur `qhuy/ai_context` lui-même qui exécute `tests/smoke-test.sh` (matrix Ubuntu/macOS).
- Dog-fooding : appliquer pleinement le mesh sur `ai_context` lui-même (déjà partiellement fait sous `.docs/features/`).
- Dog-fooding runtime : script source-only disponible ; les workflows CI source restent volontairement hors synchronisation car plus stricts que le rendu downstream.

**P2 — confort UX**
- Pipelines CI hors GitHub Actions (Azure DevOps, GitLab).
- Profil `scope_profile=custom` interactif (liste CSV `custom_scopes` + jinja loop).
- `pr-report.sh` enrichi : exclusions par défaut (`README.md`, `.github/**`, `.ai/**`, `docs/**`), warnings `feature done modifiée`, formats `markdown`/`json`, options `--base`/`--head` pour CI, distinction direct/shared.
- Graphe Mermaid auto-généré du mesh (depuis l'index JSON).
- Site docs statique (mkdocs-material) sourcé depuis README/CHANGELOG/MIGRATION/skills.

**P3 — extensions**
- MCP (Model Context Protocol) côté agents pour pousser le contexte au lieu d'injecter par hook.
- Learning log automatique : Stop hook append patterns récurrents à `.ai/memory/<scope>.md` avec gate de validation manuelle (évite pollution).
- Benchmarks publics (gain tokens / temps de hook) sur projets de référence.
- Repo démo externe consommant `ai_context` à jour.

## Règle anti-doc-drift

Quand une fonctionnalité change, les fichiers suivants **doivent** être revus dans le même chantier (la règle est rappelée dans `CONTRIBUTING.md` et bloquée par `tests/smoke-test.sh` quand applicable) :

- `README.md` (référence utilisateur)
- `CHANGELOG.md` (`Unreleased` regroupé par release future)
- `PROJECT_STATE.md` (état + roadmap)
- `MIGRATION.md` (si la migration utilisateur change)
- `copier.yml` (questions + `_message_after_copy`)
- `template/.claude/skills/**/SKILL.md.jinja` + `workflow.md.jinja` (workflows skill alignés)
- `tests/smoke-test.sh` (au moins une assertion)
- Les deux versions des scripts si applicable : `.ai/scripts/<name>` (dogfooding) **et** `template/.ai/scripts/<name>.jinja` (template). Une divergence accidentelle est un bug.

## Points d'attention

- **Hook Bash `git commit`** — extraction heuristique du message (`-m "..."`, heredoc). Fallback sur `.githooks/commit-msg`.
- **Globs `touches:`** — la sémantique est centralisée dans `_lib.sh` (`path_matches_touch`) ; utiliser `touches_shared:` pour les surfaces transverses afin d'éviter que des globs trop larges augmentent le bruit de freshness.

## Tests

- `bash tests/unit/test-path-matches-touch.sh` — 18 cas unitaires sur le helper de matching `touches:`.
- `bash tests/unit/test-check-feature-freshness.sh` — non-régression staged freshness quand un fichier est couvert par plusieurs features.
- `bash tests/unit/test-dogfood-drift-extra.sh` — non-régression drift dogfood sur fichier runtime destination-only.
- `bash tests/unit/test-review-delta-shared.sh` — non-régression `touches_shared` visible en review mais non bloquant en freshness.
- `bash tests/smoke-test.sh` — 28 étapes principales (+ étape unit + étape bonus big-mesh), requiert `copier` dans le PATH (`pip install --user copier`).
- CI GitHub Actions (`enable_ci_guard: true` par défaut) — `check-shims` + `check-features` (avec validation `touches:` dure) + `check-ai-references`. Matrix `template-smoke-test.yml` étendue à `windows-latest` (best-effort, non-bloquant).

## Quick refs

- Repo : https://github.com/qhuy/ai_context
- Copier docs : https://copier.readthedocs.io/
- AGENTS.md standard : https://agents.md
