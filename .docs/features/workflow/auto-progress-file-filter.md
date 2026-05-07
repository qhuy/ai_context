---
id: auto-progress-file-filter
scope: workflow
title: Filtrer la transition spec→implement par type de fichier édité
status: draft
depends_on: []
touches:
  - .ai/scripts/auto-progress.sh
  - .claude/settings.json
  - tests/smoke-test.sh
touches_shared:
  - .ai/scripts/features-for-path.sh
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
  step: "draft cadré, à reprendre pour implémentation"
  blockers: []
  resume_hint: "lire auto-progress.sh, définir le critère « édit structurel », implémenter le filtre + tests reproductibles"
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

Ouvertes, à arbitrer en phase implement :

- Liste d'extensions « non structurelles » : par défaut `.md`, `.txt`, `.lock`. À discuter pour `.json`, `.yml` (souvent config, parfois data).
- Comportement sur fichiers de tests : (a) considérer comme structurel (TDD valide la phase implement), ou (b) non structurel (test seul ne fait pas avancer la feature). Préférence par défaut : (a) pour ne pas pénaliser TDD.
- Fichiers fiches feature (`.docs/features/<scope>/<id>.md`) : non structurels par définition (la fiche n'est pas l'implémentation).
- Si la feature n'a pas de `touches:` (cas pathologique), comportement actuel ou no-bump strict ?

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

- Test reproductible 1 : feature en `phase: spec`, hook Stop avec un seul fichier `.md` édité → vérifier que phase reste `spec`.
- Test reproductible 2 : même feature, hook Stop avec un fichier source matchant `touches:` direct → vérifier que phase devient `implement`.
- Test reproductible 3 : même feature, hook Stop avec mix `.md` + source structurel → bump (au moins un fichier passe).
- Test reproductible 4 : même feature, hook Stop avec uniquement des fichiers `touches_shared:` → no-bump.
- `bash tests/smoke-test.sh` PASS après intégration.

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
