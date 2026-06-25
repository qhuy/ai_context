---
id: feature-mesh-contract-alignment
scope: core
title: Alignement schema et parser du feature mesh
status: active
depends_on:
  - core/feature-mesh
  - core/index-contract-v2
  - product/product-portfolio-loop
touches:
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
  - tests/unit/test-build-feature-index-fallback.sh
  - CHANGELOG.md
  - .docs/features/core/feature-mesh-contract-alignment.md
  - .docs/features/core/feature-mesh-contract-alignment.worklog.md
touches_shared:
  - .ai/schema/feature.schema.json
  - template/.ai/schema/feature.schema.json
  - .docs/features/core/feature-mesh.md
  - .docs/features/product/product-portfolio-loop.md
product:
  initiative: product/ai-context-stability-migration
  contribution: "Aligne le parser fallback sans yq sur les champs product.portfolio définis par le schema et consommés par les rapports product."
  evidence: "Test fallback sans yq PASS, contrat index PASS, checks mesh/docs/dogfood PASS."
external_refs:
  frame: ".docs/frames/2026-05-14-ai-context-stability-migration.md"
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
  phase: review
  step: "fallback product.portfolio implémenté et testé"
  blockers: []
  resume_hint: "relire le delta core puis décider si kill_criteria doit aussi être couvert par le fallback"
  updated: "2026-05-14"
type: feature
---

# Alignement schema et parser du feature mesh

## Résumé

Le schema frontmatter expose déjà `product.portfolio.*`, mais le fallback `build-feature-index.sh` sans `yq` ne restitue pas ces champs. Cette feature aligne le parser fallback sur le contrat existant pour que les rapports product restent fiables sur les environnements minimalistes.

## Objectif

Éviter une dégradation silencieuse du scoring product quand `yq` est absent. Les projets downstream doivent obtenir le même objet `product.portfolio` minimal avec ou sans `yq`, au moins pour les champs définis par le schema.

## Périmètre

### Inclus

- Parser fallback Bash/awk de `product.portfolio.appetite`.
- Parser fallback Bash/awk de `product.portfolio.confidence`.
- Parser fallback Bash/awk de `product.portfolio.expected_impact`.
- Parser fallback Bash/awk de `product.portfolio.urgency`.
- Parser fallback Bash/awk de `product.portfolio.strategic_fit`.
- Test unitaire forçant l'absence de `yq`.
- Parité runtime/template.

### Hors périmètre

- Remplacer le fallback awk par un parser YAML complet.
- Changer le scoring de `product-portfolio.sh`.
- Rendre `yq` obligatoire.
- Redéfinir le schema `product`.
- Valider exhaustivement toutes les structures YAML arbitraires.

### Granularité / nommage

Cette fiche couvre l'alignement d'un contrat déjà public, pas une refonte générale du feature mesh.

## Invariants

- `build-feature-index.sh` doit fonctionner avec `jq` seul.
- Le fallback reste borné aux champs explicitement consommés.
- L'absence de `yq` ne doit pas changer le sens des rapports product.
- Les ajouts sont rétrocompatibles et ne changent pas `schema_version`.
- La sortie stdout reste non mutante.

## Décisions

- Garder un parser ciblé plutôt qu'introduire une dépendance YAML supplémentaire.
- Ne pas bumper `schema_version` : les champs existent déjà dans le contrat logique et le schema.
- Tester le fallback en masquant `yq` via `PATH`, sans masquer `jq`.

## Comportement attendu

- Une initiative product avec `product.portfolio.*` ressort dans l'index avec le même sous-objet en mode `yq` et en fallback.
- `product-portfolio.sh` conserve ses scores quand `yq` est absent.
- Les champs vides restent omis pour ne pas bruiter l'index.

## Contrats

- Entrée : frontmatter feature markdown.
- Sortie : `.features[].product.portfolio` dans le JSON émis par `build-feature-index.sh`.
- Champs couverts : `appetite`, `confidence`, `expected_impact`, `urgency`, `strategic_fit`.
- Compatibilité : Bash 3.2/macOS, `jq` requis, `yq` optionnel.

## Validation

- `bash tests/unit/test-build-feature-index-fallback.sh`
- `bash tests/unit/test-build-feature-index-contract.sh`
- `bash .ai/scripts/check-features.sh --no-write`
- `bash .ai/scripts/check-feature-docs.sh --strict core/feature-mesh-contract-alignment`
- `bash .ai/scripts/check-dogfood-drift.sh`

## Droits / accès

Non requis.

## Données

Pas de données applicatives. Les données concernées sont le frontmatter markdown et l'index JSON généré.

## UX

Non requis.

L'effet visible est une meilleure fiabilité des rapports product sur environnements sans `yq`.

## Observabilité

Non requis.

La preuve attendue est le test unitaire forçant le fallback.

## Déploiement / rollback

- Déploiement : `copier update` propage le parser amélioré.
- Migration : aucune action utilisateur attendue.
- Rollback : revenir à l'ancien parser fallback ; les champs product portfolio redeviendraient des valeurs par défaut dans les rapports sans `yq`.

## Risques

- Le parser awk reste volontairement limité et ne couvre pas tout YAML valide.
- Un frontmatter très exotique peut encore nécessiter `yq`.
- Une logique trop ambitieuse rendrait le fallback plus fragile que le problème initial.

## Cross-refs

- `core/feature-mesh` : définit le frontmatter et le schema.
- `core/index-contract-v2` : stabilise la sortie JSON de l'index.
- `product/product-portfolio-loop` : consomme `product.portfolio.*` pour le scoring.

## Historique / décisions

- 2026-05-14 : création après la tranche P0 read-only/index ; le prochain écart fiable identifié est la divergence `yq` vs fallback sur `product.portfolio`.
- 2026-05-14 : implémentation du parser fallback ciblé pour `product.portfolio.*` et test unitaire forçant l'absence de `yq`.
