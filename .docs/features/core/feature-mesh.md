---
id: feature-mesh
scope: core
title: Feature mesh markdown (frontmatter + dépendances cross-scope)
status: active
depends_on: []
touches:
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja
  - template/{{docs_root}}/features/**
---

# Feature mesh

## Objectif

Source unique de vérité pour les features d'un projet : un fichier markdown par feature, frontmatter typé, dépendances déclarées explicitement. Empêche les doublons et la dérive entre code et doc.

## Comportement attendu

- Chaque feature vit sous `<docs_root>/features/<scope>/<id>.md`.
- Le frontmatter expose `id`, `scope`, `title`, `status`, `depends_on`, `touches` (+ `progress` optionnel).
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
