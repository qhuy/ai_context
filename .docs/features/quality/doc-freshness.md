---
id: doc-freshness
scope: quality
title: Fraicheur documentaire des features
status: active
depends_on: []
touches:
  - .ai/scripts/check-feature-freshness.sh
  - .ai/scripts/check-commit-features.sh
  - tests/unit/test-check-feature-freshness.sh
  - tests/unit/test-review-delta-shared.sh
  - .ai/quality/QUALITY_GATE.md
  - .github/workflows/ai-context-check.yml
  - template/.ai/scripts/check-feature-freshness.sh.jinja
  - template/.ai/scripts/check-commit-features.sh.jinja
  - template/.ai/quality/QUALITY_GATE.md.jinja
  - template/.github/workflows/ai-context-check.yml.jinja
progress:
  phase: implement
  step: "staged freshness robuste par feature candidate"
  blockers: []
  resume_hint: "verifier le mode --staged --strict pendant les commits multi-features"
  updated: 2026-05-03
---

# Fraicheur documentaire des features

## Objectif

Garantir qu'une evolution de comportement couverte par une feature ne puisse pas etre committee sans trace documentaire explicite.

## Comportement attendu

- En commit local, les changements stages sur des fichiers couverts par `touches:` doivent etre accompagnes d'une modification de la fiche feature ou de son worklog.
- En CI / quality gate, un rapport signale les features dont le code couvert est plus recent que la fiche ou le worklog.
- Le controle bloquant reste base sur `touches:`. `touches_shared:` sert au reporting/review et ne déclenche pas l'obligation de fiche/worklog staged.

## Contrats

- Script expose : `.ai/scripts/check-feature-freshness.sh`.
- Modes :
  - `--staged --strict` bloque si un fichier stage matche une feature sans doc/worklog stage.
  - `--warn` rapporte les features potentiellement stale sans bloquer.
  - `--strict` bloque sur les features stale detectees dans l'historique Git.
- Le hook `commit-msg` appelle le mode staged strict apres validation Conventional Commits.

## Cross-refs

Aucune dependance de feature declaree.

## Historique / decisions

- 2026-05-03 : correction d'une regression multi-feature : un fichier couvert par plusieurs fiches exige maintenant une fiche/worklog stage pour chaque feature candidate. Ajout d'un test unitaire dédié.
- 2026-05-03 : introduction de `touches_shared` comme surface non bloquante pour la fraîcheur staged. Objectif : réduire le bruit sur les fichiers transverses (`tests/smoke-test.sh`, CHANGELOG, états projet) sans perdre la visibilité dans les rapports.
- 2026-05-03 : simplification du controle staged. Le script pre-calcule les fiches/worklogs stages au lieu de rescanner tous les fichiers stages pour chaque feature candidate, ce qui evite un crash local silencieux sur gros commits dogfood.
- 2026-04-29 : creation du filet de securite doc/code freshness pour completer `check-features.sh`, qui valide la structure mais pas la maintenance semantique.
