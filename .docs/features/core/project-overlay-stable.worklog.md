# Worklog — core/project-overlay-stable

## 2026-05-05 — création
- Feature créée par /aic-feature-new
- Scope : core
- Intent initial : Overlay projet stable

## 2026-05-06 — freshness
- Impact indirect : les scripts source-only de dogfooding synchronisent désormais `.agents/**`.
- Aucun changement sur le contrat `.ai/project/**` ni sur l'overlay projet stable.

## 2026-05-06 — freshness
- Impact indirect : README, template README et `copier.yml` mentionnent le nouveau skill tout en conservant `.ai/project/index.md` optionnel.
- `legacy` reste documenté comme scope custom activable par projet, pas comme scope template.
- Validation associée : `check-ai-references.sh`, smoke-test PASS.
## 2026-05-06 — freshness
- Intent : tracer l'impact documentaire indirect sur README, Copier, upgrading et smoke pendant la canonisation `aic`.
- Validation : couvert par `check-shims`, `check-ai-references` et `tests/smoke-test.sh`.

## 2026-05-06 — freshness README
- Intent : verifier que le README conserve la règle `.ai/project/index.md` comme overlay project-owned et on-demand.
- Validation : `check-ai-references`, `check-features`.

## 2026-05-06 22:50 — freshness
- Impact indirect : `copier.yml` mis à jour pendant le durcissement post-cross-check (round 4 workflow/intentional-skills).
- Aucun changement sur le contrat `.ai/project/**` ni sur l'overlay projet.
- Validation associée : `check-feature-freshness.sh` (staged) PASS attendu.

## 2026-05-07 — freshness
- Impact indirect : `tests/unit/test-review-delta-uncommitted.sh` ajouté pendant l'implémentation de `quality/review-delta-uncommitted-coverage`. Aucun changement sur le contrat overlay projet ni sur `.ai/project/**`.
- Validation associée : `bash tests/unit/test-review-delta-uncommitted.sh` (6 cas) PASS.
