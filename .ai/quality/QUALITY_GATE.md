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

## Feature mesh (BLOQUANT — aucune dérogation)

**Toute** tâche qui ajoute ou modifie du comportement **DOIT** créer / mettre à jour un fichier feature sous `.docs/features/<scope>/<id>.md`.

- Un fichier par feature, nommé par `id` stable (ex : `authz-tenant-guard.md`).
- Rangé dans le dossier du **scope** qui l'implémente (`back/`, `front/`, `architecture/`, `security/`).
- Frontmatter YAML complet : voir `.docs/FEATURE_TEMPLATE.md`.
- Cross-refs obligatoires si la feature dépend d'une autre (`depends_on: ["back/foo", "security/bar"]`).

Cette règle est **systématique** — pas de seuil de complexité, pas de "trop petit pour documenter". Le maillage ne devient puissant que s'il est complet.

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
| core | Pack A chargé, HANDOFF clair si cross-scope |
| quality | Evidence + feature mesh + Conventional Commits |
| workflow | Commits fr, pas de full diff |
