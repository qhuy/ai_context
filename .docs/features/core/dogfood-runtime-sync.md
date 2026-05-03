---
id: dogfood-runtime-sync
scope: core
title: Synchronisation dogfooding du runtime ai_context
status: active
depends_on:
  - core/template-engine
  - workflow/agent-behavior
touches:
  - .ai/**
  - .claude/settings.json
  - .claude/skills/**
  - .githooks/**
  - tests/unit/test-dogfood-drift-extra.sh
  - AGENTS.md
  - CLAUDE.md
  - README_AI_CONTEXT.md
  - .docs/FEATURE_TEMPLATE.md
progress:
  phase: implement
  step: "détecter et supprimer le runtime obsolète destination-only"
  blockers: []
  resume_hint: "vérifier shims, features, measure-context-size et smoke ciblé après sync"
  updated: 2026-05-03
---

# Synchronisation dogfooding du runtime

## Objectif

Faire consommer au repo source `ai_context` la même couche runtime que celle générée par le template Copier.

## Comportement attendu

- Le repo source dispose des mêmes fichiers `.ai/agent/*`, scripts runtime, skills Claude et shims racine qu'un projet scaffoldé en profil `minimal`.
- Les caches locaux (`.ai/.feature-index.json`, `.ai/.progress-history.jsonl`) restent hors versioning.
- Les adaptations spécifiques au repo source restent possibles quand elles sont plus strictes que le rendu downstream, notamment les workflows CI source.

## Contrats

- Rendu de référence : `copier copy --vcs-ref=HEAD` avec `project_name=ai_context`, `scope_profile=minimal`, `agents=["claude","codex"]`, `commit_language=fr`.
- Ne pas écraser les fichiers mainteneur qui ne font pas partie du runtime consommateur.
- Après sync : `check-shims`, `check-ai-references`, `check-features` et `measure-context-size` doivent passer.
- Le drift check doit distinguer runtime synchronisé et fichiers source-only conservés volontairement.

## Commandes

- `bash .ai/scripts/dogfood-update.sh` : dry-run de la synchronisation.
- `bash .ai/scripts/dogfood-update.sh --apply` : applique le rendu Copier minimal au runtime du repo source.
- `bash .ai/scripts/check-dogfood-drift.sh` : compare le runtime source avec un nouveau rendu Copier minimal.

## Cross-refs

- `core/template-engine` : source du rendu Copier.
- `workflow/agent-behavior` : couche comportementale appliquée via `.ai/agent/*` et `/aic-diagnose`.

## Historique / décisions

- 2026-05-03 : correction du drift destination-only. Le drift check signale maintenant les fichiers runtime présents côté repo source mais absents du rendu Copier, et `dogfood-update.sh --apply` utilise `rsync --delete` avec exclusions explicites pour caches et scripts source-only. Ajout d'un test unitaire dédié.
- 2026-05-03 : application dogfooding de la version courante au repo source. Choix conservateur : synchroniser le runtime généré, mais conserver les workflows CI source quand ils sont plus stricts que le rendu downstream.
- 2026-05-03 : ajout des scripts source-only `dogfood-update.sh` et `check-dogfood-drift.sh`. Ils rendent le template dans `/tmp`, synchronisent ou comparent les fichiers runtime, et ignorent explicitement les fichiers mainteneur source-only.
