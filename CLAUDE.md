# CLAUDE.md — ai_context

> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

Shim lean. Les hooks/skills Claude restent disponibles via `.claude/`, mais ils ne
sont pas du contexte obligatoire pour Codex ni pour les autres agents.

Hard rules :
- Un scope primaire par tâche ; cross-scope ⇒ HANDOFF explicite.
- Contexte juste-à-temps ; pas de catalogues, worklogs, full diffs par défaut.
- Avant `feat:` : fiche feature sous `.docs/features/`.
- Avant DONE : quality gate + docs impactées.
- Commits en français.

Configuration Claude Code : `.claude/settings.json`.
