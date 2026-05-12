---
id: subagent-contract
scope: workflow
title: Contrat subagents multi-agent
status: active
depends_on:
  - workflow/intentional-skills
touches:
  - .ai/rules/workflow.md
  - template/.ai/rules/workflow.md.jinja
  - .ai/workflows/subagent-contract.md
  - template/.ai/workflows/subagent-contract.md.jinja
  - README.md
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
touches_shared: []
product: {}
external_refs:
  claude_code_subagents: "https://code.claude.com/docs/en/sub-agents"
  codex_subagents: "https://developers.openai.com/codex/subagents"
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: review
  step: "contrat documenté, validations PASS"
  blockers: []
  resume_hint: "prêt à review ; vérifier le wording multi-agent si besoin"
  updated: 2026-05-12
---

# Contrat subagents multi-agent

## Résumé

Formaliser un contrat local pour l'usage des subagents Claude, Codex ou équivalents afin de préserver un scope primaire unique, des écritures disjointes et des handoffs explicites.

## Objectif

Les runtimes modernes permettent de déléguer du travail à plusieurs agents. Sans contrat repo-local, cette capacité peut augmenter les collisions, mélanger les scopes et rendre les reprises moins fiables. Cette feature fixe les règles communes.

## Périmètre

### Inclus

- Définir les rôles autorisés pour les agents délégués.
- Décrire les limites de parallélisme, de write-set et de restitution.
- Relier tout changement cross-scope à un HANDOFF explicite.
- Documenter le comportement attendu dans les workflows et la documentation utilisateur.

### Hors périmètre

- Ajouter un orchestrateur externe ou une file de jobs.
- Imposer une implémentation spécifique à Claude ou Codex.
- Modifier les scripts de feature mesh ou la quality gate.
- Changer Pack A ou charger des skills par défaut.

### Granularité / nommage

Cette fiche couvre le contrat de délégation multi-agent. Les hooks Codex et la politique MCP vivent dans des fiches séparées car leurs risques et validations diffèrent.

## Invariants

- Un seul scope primaire reste actif dans la session source.
- Un agent worker reçoit un write-set explicite et disjoint.
- Un agent explorer est lecture seule.
- Tout changement de scope passe par HANDOFF avant édition.
- La sortie d'un agent délégué doit être exploitable sans relire tout son contexte.

## Décisions

- Le contrat est agent-agnostique : il décrit les responsabilités, pas les APIs runtime.
- Les limites de fanout doivent privilégier la réduction de risque plutôt que le débit maximal.
- Les agents délégués ne peuvent pas remplacer la feature doc, le worklog ou les checks.

## Comportement attendu

Avant de déléguer, l'agent principal identifie le scope, le résultat attendu, les fichiers autorisés et les risques. Après délégation, il intègre les résultats, ferme les agents inutiles et documente les décisions dans la fiche concernée.

## Contrats

- Entrée worker : objectif borné, paths autorisés, fichiers interdits, checks attendus.
- Entrée explorer : question précise, lecture seule, aucune mutation.
- Sortie minimale : résumé, fichiers lus/modifiés, risques, checks lancés ou non lancés, next step.
- Cross-scope : bloc HANDOFF obligatoire avant toute écriture dans le scope cible.

## Validation

- `bash .ai/scripts/check-shims.sh`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/subagent-contract`
- `bash .ai/scripts/measure-context-size.sh`

## Risques

- Un contrat trop détaillé pourrait gonfler Pack A s'il est placé au mauvais endroit.
- Des règles trop spécifiques à un runtime casseraient la compatibilité multi-agent.
- Un fanout trop permissif augmenterait les collisions d'édition.

## Cross-refs

`workflow/intentional-skills` fournit la surface utilisateur commune. Cette feature ajoute le contrat d'exécution quand cette surface déclenche un travail délégué.

## Historique / décisions

- 2026-05-12 : création suite à la veille officielle Claude Code / OpenAI Codex sur subagents.
