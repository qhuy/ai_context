# AGENTS.md — ai_context

> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

Shim lean Codex : ne charge pas `.ai/quality/QUALITY_GATE.md`, `.ai/agent/*`,
catalogues, références, worklogs, skills, indexes ou full diffs au démarrage.

Hard rules :
- Un scope primaire par tâche ; cross-scope ⇒ HANDOFF explicite.
- Contexte juste-à-temps ; recherche ciblée avec `rg`.
- Avant `feat:` : fiche feature sous `.docs/features/`.
- Avant DONE : quality gate + docs impactées.
- Commits en français.

Source unique : `.ai/`.
