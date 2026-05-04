---
id: feature-granularity
scope: workflow
title: Granularité anti fourre-tout des fiches feature
status: done
depends_on: []
touches:
  - .ai/workflows/feature-new.md
  - .agents/skills/aic-feature-new/workflow.md
  - .docs/FEATURE_TEMPLATE.md
touches_shared: []
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: done
  step: ""
  blockers: []
  resume_hint: "feature clôturée le 2026-05-04"
  updated: "2026-05-04"
---

# Granularité anti fourre-tout des fiches feature

## Résumé

Ajouter une règle visible au moment de créer ou choisir une fiche feature afin d'éviter les fiches génériques par domaine métier.

## Objectif

Une fiche feature doit représenter une intention livrable cohérente. La procédure de création doit pousser l'agent à choisir un identifiant lié au livrable, à l'étape du flux et aux validations attendues, plutôt qu'un slug de domaine trop large.

## Périmètre

### Inclus

- Procédure `feature-new`.
- Workflow du skill `/aic-feature-new`.
- Template feature, avec une note compacte de granularité.
- Exemples OK / à éviter autour du domaine `passage`.

### Hors périmètre

- Quality gate automatisée bloquante.
- Renommage des fiches existantes.
- Documentation d'architecture propre au flux `passage`.

## Invariants

- Lean context conservé : la règle doit rester dans les fichiers déjà lus pendant la création de fiche.
- Une fiche feature reste liée à un livrable et à une validation, pas à un domaine extensible.
- Une vue globale doit vivre dans une doc d'architecture ou d'overview non active.

## Décisions

- Formaliser la règle dans `feature-new` et dans le workflow du skill pour couvrir les deux entrées.
- Ajouter une note dans le template afin que la règle reste visible après création.
- Ne pas ajouter de contrôle fragile dans les scripts.

## Comportement attendu

Pour une demande liée aux passages, l'agent choisit une fiche fine comme `passage_partner_polling`, `passage_client_grpc_retrieval` ou `passage_webhook_restitution`, et refuse de créer une fiche active générique `passage`.

## Contrats

- La procédure de création contient un check anti fourre-tout avant création ou réutilisation.
- Le template rappelle quand réutiliser une fiche existante et quand en créer une nouvelle.
- Les exemples distinguent les fiches OK des slugs à éviter.

## Validation

- `bash .ai/scripts/build-feature-index.sh --write`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh workflow/feature-granularity`

## Droits / accès

Non requis : la feature modifie uniquement la documentation et les procédures internes.

## Données

Non requis : aucune donnée applicative, migration ou rétention impactée.

## UX

Non requis : aucune interface utilisateur applicative modifiée.

## Observabilité

Non requis : aucun comportement runtime ou signal d'exploitation modifié.

## Déploiement / rollback

Non requis : rollback par revert documentaire des fichiers modifiés.

## Risques

- Règle trop longue : elle serait ignorée dans le flux de création.
- Règle trop stricte : elle pourrait bloquer des petites évolutions proches qui partagent réellement le même DONE.

## Cross-refs

Aucune dépendance déclarée.

## Historique / décisions

2026-05-04 : cadrage initial pour expliciter la granularité anti fourre-tout.
2026-05-04 : règle ajoutée aux procédures de création et au template, sans quality gate automatisée.
2026-05-04 : feature clôturée après quality gate complète.
2026-05-04 : impact documentaire revu pour `workflow/feature-new-approval-step` ; la règle anti fourre-tout reste inchangée.
