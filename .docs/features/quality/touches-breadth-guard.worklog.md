# Worklog — quality/touches-breadth-guard

## 2026-06-26 — création + implémentation (approche hybride)

- Cadrage `aic-frame` après analyse de l'index : la « taxe » du gate `--staged` (un édit d'infra partagée flague des dizaines de features) vient de `touches:` mal classés, pas d'un bug. Le `FEATURE_TEMPLATE` cite déjà `tests/smoke-test.sh` comme exemple de `touches_shared`.
- Décision (confirmée utilisateur) : **hybride** — reclasser net la 1ʳᵉ vague + garde-fou advisory pour le reste incrémental. Rejet explicite du « filtre substantiel sur `--staged` » (affaiblirait la garantie).
- Livré :
  - `.ai/scripts/check-touches-breadth.sh` (+ jinja) : read-only, advisory, 2 signaux (A : fichier exact en touches: direct de > K features ; B : glob catch-all top-level). Exit 0 toujours. `AIC_TOUCHES_BREADTH_K` (défaut 4).
  - Wiring inspecteur `.ai/workflows/quality-gate.md` Phase 1 + ligne rapport (+ jinja).
  - `tests/unit/test-check-touches-breadth.sh` + smoke [0l].
  - Reclassement `tests/smoke-test.sh` → `touches_shared:` sur `core/aic-surface-canonical`, `core/codex-skills-install`, `product/product-portfolio-loop`, `quality/index-lock-contract` (propriétaire `quality/smoke-test` garde le direct).
- Run live : le guard surface README_AI_CONTEXT.md (13 features), README.md (10), `_lib.sh`/`aic.sh` (7), CHANGELOG.md (6)… + globs B (`.ai/**`, `template/**`, `tests/**`). `smoke-test.sh` est sorti du signal A après reclassement (confirme l'effet).
- Incident corrigé : le titre de cette fiche se terminait par `touches:` (deux-points non quoté) → YAML cassé → `build-feature-index.sh` plantait et cascade sur les hooks. Titre quoté. NB : build-feature-index gagnerait à ignorer/avertir sur une fiche malformée plutôt que crasher (suivi).
- Suivi : reclasser incrémentalement les fichiers flagués quand on touche leur feature (piloté par le guard + le nudge de consolidation).

## 2026-06-28 — 2e vague de reclassement (globs catch-all, Signal B)
- `template/**` (template-engine) → touches_shared ; `tests/**` (smoke-test → tests/smoke-test.sh ; project-overlay-scope-registry/stable → tests/unit/test-project-overlay.sh).
- Signal B ne liste plus que les globs légitimes (.ai/**, .githooks/**). Dé-taxe vérifiée : édit .jinja n'exige plus template-engine. check-features ✅.
- Non reclassé (co-propriété légitime) : build-feature-index.sh/.jinja sur index-contract-v2/feature-mesh-contract-alignment/okf-strict-profile.
- Fichiers : 4 fiches reclassées + cette fiche.

## 2026-06-29 — Signal A check-features (audit hebdo P0)
- Reclassement de `check-features.sh` / `.jinja` en `touches_shared` pour les fiches non propriétaires : `core/okf-strict-profile`, `quality/read-only-checks-contract`, `quality/cycle-detection`.
- `core/feature-mesh` conserve l'ownership direct : c'est la feature propriétaire du contrat frontmatter et du checker.
- Cause : le commit P0 `fix(core)` a dû bypasser le gate parce que le Signal A tirait des worklogs hors scope. Ce reclassement réduit la taxe à la racine et doit permettre au prochain edit `check-features.sh` de passer avec seulement le worklog propriétaire.

## 2026-06-30 — Signal A dispatchers/docs publiques
- Application du compagnon de reclassification demandé après `(a')` : exact owner unique pour `aic.sh`, `copier.yml`, `README.md`, `README_AI_CONTEXT.md`, dogfood update/drift, smoke-test et surfaces `aic-frame`.
- Objectif : tuer les ties exact-multi qui bloquaient le commit `aic-pilot` sans transformer les vraies features consommatrices en propriétaires opportunistes.
- Moat conservé : les propriétaires structurels gardent leur `touches:` exact et reçoivent un worklog frais ; les autres features restent visibles via `touches_shared`.

## 2026-07-01 — 2ᵉ vague : CHANGELOG.md → touches_shared: (fix diagnostiqué P6)
- Suite du diagnostic P6 (pilot `2026-06-30-ze-solution`) : `CHANGELOG.md` était en `touches:` DIRECT de 6 features (`aic-surface-canonical`, `codex-skills-install`, `feature-mesh-contract-alignment`, `okf-strict-profile`, `ai-context-stability-migration`, `read-only-checks-contract`) → toute entrée CHANGELOG déclenchait une cascade freshness cross-scope (constaté 2× ce fil : entrée CHANGELOG différée).
- Reclassé en `touches_shared:` dans les 6 fiches (déplacement mécanique, ±1 ligne/fiche). CHANGELOG reste visible en review mais ne bloque plus `check-feature-freshness --staged`.
- Vérifs : `check-features` PASS (6 fiches valides), `check-touches-breadth` ne liste PLUS `CHANGELOG.md` dans les surfaces >4. Personne n'« implémente » une feature DANS le changelog → aucun propriétaire exact légitime perdu.
- Reste (breadth-guard, vagues futures) : `_lib.sh`/`build-feature-index.sh`/`.ai/index.md`/`docs/upgrading.md` restent >4 mais sont des surfaces de code réelles (couverture plus légitime) — à trancher au cas par cas, pas mécaniquement.

## 2026-07-03 — 3ᵉ vague : docs/upgrading.md → owner migration unique
- Déclencheur : ajout prévu d'une note migration C1 (shims/AGENTS.md) dans `docs/upgrading.md` ; le fichier était en `touches:` exact de 6 features et aurait forcé 5 worklogs sans rapport.
- Décision : conserver l'ownership direct sur `product/ai-context-stability-migration` (page de migration globale), reclasser en `touches_shared:` les consommateurs `core/aic-surface-canonical`, `core/okf-strict-profile`, `core/project-overlay-stable`, `core/template-engine`, `quality/read-only-checks-contract`.
- Effet attendu : `docs/upgrading.md` reste visible en review/report pour ces features, mais ne bloque plus la fraîcheur staged quand une note d'upgrade appartient à une autre feature.

## 2026-07-03 — done
- Intent : clôturer `quality/touches-breadth-guard` après livraison du guard advisory et des premières vagues de reclassement.
- Fichiers/surfaces : `.docs/features/quality/touches-breadth-guard.md`, `.docs/features/quality/touches-breadth-guard.worklog.md`, `.ai/scripts/check-touches-breadth.sh`, `tests/unit/test-check-touches-breadth.sh`.
- Décision : statut `done`. Les signaux restants restent volontairement non bloquants et doivent être traités au fil de l'eau quand les features propriétaires sont rouvertes.
- Validation : `bash .ai/scripts/check-touches-breadth.sh` PASS advisory ; `bash tests/unit/test-check-touches-breadth.sh` PASS.
- Next : aucune action immédiate.

## 2026-07-16 15:37 — implement / HANDOFF Signal A confirmé
- Feature source : `core/feature-mesh-progressive-indexes` ; l'utilisateur confirme le HANDOFF transverse vers `quality/touches-breadth-guard`.
- Contexte : la revue Claude/Codex a révélé que les exact-multi historiques forçaient un gate freshness cross-scope sur les scripts partagés modifiés par les index progressifs.
- Décision : conserver un propriétaire structurel direct pour `_lib.sh`, `aic.sh`, les hooks/checks et les tests ; reclasser les consommateurs en `touches_shared:`. Conserver les quatre co-propriétaires légitimes de `build-feature-index.sh` documentés depuis la 2ᵉ vague.
- Surfaces reclassées : `_lib.sh`, `aic.sh`, `auto-worklog-log.sh`, `features-for-path.sh`, `check-commit-features.sh`, `check-feature-docs.sh`, `build-feature-index.sh` pour ses consommateurs, et leurs miroirs Jinja.
- Signal intermédiaire : `_lib.sh`, `build-feature-index.sh` et `check-commit-features.sh.jinja` sortent du Signal A ; restent seulement `.ai/index.md`, son miroir et `FEATURE_TEMPLATE.md`, hors delta courant.
- blockers : aucun.
- next : tracer l'impact chez les propriétaires directs, relancer les gates stricts puis refermer cette fiche.

## 2026-07-16 — review / propriétaires alignés
- Les propriétaires directs impactés ont reçu une trace de compatibilité dans leurs worklogs ; les consommateurs conservent la visibilité via `touches_shared:`.
- `check-features.sh --no-write` ✅ ; `check-feature-docs.sh --strict quality/touches-breadth-guard` ✅ ; `check-feature-freshness.sh --worktree --strict` ✅.
- Le guard ne signale plus les surfaces du delta courant ; les trois signaux restants (`.ai/index.md`, son miroir, `FEATURE_TEMPLATE.md`) sont hors scope et restent advisory.
- blockers : aucun.
- next : simuler le staging complet, exécuter le quality gate et clôturer si GO.

## 2026-07-16 — review / gaps staged-only traités
- La simulation via index Git alternatif a révélé six propriétaires absents des checks worktree : docs de migration, template du commit gate et templates du reminder.
- Correctifs : worklogs des propriétaires migration mis à jour ; consommateurs `git-hooks`, `graph-aware-injection` et `feature-mesh-progressive-indexes` reclassés en `touches_shared:` ; `workflow/pre-turn-reminder` reste propriétaire du reminder.
- next : régénérer les index et rejouer la simulation staged stricte.

## 2026-07-16 — review / owner runtime reminder explicité
- Le second staging simulé a révélé que le runtime `pre-turn-reminder.sh` n'avait qu'un coverer glob `.ai/**` (`dogfood-runtime-sync`).
- `workflow/pre-turn-reminder` devient propriétaire exact du runtime comme de son miroir Jinja ; le glob dogfood reste secondaire advisory.
- next : rejouer la simulation staged stricte.

## 2026-07-16 15:46 — DONE

### Evidence
- Build : `bash .ai/scripts/build-feature-index.sh --write` ✅
- Tests : `bash tests/unit/test-check-touches-breadth.sh` ✅ ; suite unitaire 45/45 ✅ ; smoke Copier ✅
- Gates : freshness worktree strict ✅ ; staging complet simulé strict + gate `feat:` ✅ ; quality gate ✅

### Résumé livré
- Consommateurs des surfaces partagées reclassés en `touches_shared:` avec propriétaires structurels directs conservés.
- Co-propriété légitime de `build-feature-index.sh` préservée et documentée.
- Propriétaires migration, hooks, reminder et tests tracés dans leurs worklogs.
- Signal A nettoyé pour tout le delta des index Markdown progressifs.

### Commit suggéré
refactor(quality): reclasser les surfaces partagées du feature mesh
