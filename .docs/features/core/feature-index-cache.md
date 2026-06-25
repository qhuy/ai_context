---
id: feature-index-cache
scope: core
title: Cache JSON déterministe du feature mesh
status: active
depends_on:
  - core/feature-mesh
touches:
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
  - template/.ai/scripts/_lib.sh.jinja
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/pr-report.sh.jinja
  - .ai/scripts/pr-report.sh
progress:
  phase: review
  step: "bootstrap dog-fooding (v0.9 historique)"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-06-25
type: feature
---

# Cache JSON du feature mesh

## Résumé

`build-feature-index.sh` agrège les frontmatter de toutes les fiches en un cache `.ai/.feature-index.json` déterministe et gitignoré, pour que les hooks d'injection consomment le mesh sans reparser le markdown à chaque appel.

## Objectif

Éviter de re-parser le markdown à chaque appel de hook : `build-feature-index.sh` agrège tous les frontmatter en un `.ai/.feature-index.json` reconstruit déterministiquement, gitignoré.

## Périmètre

### Inclus

- L'agrégation des frontmatter (`id`, `scope`, `title`, `status`, `depends_on`, `touches`, `touches_shared`, `progress?`, `product?`, `external_refs?`, `path`) en un tableau JSON.
- Le parsing YAML (`yq v4` si dispo, fallback awk/sed bash 3.2) et l'échappement JSON sûr via `jq -nc --arg`.
- Le verrou atomique `mkdir` autour de l'écriture du cache et le rebuild on-demand (hook + reminder si fichier manquant).
- Les deux variantes maintenues en parallèle : runtime dogfoodé (`.ai/scripts/build-feature-index.sh`) et gabarit Copier (`.jinja`), plus les helpers de matching partagés dans `_lib.sh`.

### Hors périmètre

- La détection de cycles dans `depends_on` (portée par `cycle-detection`, exécutée en validation post-build).
- La sémantique de blocage cross-scope et les checks de cohérence du mesh (portés par `feature-mesh` / `check-features.sh`).
- La consommation du cache par les hooks downstream (`pre-turn-reminder`, `features-for-path`, `resume-features`).

## Comportement attendu

- Trigger : `post-checkout` git hook + `pre-turn-reminder` (rebuild si manquant).
- Lecture YAML via `yq v4` si dispo, sinon fallback awk/sed (bash 3.2 compatible).
- Échappement JSON sûr (paths avec quotes/backslashes via `jq -nc --arg`).
- Lock atomique `mkdir` (pas `flock`, portable macOS).

## Invariants

- Deux builds successifs sans changement de source produisent un JSON byte-identique (ordre stable, pas de timestamp).
- Une fiche au frontmatter invalide est exclue avec warning mais n'arrête jamais le build (cache toujours produit).
- Les paths contenant quotes/backslashes sont échappés sûrement (`jq -nc --arg`), jamais concaténés à la main.
- Le cache reste gitignoré et reconstructible : aucune source de vérité ne vit dans `.feature-index.json`.
- Les helpers de matching `touches:` sont centralisés dans `_lib.sh` ; runtime et gabarit `.jinja` partagent la même sémantique.

## Décisions

- Cache pré-agrégé plutôt que reparsing à chaque hook : le coût markdown est payé une fois au `post-checkout`.
- Verrou `mkdir` plutôt que `flock` : portable sur macOS où `flock` est absent.
- `yq v4` privilégié quand présent, fallback awk/sed pour rester exécutable sous bash 3.2 (macOS système).
- Matching `touches:` direct volontairement séparé de `touches_shared` : `features_matching_path` reste limité aux touches directs pour préserver la sémantique bloquante.
- Objets `product` et `external_refs` optionnels et inertes par défaut : les scripts read-only les exploitent sans imposer de reparsing spécifique.

## Contrats

- Sortie : tableau JSON `[{id, scope, title, status, depends_on, touches, touches_shared, progress?, path}]`.
- Idempotent : 2 builds successifs produisent un JSON byte-identique.
- Tolérance : feature au frontmatter invalide → exclue + warning, pas d'arrêt.

## Validation

- Idempotence : deux exécutions consécutives de `build-feature-index.sh` produisent un JSON byte-identique (couvert par les tests unitaires `index contract` sous `tests/unit/`).
- Échappement : une fiche dont un `touches:` contient quote/backslash produit un JSON valide (`jq .` ne lève pas d'erreur).
- Tolérance : une fiche au frontmatter invalide est exclue avec warning sans faire échouer le build.
- Parité runtime/gabarit : le smoke-test rejoue `copier copy` puis vérifie que le script généré (`.jinja`) produit le même cache que le runtime dogfoodé.
- Validation post-build du mesh déléguée à `cycle-detection`.

## Cross-refs

- Source consommée par tous les hooks d'injection (`pre-turn-reminder`, `features-for-path`, `resume-features`).
- Validation post-build via `cycle-detection`.

## Historique / décisions

- v0.7.2 : fix bug silencieux d'escaping JSON (paths avec quotes corrompaient le JSONL).
- 2026-04-24 : centralisation du matching `touches:` dans `_lib.sh` (`path_matches_touch` + `features_matching_path`). Les hooks/scripts consommateurs partagent désormais la même sémantique exact/dossier/glob/`/**`.
- 2026-04-24 : `AI_CONTEXT_DOCS_ROOT` et `AI_CONTEXT_FEATURES_DIR` ajoutés dans `_lib.sh` pour que les scripts runtime suivent le `docs_root` rendu par Copier au lieu de réencoder `.docs/features`.
- 2026-04-28 : ajout `is_valid_phase()` dans `.ai/scripts/_lib.sh` (dogfoodé) **et** `template/.ai/scripts/_lib.sh.jinja` (la doc d'en-tête le promettait déjà via `PHASE_ENUM`). Suppression de la définition locale dupliquée dans `template/.ai/scripts/check-features.sh.jinja`. Aucun changement de comportement runtime — la fonction délègue à `PHASE_ENUM` (lui-même dérivé du schema). Smoke-test [11/28] couvre toujours le warning `progress.phase='typo'`.
- 2026-05-03 : index enrichi avec `touches_shared` et helpers `_lib.sh` dédiés (`features_matching_shared_path`, `features_related_to_path`). `features_matching_path` reste volontairement limité aux `touches` directs pour préserver la sémantique bloquante.
- 2026-05-03 : index enrichi avec l'objet optionnel `product` afin que les scripts read-only puissent calculer status, portfolio et review sans reparsing spécifique.
- 2026-05-04 : index enrichi avec l'objet optionnel `external_refs` pour exposer les liens BMAD, Spec Kit, tickets ou docs externes aux rapports et outils downstream.
