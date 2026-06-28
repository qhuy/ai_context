# Garde-fous — ai_context

> Couche de cadrage produit. Chargée **à la demande** (Pack A) uniquement pour : non-goals,
> glossaire métier, gouvernance du backlog. Ne pas précharger. Fichier projet-spécifique
> (exclu du dogfood drift ; les projets consommateurs reçoivent un squelette à compléter).

## Non-goals

ai_context **ne** vise **pas** à :

- Remplacer un outil de roadmap / ticketing (Linear, Jira, GitHub Projects) — il les **relie**
  via `external_refs`, sans dupliquer leur contenu.
- Remplacer un framework spec-driven (BMAD, Spec Kit, Kiro) — il est la couche **locale** de gates
  et de traçabilité code↔doc **au-dessus** d'eux.
- Offrir une parité runtime identique entre agents. L'expérience la plus riche est sur **Claude**
  (hooks live). Codex / Cursor / Gemini / Copilot bénéficient des shims + git hooks + checks.
  **Ne jamais masquer cette asymétrie** (cf. `product/readme-positioning`, kill_criteria).
- Générer le contexte à la place de l'humain — il en **force la fraîcheur**, il ne l'invente pas.
- Être un runtime à installer — c'est un **template Copier**, sans dépendance hors `bash`/`jq`
  (et `yq` optionnel).

## Glossaire métier

- **Feature mesh** : ensemble des fiches `.docs/features/<scope>/<id>.md` reliées par
  `depends_on` / `touches`, compilées en `.ai/.feature-index.json`.
- **Scope** : domaine primaire d'une tâche (`core` / `quality` / `workflow` / `product`).
  Un scope par tour ; cross-scope ⇒ HANDOFF explicite.
- **Pack A** : contexte minimal chargé au démarrage (requête + `.ai/index.md` + `git status` + `rg` ciblé).
- **Frame** : artefact de cadrage durable sous `.docs/frames/`.
- **Worklog** : journal d'avancement append-only par fiche (`*.worklog.md`).
- **Dogfood drift** : vérification que le runtime `.ai/` égale le rendu Copier minimal.

## Gouvernance du backlog

### B0 — Budget méta-process

*(décidé le 2026-06-28 — frame `.docs/frames/2026-06-28-audit-strategique-remediation.md`)*

Toute nouvelle fiche de scope `workflow` ou à objet **méta-process** (outillage du process, pas
valeur livrée à l'utilisateur final du template) ne peut être créée qu'en **clôturant
simultanément** une fiche méta existante (`done` / `archived`).

Gel par défaut des nouvelles fiches `workflow/*` tant que le nombre de fiches figées en phase
`review` n'est pas redescendu sous un seuil sain.

**But** : garder le feature mesh comme un **registre de livrables**, pas un journal de process qui
prolifère. L'audit du 2026-06-28 a constaté 3 fiches dédiées uniquement à combattre la
prolifération de fiches (`feature-granularity`, `feature-new-approval-step`,
`feature-consolidation-nudge`) — symptôme que la règle B0 vise à enrayer.
