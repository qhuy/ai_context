---
id: ci-guard
scope: quality
title: Workflow GitHub Actions (check-shims + check-features)
status: active
depends_on:
  - quality/smoke-test
  - quality/cycle-detection
touches:
  - .github/workflows/ai-context-check.yml
  - .github/workflows/template-smoke-test.yml
  - template/.github/workflows/ai-context-check.yml.jinja
progress:
  phase: review
  step: "bootstrap dog-fooding (v0.9 historique)"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-04-24
---

# CI guard

## Objectif

Rejouer en CI les validations critiques pour rattraper les contournements locaux (`git commit --no-verify`, hooks désactivés).

## Comportement attendu

- Trigger : `push` + `pull_request`.
- Workflow généré : matrix `ubuntu-latest` + `macos-latest`, install jq/yq/shellcheck → `check-shims.sh` → `check-features.sh`.
- Workflow template repo : install jq/yq/copier → `tests/smoke-test.sh`.
- Opt-in via `enable_ci_guard: true` (default) du copier.yml.

## Contrats

- Échec bloque le merge si protection de branche activée côté repo cible.
- Le smoke-test complet tourne dans le repo template uniquement, pas dans les projets scaffoldés.

## Cross-refs

Filet de sécurité au-dessus de `git-hooks` (qui peuvent être contournés localement).

## Historique / décisions

- Workflow généré volontairement minimal : pas d'install de Python, pas de cache, pas de matrix. Vise < 30s d'exécution.
- 2026-04-24 : ajout de `.github/workflows/template-smoke-test.yml` pour valider le rendu Copier complet du template dans le repo source.
- 2026-04-27 : durcissement CI : `yq` pin en `v4.44.3` + étape `shellcheck .ai/scripts/*.sh` dans les workflows check et smoke.
- 2026-04-27 : extension matrix du workflow check sur `ubuntu-latest` et `macos-latest` (install cross-platform jq/yq/shellcheck).
- 2026-04-27 : `shellcheck` exécuté en mode `-S error` pour bloquer uniquement les erreurs critiques et éviter les faux négatifs CI sur warnings non bloquants.
