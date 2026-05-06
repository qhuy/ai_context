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
  phase: implement
  step: "approche tranchée post cross-check Codex, prêt à coder"
  blockers: []
  resume_hint: "implémenter Approche A : git status --untracked-files=all comme source uncommitted, libellé section non figé HEAD~1..HEAD, garder features_matching_path direct, ajouter tests/unit dédié"
  updated: 2026-05-07
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

1. Lister le delta committed via la logique existante (préserver le contrat actuel).
2. Lister le delta uncommitted via `git status --short --untracked-files=all`, normaliser les paths (deletions/renames visibles avec leur chemin pertinent).
3. Croiser chaque liste avec les features via `features_matching_path` ([_lib.sh:130](.ai/scripts/_lib.sh:130)) en mode best-effort. Aucun fail hard sur matcher dans ce scope.
4. Sortir un rapport markdown avec deux sections explicites : « Delta committed reference » (logique existante préservée) et « Delta uncommitted (working tree + index + untracked) » (nouvelle).
5. Avec `--committed-only`, n'afficher que la première section (compat ascendante stricte).
6. Code retour 0 si le script s'exécute sans erreur catastrophique (jq absent, repo non-git). Pattern matcher cassé → warning stderr, pas d'échec.

## Contrats

- Sortie markdown stable consommable par `aic.sh review` et lisible humainement.
- **Compat ascendante stricte** : la portion « committed reference » conserve le format actuel. La section uncommitted s'ajoute en suffixe. Un consommateur qui parsait l'ancienne sortie continue de fonctionner.
- Flag `--committed-only` restaure l'ancien comportement strict (uniquement committed).
- Code retour 0 sur exécution normale (présence ou absence de delta n'est pas un échec). Code retour ≠ 0 uniquement sur erreur catastrophique (jq absent, repo non-git, index manquant).
- Variables d'environnement : `AI_CONTEXT_REVIEW_DELTA_BASE` pour override la base de comparaison committed (utile en CI). Pas d'env var pour uncommitted (toujours `git status --short --untracked-files=all`).

## Validation

Test unit-test dédié `tests/unit/test-review-delta-uncommitted.sh` couvrant 5 cas minimum :

1. Fichier tracked modifié non commité → visible dans section uncommitted.
2. Fichier staged (index) → visible dans section uncommitted.
3. Fichier untracked → visible dans section uncommitted.
4. Fichier supprimé (deletion) → visible avec son chemin.
5. Flag `--committed-only` → section uncommitted absente, format committed inchangé.

Plus :
- `bash tests/smoke-test.sh` PASS après intégration (smoke peut invoquer le test unit s'il suit le pattern local, sinon test unit autonome).
- Validation manuelle : `bash .ai/scripts/aic.sh review` produit un rapport dont la liste uncommitted matche exactement `git status --short --untracked-files=all` (au path près, normalisation des renames acceptée).

## Risques

- Modifier le contrat de `review-delta.sh` peut casser des consommateurs si `aic.sh review` ou un autre script attend l'ancien format. **Atténué** : compat ascendante stricte (section uncommitted ajoutée en suffixe, format committed inchangé) + flag `--committed-only` pour restaurer l'ancien comportement.
- Le bug bash 3.2 sur le matcher `features_matching_path` (couvert par `quality/features-for-path-ranking-and-matcher-correctness`) peut polluer la portion « features impactées » du rapport. **Atténué** : mode best-effort, warning stderr sans bloquer. Décision : ne pas migrer vers `features-for-path.sh` dans ce scope pour éviter de mélanger avec Phase 2 #2.
- `git status --short --untracked-files=all` peut être lent sur très gros repo. **Atténué** : pas un risque pour ce repo (taille modeste). À surveiller si extension multi-repo.

## Cross-refs

- `quality/features-for-path-ranking-and-matcher-correctness` : matcher correct nécessaire pour que la portion « features impactées » du rapport soit fiable.
- `workflow/intentional-skills` : l'ordre Phase 2 a été décidé dans cette fiche après cross-check Claude/Codex (egress > injection sur faux feu vert).

## Historique / décisions

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`. Bug confirmé en local (`bash .ai/scripts/review-delta.sh` sort 1 fichier `HEAD~1..HEAD` alors que `git status --short` montre 30+ uncommitted). Ordre Phase 2 fixé : cette fiche en #1, avant `quality/features-for-path-ranking-and-matcher-correctness` (#2).
- 2026-05-07 : cross-check Codex pre-implémentation. 4 corrections actées : (1) Approche A confirmée + compat parsabilité stricte ; (2) source de vérité uncommitted = `git status --short --untracked-files=all`, pas `git diff HEAD` qui rate les untracked ; (3) libellé section « Delta committed reference », ne pas figer `HEAD~1..HEAD` comme contrat ; (4) garder `features_matching_path` direct, ne pas migrer vers `features-for-path.sh` (évite mélange avec Phase 2 #2). Tests : unit-test dédié `tests/unit/test-review-delta-uncommitted.sh`, 5 cas. Phase bumpée spec → implement.
