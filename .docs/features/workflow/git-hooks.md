---
id: git-hooks
scope: workflow
title: Git hooks (commit-msg + post-checkout)
status: active
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
touches:
  - template/.githooks/**
  - template/.ai/scripts/check-commit-features.sh.jinja
progress:
  phase: review
  step: "bootstrap dog-fooding (v0.9 historique)"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-04-24
---

# Git hooks

## Objectif

Faire respecter le mesh au moment du commit et tenir l'index à jour entre branches.

## Comportement attendu

- `commit-msg` : valide Conventional Commits ; si type `feat:`, exige qu'au moins un fichier `<docs_root>/features/**` soit touché par le commit.
- `post-checkout` : rebuild de `.feature-index.json` (le mesh peut diverger entre branches).
- Activation : `git config core.hooksPath .githooks && chmod +x .githooks/*` (étape 2 du `_message_after_copy`).

## Contrats

- Bloquant pour `feat:` sans feature touchée.
- Non bloquant pour `chore`, `docs`, `fix` (warning si message hors Conventional).
- Langue du message imposée par `commit_language` (fr/en).

## Cross-refs

Côté CI : `ci-guard` rejoue `check-features.sh` même si le hook local a été contourné (`--no-verify`).

## Historique / décisions

- Heuristique d'extraction du message commit (`-m "..."`, heredoc) : si format atypique, validation passe silencieusement. Limitation tracée dans PROJECT_STATE.md.
