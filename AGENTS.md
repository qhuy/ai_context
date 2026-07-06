# AGENTS.md — ai_context

> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

Shim lean : rien d'autre au démarrage (ni quality gate, ni agent docs, ni catalogues/worklogs/indexes/full diffs).

Hard rules :
- Un scope primaire par tâche ; cross-scope ⇒ HANDOFF explicite.
- Contexte juste-à-temps ; recherche ciblée avec `rg`.
- Avant `feat:` : fiche feature sous `.docs/features/`.
- Avant DONE : quality gate + docs impactées.
- Aucune supposition : prouver (code lu, commande, doc) ou marquer « Hypothèse ».
- Commits en français.

Source unique : `.ai/`.
