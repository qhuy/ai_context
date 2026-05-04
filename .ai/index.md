# AI Context Index — ai_context

> Template copier pour industrialiser le contexte des agents IA

Entrée unique des agents. Mode par défaut : **lean context**.

## Pack A — always load

Lire uniquement ceci au démarrage :

- Requête utilisateur.
- Ce fichier (`.ai/index.md`).
- `git status --short`.
- Fichiers d'implémentation les plus proches, trouvés par `rg` ciblé.

Invariants :
- Un scope primaire par tâche. Cross-scope ⇒ `HANDOFF` explicite + confirmation.
- Ne charger que le contexte nécessaire. Pas de docs/catalog/index/cache/logs/full diff par défaut.
- Avant `feat:` : une fiche `.docs/features/<scope>/<id>.md` doit être créée ou mise à jour.
- Avant DONE : exécuter la delivery gate et mettre à jour les docs impactées.
- Commits en français.

## Scope Routing

Ne charge `.ai/rules/<scope>.md` que si le scope est clair et utile à l'édition.
Si le scope est incertain, utiliser cette table puis charger **un seul** fichier de scope.

| Scope | Quand charger |
|---|---|
| `core` | Règles propres au scope `core` |
| `quality` | Règles qualité spécifiques au projet, près de DONE |
| `workflow` | Routage ou procédure si le flux est ambigu |
| `product` | Initiative, roadmap, décision produit, traceability |

## On Demand

- Feature docs : charger seulement si l'intent ou les paths matchent une feature ; si un path est connu, préférer `bash .ai/scripts/features-for-path.sh <path> --with-docs` avant tout listing de dossiers.
- `depends_on` : suivre seulement les dépendances nécessaires à la décision ou à l'édition.
- Quality gate : charger `.ai/quality/QUALITY_GATE.md` ou `.ai/workflows/quality-gate.md` près de DONE, ou tôt pour tâches risquées (contrat, doc canonique, sécurité, DB).
- Agent guidance : `.ai/agent/*` est optionnel, jamais Pack A.
- Guardrails projet : charger `.ai/guardrails.md` seulement pour cadrage produit, non-goals ou glossaire métier.
- Legacy/local rules : charger seulement le pointeur ou fichier local qui matche les paths touchés.
- Catalogues, références, worklogs, changelogs, skills, indexes générés, caches et diffs complets : recherche ciblée uniquement.

## Exclusions

Pour la récupération de contexte Codex, considérer on-demand seulement : `.claude/skills/**`, `.ai/docs/**`, `.ai/tests/**`, `docs/reference/**`, docs de migration, caches générés, logs/worklogs, diffs complets, larges listings récursifs. Détail : `.ai/context-ignore.md`.
