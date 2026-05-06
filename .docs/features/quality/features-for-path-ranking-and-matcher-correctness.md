---
id: features-for-path-ranking-and-matcher-correctness
scope: quality
title: Ranker features-for-path et corriger le matcher globstar bash 3.2
status: draft
depends_on: []
touches:
  - .ai/scripts/features-for-path.sh
  - .ai/scripts/_lib.sh
  - tests/smoke-test.sh
touches_shared:
  - .claude/settings.json
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
  resume_hint: "lire features-for-path.sh + _lib.sh, choisir entre fix matcher (A/B) ou borner patterns (C), implémenter ranking top-K"
  updated: 2026-05-06
---

# Ranker features-for-path et corriger le matcher globstar bash 3.2

## Résumé

`features-for-path.sh` matche les paths contre les `touches:` des features sans aucun ranking : toutes les features qui matchent sont injectées en PreToolUse, peu importe la spécificité du glob. Et son matcher repose sur `enable_globstar` qui est silencieusement no-op sur bash 3.2 macOS — donc les patterns `src/**/*.ts` ou `foo-*/**` ne matchent pas correctement la machine de dev type.

Cette fiche couvre **les deux** : ranking par spécificité (top-K) ET correctness du matcher pour bash 3.2. L'acceptance bloque la livraison du ranking tant que le matcher n'est pas correct sur globs multi-niveaux — un ranking sur matcher buggé donne une fausse confiance.

## Objectif

Réduire le bruit du contexte injecté en PreToolUse Claude (et de tout consommateur CLI explicite, Codex inclus) en :

1. **Corrigeant** le matcher pour qu'un pattern `touches: src/**/*.ts` matche réellement `src/sub/file.ts` sous bash 3.2.
2. **Rankant** les features matchées par spécificité du glob, en bornant à top-K (3 par défaut).
3. **Bornant** le coût tokens et la pollution cross-feature de l'injection.

## Périmètre

### Inclus

- Lecture détaillée du matcher actuel (`features-for-path.sh:116` et `_lib.sh:118-121`) pour cartographier les cas couverts/non couverts.
- Fix du matcher pour que `**` se comporte correctement multi-niveaux sous bash 3.2, ou borne explicite des patterns supportés avec erreur claire si pattern non supporté.
- Algorithme de ranking : longueur du préfixe non-glob, nombre de wildcards, ou combinaison.
- Top-K configurable via env var (`AI_CONTEXT_FEATURES_TOP_K`, défaut 3).
- Tests reproductibles : pattern multi-niveaux ne se résout plus en faux positif/faux négatif ; ranking ordonne stablement.

### Hors périmètre

- Couverture du delta uncommitted (`quality/review-delta-uncommitted-coverage`).
- Mesure post-hoc de pertinence (`quality/context-relevance-tracker`).
- Filtre auto-progression (`workflow/auto-progress-file-filter`).
- Migration vers Python (Phase 3, hors scope tant qu'on n'a pas validé le besoin).

### Granularité / nommage

Cette fiche couvre un seul outil (`features-for-path.sh`) et son matcher (`_lib.sh`). Le ranking est inséparable du matcher correct ; les deux sont dans la même fiche pour éviter de séparer un livrable cohérent.

## Invariants

- Pack A reste lean : pas d'élargissement.
- Le script reste agent-agnostic (Bash, pas de dépendance hookée Claude).
- Comportement déterministe : sortie reproductible pour un même path et un même état du mesh.
- Erreur claire si un pattern non supporté est utilisé (pas de silent no-op).

## Décisions

Ouvertes, à arbitrer en phase implement :

### Matcher (option A/B/C, Codex round 3)

- **Option A** — Insérer un fix matcher avant ranking en fiche séparée. *Rejetée par Codex* : crée une fiche de plomberie redondante.
- **Option B** *(préférée)* — Intégrer le fix matcher comme prérequis interne du ranking. Acceptance bloque : « ranking impossible à déclarer livré tant que matcher incorrect ». Un seul livrable cohérent.
- **Option C** — Borner officiellement les patterns supportés à `prefix/**` simple, refuser `src/**/*.ts` jusqu'au fix profond. *Rejetée par Codex* : documente une faiblesse au lieu de corriger.

Choix par défaut : **B**. À confirmer après lecture détaillée du code.

### Ranking

- Critère de spécificité : longueur du préfixe non-glob (plus long = plus spécifique) en premier ordre, puis nombre de wildcards (moins = plus spécifique) en départage.
- Top-K par défaut : 3 (configurable via `AI_CONTEXT_FEATURES_TOP_K`).
- Comportement quand >K matches : tronquer + signaler dans la sortie le nombre de features omises.

### Bash 3.2

- Critère P1 confirmé en local (`/bin/bash 3.2.57 arm64-darwin25` sur la machine de dev).
- Les patterns `prefix/**` simples ont déjà une branche spéciale (`_lib.sh:118-121`).
- Les patterns multi-niveaux (`src/**/*.ts`, `foo-*/**`) restent contaminés. Approche : étendre la branche spéciale ou utiliser une stratégie de regex Bash POSIX compatible 3.2.

## Comportement attendu

`bash .ai/scripts/features-for-path.sh <path>` doit :

1. Matcher le path contre tous les `touches:` des features actives, en respectant correctement `**` multi-niveaux.
2. Trier les features matchées par spécificité décroissante.
3. Renvoyer top-K features (3 par défaut), avec mention du nombre de features omises si troncature.
4. Erreur claire et code retour ≠ 0 si un pattern n'est pas supporté par le matcher (pas de silent no-op).

## Contrats

- Sortie JSON ou markdown stable consommable par `aic.sh` et le hook PreToolUse Claude.
- Variables d'env : `AI_CONTEXT_FEATURES_TOP_K` (défaut 3), `AI_CONTEXT_FEATURE_DOC_MAX_CHARS` (existant), `AI_CONTEXT_FEATURE_DOC_PER_DOC_CHARS` (existant).
- Compatibilité ascendante : aucune feature actuellement déclarée ne doit régresser. Rebuild de l'index puis comparaison avant/après sur 100 paths types pour détecter les régressions.

## Validation

- Test reproductible matcher : créer une fiche avec `touches: src/**/*.ts`, lancer le script sur `src/sub/file.ts`, vérifier que la fiche est matchée. Idem pour `foo-*/**`.
- Test ranking : créer 5 fiches dont les `touches:` matchent un même path à des spécificités différentes, vérifier que top-3 sont retournées dans l'ordre attendu.
- `bash tests/smoke-test.sh` PASS après intégration.
- Mesure de bruit : lancer le hook PreToolUse sur 10 paths représentatifs avant/après, vérifier réduction du nombre de features injectées sans perte des features pertinentes.

## Risques

- Modifier le contrat de sortie peut casser le hook PreToolUse Claude. Tester avec `AI_CONTEXT_DEBUG=1` avant déploiement.
- Le ranking peut masquer une feature pertinente si la métrique de spécificité est mal calibrée. Avoir une boucle de validation post-hoc (cf. `quality/context-relevance-tracker`).
- Sur bash >=4 (Linux CI, macOS brewé), la branche `enable_globstar` reste active. Le fix doit rester compatible avec les deux modes.

## Cross-refs

- `quality/review-delta-uncommitted-coverage` : Phase 2 #1, ne dépend pas de cette fiche mais bénéficiera du matcher correct pour la portion « features impactées » du rapport.
- `quality/context-relevance-tracker` : Phase 2 #3, partenaire naturel pour calibrer le ranking via boucle de feedback.
- `workflow/intentional-skills` : ordre Phase 2 décidé après cross-check Claude/Codex (round 2).

## Historique / décisions

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`. Bug bash 3.2 confirmé en local : `_lib.sh:82-84` (`enable_globstar()` no-op sur 3.2) + branche spéciale partielle `_lib.sh:118-121` (couvre `prefix/**` simple, pas multi-niveaux). Choix Option B : un seul livrable cohérent ranking+correctness, acceptance bloque livraison sur matcher correct.
