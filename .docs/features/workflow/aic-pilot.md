---
id: aic-pilot
scope: workflow
title: Skill aic-pilot pour pilotage transverse et suivi d'audit
status: active
type: feature
description: "Ajoute un copilote produit/tech qui transforme les audits larges en registre suivi, sans créer une fausse feature globale."
depends_on:
  - workflow/intentional-skills
  - workflow/aic-frame-external-reference
touches:
  - .agents/skills/aic-pilot/**
  - .claude/skills/aic-pilot/**
  - template/.agents/skills/aic-pilot/**
  - template/.claude/skills/aic-pilot/**
  - .docs/pilots/**
  - template/{{docs_root}}/pilots/**
touches_shared:
  - .agents/skills/aic-frame/**
  - .claude/skills/aic-frame/**
  - template/.agents/skills/aic-frame/**
  - template/.claude/skills/aic-frame/**
  - .docs/frames/0000-template.md
  - template/{{docs_root}}/frames/0000-template.md.jinja
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - .ai/scripts/dogfood-update.sh
  - .ai/scripts/check-dogfood-drift.sh
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - README.md
  - copier.yml
  - tests/smoke-test.sh
  - tests/unit/test-dogfood-update-preserves-frames.sh
  - tests/unit/test-dogfood-drift-extra.sh
product: {}
external_refs: {}
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: false
    observability: false
progress:
  phase: implement
  step: "skill aic-pilot, débrayage aic-frame et registre pilots livrés ; reclassification exact-multi appliquée"
  blockers: []
  resume_hint: "lancer freshness staged/worktree, dogfood drift, check-features et smoke avant commit"
  updated: 2026-06-30
---

# Skill aic-pilot pour pilotage transverse et suivi d'audit

## Résumé

`aic-pilot` ajoute une couche de pilotage au-dessus des features. Il sert quand une demande ou un audit fait émerger plusieurs constats, bugs, corrections, décisions ou features potentielles. Le but est de suivre chaque point jusqu'à décision, exécution, validation ou abandon, sans créer une fiche feature fourre-tout.

## Objectif

Fournir un copilote produit/tech capable de challenger, trier, prioriser et suivre un ensemble de sujets transverses. Il doit comprendre le fonctionnel et le technique, poser les bonnes questions une par une, puis router chaque item vers `feature`, `fix`, `docs`, `refactor`, `diagnose`, `handoff`, `manual` ou `dropped`.

## Périmètre

### Inclus

- Nouveau skill public `aic-pilot` côté Claude et Codex.
- Template Copier associé pour les deux runtimes.
- Débrayage explicite depuis `aic-frame` quand la demande est trop large pour une intention unique.
- Artefact durable de pilotage sous `.docs/pilots/`.
- Préservation dogfood des registres datés `.docs/pilots/YYYY-MM-DD-*.md`.
- Documentation utilisateur et smoke-test de présence du skill.

### Hors périmètre

- Remplacer Linear/Jira/BMAD/Spec Kit.
- Exécuter automatiquement tous les items d'un audit en batch.
- Créer des fiches feature sans confirmation humaine.
- Autoriser une implémentation multi-scope sans HANDOFF explicite.
- Modifier le schéma frontmatter des fiches feature.

### Granularité / nommage

Cette fiche couvre le rôle de pilotage transverse. Les actions issues d'un registre gardent chacune leur propre fiche feature, fix, doc ou handoff selon leur nature.

## Invariants

- Un registre de pilotage n'est pas une feature produit.
- Un item validé comme vraie feature doit avoir sa fiche `.docs/features/<scope>/<id>.md`.
- Un item cross-scope nécessite un HANDOFF avant d'éditer hors scope primaire.
- Le pilote montre la carte des sujets mais traite une seule décision active à la fois.
- Les questions décisionnelles sont posées une par une.
- Aucun item validé ne disparaît : il doit être marqué fait, abandonné, bloqué, handoff, ou à reprendre.

## Décisions

- Nom retenu : `aic-pilot`.
- Rôle : copilote produit/tech, proche Chief of Staff, pas CEO autonome.
- `aic-frame` conserve son rôle de cadrage d'une intention précise et route vers `aic-pilot` si l'intention est un audit ou un paquet de sujets.
- Les registres durables vivent sous `.docs/pilots/`, distincts de `.docs/frames/`.
- Les registres datés sont project-owned et préservés par dogfood update/drift comme les frames datés.

## Comportement attendu

Quand `aic-pilot` est utilisé, l'agent :

- reformule le résultat attendu ;
- construit ou met à jour la carte des sujets ;
- classe les items par statut, scope probable, route et preuve attendue ;
- challenge les ambiguïtés, doublons, mélanges de scope et fausses priorités ;
- pose une seule question active ;
- acte la décision avant de passer à l'item suivant ;
- tient un registre durable si la reprise est nécessaire ;
- route les items validés vers les workflows adaptés.

## Contrats

- **Entrée** : audit général, liste de constats, demande de suivi, backlog de corrections, ou cadrage trop large détecté par `aic-frame`.
- **Sortie conversationnelle** : carte globale + question active unique + prochaine action minimale.
- **Sortie durable** : `.docs/pilots/<YYYY-MM-DD>-<slug>.md` quand le suivi dépasse la conversation courante.
- **Statuts item** : `inbox`, `triage`, `validated`, `blocked`, `handoff`, `doing`, `review`, `done`, `dropped`.
- **Routes item** : `feature`, `fix`, `docs`, `refactor`, `chore`, `diagnose`, `handoff`, `manual`, `dropped`.

## Validation

- `aic-pilot` existe dans `.agents/skills`, `.claude/skills` et leurs templates.
- `aic-frame` peut router vers `pilot`.
- Le template `.docs/pilots/0000-template.md` existe dans le repo et le rendu Copier.
- `dogfood-update` préserve les registres datés.
- `check-dogfood-drift` ignore les registres datés et détecte la dérive du template.
- `tests/smoke-test.sh` vérifie la présence du skill.

## Droits / accès

Non applicable : aucun rôle applicatif ni permission runtime.

## Données

Non applicable : pas de modèle de données applicatif. Les registres Markdown sont versionnés dans le repo.

## UX

Interaction conversationnelle :

- afficher la carte globale ;
- traiter un item actif ;
- poser une seule question décisionnelle ;
- acter la décision avant de passer au point suivant.

## Observabilité

Non applicable côté runtime. La preuve vit dans le registre `.docs/pilots/` et dans les checks.

## Déploiement / rollback

Déploiement via template Copier et dogfood runtime. Rollback : retirer le skill `aic-pilot`, la route `pilot` dans `aic-frame` et les templates `.docs/pilots/`.

## Risques

- Risque de créer un backlog bis : mitigé par une question active unique et une route obligatoire par item.
- Risque de contourner les fiches feature : mitigé par l'invariant "registre != feature".
- Risque de sur-centraliser les décisions : mitigé par la validation humaine des arbitrages structurants.

## Cross-refs

- `workflow/intentional-skills` : surface publique des skills `aic-*`.
- `workflow/aic-frame-external-reference` : contrat de cadrage durable, complété par le débrayage vers pilot.

## Historique / décisions

- 2026-06-29 — Création. Origine : besoin d'un copilote produit/tech pour audits larges, avec suivi des points validés sans créer une fiche feature globale.
