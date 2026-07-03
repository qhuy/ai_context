---
id: touches-breadth-guard
scope: quality
title: "Garde-fou advisory contre la sur-couverture touches:"
status: done
type: feature
description: "Check advisory qui signale les fichiers infra partagés (et globs trop larges) en touches: direct, candidats à touches_shared, pour réduire la taxe du gate freshness --staged."
depends_on:
  - core/feature-mesh
  - quality/doc-freshness
  - workflow/feature-consolidation-nudge
touches:
  - .ai/scripts/check-touches-breadth.sh
  - template/.ai/scripts/check-touches-breadth.sh.jinja
  - tests/unit/test-check-touches-breadth.sh
touches_shared:
  - .ai/workflows/quality-gate.md
  - template/.ai/workflows/quality-gate.md.jinja
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
  phase: done
  step: "guard advisory livré : signaux A/B, test, wiring quality-gate/smoke et vagues de reclassement validés"
  blockers: []
  resume_hint: "aucune action immédiate ; traiter les signaux advisory restants au fil de l'eau quand leurs features propriétaires sont rouvertes"
  updated: 2026-07-03
---

# Garde-fou advisory contre la sur-couverture touches:

## Résumé

Le gate de fraîcheur `check-feature-freshness.sh --staged --strict` exige, pour chaque fichier de code stagé, que **toutes** les features dont un `touches:` direct le couvre soient documentées. Quand un fichier d'**infra partagée** (ex. `tests/smoke-test.sh`, `README*.md`, `_lib.sh`) est listé en `touches:` direct par des dizaines de features, un simple édit force à toucher des dizaines de worklogs — la « taxe ». Ce check **advisory** détecte ces sur-couvertures et propose de les reclasser en `touches_shared:` (qui apparaît dans les rapports mais ne déclenche **pas** l'obligation `--staged`).

## Objectif

Rendre **visible et réductible au fil de l'eau** la sur-couverture `touches:`, sans nettoyage de masse ni gate bloquant. Complète `workflow/feature-consolidation-nudge` (prolifération de fiches) côté **modèle de couverture**.

## Périmètre

### Inclus

- `check-touches-breadth.sh` : check read-only, deux signaux advisory.
  - **A** : fichier exact présent dans le `touches:` direct de > K features (`AIC_TOUCHES_BREADTH_K`, défaut 4).
  - **B** : glob catch-all top-level en `touches:` (préfixe non-glob ≤ 1 segment : `.ai/**`, `template/**`, `tests/**`…).
- Wiring dans l'inspecteur `.ai/workflows/quality-gate.md` (Phase 1, ligne advisory + ligne de rapport).
- 1ʳᵉ vague de reclassement : `tests/smoke-test.sh` → `touches_shared:` sur les 4 features qui ne le possèdent pas (propriétaire `quality/smoke-test` garde le direct).

### Hors périmètre

- **Blocage** : jamais (honore `workflow/feature-granularity` « pas de gate fragile dans les scripts »). Exit 0 toujours.
- Reclassement automatique des fiches (jugement scope/ownership ; reste manuel/incrémental).
- Réécriture des globs larges légitimes (ex. `git-hooks` possède `.githooks/**`) : le signal B dit « vérifier », pas « corriger ».
- Le filtre `--staged` lui-même (rejeté : appliquer le filtre « substantiel » au commit affaiblirait la garantie — workflows/settings/templates sont comportementaux).

## Invariants

- **Advisory, exit 0 toujours.** Aucune écriture (read-only : index temporaire `mktemp`, jamais `.ai/.feature-index.json`).
- Le signal A ne flague que les `touches:` **directs** (pas `touches_shared`), cohérent avec `features_matching_path` qui pilote le gate.
- `K` configurable (`AIC_TOUCHES_BREADTH_K`).

## Décisions

- **Reclasser plutôt que filtrer.** La taxe vient de données mal classées (infra partagée en `touches:`), pas d'un bug du gate. Le `FEATURE_TEMPLATE` cite déjà `tests/smoke-test.sh` comme exemple de `touches_shared` → la reclassification est endossée, pas un jugement.
- **Hybride** : reclasser net la 1ʳᵉ vague (`smoke-test.sh`) + garde-fou pour le reste, traité incrémentalement (philosophie « pas en une fois »).
- **Signal A data-driven** (fréquence > K) : auto-ajustant, sans liste curatée à maintenir.

## Comportement attendu

`bash .ai/scripts/check-touches-breadth.sh` liste les fichiers/globs sur-couvrants avec le nombre de features et la suggestion `touches_shared:`. Ne bloque jamais. Lancé en Phase 1 de l'inspecteur quality-gate (advisory).

## Contrats

- Env : `AIC_TOUCHES_BREADTH_K` (seuil signal A, défaut 4).
- Sortie : rapport texte + `✅`/`ℹ️`. Exit 0 toujours.
- Read-only : `mktemp` index, fallback cache existant, sinon no-op.

## Validation

`tests/unit/test-check-touches-breadth.sh` (smoke [0l]) : Signal A flague un fichier partagé par > K features ; Signal B flague un glob top-level ; un fichier mono-feature n'est pas flagué ; exit 0 ; pas de création d'index.

Clôture 2026-07-03 : `bash .ai/scripts/check-touches-breadth.sh` PASS advisory (signaux restants attendus, exit 0) ; `bash tests/unit/test-check-touches-breadth.sh` PASS.

## Risques

- **Bruit** : flague beaucoup au départ (README*, _lib.sh, aic.sh…). C'est le but (surfacer la dette) ; advisory, à traiter au fil de l'eau. `K` ajustable.
- **Sous-couverture si sur-reclassement** : ne jamais reclasser un fichier réellement possédé par une feature. Le signal B dit « vérifier ».

## Cross-refs

- `core/feature-mesh` : modèle `touches:` vs `touches_shared:` que ce garde-fou fait respecter.
- `quality/doc-freshness` : c'est son gate `--staged` dont ce check réduit la taxe.
- `workflow/feature-consolidation-nudge` : pendant « prolifération de fiches » ; même philosophie incrémentale advisory.

## Historique / décisions

- 2026-06-26 : création (cadrage `aic-frame`, approche hybride confirmée). Guard A+B + wiring + test. 1ʳᵉ vague reclassement `tests/smoke-test.sh` → `touches_shared:` sur `core/aic-surface-canonical`, `core/codex-skills-install`, `product/product-portfolio-loop`, `quality/index-lock-contract`. Reste surfacé par le guard pour traitement incrémental (README*, `_lib.sh`, `aic.sh`, `CHANGELOG.md`, `.ai/**`, `template/**`…).
- 2026-06-28 : **2ᵉ vague — globs catch-all (Signal B)** (frame de remédiation 2026-06-28, suite à la taxe observée : guardrails 5 fiches, fix A1 12 fiches, moat git désormais actif). Reclassés `touches:` → `touches_shared:`/affinés : `core/template-engine` `template/**` → `touches_shared` (garde `copier.yml` direct = le moteur) ; `quality/smoke-test` `tests/**` → `tests/smoke-test.sh` direct + `tests/**` shared ; `core/project-overlay-scope-registry` et `core/project-overlay-stable` `tests/**` → `tests/unit/test-project-overlay.sh` direct. Signal B ne liste plus que les globs **légitimes** (`dogfood-runtime-sync → .ai/**`, `git-hooks → .githooks/**`). Dé-taxe vérifiée : un édit `.jinja` n'exige plus `template-engine`. **Volontairement non reclassé** : `build-feature-index.sh`/`.jinja` reste direct sur `index-contract-v2`, `feature-mesh-contract-alignment`, `okf-strict-profile` — co-propriété légitime (contrat/parser/champ type), reclasser créerait de la sous-couverture. Reste : Signal A (README*, `_lib.sh`, `aic.sh`) + globs 2-segments non détectés par B (`tests/unit/**`), au fil de l'eau.
- 2026-06-30 : **3ᵉ vague — dispatchers et docs publiques exact-multi** après livraison du contrat freshness `(a')`. Propriétaires exacts retenus : `core/aic-surface-canonical` pour `aic.sh` / `README_AI_CONTEXT`, `core/template-engine` pour `copier.yml`, `product/readme-positioning` pour `README.md`, `core/dogfood-runtime-sync` pour `dogfood-update.sh` / `check-dogfood-drift.sh`, `quality/smoke-test` pour `tests/smoke-test.sh`, `workflow/aic-frame-external-reference` pour `aic-frame` et les templates de frames. Les features consommatrices passent en `touches_shared:` pour garder le signal sans cascade.
- 2026-07-03 : DONE documentaire. Le guard est livré et reste volontairement advisory ; les signaux résiduels (`_lib.sh`, `.ai/index.md`, `build-feature-index.sh`, globs légitimes) sont une dette de reclassement au fil de l'eau, pas un blocker de cette feature.
