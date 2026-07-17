---
id: graph-aware-injection
scope: core
title: Injection contextuelle filtrée par graphe (AI_CONTEXT_FOCUS)
status: done
depends_on:
  - core/feature-index-cache
touches:
  - .docs/features/core/graph-aware-injection.md
  - .docs/features/core/graph-aware-injection.worklog.md
touches_shared:
  - template/.ai/scripts/pre-turn-reminder.sh.jinja
progress:
  phase: done
  step: "contrat AI_CONTEXT_FOCUS livré, validé et inchangé après R1 pre-turn lean"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si AI_CONTEXT_FOCUS ou le voisinage graphe change."
  updated: 2026-07-03
type: feature
---

# Graph-aware injection

## Résumé

`AI_CONTEXT_FOCUS=<scope|id>` restreint l'injection contextuelle au scope ciblé et à ses voisins 1-hop dans le graphe `depends_on`, pour éviter l'explosion de tokens quand le mesh dépasse ~100 features.

## Objectif

Sur un mesh > 100 features, injecter l'inventaire complet à chaque tour explose les tokens. La variable `AI_CONTEXT_FOCUS=<scope|id>` réduit l'injection au scope ciblé + ses voisins 1-hop dans le graphe `depends_on`.

## Périmètre

### Inclus

- Lecture de `AI_CONTEXT_FOCUS` par `pre-turn-reminder.sh` et filtrage de l'inventaire injecté.
- Deux granularités : focus par scope (`back`) et focus par feature (`back/payment`).
- Traversée 1-hop bidirectionnelle du graphe `depends_on` (features pointées et features pointantes).
- Fallback sur l'inventaire complet quand le focus est invalide.

### Hors périmètre

- La validation du mesh (`check-features`) et le build de l'index : non affectés.
- Le filtrage par status (`active` par défaut) : conservé, non remplacé par le focus.
- La traversée multi-hop (> 1) : non gérée, hors scope volontaire.

## Comportement attendu

- `AI_CONTEXT_FOCUS=back` → features du scope `back` + tout ce qui les pointe ou est pointé par elles.
- `AI_CONTEXT_FOCUS=back/payment` → cette feature + voisins 1-hop bidirectionnels.
- Focus invalide (scope inexistant, id introuvable) → warn + fallback inventaire complet (jamais de vide).
- Désactivable en désactivant la variable.

## Invariants

- Un focus invalide ne produit jamais d'injection vide : fallback systématique sur l'inventaire complet + warn.
- Le voisinage 1-hop est bidirectionnel (les deux sens de `depends_on`), jamais réduit à un seul sens.
- Seul `pre-turn-reminder.sh` lit la variable ; aucun autre script n'en dépend.
- L'absence de la variable laisse le comportement historique inchangé (inventaire complet).

## Décisions

- Voisinage limité à **1-hop** : compromis assumé entre réduction des tokens et conservation du contexte directement pertinent ; pas de traversée transitive.
- Le focus est une **optimisation au-dessus** du filtrage par status, pas un remplacement : `active` reste le défaut.
- Fallback plutôt qu'erreur sur focus invalide : ne jamais dégrader l'agent en contexte vide.
- Variable d'environnement (et non flag de script) pour rester transparente vis-à-vis des appels existants.

## Contrats

- Variable lue par `pre-turn-reminder.sh` uniquement.
- N'affecte ni la validation (`check-features`) ni le build d'index.
- Compatible avec `AI_CONTEXT_SHOW_ALL_STATUS`.

## Validation

- `AI_CONTEXT_FOCUS=<scope>` et `AI_CONTEXT_FOCUS=<scope>/<id>` injectent bien le sous-ensemble attendu (scope + voisins 1-hop).
- Focus invalide (scope inexistant, id introuvable) → warn émis et inventaire complet injecté, jamais de sortie vide.
- Sans la variable, l'injection reste identique au comportement complet historique.
- `check-features` et le build d'index donnent le même résultat avec ou sans focus (non affectés).
- Smoke-test bonus big-mesh : vérifie que `AI_CONTEXT_FOCUS` réduit effectivement la taille du reminder.

## Cross-refs

Optimisation au-dessus de `feature-index-cache`. Ne remplace pas le filtrage par status (active uniquement par défaut).

## Historique / décisions

- v0.9.0 : introduction. Gain mesuré ~5× sur mesh ~100 features.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; le contrat `AI_CONTEXT_FOCUS` reste inchangé.
- 2026-07-03 : **DONE** — contrat inchangé après R1 pre-turn lean ; le graphe détaillé reste consommé en JIT par `features-for-path.sh --with-docs`, et le smoke bonus big-mesh couvre la réduction `AI_CONTEXT_FOCUS`.
