---
id: feature-schema-validator
scope: quality
title: Validation des fiches feature pilotée par le schéma
status: done
type: feature
description: "Durcir check-features en dérivant les champs requis depuis .ai/schema/feature.schema.json, sans dépendance externe, avec fallback bash conservé. Débloque l'incrément C2a compatible avec l'éthos bash/jq/yq."
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
  phase: done
  step: "incrément schema-driven livré : .required dérivé du schéma, test branché dans le smoke et parité template validée"
  blockers: []
  resume_hint: "aucune action immédiate ; cadrer une feature séparée pour dériver le pattern id, les enums imbriqués ou introduire un validateur externe"
  updated: 2026-07-03
---

# Validation des fiches feature pilotée par le schéma

## Résumé

Le frontmatter des fiches était validé par une liste de champs requis codée en
dur dans `check-features.sh`, alors que le contrat canonique vit dans
`.ai/schema/feature.schema.json`. Cette feature ferme l'écart principal en
lisant le schéma comme donnée : les clés `.required` sont dérivées via
`read_schema_enum` (`jq/yq`) avec fallback Bash conservé, sans dépendance externe
de type `ajv` ou `check-jsonschema`. Débloque l'incrément **C2a** compatible avec
l'éthos runtime du projet.

## Objectif

Fermer l'écart « contrat affirmé / contrat dupliqué dans le script » pour les
clés requises. Une clé ajoutée à `.ai/schema/feature.schema.json.required` doit
être exigée par `check-features.sh` sans rééditer le script.

## Périmètre

### Inclus

- Dérivation des champs requis depuis `.ai/schema/feature.schema.json.required`.
- Branchement dans `check-features.sh` et son miroir Jinja.
- **Fallback Bash conservé** : si la lecture du schéma échoue, la liste historique reste le plancher.
- Test discriminant : un schéma temporaire qui ajoute `owner` à `.required` doit faire échouer une fiche sans `owner`.
- Branchement du test dans le smoke.

### Hors périmètre

- Introduire un validateur externe JSON-Schema (`ajv`, `check-jsonschema`) : rejeté pour cet incrément, car contraire à l'éthos runtime documenté.
- Dériver le pattern `id`, les enums de premier niveau ou les enums imbriqués (`product.portfolio.*`) → feature séparée si priorisée.
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
- Un champ requis manquant doit être reporté explicitement par nom de clé.

## Décisions

- **Runtime tranché (2026-06-30) : zéro dépendance, dérivation jq/yq.** Le spike a montré que le schéma documente lui-même l'éthos « bash/jq/yq, AUCUNE dépendance ajv/check-jsonschema » (`$comment`) ; recommander `check-jsonschema` aurait contredit une décision actée. Le « vrai validateur » devient donc : `check-features` lit le schéma comme **donnée** (`read_schema_enum`, générique) au lieu de listes codées en dur. Décision de recadrage prise via `aic-pilot` (P3, option « durcir via jq/yq »).
- **Incrément 1 = clés requises dérivées du schéma** (`.required`). Avant : liste hardcodée `id scope title status depends_on touches` dans `check-features.sh`. Après : `REQUIRED_FIELDS="$(read_schema_enum '.required' ...)"`. Une clé ajoutée au schéma est exigée sans rééditer le script.
- **Surface = `core/feature-mesh`** : `check-features.sh` est possédé par `core/feature-mesh` (`touches:`) ; cette feature (quality) en est l'initiative, le code vit côté core (cross-ref + worklog core/feature-mesh).
- **Suite hors feature** : pattern `id` (traduire `(?:`→`(` pour ERE) et enums imbriqués (`product.portfolio`) si jugé utile — toujours bash/jq, jamais de validateur externe sauf nouvelle décision explicite.

## Comportement attendu

- `check-features.sh` lit les champs requis depuis `.ai/schema/feature.schema.json.required` via `read_schema_enum`.
- Frontmatter sans champ requis ⇒ échec avec le nom de clé manquante.
- Lecture du schéma indisponible ⇒ fallback vers la liste historique, sans dépendance externe.

## Contrats

- **Entrée** : fiche `.docs/features/<scope>/<id>.md` (frontmatter YAML) + `.ai/schema/feature.schema.json`.
- **Sortie** : exit 0 si conforme ; exit ≠ 0 si une clé requise par le schéma est absente.
- **Dégradation** : lecture du schéma indisponible ⇒ liste fallback historique.

## Validation

- `bash tests/unit/test-schema-driven-required.sh` : ajoute `owner` à `.required` dans un schéma temporaire ; une fiche sans `owner` échoue, puis passe quand `owner` est ajouté.
- `tests/smoke-test.sh` exécute ce test en étape `[0q/28]`.
- DONE : `.required` dérivé du schéma, miroir Jinja aligné, test standalone et smoke branché, aucun validateur externe introduit.

## Droits / accès

Non requis (`doc.requires.auth: false`). Exécution locale/CI, aucun secret.

## Données

Non requis (`doc.requires.data: false`). « Données » = fiches feature + schéma, repo-local.

## UX

Non requis (`doc.requires.ux: false`). UX = mainteneur/CI : message d'erreur pointant la règle de schéma.

## Observabilité

Non requis (`doc.requires.observability: false`). Preuves = sorties `check-features` (réel + fallback) et tests.

## Déploiement / rollback

- Déploiement immédiat : `check-features` continue de bloquer les clés requises manquantes ; seule la source de la liste passe du hardcode au schéma.
- Rollback : revenir à la liste hardcodée historique dans `check-features.sh`.
- Vérifs post-déploiement : `check-features --no-write`, `test-schema-driven-required`, `smoke-test`, `check-dogfood-drift`.

## Risques

- **Divergence résiduelle** : les enums et types restent partiellement validés par Bash ; à traiter dans une feature séparée si le signal le justifie.
- **Surprise future** : ajouter une clé à `.required` devient immédiatement bloquant ; c'est voulu, mais doit être documenté côté contrat.
- **Fallback silencieux** : un environnement sans `jq/yq` retombe sur la liste historique ; le smoke couvre l'environnement nominal.

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
- 2026-07-03 : DONE documentaire après recadrage livré. Le runtime externe est abandonné ; l'incrément clos dérive `.required` depuis le schéma via `read_schema_enum`, garde le fallback Bash, et le test discriminant est branché dans le smoke `[0q/28]`. Les suites pattern `id` / enums imbriqués deviennent des features séparées si priorisées.
