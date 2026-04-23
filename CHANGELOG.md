# CHANGELOG

## v0.3.0 — 2026-04-23

Garantie d'exploitation du maillage feature (pas seulement de création).

### Nouveau
- `.ai/scripts/features-for-path.sh` — lit le `touches:` des features et retourne celles qui concernent un path donné. Mode CLI + mode hook Claude (stdin JSON).
- Hook Claude `PreToolUse` sur `Write|Edit|MultiEdit` → appelle `features-for-path.sh`, injecte en `additionalContext` les features concernées avant toute écriture.
- `pre-turn-reminder.sh` enrichi — liste dynamique des features actives par scope (avec statut) injectée à chaque tour.

### Changé
- `check-features.sh` — valide désormais que chaque entrée `touches:` résout un chemin réel (fichier, dossier, ou glob). Une référence morte fait échouer le check.
- `check-commit-features.sh` — accepte maintenant du JSON Claude sur stdin (extraction robuste du message depuis `-m "..."`, `-m '...'`, ou heredoc `cat <<'EOF'`). Fix d'un bug v0.2.0 où le hook Claude consommait stdin deux fois avec `jq`.
- `.claude/settings.json` — hook Bash simplifié (délégué à `check-commit-features.sh` au lieu d'un inline `jq`).
- `.ai/index.md` et `.ai/reminder.md` — suppression de la wiggle room : "lister `features/<scope>/`" devient obligatoire à chaque tour (plus de "si applicable").

### Philosophie
v0.2 garantissait la **création** du maillage (hooks bloquants). v0.3 garantit son **exploitation** (context dynamique injecté à chaque tour + avant chaque écriture).

## v0.2.0 — 2026-04-23

Feature mesh enforcement — systématique, organisé par scope, cross-refs imposées.

### Nouveau
- `{{ docs_root }}/FEATURE_TEMPLATE.md` — squelette feature (frontmatter `id/scope/title/status/depends_on/touches`).
- `{{ docs_root }}/features/<scope>/` — organisation par scope métier (back, front, architecture, security).
- `.ai/scripts/check-features.sh` — validation du maillage (frontmatter présent, scope == dossier parent, `depends_on` résout).
- `.ai/scripts/check-commit-features.sh` — validation Conventional Commits + blocage `feat:` sans fichier `features/` touché.
- `.githooks/commit-msg` — délégation du check commit-msg (active via `git config core.hooksPath .githooks`).
- Hook Claude `PreToolUse` sur `Bash(git commit*)` — même check sous Claude Code avant l'exécution.

### Changé
- `.ai/quality/QUALITY_GATE.md` — suppression de l'option "C — Skip" (remplacée par Conventional Commits). Ajout des sections **Feature mesh** et **Commits** bloquantes.
- `.ai/rules/{back,front,architecture,security}.md` — obligation feature systématique documentée.
- `.ai/index.md` — table scope avec colonne Features, section Feature mesh, runtime enforcement étendu.
- `README_AI_CONTEXT.md` — étape d'activation des git hooks.

### Philosophie
Pas de dérogation par "taille de projet". Un maillage complet = agents plus puissants. Aucune wiggle room laissée à l'Agent.

## v0.1.0 — 2026-04-23

Initial release. MVP du template copier.

### Inclus
- 4 shims cross-agent (AGENTS, CLAUDE, GEMINI, Copilot) + Cursor `.mdc` opt-in
- `.ai/index.md` (entrée impérative) + `.ai/rules/<scope>.md` (squelettes par scope)
- `.ai/quality/QUALITY_GATE.md` (DoD + Doc Impact Decision)
- `.ai/reminder.md` (contenu extrait, éditable)
- `.ai/scripts/` : `pre-turn-reminder.sh` (dual text/json), `check-shims.sh`, `check-ai-references.sh`
- Hook Claude `UserPromptSubmit` (`.claude/settings.json`)
- `.copier-answers.yml` pour `copier update`
- Profils scope : `minimal`, `backend`, `fullstack`, `custom`
- CI GitHub Actions opt-in (`enable_ci_guard`)

### Prévu v2 (issues à ouvrir)
- Slash commands Claude (`/handoff`, `/plan-task`)
- Hook `PreToolUse` bloquant sur `git commit` quand `.docs/` non maj
- `check-feature-coverage.sh`, `check-workflow-coherence.sh`
- `check-ai-pack-size.sh` avec tokenizer tiktoken
- Mode low-context (exceptions de chargement)
- Stop hook `.ai/state/last-handoff.md`
- Support legacy `.cursorrules`
- Profil `custom` interactif avec liste de scopes
- Pipelines CI : Azure, GitLab
- i18n reminder (EN)
