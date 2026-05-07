---
id: auto-progress-file-filter
scope: workflow
title: Filtrer la transition spec→implement par type de fichier édité
status: draft
depends_on: []
touches:
  - .ai/scripts/auto-progress.sh
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/auto-progress.sh.jinja
  - template/.ai/scripts/_lib.sh.jinja
  - tests/unit/test-auto-progress-filter.sh
touches_shared:
  - .ai/scripts/features-for-path.sh
  - .claude/settings.json
  - tests/smoke-test.sh
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
  phase: review
  step: "implémentation livrée, 22 cas test PASS, prêt à commit"
  blockers: []
  resume_hint: "commit feat(workflow) ; #5 stop-hook-idempotence consommera le helper dans un turn dédié"
  updated: 2026-05-07
---

# Filtrer la transition spec→implement par type de fichier édité

## Résumé

Aujourd'hui, le hook Stop côté Claude bumpe `progress.phase` de `spec` à `implement` dès qu'un fichier est édité dans le tour, peu importe le fichier. Éditer un README, un test, un commentaire ou une fiche feature suffit à faire passer la feature en `implement`. Conséquence : `progress.phase` perd son pouvoir de signal pour `aic-status` et la reprise.

Cette fiche couvre le filtrage de la transition : ne bumper la phase que si le fichier édité correspond réellement à une implémentation (matche un `touches:` direct de la feature, pas `touches_shared:`, et n'est pas une extension purement documentaire/test/config).

## Objectif

Restaurer la sémantique de `progress.phase` comme signal vrai de l'avancement implémentation. `phase: implement` doit indiquer qu'on a vraiment commencé à coder le livrable, pas qu'on a juste touché un fichier dans le périmètre élargi.

## Périmètre

### Inclus

- Lire le code actuel de `auto-progress.sh` et identifier où la décision de bump se prend.
- Définir le critère « édit structurel » : fichier matche `touches:` direct (pas `touches_shared:`) ET extension ∈ liste autorisée (probablement code source du projet, à exclure : `.md`, `.txt`, `.lock`, `.json` hors config-driven, fichiers de tests, fixtures).
- Implémenter le filtre dans `auto-progress.sh` : si zéro fichier édité ne passe le filtre, no-op sur la transition spec→implement.
- Tests reproductibles : édit `.md` seul → no bump ; édit fichier dans `touches_shared` seul → no bump ; édit fichier dans `touches:` direct → bump.
- Documentation du filtre dans le workflow associé (`.ai/workflows/feature-update.md` ou nouvelle section).

### Hors périmètre

- Idempotence du Stop hook sur tours purement conversationnels (`workflow/stop-hook-idempotence`, Phase 2 #5).
- Couverture du delta uncommitted (`quality/review-delta-uncommitted-coverage`).
- Ranking et matcher correct (`quality/features-for-path-ranking-and-matcher-correctness`) — mais le filtre dépend du matcher correct pour identifier `touches:` direct vs `touches_shared:`.
- Transitions implement→review et review→done (restent manuelles via `/aic`).

### Granularité / nommage

Cette fiche couvre **uniquement** la transition `spec→implement` du hook Stop. Les autres transitions auto-progressives (s'il y en a) ne sont pas dans le scope.

## Invariants

- Le filtre reste agent-agnostic : `auto-progress.sh` est un script Bash invoqué par hook. Si Codex acquiert un hook Stop équivalent un jour, le même script s'applique.
- Comportement déterministe : pour un même set d'édits, la décision bump/no-bump est reproductible.
- `/aic` reste la voie d'override : si le filtre bloque indûment, l'humain peut forcer la transition par langage naturel ou `/aic`.
- Pas de régression sur les transitions manuelles ou sur les autres phases.

## Décisions

Tranchées post cross-check Codex 2026-05-07 :

### 1. Critère « non-structurel » (Codex affine A1 → ciblé)

- **Exclure toujours** : `.docs/features/**` (fiches + worklogs), `*.worklog.md` partout, `.lock`, fichiers cachés `.ai/.*` (logs/cache auto).
- **Ne pas exclure** `.md` globalement en v1. Un `.md` peut être le livrable réel d'une feature documentaire dans ce repo. Override via env var possible mais pas en défaut.
- Le critère est **complémentaire** au matching `touches:` direct : on filtre l'édit AVANT d'évaluer s'il bumpe la phase. Le caller `auto-progress.sh` consomme déjà des fichiers déjà passés par `features_matching_path`.

### 2. Tests = structurel (B1)

Si un fichier de test matche `touches:` direct d'une feature, son édit est structurel. TDD doit pouvoir faire passer `spec → implement`. Pas de filtre extension `.test.*` ou `_test.go`.

### 3. Feature sans `touches:` = no-bump (C1/C3)

Cas en pratique exclu par le flux actuel : `auto-worklog-log.sh` ne logge dans `.session-edits.log` que les fichiers matchant un `touches:` direct via `features_matching_path`. Une feature sans `touches:` n'arrive donc pas dans `auto-progress.sh`, sauf trace synthétique/stale.

Tranche : **no-bump**. Debug visible si `AI_CONTEXT_DEBUG=1`. Override via `/aic` si besoin réel.

### 4. Helper minimal `is_structural_feature_edit` (D1)

Signature : `is_structural_feature_edit <feature_path> <file_path>`. Retourne 0 si l'édit est structurel pour la feature, 1 sinon.

**Périmètre minimal** : filtre metadata/noise uniquement. Ne refait pas la politique matcher (`features_matching_path` a déjà tranché direct vs shared). Dans `auto-progress.sh`, on peut revalider direct-vs-shared via l'index si besoin, mais c'est un raffinement séparé.

Refactor dans `_lib.sh` pour partage avec Phase 2 #5 (`stop-hook-idempotence`) sans coupling fort : #5 consommera le helper dans son turn dédié.

### 5. Tests E1 dédiés

`tests/unit/test-auto-progress-filter.sh` couvrant 7 cas (cf. Validation).

### Stratégie de delivery — L2 (sequential)

#4 livre le helper + son consumer (`auto-progress.sh`). #5 dans un turn dédié consommera le helper sans refactor supplémentaire. Pas de dual delivery #4+#5 dans ce turn.

## Comportement attendu

`auto-progress.sh` invoqué par le hook Stop avec la liste des fichiers édités dans le tour :

1. Récupérer la feature en `progress.phase: spec` ciblée par le tour.
2. Pour chaque fichier édité, vérifier qu'il matche un `touches:` direct (pas `touches_shared:`) ET n'a pas une extension exclue.
3. Si au moins un fichier passe le filtre → bumper `phase` à `implement` et appender le tour au worklog.
4. Si zéro fichier passe → no-op sur la transition (mais peut continuer à appender un freshness au worklog selon `workflow/stop-hook-idempotence`).

## Contrats

- Variables d'env : `AI_CONTEXT_AUTO_PROGRESS_DISABLED=1` désactive complètement (existant probablement). `AI_CONTEXT_AUTO_PROGRESS_FILTER_EXT` permet d'override la liste d'extensions exclues si besoin.
- Code retour 0 toujours (best-effort).
- Trace : si `AI_CONTEXT_DEBUG=1`, logger la décision bump/no-bump avec le motif (« 0/3 fichiers structurels » par exemple).

## Validation

Tests obligatoires (Codex post cross-check, 7 cas) :

1. `.docs/features/**` seul édité → no-bump.
2. Worklog `*.worklog.md` seul → no-bump.
3. Source matchant `touches:` direct → bump.
4. Test matchant `touches:` direct → bump (TDD valide).
5. `touches_shared:` seul → no-bump.
6. Feature sans `touches:` → no-bump.
7. Override env d'extensions exclues si ajoutée (optionnel v1).

Plus :
- `bash tests/smoke-test.sh` PASS après intégration.
- Non-régression : édit fichier source légitime continue de bumper.

## Risques

- Sur-filtrer : risque d'empêcher la transition légitime si la liste d'extensions est trop large. Compenser via `/aic` override et logs debug.
- Sous-filtrer : risque de garder le bug actuel si les critères sont trop laxistes. Boucle de validation : tester sur 5-10 features récentes et voir si les transitions auraient été correctes.
- Le filtre dépend du matcher de `features-for-path.sh` (cf. `quality/features-for-path-ranking-and-matcher-correctness`). Sur bash 3.2 avec matcher buggé, le filtre peut classer un fichier comme `touches_shared:` à tort. À tester après le fix matcher.
- Compatibilité : si une feature n'a pas de `touches:` (cas légitime ?), comportement à définir. Probable : laisser bumper comme fallback.

## Cross-refs

- `workflow/stop-hook-idempotence` : Phase 2 #5, partenaire naturel sur le hook Stop. Implémentation possible dans le même turn ou en deux temps.
- `quality/features-for-path-ranking-and-matcher-correctness` : Phase 2 #2, le filtre devient fiable après le matcher correct.
- `core/feature-mesh` : modèle `touches:` vs `touches_shared:`, la distinction est centrale ici.
- `workflow/auto-worklog` : hook proche, mêmes contraintes best-effort.
- `workflow/intentional-skills` : ordre Phase 2 décidé après cross-check Claude/Codex (round 4).

## Historique / décisions

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`. Bug de signal identifié : `progress.phase` devient bruyant car bumpé sur n'importe quelle édition. Fix : filtre déterministe par `touches:` direct + extension structurelle. Indépendant des autres fiches Phase 2 (peut être livré sans #1, #2, #3) mais devient calibré après matcher correct.
