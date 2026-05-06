---
id: review-delta-uncommitted-coverage
scope: quality
title: Couvrir le delta uncommitted dans review-delta.sh
status: draft
depends_on: []
touches:
  - .ai/scripts/review-delta.sh
  - tests/smoke-test.sh
touches_shared:
  - .ai/scripts/aic.sh
product: {}
external_refs: {}
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
  phase: spec
  step: "draft cadré, à reprendre pour implémentation"
  blockers: []
  resume_hint: "arbitrer Approche A (étendre review-delta.sh) vs B (script séparé) puis implémenter"
  updated: 2026-05-06
---

# Couvrir le delta uncommitted dans review-delta.sh

## Résumé

`review-delta.sh` compare aujourd'hui `HEAD~1..HEAD` et ignore le working tree. Sur un commit en préparation, le script peut produire un faux feu vert si le delta réel vit en uncommitted/staged. Cette fiche cadre la correction du script et de la procédure `aic-review` qui s'en sert.

## Objectif

Garantir que toute review pre-commit voit le vrai delta — incluant working tree et index — avant de produire un verdict ou des features impactées. Sécuriser ainsi les commits humainement validés via `aic.sh review`.

## Périmètre

### Inclus

- Reformuler `review-delta.sh` pour couvrir `HEAD..working tree` ou produire les deux deltas (committed + uncommitted) avec sortie distincte.
- Garantir que `aic.sh review` consomme un signal complet.
- Couvrir le cas par un test (smoke-test ou unit-test dédié) qui vérifie que le script détecte les fichiers uncommitted.
- Documenter le comportement attendu dans le workflow consommateur (probablement `.ai/workflows/quality-gate.md`).

### Hors périmètre

- Ranking des features injectées (couvert par `quality/features-for-path-ranking-and-matcher-correctness`).
- Mesure post-hoc de pertinence (`quality/context-relevance-tracker`).
- Filtre auto-progression (`workflow/auto-progress-file-filter`).
- Idempotence du Stop hook (`workflow/stop-hook-idempotence`).

### Granularité / nommage

Cette fiche couvre l'outil de review pre-commit ; pas la pertinence d'injection ni le tracking post-hoc.

## Invariants

- `aic.sh review` ne doit jamais bénir un commit dont le delta réel n'a pas été analysé.
- Le script doit rester agent-agnostic (Bash, pas de dépendance hookée Claude).
- La sortie doit identifier clairement la frontière commit/uncommitted pour que l'agent et l'humain comprennent ce qui a été couvert.

## Décisions

Ouvertes, à arbitrer en phase implement :

- **Approche A** : étendre `review-delta.sh` pour gérer `HEAD..working tree` par défaut, avec flag `--committed-only` pour l'ancien comportement. Un seul outil cohérent.
- **Approche B** : créer un script séparé `review-delta-uncommitted.sh` et l'invoquer en plus dans `aic-review`. Plus simple à versionner mais double surface.
- Approche A préférée par défaut (un seul outil cohérent) ; à confirmer après lecture détaillée du code actuel.

## Comportement attendu

`bash .ai/scripts/review-delta.sh` sans argument doit :

1. Détecter le delta complet (committed depuis base + staged + unstaged).
2. Lister les fichiers modifiés avec frontière claire commit/uncommitted.
3. Croiser avec les features (via `features-for-path.sh` une fois ce dernier corrigé par `quality/features-for-path-ranking-and-matcher-correctness`).
4. Sortir un rapport structuré (markdown) avec sections « Delta committed » et « Delta uncommitted » séparées.

## Contrats

- Sortie markdown stable consommable par `aic.sh review` et lisible humainement.
- Code retour 0 si le script s'exécute sans erreur (présence ou absence de delta n'est pas un échec).
- Variables d'environnement : éventuellement `AI_CONTEXT_REVIEW_DELTA_BASE` pour override la base de comparaison (utile en CI).

## Validation

- Test reproductible : créer un fichier modifié non commité, lancer le script, vérifier qu'il apparaît dans la section uncommitted.
- `bash tests/smoke-test.sh` PASS après intégration.
- Validation manuelle : `bash .ai/scripts/aic.sh review` produit un rapport cohérent avec `git status --short`.

## Risques

- Modifier le contrat de `review-delta.sh` peut casser des consommateurs si `aic.sh review` ou un autre script attend l'ancien format. À vérifier au moment du fix.
- Le bug bash 3.2 sur `features-for-path.sh` peut polluer la portion « features impactées » du rapport. Ne pas s'appuyer sur features-for-path comme preuve exhaustive tant que `quality/features-for-path-ranking-and-matcher-correctness` n'est pas livré.

## Cross-refs

- `quality/features-for-path-ranking-and-matcher-correctness` : matcher correct nécessaire pour que la portion « features impactées » du rapport soit fiable.
- `workflow/intentional-skills` : l'ordre Phase 2 a été décidé dans cette fiche après cross-check Claude/Codex (egress > injection sur faux feu vert).

## Historique / décisions

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`. Bug confirmé en local (`bash .ai/scripts/review-delta.sh` sort 1 fichier `HEAD~1..HEAD` alors que `git status --short` montre 30+ uncommitted). Ordre Phase 2 fixé : cette fiche en #1, avant `quality/features-for-path-ranking-and-matcher-correctness` (#2).
