---
id: pre-turn-reminder
scope: workflow
title: Injection contextuelle au début de chaque tour Claude
status: active
depends_on:
  - core/feature-index-cache
  - core/graph-aware-injection
touches:
  - template/.ai/scripts/pre-turn-reminder.sh.jinja
  - template/.ai/scripts/features-for-path.sh.jinja
  - template/.ai/reminder.md.jinja
progress:
  phase: review
  step: "features-for-path injecte fiches directes + depends_on avant écriture"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-05-07
---

# Pre-turn reminder

## Objectif

À chaque prompt utilisateur, injecter automatiquement (hook `UserPromptSubmit`) le bon contexte : règles + inventaire des features actives + reverse deps + `reminder.md`. L'agent n'a plus à deviner ni à recharger.

## Comportement attendu

- Sortie : bloc texte injecté avant le prompt utilisateur.
- Filtrage : status `active` par défaut (override : `AI_CONTEXT_SHOW_ALL_STATUS=1`).
- Focus : `AI_CONTEXT_FOCUS=<scope|id>` réduit l'inventaire (cf. `graph-aware-injection`).
- Format : texte ou JSON selon `AI_CONTEXT_OUTPUT` (couvert par smoke-test).
- i18n : reminder FR/EN selon `commit_language`.
- Avant écriture Claude : `features-for-path.sh` injecte les fiches directes liées au path + leurs `depends_on`, avec budget borné, sans gonfler le reminder par tour.

## Contrats

- Latence cible : < 200 ms sur mesh < 100 features.
- Si index manquant : rebuild auto puis injection.
- Aucun appel réseau.

## Cross-refs

Première brique du flux invisible. Complétée par `features-for-path` en `PreToolUse`, puis `auto-worklog` (capture les éditions) et `git-hooks` (valide au commit).

## Historique / décisions

- v0.6 : filtre status active.
- v0.8 : i18n.
- v0.9 : graph-aware focus.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; aucun changement de format ou de budget d'injection.
- 2026-05-03 : `features-for-path.sh` passe de rappel de liste à injection juste-à-temps bornée des fiches concernées et de leurs dépendances. Le reminder reste inchangé pour préserver le coût tokens par prompt.
