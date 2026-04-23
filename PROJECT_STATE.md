# PROJECT_STATE — ai_context

**But** : template `copier` qui industrialise le setup AI context (multi-agent : Claude / Codex / Cursor / Gemini / Copilot) d'un nouveau projet.
**Remote** : [github.com/qhuy/ai_context](https://github.com/qhuy/ai_context) (public)
**Local** : `/Users/huy/Documents/Perso/ai_context`
**Dernière version publiée** : v0.7.2 (voir [CHANGELOG.md](CHANGELOG.md))

> Ce fichier est un **point d'entrée rapide**. Pour l'historique détaillé des versions, consulter [CHANGELOG.md](CHANGELOG.md). Pour adopter le template sur un projet existant, [MIGRATION.md](MIGRATION.md). Pour l'architecture visuelle, diagramme mermaid dans [README.md](README.md).

## Comment reprendre le dev

1. Ouvrir Claude Code dans `/Users/huy/Documents/Perso/ai_context`.
2. Lire [CHANGELOG.md](CHANGELOG.md) — les dernières breaking/nouveautés.
3. Lancer le smoke-test : `export PATH="$HOME/Library/Python/3.9/bin:$PATH" && bash tests/smoke-test.sh` (21 étapes, attendu `✅ PASS`).
4. Consommer le template : `copier copy gh:qhuy/ai_context ./mon-projet`. Mettre à jour : `cd mon-projet && copier update`.

## Architecture (vue d'ensemble)

- `copier.yml` — questions utilisateur (project_name, scope_profile, commit_language, docs_root, agents, enable_ci_guard) + `_exclude` conditionnel.
- `template/` — racine du template (`_subdirectory: template`, `_templates_suffix: .jinja`).
- `template/AGENTS.md.jinja` = entrée canonique cross-agent ; `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/*.mdc` = shims vers `.ai/index.md`.
- `template/.ai/` = source unique de vérité (rules, QUALITY_GATE, scripts, reminder, skills).
- `template/{{docs_root}}/features/<scope>/` = maillage feature par scope (back, front, architecture, security).
- `template/.githooks/commit-msg` + `post-checkout` — enforcement Conventional Commits et rebuild index au switch de branche.
- `template/.claude/settings.json.jinja` — hooks UserPromptSubmit / PreToolUse / PostToolUse / Stop.
- `template/.claude/skills/aic-*/` — 6 skills (`feature-new`, `feature-resume`, `feature-update`, `feature-handoff`, `quality-gate`, `feature-done`).
- `tests/smoke-test.sh` — 21 assertions end-to-end.

## État actuel (v0.7.2)

- **Feature mesh** — frontmatter validé (id/scope/title/status/depends_on/touches), détection cycles, scope enum, touches morte bloquante.
- **Continuité inter-session** — frontmatter `progress:` + worklog append-only par feature + `resume-features.sh` 4 buckets.
- **Auto-worklog** — hooks `PostToolUse` + `Stop` logguent automatiquement les éditions, bumpent `progress.updated`.
- **Coût tokens maîtrisé** — reminder compressé, filtrage par status, `measure-context-size.sh`.
- **Fiabilité** — `_lib.sh` helpers, lock atomique sur index, globstar, dépendances vérifiées, JSON escaping via jq.
- **Documentation** — README avec mermaid + FAQ + use cases, MIGRATION.md progressif, skills self-contained.

## Roadmap — pistes ouvertes

**P1**
- Support `status: deprecated` avec warn si une feature dépend d'une feature deprecated.
- i18n reminder : aligner la langue sur `commit_language` (FR/EN).
- Pipelines CI hors GitHub Actions (Azure DevOps, GitLab).

**P2**
- Dog-fooding : appliquer le template sur `ai_context` lui-même.
- Site docs statique (mkdocs / vitepress) généré depuis `docs/`.
- Tag `copier` par version pour reproductibilité (`copier update --vcs-ref=v0.7.2`).
- Profil `scope_profile=custom` interactif (liste de scopes saisie par l'utilisateur).

**P3**
- RAG/Memory agentique : index parsé en graphe injecté sélectivement selon scope/tâche.
- Learning log automatique des patterns récurrents par scope (validation manuelle requise pour éviter pollution).

## Points d'attention

- **Hook Bash `git commit`** — extraction heuristique du message (`-m "..."`, heredoc). Fallback sur `.githooks/commit-msg`.
- **Globs `touches:`** — bash 3.2 macOS ne fait pas `globstar` nativement ; helper `enable_globstar` active où possible.
- **Pas de tag git** sur les versions — `copier update` utilise la branche `main`. À envisager pour reproductibilité.

## Tests

- `bash tests/smoke-test.sh` — 21 étapes, requiert `copier` dans le PATH (`pip install --user copier`).
- CI GitHub Actions (`enable_ci_guard: true` par défaut) — `check-shims` + `check-features` + `check-ai-references`.

## Quick refs

- Repo : https://github.com/qhuy/ai_context
- Copier docs : https://copier.readthedocs.io/
- AGENTS.md standard : https://agents.md
