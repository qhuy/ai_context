---
id: graph-aware-injection
scope: core
title: Injection contextuelle filtrée par graphe (AI_CONTEXT_FOCUS)
status: active
depends_on:
  - core/feature-index-cache
touches:
  - template/.ai/scripts/pre-turn-reminder.sh.jinja
progress:
  phase: review
  step: "freshness documentaire rafraîchie après dogfood"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-05-03
---

# Graph-aware injection

## Objectif

Sur un mesh > 100 features, injecter l'inventaire complet à chaque tour explose les tokens. La variable `AI_CONTEXT_FOCUS=<scope|id>` réduit l'injection au scope ciblé + ses voisins 1-hop dans le graphe `depends_on`.

## Comportement attendu

- `AI_CONTEXT_FOCUS=back` → features du scope `back` + tout ce qui les pointe ou est pointé par elles.
- `AI_CONTEXT_FOCUS=back/payment` → cette feature + voisins 1-hop bidirectionnels.
- Focus invalide (scope inexistant, id introuvable) → warn + fallback inventaire complet (jamais de vide).
- Désactivable en désactivant la variable.

## Contrats

- Variable lue par `pre-turn-reminder.sh` uniquement.
- N'affecte ni la validation (`check-features`) ni le build d'index.
- Compatible avec `AI_CONTEXT_SHOW_ALL_STATUS`.

## Cross-refs

Optimisation au-dessus de `feature-index-cache`. Ne remplace pas le filtrage par status (active uniquement par défaut).

## Historique / décisions

- v0.9.0 : introduction. Gain mesuré ~5× sur mesh ~100 features.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; le contrat `AI_CONTEXT_FOCUS` reste inchangé.
