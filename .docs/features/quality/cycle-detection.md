---
id: cycle-detection
scope: quality
title: Détection de cycles dans depends_on (DFS jq)
status: active
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
touches:
  - template/.ai/scripts/check-features.sh.jinja
progress:
  phase: review
  step: "bootstrap dog-fooding ; check-features partagé avec touches_shared"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-06-25
type: feature
---

# Détection de cycles

## Résumé

Une DFS en `jq` parcourt le graphe `depends_on` du mesh et rejette tout cycle (A → B → A). Sans cette garde, l'injection contextuelle boucle à l'infini en chargeant récursivement les dépendances.

## Objectif

Refuser tout mesh qui contient un cycle dans le graphe `depends_on` (A → B → A). Un cycle non détecté entraîne des boucles infinies à l'injection contextuelle (chargement récursif des deps).

## Périmètre

### Inclus

- La DFS de détection de cycles sur les arêtes `depends_on`, implémentée en `jq` dans `check-features.sh`.
- La sortie de la liste des cycles trouvés et le code de sortie non-zéro associé.
- La couverture du script partagé `check-features.sh` (mesh + chemins optionnels `touches_shared`).

### Hors périmètre

- La construction du graphe `depends_on` et la résolution des arêtes vers features inexistantes (warning porté par `feature-mesh`, pas une erreur de cycle).
- Le cache d'index et son invalidation (couverts par `feature-index-cache`).
- L'orchestration CI / quality-gate qui invoque le check (portée par `ci-guard`).

## Invariants

- Aucun mesh contenant un cycle `depends_on` ne passe : présence d'un cycle ⇒ exit non-zéro.
- Une arête vers une feature inexistante ne compte jamais comme un cycle (warning séparé, pas un échec de cette garde).
- La DFS reste pure `jq` : aucune dépendance runtime supplémentaire (Python/Node) n'est introduite.
- La complexité reste linéaire O(V+E), soutenable jusqu'à ~10⁴ features.

## Comportement attendu

- DFS implémenté en `jq` (pur, pas de dépendance Python/Node).
- Sortie : liste des cycles détectés, exit non-zéro si > 0.
- Invoqué par `check-features.sh` (script unique appelé en CI et `/aic-quality-gate`).

## Contrats

- Complexité O(V+E), acceptable jusqu'à ~10⁴ features.
- Tolère les arêtes vers features inexistantes (warning séparé, pas une erreur de cycle).

## Décisions

- DFS en `jq` plutôt qu'en Python/Node : zéro runtime supplémentaire, `jq` est déjà requis par `feature-index-cache`.
- Détection branchée dans `check-features.sh` (script unique) plutôt qu'un script dédié : un seul point d'entrée rejoué en CI et par `/aic-quality-gate`.
- Les arêtes pendantes (vers features absentes) sont traitées en warning séparé, pas en erreur de cycle : on ne mélange pas validation de référence et détection de boucle.

## Validation

- Tests de contrat du mesh rejoués par `feature-mesh`, `smoke-test` et `ci-guard`.
- Un mesh portant un cycle `depends_on` fait sortir `check-features.sh` en non-zéro (liste des cycles affichée).
- Un mesh sain (sans cycle) passe `check-features.sh --no-write`, y compris en présence d'arêtes `touches_shared`.

## Cross-refs

Validation côté `feature-mesh` ; rejoué par `smoke-test` et `ci-guard`.

## Historique / décisions

- Choix `jq` plutôt que Python : zéro runtime supplémentaire, déjà requis par `feature-index-cache`.
- 2026-05-03 : `check-features.sh` valide aussi les chemins optionnels `touches_shared`. Aucun changement sur la DFS de cycles, mais le fichier script partagé reste couvert par cette fiche.
