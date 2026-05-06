---
id: project-overlay-stable
scope: core
title: Overlay projet stable
status: active
depends_on: []
touches:
  - "copier.yml"
  - "template/.ai/index.md.jinja"
  - "template/.ai/OWNERSHIP.md.jinja"
  - "template/.ai/templates/project-overlay/README.md.jinja"
  - "template/README_AI_CONTEXT.md.jinja"
  - ".ai/index.md"
  - ".ai/OWNERSHIP.md"
  - ".ai/templates/project-overlay/README.md"
  - ".ai/scripts/check-dogfood-drift.sh"
  - ".ai/scripts/dogfood-update.sh"
  - "docs/upgrading.md"
  - "README.md"
  - "tests/**"
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
  phase: implement
  step: "implémentation overlay projet"
  blockers: []
  resume_hint: "Vérifier que .ai/project reste project-owned, optionnel et ignoré par les checks de drift."
  updated: 2026-05-07
---

# Overlay projet stable

## Résumé

Ajouter un overlay projet optionnel sous `.ai/project/**` pour isoler les règles locales des fichiers gérés par le template.

## Objectif

Permettre aux repos consommateurs de conserver durablement leurs règles locales lors des mises à jour Copier, sans déplacer les règles génériques existantes.

## Périmètre

### Inclus

- Chargement minimal de `.ai/project/index.md` depuis l'index principal si le fichier existe.
- Documentation ownership template/project.
- Exemple de structure project overlay.
- Checks adaptés pour ne pas signaler `.ai/project/**` comme dérive template.

### Hors périmètre

- Migration automatique de règles existantes.
- Obligation de créer `.ai/project/index.md`.
- Déplacement des règles génériques `.ai/rules/**`.

## Invariants

- `.ai/project/**` est project-owned.
- Les agents ne chargent pas récursivement `.ai/project/**`.
- Un repo sans overlay garde le comportement actuel.

## Décisions

- L'exemple vit sous `.ai/templates/project-overlay/README.md`, pas directement sous `.ai/project`, pour éviter de rendre l'overlay présent par défaut.
- Copier est configuré avec `_skip_if_exists` sur `.ai/project/**` comme garde-fou anti-écrasement.

## Comportement attendu

Si `.ai/project/index.md` existe, l'agent le lit après les règles générales et avant les règles de scope. Sinon, aucune action ni erreur.

## Contrats

- Entrée overlay : `.ai/project/index.md`.
- Ownership projet : tout `.ai/project/**`.
- Ownership template : `.ai/index.md`, `.ai/rules/**`, `.ai/workflows/**`, `.ai/scripts/**`, `.ai/templates/**`.

## Validation

- `check-shims` passe sans `.ai/project/index.md`.
- `check-ai-references` accepte des liens vers des fichiers existants sous `.ai/project/**`.
- Le drift dogfood ignore les fichiers projet sous `.ai/project/**`.

## Historique / décisions

Créé pour stabiliser les règles locales des repos consommateurs pendant `copier update`.
