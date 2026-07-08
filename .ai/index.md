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

## Commit & Doc Level

Choisir le type de commit selon l'intention :

- `feat:` : nouveau comportement utilisateur, agent, workflow ou contrat ; exige une fiche feature créée ou mise à jour dans le même commit.
- `fix:` : correction d'un comportement cassé ou dangereux ; rattacher à une fiche existante si un `touches:` couvre la surface.
- `refactor:` : restructuration sans changement de comportement attendu ; documenter l'impact dans le worklog de la feature couvrante.
- `chore:` : maintenance, outillage ou métadonnées sans effet produit direct ; pas de contournement pour livrer une vraie feature sans fiche.
- `docs:` : documentation seule ; utiliser si le delta ne modifie ni comportement runtime ni contrat.

`doc.level` :

- `brief` : changement interne étroit, faible risque, sans nouveau contrat durable.
- `standard` : défaut pour une feature ou un contrat maintenu.
- `full` : surface critique, sécurité, données, rollout, observabilité, API stable ou impact multi-scope.

## Scope Routing

Ne charge `.ai/rules/<scope>.md` que si le scope est clair et utile à l'édition.
Si le scope est incertain, utiliser cette table puis charger **un seul** fichier de scope.

| Scope | Quand charger |
|---|---|
| `core` | Règles propres au scope `core` |
| `quality` | Règles qualité spécifiques au projet, près de DONE |
| `workflow` | Routage ou procédure si le flux est ambigu |
| `product` | Initiative, roadmap, décision produit, traceability |

## Project Overlay

Si `.ai/project/index.md` existe, le lire maintenant. Ne pas précharger le reste de `.ai/project/**` : ce fichier projet décide seul quelles règles locales charger. Si ce fichier route un path vers `.ai/project/<scope>/index.md`, charger cet index de scope sur match de path — descente d'un niveau, par pointeur explicite, jamais de récursion aveugle.

## On Demand

- Feature docs : charger seulement si l'intent ou les paths matchent une feature ; si un path est connu, préférer `bash .ai/scripts/features-for-path.sh <path> --with-docs` avant tout listing de dossiers.
- `depends_on` : suivre seulement les dépendances nécessaires à la décision ou à l'édition.
- Quality gate : charger `.ai/quality/QUALITY_GATE.md` ou `.ai/workflows/quality-gate.md` près de DONE, ou tôt pour tâches risquées (contrat, doc canonique, sécurité, DB).
- Agent guidance : `.ai/agent/*` est optionnel, jamais Pack A.
- Guardrails projet : charger `.ai/guardrails.md` seulement pour cadrage produit, non-goals ou glossaire métier.
- Knowledge hub : utiliser `bash .ai/scripts/aic.sh knowledge <publish|search|link|import|freshness>` seulement si l'intent porte sur publication, recherche, lien ou import de connaissance durable.
- Legacy/local rules : charger seulement le pointeur ou fichier local qui matche les paths touchés.
- Catalogues, références, worklogs, changelogs, skills, indexes générés, caches et diffs complets : recherche ciblée uniquement.

## Exclusions

Pour la récupération de contexte Codex, ne pas dupliquer la liste ici : appliquer `.ai/context-ignore.md`.
