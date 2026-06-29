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
