# CHANGELOG

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
