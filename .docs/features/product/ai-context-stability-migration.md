---
id: ai-context-stability-migration
scope: product
title: Stabilisation et migration ai_context
status: done
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
  - workflow/intentional-skills
  - product/product-portfolio-loop
touches:
  - .docs/features/product/ai-context-stability-migration.md
  - .docs/features/product/ai-context-stability-migration.worklog.md
  - .docs/frames/2026-05-14-ai-context-stability-migration.md
  - docs/upgrading.md
  - CHANGELOG.md
touches_shared:
  - README.md
  - README_AI_CONTEXT.md
  - PROJECT_STATE.md
product:
  type: initiative
  bet: "Stabiliser les contrats runtime, workflows et migrations de ai_context augmente la confiance des projets existants sans réduire la compatibilité multi-agent."
  target_user: "Mainteneurs de projets ayant déjà scaffoldé ai_context et mainteneurs du template ai_context"
  success_metric: "Les changements read-only/index/workflows disposent d'un chemin de migration documenté, de tests branchés et d'une compatibilité Copier validée."
  leading_indicator: "Les features techniques liées déclarent product.initiative, documentent la migration downstream et passent leurs checks ciblés."
  decision_state: commit
  next_decision_date: 2026-06-28
  kill_criteria:
    - "Le programme devient une refonte globale sans découpage livrable."
    - "Les changements cassent copier update ou les hooks existants sans migration documentée."
    - "Les features techniques dupliquent BMAD, Spec Kit, Linear ou Jira au lieu de les relier."
  portfolio:
    appetite: medium
    confidence: high
    expected_impact: high
    urgency: high
    strategic_fit: high
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
  phase: done
  step: "initiative clôturée — P0 read-only/index/fallback/OKF livré (v0.13)"
  blockers: []
  resume_hint: "clôturée ; le durcissement continu est porté par .docs/frames/2026-06-28-audit-strategique-remediation.md, pas par une initiative stabilisation perpétuelle"
  updated: 2026-06-28
type: feature
---

# Stabilisation et migration ai_context

## Résumé

Initiative chapeau pour stabiliser `ai_context` après les audits par scope, en priorisant les contrats runtime, la fiabilité des traitements, la rationalisation des workflows et la compatibilité des projets déjà scaffoldés.

## Objectif

Organiser les changements nécessaires sans les mélanger dans une refonte globale. Chaque chantier technique doit être relié à cette initiative, documenter ses impacts downstream, et fournir un chemin de migration vérifiable.

## Périmètre

### Inclus

- Contrat read-only des scripts de diagnostic et de reporting.
- Contrat de l'index feature : format, déterminisme, cache, timestamp, fallback.
- Alignement du feature mesh : schema, checker, parser fallback, docs.
- Rationalisation des workflows et skills redondants.
- Réorganisation des tests CI/smoke/unitaires.
- Durcissement de la boucle product quand elle dépend de l'index ou du cache.
- Documentation de migration pour les projets existants.

### Hors périmètre

- Réécrire tous les scripts en une seule livraison.
- Supprimer brutalement des commandes publiques ou hooks existants.
- Remplacer BMAD, Spec Kit, Linear, Jira ou GitHub.
- Créer une roadmap parallèle dans `.docs/features/product/`.
- Modifier les comportements runtime sans feature technique dédiée.

### Granularité / nommage

Cette fiche est une initiative de coordination. Les changements exécutables doivent vivre dans des features séparées, par exemple :

- `quality/read-only-checks-contract`
- `core/index-contract-v2`
- `core/feature-mesh-contract-alignment`
- `workflow/surface-rationalization`
- `quality/test-suite-reorg`
- `product/product-loop-hardening`

## Invariants

- Un diagnostic ne doit pas modifier le repo sans option explicite.
- Une migration downstream doit être prévue avant tout changement de contrat public.
- Les scripts locaux déterministes restent la source de garantie ; les agents et MCP restent des couches d'orchestration.
- Claude, Codex, autres agents et humains doivent converger via les mêmes checks versionnés.
- Le scope product relie et décide ; il ne possède pas directement tous les fichiers techniques des features liées.

## Décisions

- Lancer un programme de stabilisation en plusieurs features plutôt qu'une refonte globale.
- Commencer par le couple read-only/index, car il conditionne la confiance dans les audits et checks.
- Utiliser `product.initiative: product/ai-context-stability-migration` dans les futures features techniques liées.
- Garder la compatibilité downstream par phases : warning, nouveau défaut, suppression/verrouillage.
- Déclasser ou fusionner les features historiques seulement après avoir préservé l'information utile dans les fiches cibles ou docs.

## Comportement attendu

Pour un mainteneur de `ai_context` :

- Les priorités de stabilisation sont visibles et reliées à des features techniques.
- Les décisions `KEEP / IMPROVE / SIMPLIFY / MERGE / DOWNGRADE_TO_DOC` sont traçables.
- Les changements de contrat ne sont pas livrés sans plan de migration.

Pour un projet downstream :

- `copier update` reste viable.
- Les hooks et scripts existants disposent d'une période de compatibilité ou d'une dépréciation claire.
- Les commandes de diagnostic peuvent être lancées sans modifier le repo par surprise.

## Contrats

- Toute feature technique liée doit déclarer :
  - `product.initiative: product/ai-context-stability-migration`
  - un impact migration dans sa section `Déploiement / rollback`
  - les checks de compatibilité downstream prévus
- Les changements de CLI ou comportement script doivent avoir :
  - un mode legacy ou un warning temporaire si nécessaire
  - une entrée `CHANGELOG.md`
  - une note `docs/upgrading.md` si le comportement visible change
- Les changements Copier doivent être testés sur les profils pertinents : `minimal`, `backend`, `fullstack`, agents `claude` et `codex` au minimum.

## Validation

- `bash .ai/scripts/check-ai-references.sh`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh product/ai-context-stability-migration`
- Checks ciblés des features liées avant chaque clôture.
- Smoke Copier après modification de template ou hooks.
- Vérification de migration : docs upgrade/changelog présentes quand un contrat public change.

## Droits / accès

Non requis pour cette initiative produit.

Les éventuels impacts d'accès aux fichiers, hooks, CI ou outils externes doivent être documentés dans les features techniques liées si elles changent les droits d'exécution ou les prérequis locaux.

## Données

Non requis comme modèle applicatif.

Les données concernées sont des artefacts repo-local : fiches feature, worklogs, index généré, traces ignorées, docs de migration et résultats de checks. Toute évolution du contrat de `.ai/.feature-index.json` doit être portée par une feature dédiée.

## UX

Non requis comme interface utilisateur applicative.

L'expérience concernée est la developer experience : commandes explicites, messages de warning, upgrade path, compatibilité hooks et lisibilité des docs. Les changements UX concrets doivent être décrits dans les features liées.

## Observabilité

Non requis comme observabilité runtime applicative.

Les signaux attendus sont les checks locaux, les tests CI et les rapports de migration. Les métriques expérimentales de contexte restent hors gate tant qu'elles ne sont pas stabilisées.

## Déploiement / rollback

- Release N : ajouter les nouveaux modes et warnings sans retirer les anciens comportements.
- Release N+1 : rendre les diagnostics non mutants par défaut, avec mutation explicite.
- Release N+2 : retirer ou verrouiller les chemins dépréciés après migration documentée.
- Rollback : conserver les commandes legacy ou flags temporaires jusqu'à ce que les projets downstream aient un chemin de transition validé.

## Risques

- Le programme peut devenir trop large si les features techniques ne sont pas découpées.
- Le coût de compatibilité temporaire peut retarder la simplification.
- Les scripts product et quality partagent l'index ; un mauvais contrat d'index peut propager des erreurs à plusieurs surfaces.
- La rationalisation workflow peut perdre des détails historiques si les fusions ne conservent pas les décisions utiles.

## Cross-refs

- `core/feature-mesh` : contrat des fiches et mécanisme de traceability.
- `core/feature-index-cache` : source commune pour hooks, checks, product et reports.
- `workflow/intentional-skills` : surface agent publique à préserver.
- `product/product-portfolio-loop` : règle d'initiative product et liens vers artefacts externes.

## Historique / décisions

- 2026-05-14 : deux passes d'audit ont confirmé que les priorités ne sont pas une analyse supplémentaire mais un programme de stabilisation/migration.
- 2026-05-14 : décision de commencer par read-only/cache/index avant les nettoyages documentaires généraux.
- 2026-05-14 : décision de ne pas supprimer de fonctionnalité sans période de compatibilité downstream.
- 2026-06-28 : **clôture (done)**. Le périmètre P0 est livré en v0.13 (`quality/read-only-checks-contract`, `core/index-contract-v2`, `core/feature-mesh-contract-alignment`, fallback portfolio, profil OKF). Critère de sortie retenu : une « stabilisation » ne peut rester `active` en permanence pendant qu'on empile des features — elle se clôt quand son P0 est shippé. Le durcissement continu (audit stratégique 2026-06-28) est porté par `.docs/frames/2026-06-28-audit-strategique-remediation.md`, pas par une initiative perpétuelle. Critères mesurables du cycle suivant (cf. frame, bac D) : ratio `fix:feat(quality)` < 1:1 et 0 draft gelé > 30 j.
