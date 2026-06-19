---
id: agent-behavior
scope: workflow
title: Couche comportementale agent légère
status: active
depends_on:
  - workflow/claude-skills
touches:
  - .ai/agent/**
  - .ai/index.md
  - .claude/skills/aic-diagnose/**
  - template/.ai/agent/**
  - template/.ai/index.md.jinja
  - template/.claude/skills/aic-diagnose/**
touches_shared:
  - copier.yml
  - README.md
progress:
  phase: implement
  step: "couche agent sortie du Pack A Codex"
  blockers: []
  resume_hint: "vérifier check-shims, measure-context-size et smoke-test après changement Pack A"
  updated: 2026-06-19
---

# Couche comportementale agent légère

## Résumé

Une couche de qualité comportementale (posture, contrat d'initiative, style de réponse) vit sous `.ai/agent/` et reste chargée **on-demand** : elle améliore proactivité, diagnostic et sortie orientée prochaine action sans gonfler le contexte injecté à chaque tour. Côté Claude elle s'expose via le skill `/aic-diagnose` ; côté Codex via la lecture naturelle de `.ai/agent/*`.

## Objectif

Ajouter une couche de qualité comportementale inspirée de BOS sans transformer `ai_context` en prompt monolithique.

La couche doit améliorer la proactivité, l'écoute, le diagnostic, la capacité à prendre position, et la sortie orientée prochaine action tout en gardant le chargement juste-à-temps.

## Périmètre

### Inclus

- Les fichiers comportementaux sous `template/.ai/agent/` : `posture.md.jinja`, `initiative-contract.md.jinja`, `response-style.md.jinja`, et leur rendu dogfoodé `.ai/agent/*`.
- Le skill Claude `/aic-diagnose` (`SKILL.md.jinja` + `workflow.md.jinja`) et son rendu `.claude/skills/aic-diagnose/*`.
- La déclaration **on-demand** de la couche dans `.ai/index.md` et l'équivalent naturel exposé à Codex hors Pack A obligatoire.
- Le contrat de clôture de tâche porté par `response-style.md` (format adaptatif compact/structuré).

### Hors périmètre

- L'injection à chaque tour : `.ai/reminder.md` (et `template/.ai/reminder.md.jinja`) reste inchangé, la couche n'y est jamais ajoutée.
- La logique procédurale des intentions `frame/status/diagnose/review/ship`, portée par `.ai/workflows/` et la feature `workflow/claude-skills`.
- Les ajouts transverses `README.md` / `copier.yml`, suivis en `touches_shared` et non bloquants pour cette fiche.

## Invariants

- Les règles comportementales vivent dans `.ai/agent/`, jamais dans les shims racine (`CLAUDE.md`, `AGENTS.md`).
- La couche n'est jamais chargée par défaut dans Pack A : son chargement reste explicitement on-demand (diagnostic, posture ou style demandés).
- `measure-context-size.sh` ne compte pas cette couche au démarrage tant que le reminder ne la référence pas.
- Parité Claude/Codex : le diagnostic produit via `/aic-diagnose` et via la lecture `.ai/agent/*` + prompt naturel reste équivalent.
- Le rendu Copier minimal et le dogfooding du repo source restent synchronisés (`.ai/agent/*`, `.ai/index.md`, `.claude/skills/aic-diagnose/*`).

## Comportement attendu

- Les règles comportementales vivent dans `template/.ai/agent/`, pas dans les shims racine.
- `.ai/index.md` déclare cette couche comme **on-demand** : elle n'est jamais chargée par défaut dans Pack A.
- `.ai/reminder.md` reste inchangé pour ne pas augmenter l'injection à chaque tour.
- Un skill Claude `/aic-diagnose` permet de produire un diagnostic stable quand une tâche ou feature est bloquée.
- Codex n'a pas besoin de skill : il lit `AGENTS.md` puis `.ai/index.md`, et ne charge `.ai/agent/*` que si la tâche demande explicitement diagnostic, posture ou style.

## Contrats

- Fichiers agent :
  - `template/.ai/agent/posture.md.jinja`
  - `template/.ai/agent/initiative-contract.md.jinja`
  - `template/.ai/agent/response-style.md.jinja`
- Skill Claude :
  - `template/.claude/skills/aic-diagnose/SKILL.md.jinja`
  - `template/.claude/skills/aic-diagnose/workflow.md.jinja`
- Message Copier : `/aic-diagnose` est listé parmi les commandes rares exposées.
- Compatibilité Codex : `.ai/index.md` garde l'équivalent naturel de `/aic-diagnose` hors Pack A obligatoire.
- Mesure contexte : l'absence de modification de `template/.ai/reminder.md.jinja` garantit que `measure-context-size.sh` ne charge pas cette couche à chaque tour.
- Clôture de tâche : `response-style.md` définit un format adaptatif compact/structuré pour livrer résultat, validations, risques, recommandation et prochaine action sans imposer un tableau systématique.

## Décisions

- Couche éclatée en **trois fichiers séparés** (posture / initiative / style) plutôt qu'un prompt monolithique, pour rester lisible et chargeable à la carte.
- Pack A **référence** la couche mais le reminder ne l'**injecte pas** : on assume le coût d'une lecture explicite contre le gain de contexte par défaut.
- Pas de skill côté Codex : il applique le même diagnostic via `.ai/agent/*` + prompt naturel, ce qui préserve la parité sans dupliquer la mécanique.
- Surface Claude/Codex reformulée autour d'**intentions** (`frame/status/diagnose/review/ship`) et logique procédurale déplacée sous `.ai/workflows/`, plutôt que des skills procéduraux dans les shims.
- Lean Codex assumé : `.ai/agent/*` sort du Pack A et reste disponible on-demand ; le démarrage ne charge plus les fichiers agent.

## Validation

- `check-shims.sh` : les shims racine ne contiennent pas la couche comportementale.
- `measure-context-size.sh` : le poids de contexte au démarrage n'augmente pas (couche absente du reminder et du Pack A).
- `smoke-test.sh` / `copier copy` : le template rend `.ai/agent/*` et le skill `aic-diagnose` sans erreur Jinja.
- `check-dogfood-drift.sh` : `.ai/agent/*`, `.ai/index.md` et `.claude/skills/aic-diagnose/*` restent alignés sur le rendu Copier minimal.

## Cross-refs

- `workflow/claude-skills` : le nouveau skill suit la convention `SKILL.md.jinja` + `workflow.md.jinja`.

## Historique / décisions

- 2026-05-03 — Création de la couche comportementale en trois fichiers séparés et d'un skill `/aic-diagnose`. Décision explicite : Pack A référence la couche, le reminder ne l'injecte pas. Le message Copier expose `/aic-diagnose` sans ajouter d'étape obligatoire.
- 2026-05-03 — Compatibilité Claude/Codex explicitée : Claude peut utiliser le skill `/aic-diagnose`; Codex applique le même diagnostic via `.ai/agent/*` et un prompt naturel.
- 2026-05-03 — Dogfooding appliqué au repo source : `.ai/agent/*`, `.ai/index.md` et le skill rendu `.claude/skills/aic-diagnose/*` sont synchronisés depuis le rendu Copier minimal.
- 2026-05-03 — `README.md` passe en `touches_shared` : la documentation utilisateur reste visible en review, mais les ajouts transverses README ne rendent plus cette fiche bloquante.
- 2026-05-03 — `.ai/index.md` reformule la surface Claude/Codex autour d'intentions (`frame/status/diagnose/review/ship`) plutôt que de skills procéduraux.
- 2026-05-03 — La logique procédurale est déplacée sous `.ai/workflows/`, ce qui conserve la parité Claude/Codex sans gonfler les shims ni le reminder.
- 2026-05-03 — `response-style.md` ajoute un contrat de clôture de tâche : format compact pour les petites réponses, format structuré avec tableau quand le périmètre/les checks/les risques le justifient, et recommandation assumée + prochaine action minimale.
- 2026-05-03 — `.ai/index.md` documente le lien entre posture agent et initiatives product sans injecter cette couche dans le reminder.
- 2026-05-04 — `.ai/index.md` recadre le product loop comme traceability/governance compatible artefacts externes (`external_refs`), sans augmenter le reminder.
- 2026-05-04 — Lean Codex : `.ai/agent/*` sort du Pack A. La couche reste disponible on-demand pour diagnostic/posture/style, mais le démarrage ne charge plus les fichiers agent.
