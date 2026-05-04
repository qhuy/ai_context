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
  step: "runtime dogfoodé sur Pack A lean"
  blockers: []
  resume_hint: "vérifier check-shims, dogfood drift, measure-context-size et smoke-test complet"
  updated: 2026-05-04
---

# Synchronisation dogfooding du runtime

## Objectif

Faire consommer au repo source `ai_context` la même couche runtime que celle générée par le template Copier.

## Comportement attendu

- Le repo source dispose des mêmes fichiers `.ai/agent/*`, scripts runtime, skills Claude et shims racine qu'un projet scaffoldé en profil `minimal`.
- Le repo source dogfoode `.ai/context-ignore.md` et le Pack A lean rendu par Copier.
- Les caches locaux (`.ai/.feature-index.json`, `.ai/.progress-history.jsonl`) restent hors versioning.
- Les adaptations spécifiques au repo source restent possibles quand elles sont plus strictes que le rendu downstream, notamment les workflows CI source.

## Contrats

- Rendu de référence : `copier copy --vcs-ref=HEAD` avec `project_name=ai_context`, `scope_profile=minimal`, `agents=["claude","codex"]`, `commit_language=fr`.
- Ne pas écraser les fichiers mainteneur qui ne font pas partie du runtime consommateur.
- Après sync : `check-shims`, `check-ai-references`, `check-features` et `measure-context-size` doivent passer.
- Le drift check doit distinguer runtime synchronisé et fichiers source-only conservés volontairement.
- Les scripts runtime dogfoodés restent alignés avec le template ; une injection hook ajoutée côté source doit être présente côté `template/.ai/scripts/`.

## Commandes

- `bash .ai/scripts/dogfood-update.sh` : dry-run de la synchronisation.
- `bash .ai/scripts/dogfood-update.sh --apply` : applique le rendu Copier minimal au runtime du repo source.
- `bash .ai/scripts/check-dogfood-drift.sh` : compare le runtime source avec un nouveau rendu Copier minimal.

## Cross-refs

- `core/template-engine` : source du rendu Copier.
- `workflow/agent-behavior` : couche comportementale appliquée via `.ai/agent/*` et `/aic-diagnose`.

## Historique / décisions

- 2026-05-03 : correction du drift destination-only. Le drift check signale maintenant les fichiers runtime présents côté repo source mais absents du rendu Copier, et `dogfood-update.sh --apply` utilise `rsync --delete` avec exclusions explicites pour caches et scripts source-only. Ajout d'un test unitaire dédié.
- 2026-05-03 : dogfooding des nouveaux skills intentionnels (`aic-frame`, `aic-status`, `aic-review`, `aic-ship`) dans `.claude/skills/` et mise à jour de `.ai/index.md` / `README_AI_CONTEXT.md`.
- 2026-05-03 : dogfooding de la migration des primitives procédurales vers `.ai/workflows/` ; le runtime source expose désormais 6 skills Claude publics et 8 workflows internes partagés avec Codex.
- 2026-05-03 : application dogfooding de la version courante au repo source. Choix conservateur : synchroniser le runtime généré, mais conserver les workflows CI source quand ils sont plus stricts que le rendu downstream.
- 2026-05-03 : ajout des scripts source-only `dogfood-update.sh` et `check-dogfood-drift.sh`. Ils rendent le template dans `/tmp`, synchronisent ou comparent les fichiers runtime, et ignorent explicitement les fichiers mainteneur source-only.
- 2026-05-03 : `features-for-path.sh` synchronisé runtime/template pour injecter en hook Claude les fiches directes + `depends_on`, et offrir un mode CLI `--with-docs` utilisable par Codex.
- 2026-05-03 : `ai-context.sh status` et `ai-context.sh brief <path>` dogfoodés côté repo source ; `README_AI_CONTEXT.md` documente le workflow quotidien Claude/Codex.
- 2026-05-03 : dogfooding des commandes `mission`, `document-delta`, `repair` et `ship-report` dans `.ai/scripts/ai-context.sh`; `README_AI_CONTEXT.md` documente désormais le cycle cadrage → édition JIT → doc delta → ship.
- 2026-05-03 : dogfood adapté au développement local dirty : `check-dogfood-drift.sh`, `dogfood-update.sh` et le smoke rendent maintenant depuis une copie temporaire sans `.git`, afin de comparer le runtime au template courant avant commit.
- 2026-05-04 : dogfooding de `ai-context.sh first-run` dans le runtime source et le template ; `check-dogfood-drift.sh` confirme l'alignement du rendu minimal.
- 2026-05-04 : dogfooding de `repair-copier-metadata` et `template-diff` dans `.ai/scripts/ai-context.sh` + `README_AI_CONTEXT.md`; `check-dogfood-drift.sh` confirme l'alignement du rendu minimal.
- 2026-05-04 : dogfooding du contexte lean Codex : `.ai/index.md` minimal, `.ai/context-ignore.md`, shims minces et `check-shims.sh` enrichi pour bloquer le retour de charges on-demand dans Pack A.
