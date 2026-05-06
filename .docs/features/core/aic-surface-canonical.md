---
id: aic-surface-canonical
scope: core
title: Surface utilisateur canonique aic
status: active
depends_on: []
touches:
  - README.md
  - README_AI_CONTEXT.md
  - CHANGELOG.md
  - PROJECT_STATE.md
  - MIGRATION.md
  - CONTRIBUTING.md
  - AUDIT_2026-05-06.md
  - docs/upgrading.md
  - copier.yml
  - template/README_AI_CONTEXT.md.jinja
  - template/.ai/scripts/aic.sh.jinja
  - .ai/scripts/aic.sh
  - .ai/scripts/product-status.sh
  - .ai/scripts/product-portfolio.sh
  - template/.ai/scripts/product-status.sh.jinja
  - template/.ai/scripts/product-portfolio.sh.jinja
  - template/.claude/skills/aic-*/**
  - template/.agents/skills/aic-*/**
  - tests/smoke-test.sh
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
  step: "surface aic implementee et smoke complet PASS"
  blockers: []
  resume_hint: "Relire le delta puis faire le commit dedie du sous-chantier si le scope convient."
  updated: "2026-05-06"
---

# Surface utilisateur canonique aic

## Résumé

Cette feature unifie la surface publique autour de `aic` et des skills `aic-*`.
Les anciens verbes publics exposes via `ai-context` ne doivent plus apparaitre
comme interface utilisateur recommandee.

## Objectif

Reduire l'ambiguite entre Claude, Codex et les agents non-hookes. Un utilisateur
doit voir une seule taxonomie : `aic`, `aic-frame`, `aic-status`,
`aic-diagnose`, `aic-document-feature`, `aic-review`, `aic-ship`.

## Périmètre

### Inclus

- Supprimer la presentation publique des anciens verbes `ai-context` quand ils
  doublonnent la surface `aic`.
- Aligner README, etat projet, changelog, migration, messages Copier et aide
  runtime/template.
- Ajouter une verification smoke qui detecte la reintroduction d'anciens noms
  publics.
- Garder les scripts internes uniquement comme implementation, pas comme UX
  utilisateur.

### Hors périmètre

- Refonte BOS-like de `aic-frame`.
- Ajout du champ `verification:` au frontmatter feature.
- MCP local, plugin Claude Code, site docs ou benchmark public.

### Granularité / nommage

Cette fiche couvre la migration de surface utilisateur, pas tous les chantiers
P0/P1 de la roadmap.

## Invariants

- `.ai/` reste la source unique.
- Le langage utilisateur canonique est `aic`, pas `ai-context`.
- Aucun alias legacy public ne doit etre conserve pour les anciens verbes.
- Les commits restent en francais.

## Décisions

- Migration breaking propre : suppression nette des anciens noms publics au lieu
  d'aliases de compatibilite.
- `aic-document-feature` fait partie du noyau officiel.
- Le wrapper runtime/template est renomme de `ai-context.sh` vers `aic.sh`.
  Aucun alias legacy n'est rendu dans le scaffold.
- Les anciens noms ne sont conserves que comme references historiques ou table de
  migration explicite, pas comme surface active.

## Comportement attendu

Un utilisateur qui lit le README, le message post-copy ou l'aide runtime voit la
surface `aic` comme entree principale. Les commandes historiques de cadrage,
brief, document-delta et ship-report ne sont plus presentees comme chemins
utilisateur.

## Contrats

- Surface publique canonique :
  - `aic`
  - `aic-frame`
  - `aic-status`
  - `aic-diagnose`
  - `aic-document-feature`
  - `aic-review`
  - `aic-ship`
- Les workflows internes `.ai/workflows/*` restent la source procedurale
  partagee.

## Validation

- `bash .ai/scripts/check-shims.sh`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh core/aic-surface-canonical`
- `bash tests/smoke-test.sh`
- `bash .ai/scripts/check-ai-references.sh`
- `bash .ai/scripts/check-feature-coverage.sh`
- `bash .ai/scripts/measure-context-size.sh`
- Assertion smoke : les anciens noms publics ne reapparaissent pas dans les
  surfaces utilisateur.

## Risques

- Des references historiques peuvent rester dans `CHANGELOG.md` par nature.
  Elles doivent rester cantonnees a l'historique, pas a la documentation active.
- Supprimer des commandes runtime existantes peut casser des utilisateurs
  downstream ; la migration doit etre documentee dans `MIGRATION.md`.

## Cross-refs

Aucune dependance frontmatter.

## Historique / décisions

- 2026-05-06 : decision de faire une migration breaking sans alias legacy, avec
  un commit dedie au sous-chantier.
