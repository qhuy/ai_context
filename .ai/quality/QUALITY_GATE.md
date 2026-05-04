# Quality Gate — ai_context

Critères **BLOQUANTS** avant de déclarer une tâche DONE. À lire avec `.ai/index.md`.

## Evidence (obligatoire)

Avant DONE, fournir :

1. **Diff ciblé** des fichiers touchés (pas de `git diff` complet).
2. **Build** vert (commande locale + nom).
3. **Tests** passés sur le périmètre touché (commande + résultat).
4. **Lint / format** OK si le projet en a.

## Risk Ledger (par tâche non triviale)

Lister explicitement :

- Changements breaking ?
- Migrations de données / schéma ?
- Impact sur la sécurité / auth / tenancy ?
- Compatibilité arrière cassée ?

Si une case est cochée → confirmation utilisateur avant merge.

## Doc Impact Decision (obligatoire)

Avant DONE, déclarer l'une des décisions suivantes :

- **A — Aucun impact doc** : changement interne sans effet comportemental, justifié en une ligne.
- **B — Worklog seulement** : avancement, fix mineur ou décision locale sans changement de contrat.
- **C — Fiche feature mise à jour** : comportement, contrat, dépendance, scope, permission, API, UX ou règle métier modifiée.

Si la décision est **C**, la fiche feature concernée doit être modifiée dans le même changement. Si un fichier couvert par `touches:` est modifié, le hook `commit-msg` bloque le commit tant que la fiche feature ou son worklog associé n'est pas staged.

## Feature mesh (BLOQUANT — aucune dérogation)

**Toute** tâche qui ajoute ou modifie du comportement **DOIT** créer / mettre à jour un fichier feature sous `.docs/features/<scope>/<id>.md`.

- Un fichier par feature, nommé par `id` stable (ex : `authz-tenant-guard.md`).
- Rangé dans le dossier du **scope** qui l'implémente (`back/`, `front/`, `architecture/`, `security/`).
- Frontmatter YAML complet : voir `.docs/FEATURE_TEMPLATE.md`.
- Cross-refs obligatoires si la feature dépend d'une autre (`depends_on: ["back/foo", "security/bar"]`).

Cette règle est **systématique** — pas de seuil de complexité, pas de "trop petit pour documenter". Le maillage ne devient puissant que s'il est complet.

## Fraîcheur documentaire (BLOQUANT au commit)

- `bash .ai/scripts/check-feature-freshness.sh --staged --strict` vérifie qu'un changement staged sur du code couvert par `touches:` inclut aussi la fiche feature ou son worklog.
- `bash .ai/scripts/check-feature-freshness.sh --warn` signale les features dont le code couvert est plus récent que la documentation.
- En CI, le mode `--warn` reste informatif pour éviter les faux positifs sur l'historique importé ; le blocage strict se fait au commit.

## Commits — Conventional Commits (BLOQUANT)

Tous les commits respectent le format :

```
<type>[(scope)][!]: <description>
```

Types autorisés : `feat`, `fix`, `refactor`, `chore`, `test`, `docs`, `style`, `perf`, `ci`, `build`, `revert`.

Règles :

- **`feat:`** → oblige à toucher un fichier `.docs/features/<scope>/*.md` dans le même commit. Bloqué par `.githooks/commit-msg`.
- **`fix:` / `refactor:`** sur du code de feature → mettre à jour la section **Historique** du fichier feature concerné.
- Tout autre type (`chore`, `docs`, `test`, ...) → pas d'obligation feature, mais le type doit refléter la nature réelle du commit.

Pas de "skip doc" implicite : si tu hésites entre `feat` et `refactor`, c'est probablement `feat`.

## Scope checklist (par scope)

| Scope | Items bloquants |
|---|---|
| core | Pack A lean lu, HANDOFF clair si cross-scope |
| quality | Evidence + feature mesh + Conventional Commits |
| workflow | Commits fr, pas de full diff |
