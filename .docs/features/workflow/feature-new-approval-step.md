---
id: feature-new-approval-step
scope: workflow
title: Validation explicite avant création et développement feature
status: active
depends_on:
  - workflow/feature-granularity
touches:
  - .ai/workflows/feature-new.md
  - .agents/skills/aic-feature-new/workflow.md
  - template/.ai/workflows/feature-new.md.jinja
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
  phase: review
  step: "proposition validable dogfoodée dans le template"
  blockers: []
  resume_hint: "Relire la propagation template/runtime puis clôturer si les checks passent."
  updated: "2026-05-04"
---

# Validation explicite avant création et développement feature

## Résumé

Modifier le workflow de création de feature pour qu'il propose d'abord une synthèse actionnable, puis attende validation humaine avant d'écrire la fiche ou d'orienter vers le développement.

## Objectif

Éviter que `/aic-feature-new` donne l'impression de partir directement en développement. Le skill doit cadrer l'intention, exposer les tâches logiques, impacts, risques et conseils éventuels, puis demander une validation explicite.

## Périmètre

### Inclus

- Procédure canonique `.ai/workflows/feature-new.md`.
- Workflow du skill `.agents/skills/aic-feature-new/workflow.md`.
- Format de synthèse avant écriture.
- Règle de STOP tant que l'utilisateur n'a pas validé.

### Hors périmètre

- Modification de la quality gate.
- Automatisation de la validation utilisateur.
- Changement des scripts de génération d'index ou de checks.
- Exécution automatique du développement après création.

### Granularité / nommage

- Cette fiche couvre le comportement du workflow `feature-new`, pas les autres skills de livraison.

## Invariants

- Lean context conservé : la proposition s'appuie sur les lectures déjà obligatoires et des recherches ciblées si nécessaire.
- Pas d'écriture de fiche sans validation explicite.
- Pas de développement applicatif dans `aic-feature-new`.
- Les règles anti fourre-tout restent appliquées avant la proposition.

## Décisions

- Ajouter une phase `Proposition avant écriture` entre le cadrage et la création de fiche.
- La proposition doit contenir : cible feature, tâches logiques, impacts, risques, validations et conseils éventuels.
- La validation doit être explicite (`go`, `ok`, `oui`, ou correction utilisateur).

## Comportement attendu

Quand l'utilisateur demande une nouvelle feature, l'agent propose d'abord ce qu'il va créer et pourquoi. Il attend ensuite la validation avant de créer `.docs/features/<scope>/<id>.md` et son worklog. Après création, il indique la suite sans démarrer le développement applicatif.

## Contrats

- `feature-new` ne crée rien tant que la proposition n'est pas validée.
- Le format de proposition est stable et court.
- Une correction utilisateur ramène à la phase de cadrage, puis génère une nouvelle proposition.

## Validation

- `bash .ai/scripts/build-feature-index.sh --write`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh workflow/feature-new-approval-step`

## Droits / accès

Non requis : workflow documentaire uniquement.

## Données

Non requis : aucune donnée applicative impactée.

## UX

Non requis : aucune interface applicative impactée.

## Observabilité

Non requis : aucun signal runtime impacté.

## Déploiement / rollback

Rollback par revert documentaire des deux workflows modifiés.

## Risques

- Proposition trop lourde : le skill redeviendrait pénible pour les petites features.
- Validation trop floue : l'agent pourrait interpréter un échange comme un feu vert.

## Cross-refs

- `workflow/feature-granularity` : la proposition doit inclure la vérification anti fourre-tout.

## Historique / décisions

2026-05-04 : création pour ajouter une étape de proposition validable à `feature-new`.
2026-05-04 : phase de proposition avant écriture ajoutée au workflow canonique et au skill.
2026-05-04 : phase propagée au template Copier et dogfood runtime aligné.
