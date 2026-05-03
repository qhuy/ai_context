---
id: agent-behavior
scope: workflow
title: Couche comportementale agent légère
status: active
depends_on:
  - workflow/claude-skills
touches:
  - copier.yml
  - .ai/agent/**
  - .ai/index.md
  - .claude/skills/aic-diagnose/**
  - template/.ai/agent/**
  - template/.ai/index.md.jinja
  - template/.claude/skills/aic-diagnose/**
touches_shared:
  - README.md
progress:
  phase: implement
  step: "contrat de clôture de réponse ajouté"
  blockers: []
  resume_hint: "vérifier check-features + mesure contexte après intégration"
  updated: 2026-05-03
---

# Couche comportementale agent légère

## Objectif

Ajouter une couche de qualité comportementale inspirée de BOS sans transformer `ai_context` en prompt monolithique.

La couche doit améliorer la proactivité, l'écoute, le diagnostic, la capacité à prendre position, et la sortie orientée prochaine action tout en gardant le chargement juste-à-temps.

## Comportement attendu

- Les règles comportementales vivent dans `template/.ai/agent/`, pas dans les shims racine.
- `.ai/index.md` référence cette couche au début d'une session ou d'une tâche importante.
- `.ai/reminder.md` reste inchangé pour ne pas augmenter l'injection à chaque tour.
- Un skill Claude `/aic-diagnose` permet de produire un diagnostic stable quand une tâche ou feature est bloquée.
- Codex n'a pas besoin de skill : il lit `AGENTS.md` puis `.ai/index.md`, charge `.ai/agent/*`, et applique le même format de diagnostic en langage naturel.

## Contrats

- Fichiers agent :
  - `template/.ai/agent/posture.md.jinja`
  - `template/.ai/agent/initiative-contract.md.jinja`
  - `template/.ai/agent/response-style.md.jinja`
- Skill Claude :
  - `template/.claude/skills/aic-diagnose/SKILL.md.jinja`
  - `template/.claude/skills/aic-diagnose/workflow.md.jinja`
- Message Copier : `/aic-diagnose` est listé parmi les commandes rares exposées.
- Compatibilité Codex : `.ai/index.md` documente l'équivalent naturel de `/aic-diagnose`.
- Mesure contexte : l'absence de modification de `template/.ai/reminder.md.jinja` garantit que `measure-context-size.sh` ne charge pas cette couche à chaque tour.
- Clôture de tâche : `response-style.md` définit un format adaptatif compact/structuré pour livrer résultat, validations, risques, recommandation et prochaine action sans imposer un tableau systématique.

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
