---
id: cycle-detection
scope: quality
title: Détection de cycles dans depends_on (tri topologique jq)
status: done
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
touches:
  - tests/unit/test-cycle-detection-diamond.sh
touches_shared:
  - template/.ai/scripts/check-features.sh.jinja
progress:
  phase: done
  step: "détection de cycles Kahn O(V+E) livrée et garde diamant validée"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si le graphe depends_on ou check-features change"
  updated: 2026-07-03
type: feature
---

# Détection de cycles

## Résumé

Un tri topologique de Kahn en `jq` (point fixe, O(V+E)) parcourt le graphe `depends_on` du mesh et rejette tout cycle (A → B → A). Sans cette garde, l'injection contextuelle boucle à l'infini en chargeant récursivement les dépendances.

## Objectif

Refuser tout mesh qui contient un cycle dans le graphe `depends_on` (A → B → A). Un cycle non détecté entraîne des boucles infinies à l'injection contextuelle (chargement récursif des deps).

## Périmètre

### Inclus

- La détection de cycles sur les arêtes `depends_on` (tri topologique de Kahn), implémentée en `jq` dans `check-features.sh`.
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

- Tri topologique de Kahn en `jq` (pur, pas de dépendance Python/Node ; O(V+E), point fixe sans récursion).
- Sortie : liste triée des features impliquées dans un cycle, exit non-zéro si > 0.
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
- Clôture 2026-07-03 : `bash tests/unit/test-cycle-detection-diamond.sh` PASS et `bash .ai/scripts/check-features.sh --no-write` PASS.

## Cross-refs

Validation côté `feature-mesh` ; rejoué par `smoke-test` et `ci-guard`.

## Historique / décisions

- Choix `jq` plutôt que Python : zéro runtime supplémentaire, déjà requis par `feature-index-cache`.
- 2026-05-03 : `check-features.sh` valide aussi les chemins optionnels `touches_shared`. Aucun changement sur la détection de cycles, mais le fichier script partagé reste couvert par cette fiche.
- 2026-06-29 : **DFS récursive → tri topologique de Kahn** (audit A13). L'ancienne DFS threadait `$visited` par chemin (pas de mémoïsation globale) → ré-exploration exponentielle sur un DAG en diamant (mesuré : k=20 ≈ 76s, k≥22 timeout). L'invariant « O(V+E) » de cette fiche était donc **faux**. Kahn (point fixe : on résout itérativement tout nœud dont les deps sont déjà résolues ; le reste est cyclique) le rend **vrai** : diamant k=24 instantané. Message d'erreur : liste des features impliquées au lieu d'un chemin `A → B → A` (le smoke ne vérifiait que l'exit non-zéro). Garde de non-régression : `tests/unit/test-cycle-detection-diamond.sh`. Code dans `check-features.sh` (commit `fix(core)`), HANDOFF appliqué ici.
- 2026-07-03 : DONE documentaire. La garde Kahn est livrée, testée par `test-cycle-detection-diamond`, et le fichier runtime partagé reste en `touches_shared` pour éviter la sur-couverture.
