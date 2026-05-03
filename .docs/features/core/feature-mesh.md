---
id: feature-mesh
scope: core
title: Feature mesh markdown (frontmatter + dépendances cross-scope)
status: active
depends_on: []
touches:
  - .docs/FEATURE_TEMPLATE.md
  - .ai/schema/feature.schema.json
  - .ai/scripts/check-features.sh
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja
  - template/{{docs_root}}/features/**
  - template/.ai/scripts/check-features.sh.jinja
  - template/.ai/scripts/migrate-features.sh.jinja
progress:
  phase: review
  step: "template feature aligné sur workflows internes"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-04-28
---

# Feature mesh

## Objectif

Source unique de vérité pour les features d'un projet : un fichier markdown par feature, frontmatter typé, dépendances déclarées explicitement. Empêche les doublons et la dérive entre code et doc.

## Comportement attendu

- Chaque feature vit sous `<docs_root>/features/<scope>/<id>.md`.
- Le frontmatter expose `id`, `scope`, `title`, `status`, `depends_on`, `touches` (+ `touches_shared` et `progress` optionnels).
- `depends_on` autorise les arêtes cross-scope (`back/x` peut dépendre de `security/y`).
- `touches` accepte les globs ; consommé par `features-for-path.sh` pour injecter le bon contexte à l'édition.

## Contrats

- `status` ∈ {draft, active, done, deprecated, archived}.
- `id` kebab-case, unique dans le scope.
- `scope` doit matcher le dossier parent.
- Cycles dans `depends_on` interdits (cf. `cycle-detection`).

## Cross-refs

- Consommé par `feature-index-cache` (build du JSON).
- Validé par `cycle-detection` et `check-features` (CI).
- Filtré graphiquement par `graph-aware-injection` (focus + voisins 1-hop).

## Historique / décisions

- v0.1 : structure initiale.
- v0.6 : `progress.{phase,step,blockers,resume_hint,updated}` pour la reprise inter-session.
- v0.8 : warn sur `depends_on` pointant vers `deprecated` / `archived`.
- 2026-04-27 : ajout du schéma `.ai/schema/feature.schema.json` comme contrat de référence ; `check-features.sh` aligné (warn enum `progress.phase`).
- 2026-04-27 : ajout de `migrate-features.sh` pour migration dry-run/apply des frontmatters legacy (schema_version, champs requis, status normalisé).
- 2026-04-27 : centralisation des enums (`status`, `progress.phase`) — `_lib.sh` les dérive maintenant du schema JSON via `read_schema_enum()`, fallback hardcodé si schema absent. Suppression de la duplication dans `check-features.sh`. Smoke-test couvre l'ajout d'un statut au schema.
- 2026-04-28 : alignement `check-features.sh` sur le schema (Option A) — `depends_on` et `touches` sont maintenant des **clés frontmatter obligatoires** (toujours déclarables comme `[]` mais ne peuvent plus être omises). Cohérence avec `feature.schema.json` qui les exige déjà dans `required`. Côté template **et** côté dogfooding (`.ai/scripts/check-features.sh`). Sync de la version dogfoodée pour qu'elle ait également le check `progress.phase` (via `is_valid_phase`, désormais dans `_lib.sh`).
- 2026-05-03 : ajout optionnel `touches_shared` au contrat frontmatter. Il distingue surfaces de review/reporting et ownership direct, sans changer l'obligation existante sur `touches`.
- 2026-05-03 : template de fiche mis à jour pour référencer `.ai/workflows/feature-new.md`, `.ai/workflows/feature-update.md` et la reprise feature au lieu d'anciens skills procéduraux.
- 2026-05-03 : ajout du scope `product` et du lien typé `product.initiative` pour relier initiative produit et features dev sans détourner `depends_on` de son rôle technique.
- 2026-05-04 : ajout du champ optionnel `external_refs` au frontmatter pour relier specs, stories, tickets et artefacts externes sans les dupliquer dans le mesh.
