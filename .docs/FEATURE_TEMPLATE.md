---
id: <feature-id-kebab-case>
scope: <back | front | architecture | security>
title: <Titre court de la feature>
status: draft
depends_on: []
touches: []
# Optionnel : surfaces partagées utiles au reporting/review, non bloquantes
# pour `check-feature-freshness --staged`.
touches_shared: []
# progress : état de reprise entre sessions (optionnel, auto-géré par /aic-feature-update)
progress:
  phase: spec         # spec | implement | test | review | done
  step: ""            # libre, ex : "4/7 controller"
  blockers: []        # liste courte, ex : "API spec TBD"
  resume_hint: ""     # où reprendre concrètement
  updated: ""         # YYYY-MM-DD, mis à jour à chaque /aic-feature-update
---

# <Titre>

> Copier ce fichier vers `.docs/features/<scope>/<id>.md` pour chaque nouvelle feature.
> Journal d'avancement append-only : `.docs/features/<scope>/<id>.worklog.md` (créé par `/aic-feature-new`).

## Objectif

Pourquoi cette feature existe. Problème qu'elle résout.

## Comportement attendu

Description fonctionnelle depuis le point de vue utilisateur (ou du client de l'API).

## Contrats

- Endpoints / interfaces / événements exposés
- Types / schémas
- Pré / post-conditions

## Cross-refs

Dépendances déclarées dans le frontmatter `depends_on`. Décrire brièvement comment cette feature interagit avec chacune.

## Historique / décisions

Choix marquants, ADRs liées, décisions produit.

---

**Frontmatter obligatoire** :

- `id` : slug kebab-case unique dans ce scope
- `scope` : doit matcher le dossier parent (`features/<scope>/`)
- `title` : résumé humain
- `status` : `draft` | `active` | `done` | `deprecated` | `archived`
- `depends_on` : liste de `<scope>/<id>` (ex : `back/payment-intent`)
- `touches` : paths (globs OK) du code qui implémente cette feature

**Frontmatter optionnel (reprise entre sessions)** :

- `touches_shared` : surfaces transverses liées à la feature (`tests/smoke-test.sh`, `CHANGELOG.md`, docs d'état). Ces chemins apparaissent dans les rapports mais ne déclenchent pas l'obligation de fiche/worklog dans `check-feature-freshness --staged`.
- `progress.phase` : étape courante du cycle
- `progress.step` : détail libre (humain)
- `progress.blockers` : liste courte ; si non vide, apparaît dans `/aic-feature-resume`
- `progress.resume_hint` : ce qu'un·e agent doit savoir pour reprendre
- `progress.updated` : date ISO, auto-renseignée

Le journal complet vit dans `<id>.worklog.md` (append-only, jamais édité ailleurs).

Référence formelle du contrat : `.ai/schema/feature.schema.json`.
