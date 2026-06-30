---
id: feature-schema-validator
scope: quality
title: Validateur JSON-Schema réel des fiches feature (enforce le contrat, fallback bash conservé)
status: draft
type: feature
description: "Remplacer l'heuristique bash de validation du frontmatter par un vrai validateur JSON-Schema qui consomme .ai/schema/feature.schema.json, avec dégradation gracieuse (fallback bash) si le binaire est absent. Débloque C2a."
depends_on:
  - core/okf-strict-profile
  - core/feature-mesh
touches:
  - .docs/features/quality/feature-schema-validator.md
  - .docs/features/quality/feature-schema-validator.worklog.md
  - tests/unit/test-schema-driven-required.sh
touches_shared:
  - .ai/schema/feature.schema.json
  - template/.ai/schema/feature.schema.json
  - .ai/scripts/check-features.sh
  - template/.ai/scripts/check-features.sh.jinja
  - tests/smoke-test.sh
  - CHANGELOG.md
product: {}
external_refs:
  pilot: ".docs/pilots/2026-06-30-ze-solution.md"
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: implement
  step: "incrément 1 livré : clés requises dérivées du schéma (.required) dans check-features via read_schema_enum (zéro dép) ; test + parité OK"
  blockers: []
  resume_hint: "follow-ups : (1) HANDOFF quality/smoke-test = brancher le test dans smoke [0q/28] ; (2) entrée CHANGELOG (différée, couplage) ; (3) suite optionnelle : dériver le pattern id ((?:→() et enums imbriqués product.portfolio. Runtime reste bash/jq/yq, AUCUN validateur externe (décision vs éthos schéma)"
  updated: 2026-06-30
---

# Validateur JSON-Schema réel des fiches feature

## Résumé

Aujourd'hui le frontmatter des fiches est validé par des heuristiques Bash
(`check-features.sh`) : le système **impose un schéma qu'il ne valide pas
rigoureusement**. Cette feature introduit un **vrai validateur JSON-Schema** qui
consomme `.ai/schema/feature.schema.json`, avec **dégradation gracieuse** : si le
binaire validateur est absent, on retombe sur l'heuristique Bash (qui reste le
plancher). Débloque le finding **C2a** de l'audit de remédiation.

## Objectif

Fermer l'écart « contrat affirmé / contrat non vérifié ». Une fiche au frontmatter
invalide (enum hors liste, champ requis manquant, type erroné, structure
`product.*` malformée) doit être **rejetée par le schéma lui-même**, avec un
message pointant la règle violée — pas par une regex bash approximative.

## Périmètre

### Inclus

- Intégration d'un validateur JSON-Schema réel consommant le schéma existant.
- Branchement dans `check-features.sh` en **mode warn** d'abord (parité avec la stratégie OKF).
- **Fallback Bash conservé** : si le binaire est absent, warning + heuristique actuelle (jamais de hard-fail sur dépendance manquante).
- Tests valides **et** invalides (enum, required, type, `product.portfolio.*`).
- Migration consommateurs documentée (warn → fail en vN+1).

### Hors périmètre

- Définir/étendre le contrat lui-même (champs requis, `type` dans `required[]`) → `core/okf-strict-profile`.
- Aligner le parser fallback sans `yq` → `core/feature-mesh-contract-alignment`.
- Réécrire le moteur d'index/graphe en Python (P4) → chantier séparé, fortes deps inverses.
- Valider autre chose que les fiches feature (configs agents = `quality/agent-config-validation`).

### Granularité / nommage

Une fiche pour le **moteur d'enforcement** du contrat de fiche. Distincte du
contrat (`okf-strict-profile`) et de l'alignement parser (`feature-mesh-contract-alignment`).

## Invariants

- Le schéma `.ai/schema/feature.schema.json` reste la **source de vérité unique** du contrat (les énums Bash en dérivent déjà via `_lib.sh`).
- **Aucune dépendance dure** : binaire absent ⇒ dégradation gracieuse, jamais de blocage d'un environnement minimaliste.
- Parité runtime/template tenue (dogfood drift) si `check-features` est modifié des deux côtés.
- Un résultat de validation doit pointer la **règle de schéma** violée (chemin JSON), pas un message opaque.

## Décisions

- **Runtime tranché (2026-06-30) : zéro dépendance, dérivation jq/yq.** Le spike a montré que le schéma documente lui-même l'éthos « bash/jq/yq, AUCUNE dépendance ajv/check-jsonschema » (`$comment`) ; recommander `check-jsonschema` aurait contredit une décision actée. Le « vrai validateur » devient donc : `check-features` lit le schéma comme **donnée** (`read_schema_enum`, générique) au lieu de listes codées en dur. Décision de recadrage prise via `aic-pilot` (P3, option « durcir via jq/yq »).
- **Incrément 1 = clés requises dérivées du schéma** (`.required`). Avant : liste hardcodée `id scope title status depends_on touches` dans `check-features.sh`. Après : `REQUIRED_FIELDS="$(read_schema_enum '.required' ...)"`. Une clé ajoutée au schéma est exigée sans rééditer le script.
- **Surface = `core/feature-mesh`** : `check-features.sh` est possédé par `core/feature-mesh` (`touches:`) ; cette feature (quality) en est l'initiative, le code vit côté core (cross-ref + worklog core/feature-mesh).
- **Suite** : pattern `id` (traduire `(?:`→`(` pour ERE) et enums imbriqués (`product.portfolio`) si jugé utile — toujours bash/jq, jamais de validateur externe.

## Comportement attendu

- `check-features.sh` valide chaque fiche contre le schéma via le binaire si présent ; sinon warning + heuristique Bash.
- Frontmatter invalide ⇒ message désignant la règle (`properties.status.enum`, `required`, etc.).
- Environnement sans binaire ⇒ aucun blocage : warning explicite + comportement actuel.

## Contrats

- **Entrée** : fiche `.docs/features/<scope>/<id>.md` (frontmatter YAML) + `.ai/schema/feature.schema.json`.
- **Sortie** : exit 0 si conforme ; en mode fail (vN+1), exit ≠ 0 + liste des violations (chemin de schéma + fiche).
- **Dégradation** : binaire absent ⇒ exit selon heuristique Bash + warning « validateur réel indisponible ».

## Validation

- Fiche valide ⇒ PASS validateur réel.
- Fiche invalide par cas (enum, required, type, `product.portfolio.*`) ⇒ rejet avec règle pointée.
- Binaire absent ⇒ fallback Bash + warning, pas de hard-fail.
- Tests unitaires dédiés + au moins une assertion `smoke-test`.
- DONE : validateur réel branché en warn, fallback prouvé, tests valides/invalides verts, doc migration warn→fail écrite.

## Droits / accès

Non requis (`doc.requires.auth: false`). Exécution locale/CI, aucun secret.

## Données

Non requis (`doc.requires.data: false`). « Données » = fiches feature + schéma, repo-local.

## UX

Non requis (`doc.requires.ux: false`). UX = mainteneur/CI : message d'erreur pointant la règle de schéma.

## Observabilité

Non requis (`doc.requires.observability: false`). Preuves = sorties `check-features` (réel + fallback) et tests.

## Déploiement / rollback

- Release N : validateur réel en **mode warn** dans `check-features` ; fallback Bash actif ; doc consommateurs.
- Release N+1 : **flip fail** (exit ≠ 0 sur frontmatter invalide), coordonné avec `okf-strict-profile`.
- Rollback : revenir au mode warn (le fallback Bash reste le plancher inchangé).
- Vérifs post-déploiement : `check-features` réel + simulation binaire absent + `smoke-test` verts.

## Risques

- **Nouvelle dépendance** : atténué par le fallback (jamais dure) et le choix d'un binaire de l'écosystème déjà requis (pip).
- **Divergence schéma ↔ énums Bash** de `_lib.sh` : le validateur réel doit devenir la référence ; surveiller la cohérence.
- **Bruit au flip fail** : des fiches legacy peuvent devenir invalides → migration warn d'abord, comme OKF.
- Décision ouverte : runtime exact (pip/node/lib) et emplacement (script dédié vs inline check-features).

## Cross-refs

- `core/okf-strict-profile` : définit le **contrat** (champs/`type` requis) ; cette feature en est l'**enforcement** rigoureux. Le flip fail doit être coordonné avec sa stratégie warn→fail.
- `core/feature-mesh-contract-alignment` : aligne le parser fallback ; complémentaire (parsing vs validation).
- `quality/agent-config-validation` : validation des configs agents ; périmètre disjoint (fiches vs configs).
- Pilot directeur : `.docs/pilots/2026-06-30-ze-solution.md` (item P3).

## Historique / décisions

- 2026-06-30 : création via pilotage `aic-pilot` (pilot `2026-06-30-ze-solution`, item P3),
  après HANDOFF product→quality. Objet : débloquer C2a par un vrai validateur JSON-Schema
  avec fallback bash. Décisions : validateur réel + fallback (pas de remplacement brutal) ;
  runtime recommandé `check-jsonschema` (pip) car Python/pip déjà requis par Copier ;
  migration warn→fail alignée sur `okf-strict-profile`. Décision ouverte : runtime exact.
