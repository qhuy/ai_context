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
  phase: done
  step: "R1 livré : reverse_deps=0 et JIT depends_on couvert"
  blockers: []
  resume_hint: "R1 clos ; prochaine action recommandée : R2 ranking tracker des features jamais touchées"
  updated: 2026-07-02
type: feature
---

# Pre-turn reminder

## Résumé

Hook `UserPromptSubmit` qui injecte automatiquement le contexte juste-à-temps avant chaque prompt (règles, inventaire des features actives, `reminder.md`), complété par `features-for-path.sh` en `PreToolUse` qui pousse les fiches concernées par le path édité et leurs `depends_on`. Objectif : que l'agent reçoive le bon contexte sans le deviner ni le recharger manuellement, sans charger tout le graphe à chaque tour.

## Objectif

À chaque prompt utilisateur, injecter automatiquement (hook `UserPromptSubmit`) le contexte global strictement utile : règles + inventaire des features actives + `reminder.md`. Le graphe détaillé reste juste-à-temps via `features-for-path.sh` quand un path est connu.

## Périmètre

### Inclus

- Le hook `UserPromptSubmit` (`pre-turn-reminder.sh`) : assemblage règles + inventaire features `active` + `reminder.md`.
- L'injection `PreToolUse` (`features-for-path.sh`) : fiches directes liées au path édité + leurs `depends_on`, avec budget borné.
- Le filtrage par status, le focus (`AI_CONTEXT_FOCUS`), le format de sortie (`AI_CONTEXT_OUTPUT`) et l'i18n du `reminder.md` (FR/EN).

### Hors périmètre

- La construction et la mise en cache de l'index (portée par `core/feature-index-cache`).
- La logique de sélection par graphe / focus elle-même (portée par `core/graph-aware-injection`).
- La capture des éditions (`auto-worklog`) et la validation au commit (`git-hooks`).

## Comportement attendu

- Sortie : bloc texte injecté avant le prompt utilisateur.
- Filtrage : status `active` par défaut (override : `AI_CONTEXT_SHOW_ALL_STATUS=1`).
- Focus : `AI_CONTEXT_FOCUS=<scope|id>` réduit l'inventaire (cf. `graph-aware-injection`).
- Format : texte ou JSON selon `AI_CONTEXT_OUTPUT` (couvert par smoke-test).
- i18n : reminder FR/EN selon `commit_language`.
- Avant écriture Claude : `features-for-path.sh` injecte les fiches directes liées au path + leurs `depends_on`, avec budget borné, sans gonfler le reminder par tour.

## Invariants

- L'injection reste read-only : aucun appel réseau, aucune écriture hors rebuild de l'index si absent.
- Seules les features `active` sont inventoriées par défaut (sauf override `AI_CONTEXT_SHOW_ALL_STATUS=1`).
- Le coût tokens par prompt reste borné : le `reminder.md` ne grossit pas avec le mesh, les reverse deps ne sont pas injectées à chaque tour, et `features-for-path.sh` respecte un budget plafonné (fiches directes + `depends_on` uniquement).
- La langue du `reminder.md` suit `commit_language` (FR/EN), sans divergence entre les deux variantes.

## Contrats

- Latence cible : < 200 ms sur mesh < 100 features.
- Si index manquant : rebuild auto puis injection.
- Aucun appel réseau.

## Décisions

- Deux hooks distincts plutôt qu'un seul : `UserPromptSubmit` porte le contexte global (règles + inventaire), `PreToolUse` porte le contexte ciblé sur le path édité. Cela évite de tout charger à chaque prompt.
- `features-for-path.sh` est passé d'un simple **rappel de liste** à une **injection juste-à-temps bornée** des fiches concernées et de leurs dépendances, pour rester aligné sur la règle "contexte juste-à-temps" sans gonfler le reminder.
- Les dépendances inverses ne sont plus injectées par défaut dans `UserPromptSubmit` : elles dominaient le coût par tour et sont remplacées par l'injection JIT des fiches directes + `depends_on` dès qu'un path est connu.
- Le filtrage `active` est le défaut assumé ; voir tout le mesh est un opt-in explicite (`AI_CONTEXT_SHOW_ALL_STATUS`).
- Le focus (`AI_CONTEXT_FOCUS`) délègue la réduction de l'inventaire à `graph-aware-injection` plutôt que de dupliquer la logique de graphe ici.

## Validation

- Smoke-test : couvre les deux formats de sortie (`AI_CONTEXT_OUTPUT` texte/JSON) du hook.
- Vérification manuelle du filtrage status (`active` par défaut vs `AI_CONTEXT_SHOW_ALL_STATUS=1`) et du focus (`AI_CONTEXT_FOCUS=<scope|id>`).
- Contrôle que `features-for-path.sh` injecte bien les fiches directes du path + leurs `depends_on` en `PreToolUse`, sans dépasser le budget.
- i18n : `reminder.md` rendu en FR et EN selon `commit_language`.
- Rebuild auto : suppression de l'index puis prompt → l'injection reconstruit l'index et fonctionne.
- Coût : `measure-context-size.sh` doit montrer `reverse_deps chars=0` par défaut.

## Cross-refs

Première brique du flux invisible. Complétée par `features-for-path` en `PreToolUse`, puis `auto-worklog` (capture les éditions) et `git-hooks` (valide au commit).

## Historique / décisions

- v0.6 : filtre status active.
- v0.8 : i18n.
- v0.9 : graph-aware focus.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; aucun changement de format ou de budget d'injection.
- 2026-05-03 : `features-for-path.sh` passe de rappel de liste à injection juste-à-temps bornée des fiches concernées et de leurs dépendances. Le reminder reste inchangé pour préserver le coût tokens par prompt.
- 2026-07-02 : R1 tokens — sortie des dépendances inverses du hook `UserPromptSubmit`. Le reminder global reste limité à règles + inventaire ; `features-for-path.sh --with-docs` conserve l'injection JIT des fiches directes et de leurs `depends_on`.
