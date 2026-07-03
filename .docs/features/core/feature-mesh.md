---
id: feature-mesh
scope: core
title: Feature mesh markdown (frontmatter + dépendances cross-scope)
status: done
depends_on: []
touches:
  - .docs/FEATURE_TEMPLATE.md
  - .ai/schema/feature.schema.json
  - .ai/scripts/check-features.sh
  - .ai/scripts/check-feature-docs.sh
  - tests/unit/test-id-schema-checker-parity.sh
  - tests/unit/test-check-features-yaml-strict.sh
  - tests/unit/test-check-features-frontmatter-boundary.sh
  - tests/unit/test-feature-docs-placeholder-heuristic.sh
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja
  - template/{{docs_root}}/features/**
  - template/.ai/scripts/check-features.sh.jinja
  - template/.ai/scripts/check-feature-docs.sh.jinja
  - template/.ai/scripts/migrate-features.sh.jinja
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: false
    observability: false
progress:
  phase: done
  step: "contrat feature mesh stabilisé ; C2a clarifié et checks alignés"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir si le frontmatter feature, le schéma ou check-features.sh change"
  updated: 2026-07-03
type: feature
---

# Feature mesh

## Résumé

Le feature mesh définit la fiche markdown canonique d'une feature : identité, scope, dépendances, fichiers touchés, progression et documentation technique. Il sert de source de vérité exploitable par les agents, les hooks et les checks.

## Objectif

Source unique de vérité pour les features d'un projet : un fichier markdown par feature, frontmatter typé, dépendances déclarées explicitement. Empêche les doublons et la dérive entre code et doc.

## Périmètre

Inclus : contrat frontmatter, structure documentaire, dépendances cross-scope, fichiers touchés et contrôles associés. Hors périmètre : contenu métier détaillé des features applicatives, qui reste dans chaque fiche dédiée.

## Invariants

- Une feature appartient à un scope primaire.
- Une dépendance cross-scope doit être explicite dans `depends_on`.
- Une fiche doit rester utile en lecture directe, sans imposer le chargement de catalogues ou de worklogs.
- Le legacy ne devient pas bloquant par défaut ; le strict est ciblé avant clôture.

## Décisions

- Le frontmatter porte les champs structurants et les flags documentaires `doc.*`.
- Le corps markdown porte les décisions techniques et fonctionnelles dans des sections stables.
- `check-features.sh` valide la structure frontmatter ; `check-feature-docs.sh` valide la complétude documentaire.
- Le mode strict de `check-feature-docs.sh` accepte une cible `scope/id` pour éviter de bloquer toutes les fiches legacy.

## Comportement attendu

- Chaque feature vit sous `docs_root/features/scope/id.md`.
- Le frontmatter expose `id`, `scope`, `title`, `status`, `depends_on`, `touches` (+ `touches_shared` et `progress` optionnels).
- `depends_on` autorise les arêtes cross-scope (`back/x` peut dépendre de `security/y`).
- `touches` accepte les globs ; consommé par `features-for-path.sh` pour injecter le bon contexte à l'édition.
- `doc.level` et `doc.requires.*` pilotent les modules documentaires nécessaires pour transformer la fiche en source de vérité sans imposer une fiche exhaustive par défaut.

## Contrats

- `status` ∈ {draft, active, done, deprecated, archived}.
- `id` kebab-case, unique dans le scope.
- `scope` doit matcher le dossier parent.
- Cycles dans `depends_on` interdits (cf. `cycle-detection`).
- `check-feature-docs.sh` vérifie les sections "bible feature" en warning par défaut et devient bloquant avec `--strict` ou sur une fiche `status: done`.

## Validation

- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh`
- `bash .ai/scripts/check-feature-docs.sh --strict core/feature-mesh`
- Smoke-test template pour vérifier le warning, le strict ciblé et le wrapper `ai-context.sh check-docs`.

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
- 2026-05-04 : passage au modèle "bible feature" progressif. Le template de fiche ajoute `doc.level`, `doc.requires.*`, `Résumé`, `Périmètre`, `Invariants`, `Décisions`, `Validation` et les modules conditionnels (`Droits / accès`, `Données`, `UX`, `Observabilité`, `Déploiement / rollback`). Nouveau `check-feature-docs.sh` séparé de `check-features.sh` : warnings par défaut pour préserver le legacy, `--strict` avant DONE.
- 2026-06-30 : **durcissement du heuristique `has_placeholder` de `check-feature-docs.sh`** (faux positif CI). Le motif `<[^>]+>` lisait une comparaison « x < y … z > n » (ex. ligne de clôture `ratio … < 1:1 et 0 draft gelé > 30 j` d'une fiche `done`) comme un placeholder de remplissage et bloquait le step `check-feature-docs`. Resserré en `<[^>[:space:]][^>]*>` : un placeholder a un libellé collé au `<` (`<Titre court…>`, `<product | … >`), une comparaison a un espace juste après `<`. La variante naïve « aucun espace interne » aurait cassé les vrais placeholders du template (`<Titre court de la feature>`, `<product | back | …>`) — écartée. Runtime + `.jinja` (parité), garde `tests/unit/test-feature-docs-placeholder-heuristic.sh` (régression + anti-relâche).
- 2026-06-29 : **réconciliation `id` schema↔checker** (item C2b du frame de remédiation, HANDOFF depuis `core/index-contract-v2`). Le schéma déclarait `id` en kebab-case strict (`^[a-z0-9]+(?:-[a-z0-9]+)*$`) mais `check-features.sh` tolérait l'underscore (`^[a-z0-9][a-z0-9_-]*$`) → le schéma « mentait » (audit : `foo_bar` passait le checker, violait le schéma). Checker aligné sur le schéma (ERE-équivalent `^[a-z0-9]+(-[a-z0-9]+)*$`), runtime + `.jinja`. **0 fiche sur 54 en violation** → zéro casse (vérifié). `scope` laissé tel quel (le schéma n'a pas de pattern `scope`, donc pas de divergence). Test différentiel `tests/unit/test-id-schema-checker-parity.sh` : snapshot du pattern schéma + rejet underscore + acceptation kebab → verrouille contre la re-divergence. Reste C2a (appliquer/retirer le schéma décoratif) à cadrer.
- 2026-07-03 : clôture de la fiche. C2a est clarifié par le `$comment` de `.ai/schema/feature.schema.json` et par `core/index-contract-v2` : pas de validateur JSON-Schema complet au runtime, le schéma sert de source de contrat appliquée par `check-features.sh` (required, enums, pattern `id`) dans l'éthos bash/jq/yq. Les suites éventuelles de durcissement restent routées côté `quality/feature-schema-validator` et ne bloquent plus le contrat core.
