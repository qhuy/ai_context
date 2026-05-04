---
id: intentional-skills
scope: workflow
title: Skills intentionnels pour cadrage, status, review et ship
status: active
depends_on:
  - workflow/claude-skills
  - workflow/agent-behavior
touches:
  - .ai/workflows/**
  - template/.ai/workflows/**
  - .claude/skills/aic-frame/**
  - .claude/skills/aic-status/**
  - .claude/skills/aic-review/**
  - .claude/skills/aic-ship/**
  - template/.claude/skills/aic-frame/**
  - template/.claude/skills/aic-status/**
  - template/.claude/skills/aic-review/**
  - template/.claude/skills/aic-ship/**
  - .ai/index.md
  - template/.ai/index.md.jinja
  - copier.yml
  - template/README_AI_CONTEXT.md.jinja
  - README_AI_CONTEXT.md
touches_shared:
  - README.md
  - PROJECT_STATE.md
  - CHANGELOG.md
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "intentions préservées sans chargement Pack A large"
  blockers: []
  resume_hint: "valider smoke-test et check-shims après toute évolution de .ai/index.md"
  updated: 2026-05-04
---

# Skills intentionnels

## Objectif

Réduire la friction des skills Claude en exposant des intentions utilisateur plutôt que les primitives internes du feature mesh.

Le vocabulaire utilisateur devient :

- cadrer ;
- voir le status ;
- diagnostiquer ;
- review ;
- ship.

Les primitives procédurales vivent sous `.ai/workflows/`. Elles restent disponibles pour Claude et Codex, mais ne sont plus exposées comme skills Claude invocables par l'utilisateur.

## Comportement attendu

- `/aic-frame` cadre une tâche/feature : objectif, position, spécificités métier, spécificités techniques, plan, validation, points à confirmer.
- `/aic-status` reprend le contexte : features en cours, blockers, stale, delta courant, prochaine action.
- `/aic-review` analyse le delta : risques, features directes/liées, doc/freshness, checks.
- `/aic-ship` prépare la sortie : quality gate, freshness staged, evidence, risques, commit proposé.
- `.ai/workflows/*` porte les procédures internes : création/reprise/update/handoff/audit/gate/done/guardrails.

## Contrats

- Aucun de ces skills ne doit élargir Pack A ; les procédures et skills restent on-demand.
- `/aic-frame` ne code pas et ne crée pas de fiche sans confirmation.
- `/aic-ship` ne commit/push jamais sans confirmation explicite.
- Les équivalents Codex restent en langage naturel : "cadre cette feature", "montre le status", "review le delta", "prépare le ship".
- Claude et Codex s'appuient sur les mêmes procédures internes `.ai/workflows/`, sans dupliquer de logique dans les shims.

## Cross-refs

- `workflow/claude-skills` : catalogue public vs interne.
- `workflow/agent-behavior` : posture attendue, prise de position, prochaine action.

## Historique / décisions

- 2026-05-03 : création des skills intentionnels `/aic-frame`, `/aic-status`, `/aic-review`, `/aic-ship`. Décision initiale : ne plus présenter les primitives procédurales comme UX recommandée.
- 2026-05-03 : retrait des primitives procédurales de `.claude/skills/` et déplacement sous `.ai/workflows/` pour préserver la logique interne tout en gardant la parité Claude/Codex.
- 2026-05-03 : `README_AI_CONTEXT.md` et son template ajoutent un workflow quotidien orienté intention : `status`, `brief <path>`, `review`, `doctor/check`. Objectif : rendre l'UX Codex explicite sans ajouter de skill procédural.
- 2026-05-03 : workflow quotidien étendu avec `mission`, `document-delta`, `repair` et `ship-report`. Objectif : proposer une surface naturelle Claude/Codex sans réintroduire les skills procéduraux.
- 2026-05-03 : `ai-context.sh` ajoute les commandes intentionnelles `product-status`, `product-portfolio` et `product-review` pour piloter les initiatives sans nouveau skill obligatoire.
- 2026-05-04 : ajout de l'intention `first-run` pour guider le premier usage après scaffold sans obliger Claude/Codex à invoquer un skill procédural.
- 2026-05-04 : ajout des intentions CLI `repair-copier-metadata` et `template-diff` pour rendre le cycle update Copier pilotable en langage naturel, sans nouveau skill utilisateur.
- 2026-05-04 : lean Codex confirmé : `.ai/index.md` garde les intentions comme vocabulaire d'usage, mais ne charge plus quality gate, `.ai/agent/*` ni workflows au démarrage.
