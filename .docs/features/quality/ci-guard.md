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
  step: "freshness documentaire rafraîchie après dogfood"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-05-03
---

# CI guard

## Objectif

Rejouer en CI les validations critiques pour rattraper les contournements locaux (`git commit --no-verify`, hooks désactivés).

## Comportement attendu

- Trigger : `push` + `pull_request`.
- Workflow généré : matrix `ubuntu-latest` + `macos-latest`, install jq/yq/shellcheck → `check-shims.sh` → `check-features.sh`.
- `check-feature-docs.sh` est exécuté en mode warning par défaut pour détecter les fiches faibles sans bloquer les projets legacy.
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
- 2026-04-27 : correctif template workflow : expressions GitHub Actions `${{ ... }}` échappées avec `{% raw %}` dans `template/.github/workflows/ai-context-check.yml.jinja` pour éviter `jinja2.exceptions.UndefinedError: 'matrix' is undefined` pendant `copier copy`.
- 2026-04-27 : correctif template scripts : toutes les expansions Bash `${#...}` dans les fichiers `template/.ai/scripts/*.jinja` sont protégées par `{% raw %}` pour éviter `jinja2.exceptions.TemplateSyntaxError: Missing end of comment tag` au `copier copy`.
- 2026-04-28 : `template-smoke-test.yml` étendu en matrix `ubuntu-latest` + `macos-latest` (au lieu d'Ubuntu seul). Install cross-platform de copier avec gestion du `--break-system-packages` sur macOS (PEP 668), shellcheck + jq cross-platform, yq pin v4.44.3, déclencheurs étendus à `.ai/scripts/**` et `.ai/schema/**` pour rattraper les changements dogfoodés. Ajout `workflow_dispatch` pour permettre un relancement manuel. Cible : prévenir les régressions Copier/Jinja avant tag de release.
- 2026-05-04 : ajout de `check-feature-docs.sh` au workflow généré et dogfoodé en mode non strict. Objectif : signaler la dette documentaire "bible feature" sans casser les projets existants.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; aucun changement de contrat CI.
