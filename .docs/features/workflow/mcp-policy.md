---
id: mcp-policy
scope: workflow
title: Politique MCP minimale
status: active
depends_on:
  - workflow/subagent-contract
touches:
  - .ai/rules/workflow.md
  - template/.ai/rules/workflow.md.jinja
  - .ai/workflows/mcp-policy.md
  - template/.ai/workflows/mcp-policy.md.jinja
  - README.md
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
touches_shared: []
product: {}
external_refs:
  claude_code_mcp: "https://code.claude.com/docs/en/mcp"
  codex_mcp: "https://developers.openai.com/codex/mcp"
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
  step: "politique MCP documentée, validations PASS"
  blockers: []
  resume_hint: "prêt à review ; garder MCP opt-in"
  updated: 2026-05-12
---

# Politique MCP minimale

## Résumé

Définir une politique MCP prudente pour ai_context : aucun serveur par défaut, allowlist explicite, pas de secrets et pas d'injection de contexte externe non revue.

## Objectif

MCP peut enrichir les agents mais augmente le risque de contexte non fiable, d'exfiltration ou de couplage à un outil. Cette feature fixe une politique minimale compatible Claude, Codex et autres agents.

## Périmètre

### Inclus

- Décrire quand activer un serveur MCP.
- Définir les conditions d'allowlist, de secrets et de scope.
- Rendre les contrats d'entrée/sortie explicites.
- Préserver un fallback sans MCP.

### Hors périmètre

- Ajouter un serveur MCP au template.
- Définir un catalogue d'outils MCP recommandé.
- Remplacer les scripts repo-native par des outils MCP.
- Charger les docs MCP dans Pack A.

### Granularité / nommage

Cette fiche couvre la politique d'activation MCP. Les hooks ou subagents qui consomment MCP restent gouvernés par leurs propres fiches.

## Invariants

- Aucun MCP n'est requis pour utiliser ai_context.
- Un serveur MCP doit être explicitement choisi et documenté.
- Les secrets ne sont jamais stockés dans `.ai/` ou le template.
- Un agent doit pouvoir expliquer quelles données un outil MCP lit ou écrit.

## Décisions

- MCP reste opt-in et on-demand.
- Les scripts `.ai/scripts/*` restent la première source de checks déterministes.
- Toute donnée externe récupérée via MCP doit être traitée comme non fiable tant qu'elle n'est pas vérifiée.

## Comportement attendu

Quand une tâche nécessite MCP, l'agent annonce l'outil, la raison, les données lues/écrites et le fallback si l'outil est absent. Si l'outil est trop large ou non vérifiable, la tâche revient aux scripts locaux ou à une demande de confirmation.

## Contrats

- Entrée : objectif, serveur MCP, outil appelé, permissions attendues.
- Sortie : données utilisées, source, effet produit, fallback si indisponible.
- Interdit : secret en clair, activation globale par défaut, remplacement d'un check déterministe par un appel MCP opaque.

## Validation

- Vérifier que Pack A ne mentionne pas de chargement MCP obligatoire : `bash .ai/scripts/check-shims.sh`.
- Vérifier la fiche : `bash .ai/scripts/check-feature-docs.sh --strict workflow/mcp-policy`.
- Vérifier les références : `bash .ai/scripts/check-ai-references.sh`.

## Risques

- Couplage trop fort à Claude ou Codex.
- Contexte externe injecté sans provenance claire.
- Secrets accidentellement versionnés.

## Cross-refs

`workflow/subagent-contract` définit comment encadrer les agents qui pourraient appeler MCP. `workflow/codex-hooks-parity` interdit d'utiliser MCP comme gate non déterministe.

## Historique / décisions

- 2026-05-12 : création suite à la veille officielle Claude Code / OpenAI Codex sur MCP.
