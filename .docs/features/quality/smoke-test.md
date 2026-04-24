---
id: smoke-test
scope: quality
title: Smoke-test end-to-end (27 assertions)
status: active
depends_on:
  - core/template-engine
  - core/feature-mesh
  - workflow/git-hooks
touches:
  - tests/**
progress:
  phase: review
  step: "bootstrap dog-fooding (v0.9 historique)"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-04-24
---

# Smoke-test

## Objectif

Vérifier en un script que la chaîne complète tient : `copier copy` → check-shims → check-features → reminder text+json → commit-msg Conventional → features-for-path → cycles → coverage → focus graph → i18n → auto-worklog.

## Comportement attendu

- Lancement local : `bash tests/smoke-test.sh`.
- 27 assertions, exit non-zéro à la première qui casse.
- Crée un projet jetable dans `/tmp`, applique le template, exerce les scripts.

## Contrats

- Couverture : end-to-end + tests ciblés sur le matching `touches:` dans `_lib.sh` et `docs_root=docs`.
- Idempotent : 2 lancements consécutifs sans nettoyage manuel.
- Exécutable sur macOS bash 3.2 et Linux bash 5.x.

## Cross-refs

Rejoué automatiquement par `ci-guard` sur push/PR.

## Historique / décisions

- v0.7.2 : ajout assertion sur escaping JSON (régression).
- v0.9 : ajout assertion sur `AI_CONTEXT_FOCUS` graph + i18n FR/EN.
- 2026-04-24 : ajout [18/27] — vérifie que le pre-commit `auto-progress.sh` bascule `spec → implement`, écrit le snapshot dans `.progress-history.jsonl`, crée la ligne `auto-progress` dans le worklog, et est idempotent (second commit sans re-bump). HANDOFF reçu depuis `workflow/conversational-skills` (chantier 4). Révélé au passage un bug fixé : `auto-progress.sh` ne créait pas le worklog si absent — correctif appliqué dans `.ai/scripts/` + `template/.ai/scripts/`, cross-ref tracée dans `core/template-engine` Historique.
- 2026-04-24 : ajout [26/27] — vérifie le helper `_lib.sh path_matches_touch` sur matching exact, dossier, glob `**` et faux positifs proches.
- 2026-04-24 : ajout [27/27] — scaffold avec `docs_root=docs`, puis vérifie `check-features`, `features-for-path` et l'index JSON sur `docs/features`.
