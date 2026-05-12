---
id: targeted-regression-coverage
scope: quality
title: Couverture ciblee des regressions critiques
status: done
depends_on:
  - quality/index-lock-contract
touches:
  - tests/unit/**
  - tests/smoke-test.sh
  - .ai/scripts/build-feature-index.sh
  - .ai/scripts/check-commit-features.sh
  - template/.ai/scripts/check-commit-features.sh.jinja
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/scripts/check-feature-docs.sh
  - .ai/scripts/check-feature-coverage.sh
  - copier.yml
touches_shared:
  - .docs/features/quality/index-lock-contract.md
product: {}
external_refs:
  ai_debate: "/Users/huy/Documents/Perso/ai_debate/.ai-debate/discussions/0013-qualite-code-ai-context.md#q4"
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
  step: ""
  blockers: []
  resume_hint: "Feature cloturee le 2026-05-12."
  updated: 2026-05-12
---

# Couverture ciblee des regressions critiques

## Résumé

Cette feature transforme les risques identifies dans `0013/Q4` en tests cibles, plus rapides a diagnostiquer qu'un smoke global quand une regression precise apparait.

## Objectif

Reduire les angles morts autour des scripts du feature mesh et du rendu Copier : fallback sans `yq`, parsing de messages de commit complexes, verrouillage concurrent, drift runtime/template `.jinja`, et modes d'adoption `lite`, `standard`, `strict`.

## Périmètre

### Inclus

- Ajouter ou renforcer des tests reproductibles sur les cas non couverts ou trop enfouis dans le smoke.
- Garder les tests compatibles Bash 3.2/macOS.
- Acter explicitement le statut Windows.
- Conserver les tests smoke existants comme couverture bout-en-bout.

### Hors périmètre

- Modifier les contrats runtime sauf bug revele par les tests.
- Revoir toute la strategie CI.
- Ajouter une dependance de test non deja requise par le projet.

### Granularité / nommage

La feature couvre une passe de durcissement qualite issue de l'audit `0013`. Les corrections fonctionnelles decouvertes pendant cette passe doivent rester minimales ou ouvrir une feature separee si elles depassent le test.

## Invariants

- Les tests doivent echouer clairement sur le cas qu'ils protegent.
- Les scripts restent portables macOS/Linux.
- Windows n'est pas declare supporte par ces scripts shell ; la decision doit etre documentee explicitement.
- Les changements de tests doivent rester relies a un risque Q4 identifiable.

## Décisions

- Le scope Windows est hors support direct pour les scripts shell ; la compatibilite attendue est macOS/Linux avec Bash.
- Les tests unitaires dedies sont preferes quand ils peuvent isoler le comportement sans relancer tout Copier.
- Le smoke reste la preuve d'integration pour les profils et modes Copier.

## Comportement attendu

Un mainteneur doit pouvoir lancer les tests cibles et identifier rapidement si une regression touche le parsing fallback, le guard de commit, le lock, le dogfood runtime/template, ou le rendu des modes d'adoption.

## Contrats

- `build-feature-index.sh` doit produire un index JSON valide sans `yq`.
- `check-commit-features.sh` doit gerer les messages de commit multi-lignes ou documenter clairement les limites maintenues.
- `with_index_lock` ne doit pas executer de commande protegee sans verrou.
- `check-dogfood-drift.sh` doit detecter les divergences runtime/template `.jinja`.
- Les modes `lite`, `standard`, `strict` doivent garder leurs garanties de rendu.

## Validation

- Tests unitaires cibles ajoutes ou renforces.
- `bash tests/smoke-test.sh` reste vert.
- Checks :

  ```bash
  bash .ai/scripts/check-features.sh
  bash .ai/scripts/check-feature-docs.sh --strict quality/targeted-regression-coverage
  bash .ai/scripts/check-dogfood-drift.sh
  git diff --check
  ```

## Droits / accès

Ce changement ne modifie aucun droit ni controle d'acces.

## Données

Ce changement ne modifie aucun modele de donnees.

## UX

Ce changement n'expose pas de parcours utilisateur.

## Observabilité

La sortie des tests doit identifier le cas de regression en echec.

## Déploiement / rollback

Aucun deploiement progressif n'est requis. Le rollback retirerait uniquement des tests et reduirait la couverture qualite.

## Risques

- Des tests trop larges peuvent dupliquer le smoke et ralentir la boucle locale.
- Des tests trop etroits peuvent manquer le drift template/runtime.

## Cross-refs

- `quality/index-lock-contract` : Q1 a deja corrige le contrat de lock ; Q4 doit consolider la couverture autour de ce risque et des autres points d'audit.
- Discussion source : `/Users/huy/Documents/Perso/ai_debate/.ai-debate/discussions/0013-qualite-code-ai-context.md`, item Q4.

## Historique / décisions

- 2026-05-12 : creation depuis l'item Q4 du plan AI Debate `0013`.
