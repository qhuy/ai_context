---
id: ci-guard
scope: quality
title: Workflow GitHub Actions (check-shims + check-features)
status: active
depends_on:
  - quality/smoke-test
  - quality/cycle-detection
touches:
  - template/.github/workflows/ai-context-check.yml.jinja
---

# CI guard

## Objectif

Rejouer en CI les validations critiques pour rattraper les contournements locaux (`git commit --no-verify`, hooks désactivés).

## Comportement attendu

- Trigger : `push` + `pull_request`.
- Étapes : install jq/yq → `check-shims.sh` → `check-features.sh`.
- Opt-in via `enable_ci_guard: true` (default) du copier.yml.

## Contrats

- Échec bloque le merge si protection de branche activée côté repo cible.
- N'exécute pas le smoke-test complet (trop lent en CI sur petit projet) — gardé en local.

## Cross-refs

Filet de sécurité au-dessus de `git-hooks` (qui peuvent être contournés localement).

## Historique / décisions

- Volontairement minimal : pas d'install de Python, pas de cache, pas de matrix. Vise < 30s d'exécution.
