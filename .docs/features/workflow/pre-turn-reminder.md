---
id: pre-turn-reminder
scope: workflow
title: Injection contextuelle au début de chaque tour Claude/Codex
status: done
depends_on:
  - core/feature-index-cache
  - core/graph-aware-injection
touches:
  - .ai/scripts/pre-turn-reminder.sh
  - template/.ai/scripts/pre-turn-reminder.sh.jinja
  - template/.ai/reminder.md.jinja
  - tests/unit/test-context-config-keys.sh
touches_shared:
  - template/.ai/scripts/features-for-path.sh.jinja
progress:
  phase: done
  step: "reminder partagé Claude/Codex ; ancre restitution mesurée à +146 caractères (~37–49 tokens)"
  blockers: []
  resume_hint: "aucune action immédiate ; prochaine route validée hors scope : R2 ranking tracker des features jamais touchées"
  updated: 2026-08-07
type: feature
---

# Pre-turn reminder

## Résumé

Hook `UserPromptSubmit` partagé par Claude et Codex qui injecte automatiquement le contexte juste-à-temps avant chaque prompt (règles, inventaire des features actives, `reminder.md`), complété côté Claude par `features-for-path.sh` en `PreToolUse` qui pousse les fiches concernées par le path édité et leurs `depends_on`. Objectif : que l'agent reçoive le bon contexte sans le deviner ni le recharger manuellement, sans charger tout le graphe à chaque tour.

## Objectif

À chaque prompt utilisateur Claude ou Codex doté des hooks projet, injecter automatiquement (`UserPromptSubmit`) le contexte global strictement utile : règles + inventaire des features actives + `reminder.md`. Le graphe détaillé reste juste-à-temps via `features-for-path.sh` côté Claude quand un path est connu.

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
- **Configuration `context.*` (contrat v1.0)** — précédence explicite, du plus fort au plus faible :
  - statuts visibles : `AI_CONTEXT_SHOW_ALL_STATUS=1` > `.ai/config.yml` `context.show_statuses` > défaut `[active, draft, "?"]`. Une liste vide est ignorée (retour au défaut) : la config ne peut pas masquer tout le mesh par accident.
  - focus : `--focus=<scope>` > `AI_CONTEXT_FOCUS` > `context.default_focus` > aucun focus.
  - seuil de warning : `context.max_tokens_warn` (0 = désactivé).
  Lecture via `yq` uniquement : sans `yq` ou sans clé, retour silencieux au défaut — aucun parseur YAML supplémentaire n'est introduit.

## Décisions

- Deux hooks distincts plutôt qu'un seul : `UserPromptSubmit` porte le contexte global (règles + inventaire), `PreToolUse` porte le contexte ciblé sur le path édité. Cela évite de tout charger à chaque prompt.
- `features-for-path.sh` est passé d'un simple **rappel de liste** à une **injection juste-à-temps bornée** des fiches concernées et de leurs dépendances, pour rester aligné sur la règle "contexte juste-à-temps" sans gonfler le reminder.
- Les dépendances inverses ne sont plus injectées par défaut dans `UserPromptSubmit` : elles dominaient le coût par tour et sont remplacées par l'injection JIT des fiches directes + `depends_on` dès qu'un path est connu.
- Le filtrage `active` est le défaut assumé ; voir tout le mesh est un opt-in explicite (`AI_CONTEXT_SHOW_ALL_STATUS`), et le défaut est surchargeable durablement par `context.show_statuses` depuis v1.0.
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

- 2026-07-24 (v1.0, chantier B9 du gel P16) : **`context.show_statuses` et `context.default_focus` deviennent réellement lues**. Ces deux clés étaient scaffoldées dans `.ai/config.yml` depuis v0.10 sans aucun lecteur (`PROJECT_STATE` les listait en roadmap `🚧`) — la review Codex round 3 a relevé qu'on ne pouvait pas les geler dans le contrat v1.0 en les déclarant « actives ». Deux issues possibles : implémenter, ou retirer comme l'avait fait v0.12 pour `auto_transitions.implement_to_review`/`review_to_done`. **Implémentation retenue** : le précédent v0.12 concernait des clés sans sémantique définie (« informatif », aucune heuristique), alors qu'ici le comportement existe déjà via les env vars et que `context.max_tokens_warn` de la même section est déjà lu par `read_config`. Coût mesuré avant décision : ~10 lignes, lecture `yq` seule (aucun parseur YAML ajouté, donc hors moratoire bash). Précédence env var > config > défaut, avec garde sur la liste vide pour qu'une config ne puisse pas masquer tout le mesh. `tests/unit/test-context-config-keys.sh` (7 assertions) branché en `[0q3/28]`.
- v0.6 : filtre status active.
- v0.8 : i18n.
- v0.9 : graph-aware focus.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; aucun changement de format ou de budget d'injection.
- 2026-05-03 : `features-for-path.sh` passe de rappel de liste à injection juste-à-temps bornée des fiches concernées et de leurs dépendances. Le reminder reste inchangé pour préserver le coût tokens par prompt.
- 2026-07-02 : R1 tokens — sortie des dépendances inverses du hook `UserPromptSubmit`. Le reminder global reste limité à règles + inventaire ; `features-for-path.sh --with-docs` conserve l'injection JIT des fiches directes et de leurs `depends_on`.
- 2026-07-03 : clôture DONE R1 ; `measure-context-size.sh` confirme `reverse_deps chars=0` et un budget estimé sous la cible.
- 2026-08-07 (chantier restitution, pilot `2026-08-07-retour-ux-restitution`) : le reminder gagne **une ligne d'ancre restitution** (fr + en dans le miroir template) — résultat d'abord, synthèse, données sourcées, clôture fait/vérifié/risques/suite, pointeur `.ai/agent/response-style.md`. Coût mesuré : +146 caractères statiques (`measure-context-size.sh` : 560 → 706), soit ~37–49 tokens/tour ; c'est la première extension du reminder depuis la décision « reminder inchangé » de 2026-05-03, révisée par ce chantier.
