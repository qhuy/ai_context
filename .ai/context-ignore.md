# Context Retrieval Exclusions — ai_context

Ces chemins ne sont jamais chargés par défaut. Les ouvrir seulement sur demande
explicite ou par recherche ciblée liée à la tâche.

## Never Default-Load

- `.claude/skills/**`
- `.ai/docs/**`
- `.ai/tests/**`
- `docs/reference/**`
- `.docs/reference/**`
- docs de migration et changelogs
- caches et index générés : `.ai/.feature-index.json`, `.ai/.progress-history.jsonl`
- logs et worklogs
- full diffs, gros listings récursifs, sorties de build volumineuses

## Retrieval Policy

- Commencer par la requête utilisateur, `.ai/index.md`, `git status --short`, puis `rg` ciblé.
- Charger une seule règle de scope sauf HANDOFF confirmé.
- Charger `.ai/quality/QUALITY_GATE.md` près de DONE, ou tôt seulement si la tâche est risquée.
- Charger les règles legacy/locales uniquement si leur glob ou leur chemin matche les fichiers touchés.
