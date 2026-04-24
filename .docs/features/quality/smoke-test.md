---
id: smoke-test
scope: quality
title: Smoke-test end-to-end (24 assertions)
status: active
depends_on:
  - core/template-engine
  - core/feature-mesh
  - workflow/git-hooks
touches:
  - tests/**
---

# Smoke-test

## Objectif

Vérifier en un script que la chaîne complète tient : `copier copy` → check-shims → check-features → reminder text+json → commit-msg Conventional → features-for-path → cycles → coverage → focus graph → i18n → auto-worklog.

## Comportement attendu

- Lancement local : `bash tests/smoke-test.sh`.
- 24 assertions, exit non-zéro à la première qui casse.
- Crée un projet jetable dans `/tmp`, applique le template, exerce les scripts.

## Contrats

- Couverture : end-to-end uniquement. Pas de tests unitaires sur `_lib.sh`, parsing YAML, DFS cycles (dette tracée).
- Idempotent : 2 lancements consécutifs sans nettoyage manuel.
- Exécutable sur macOS bash 3.2 et Linux bash 5.x.

## Cross-refs

Rejoué automatiquement par `ci-guard` sur push/PR.

## Historique / décisions

- v0.7.2 : ajout assertion sur escaping JSON (régression).
- v0.9 : ajout assertion sur `AI_CONTEXT_FOCUS` graph + i18n FR/EN.
