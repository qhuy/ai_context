# PROJECT_STATE — ai_context

**But** : template `copier` qui industrialise le setup AI context (multi-agent : Claude / Codex / Cursor / Gemini / Copilot) d'un nouveau projet.
**Remote** : [github.com/qhuy/ai_context](https://github.com/qhuy/ai_context) (public)
**Local** : `/Users/huy/Documents/Perso/ai_context`
**Dernière version publiée** : v0.3.0 (commit `347d51d`, 2026-04-23)

## Comment reprendre le dev

1. Ouvrir Claude Code dans `/Users/huy/Documents/Perso/ai_context` (fenêtre dédiée).
2. Lire ce fichier (`PROJECT_STATE.md`) + [CHANGELOG.md](CHANGELOG.md).
3. Pour tester vite : `export PATH="$HOME/Library/Python/3.9/bin:$PATH" && bash tests/smoke-test.sh`.
4. Consommer le template sur un projet réel : `copier copy gh:qhuy/ai_context ./mon-projet`.
5. Mettre à jour un projet déjà scaffoldé : `cd mon-projet && copier update`.

## Architecture rapide

- `copier.yml` — 7 questions (project_name, scope_profile, commit_language, docs_root, agents, enable_ci_guard) + variable dérivée `scopes`. `_exclude` conditionnel sur agents / scopes / CI.
- `template/` — racine du template (`_subdirectory: template`, `_templates_suffix: .jinja`).
- `template/AGENTS.md.jinja` = entrée canonique cross-agent. `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/*.mdc` = shims qui pointent vers `.ai/index.md`.
- `template/.ai/` = source unique de vérité (rules, quality gate, scripts, reminder).
- `template/{{docs_root}}/features/<scope>/` = maillage feature organisé par scope (back, front, architecture, security).
- `template/.githooks/commit-msg` = enforcement Conventional Commits + `feat:` exige features/ touché.
- `tests/smoke-test.sh` = 8 checks end-to-end (copier copy → check-shims → pre-turn-reminder → check-features → check-commit-features → features-for-path → touches validation).

## Ce qui est supporté (v0.1 → v0.3)

### v0.1.0 — MVP scaffolding (commit `539053b`)
- 4 shims cross-agent + Cursor `.mdc` opt-in
- `.ai/index.md` (entrée impérative) + `.ai/rules/<scope>.md` (squelettes)
- `.ai/quality/QUALITY_GATE.md` (DoD initial)
- `.ai/reminder.md` + `pre-turn-reminder.sh` (dual text/json)
- Scripts : `check-shims.sh`, `check-ai-references.sh`
- Hook Claude `UserPromptSubmit`
- `.copier-answers.yml` pour `copier update`
- Profils : `minimal`, `backend`, `fullstack`, `custom`
- CI GitHub Actions opt-in

### v0.2.0 — Création du maillage feature (commit `bad6d03`)
- `{{docs_root}}/FEATURE_TEMPLATE.md` — frontmatter (`id`, `scope`, `title`, `status`, `depends_on`, `touches`)
- `{{docs_root}}/features/<scope>/` — organisation par scope métier
- `check-features.sh` — frontmatter + scope == dossier + `depends_on` résout
- `check-commit-features.sh` — Conventional Commits + `feat:` → features/ obligatoire
- `.githooks/commit-msg` — délégation
- Hook Claude `PreToolUse` sur `Bash(git commit*)`
- `QUALITY_GATE` : suppression de "C — Skip", ajout Feature mesh + Commits
- Rules `back/front/architecture/security` : obligation feature documentée

### v0.3.0 — Exploitation garantie du maillage (commit `347d51d`)
- `features-for-path.sh` — path → features via `touches:` (CLI + hook Claude stdin)
- Hook Claude `PreToolUse` sur `Write|Edit|MultiEdit` — context auto-injecté
- `pre-turn-reminder.sh` — liste dynamique des features actives par scope + statut
- `check-features.sh` étendu — valide que `touches:` résout un chemin réel
- `check-commit-features.sh` refactor — lit JSON Claude sur stdin (fix bug v0.2 stdin consommé 2×)
- `index.md` + `reminder.md` — suppression wiggle room (listing `features/<scope>/` obligatoire)

## Roadmap — à développer

### v0.4 candidates (prochaine fenêtre)

**P0** — les "pas fait encore" évidents :
- **Slash commands Claude** : `/handoff`, `/plan-task`, `/feature-new <scope> <id>` (scaffolding du fichier feature depuis le template).
- **Warning `fix:`/`refactor:` qui touche un fichier référencé par feature sans update Historique** — étendre `check-commit-features.sh` pour détecter ce cas et warn (non-bloquant d'abord, bloquant plus tard).
- **Reverse refs dans le reminder** : quand on liste les features, indiquer aussi "si tu touches `back/auth`, les features suivantes dépendent de toi : [...]". Aide à anticiper les impacts cross-scope.

**P1** — robustesse :
- **`check-workflow-coherence.sh`** : détecte les incohérences entre `.ai/rules/*` et `QUALITY_GATE.md` (règles orphelines, références cassées).
- **`check-ai-pack-size.sh`** avec tokenizer tiktoken (estimation tokens chargés par le Pack A + scope rules).
- **Support `status: deprecated`** sur les features : warn si une feature dépend d'une feature deprecated.
- **Validator YAML frontmatter plus strict** (types, enum sur status : `draft|active|deprecated|archived`).

**P2** — écosystème :
- **Pipelines CI autres que GitHub Actions** : Azure DevOps, GitLab.
- **Mode low-context** : exceptions de chargement pour tâches mineures (typo, rename interne).
- **Stop hook `.ai/state/last-handoff.md`** — Claude écrit son état à la fin du tour pour reprise rapide.
- **Profil `scope_profile=custom` interactif** (liste de scopes saisie par l'utilisateur).
- **i18n reminder** (EN, pour projets open-source ou équipes internationales).
- **Support legacy `.cursorrules`** si besoin pour anciens Cursor.

**P3** — méta :
- **Appliquer le template sur ai_context lui-même** (dog-fooding complet : AGENTS.md, .ai/, features/ pour tracker le dev du template lui-même).
- **Site docs statique** (mkdocs ou vitepress) généré depuis `docs/`.
- **`copier` version pinning dans le README** (tester sur copier ≥ 9.x).

## Points d'attention / dette connue

- **Hook Claude Bash sur `git commit` — extraction best-effort** : l'extraction du message depuis le bash command (`-m "..."`, `-m '...'`, heredoc `<<'EOF'`) est heuristique. Si on ne parvient pas à extraire, on laisse passer et on compte sur `.githooks/commit-msg`. OK pour l'instant, mais si Claude passe via `gh` ou un autre wrapper, fallback sur git hook indispensable.
- **`features-for-path.sh` — globs vs préfixes** : match par expansion shell (`[[ "$rel_path" == $entry ]]`). Les globs avancés (`**`) ne sont pas supportés (le shell bash 3.2 macOS ne fait pas le `globstar` par défaut). Envisager `find` ou une lib si besoin.
- **`check-features.sh` — validation `touches:`** : supporte fichier, dossier, glob shell simple. Pas de validation que le glob matche au moins N fichiers.
- **Pas de versioning `copier` interne** : pas de tag `v0.3.0` sur le repo (`copier update` utilise la branche). À envisager pour reproductibilité : `git tag v0.3.0 && git push --tags`.

## Dog-fooding

Le template n'est **pas** appliqué sur le repo `ai_context` lui-même. Si tu veux tracker le dev du template avec le template (méta-récursif), c'est une tâche P3 ci-dessus.

En attendant, **ce fichier** (`PROJECT_STATE.md`) + `CHANGELOG.md` = suivi light.

## Tests

- `bash tests/smoke-test.sh` (requiert `copier` dans le PATH).
  - Installer : `pip install --user copier` puis exporter `$HOME/Library/Python/3.9/bin` dans PATH.
- 8 checks : copier copy → shims → reminder (text+json) → features (vide) → commit invalide → fix: accepté → path→feature → touches morte.
- Sur ma machine : `export PATH="$HOME/Library/Python/3.9/bin:$PATH" && bash tests/smoke-test.sh` → `✅ smoke-test PASS`.

## Quick refs

- Repo : https://github.com/qhuy/ai_context
- Documentation copier : https://copier.readthedocs.io/
- Convention cross-agent AGENTS.md : standard émergent (Codex, Cursor, Aider, Claude).
