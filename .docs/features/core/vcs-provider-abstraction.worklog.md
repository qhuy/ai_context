# Worklog — core/vcs-provider-abstraction

## 2026-07-03 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : abstraction VCS Git / TFVC pour rendre ai_context compatible avec les projets TFS non-Git.

## 2026-07-03 — implementation provider
- Ajout de `.ai/scripts/_vcs.sh` et du miroir template pour abstraire `git`, `tfvc` et `none`.
- Branchement des scripts freshness, commit guard, review delta, pr-report, doctor, stop gate et surface `aic`.
- Ajout de `vcs.provider` dans la config source/template et dans Copier.
- Test unitaire `tests/unit/test-vcs-provider.sh` ajouté et branché dans le smoke.

## 2026-07-03 — HANDOFF cross-scope
- HANDOFF explicites ajoutés dans les worklogs des surfaces co-propriétaires touchées par freshness : `core/feature-index-cache`, `core/index-contract-v2`, `core/okf-strict-profile`, `core/aic-surface-canonical`, `quality/doc-freshness`, `quality/read-only-checks-contract`, `quality/pr-report`, `quality/doctor`, `quality/agent-config-validation`, `quality/review-delta-uncommitted-coverage`, `quality/features-for-path-ranking-and-matcher-correctness`, `quality/index-lock-contract`, `quality/targeted-regression-coverage`, `quality/smoke-test`, `workflow/auto-progress-file-filter`, `workflow/stop-turn-doc-gate`.
- Ces HANDOFFs documentent un impact partagé sans changer le statut ni le contrat propre de ces features.

## 2026-07-03 — préparation validation
- Intent : rendre le delta VCS cohérent avec le feature mesh avant gate.
- Fichiers/surfaces : runtime `.ai/scripts/*`, miroirs `template/.ai/scripts/*.jinja`, config Copier/runtime, README, tests unitaires et smoke.
- Décision : `README_AI_CONTEXT.md` et les tests touchés sont couverts directement par la fiche, car ils valident ou documentent le nouveau contrat VCS.
- Doc Impact Decision : C — nouveau contrat runtime, option Copier `vcs_provider`, comportement TFVC/pending changes documenté.
- Validation prévue : test provider VCS, tests build-index touchés, tests freshness/review/commit guard, drift dogfood, checks feature/freshness.
- Next : exécuter la gate et clôturer si tous les checks passent.

## 2026-07-03 — done
- Intent : clôture de `core/vcs-provider-abstraction`.
- Evidence : `bash tests/unit/test-vcs-provider.sh`, tests build-index ciblés, `test-check-commit-features-relevance`, `test-check-feature-freshness`, `test-review-delta-uncommitted`, `test-features-for-path-relevance-ranking`, `test-stop-hook-idempotence`, `test-auto-progress-filter`, `check-feature-docs --strict core/vcs-provider-abstraction`, `check-dogfood-drift`, `check-shims`, `check-agent-config`, `check-ai-references`, `check-features --no-write`, `check-feature-coverage`, `check-touches-breadth`, `measure-context-size`, `tests/smoke-test.sh` : PASS/OK.
- Risk ledger : pas de breaking change Git attendu ; pas de migration de données ; pas d'auth/data/UX ; nouveau contrat runtime `vcs.provider` documenté ; TFVC reste best-effort sur le parsing de `tf status`.
- Doc Impact Decision : C — fiche, worklog, README, config Copier et handoffs worklogs mis à jour.
- Next : commit `feat(core): abstraire le provider VCS`.
## 2026-07-03 — routage aic knowledge sans changement VCS

- Intent : tracer le changement de `aic.sh` imposé par `workflow/knowledge-publish-search-link`.
- Fichiers/surfaces : `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`.
- Décision : aucun comportement VCS modifié ; le wrapper route `knowledge` vers un script dédié, comme les autres sous-commandes.
- Validation : le test workflow passe via `aic.sh knowledge`; freshness stricte doit constater ce worklog core dans le delta.
- Next : aucune action VCS ; rouvrir seulement si les commandes knowledge doivent lire le provider VCS courant.

## 2026-07-06 — couverture incidente (workflow/codex-hooks-parity)
- Surfaces partagées touchées : header de `stop-doc-gate.sh` (+ miroir jinja) requalifié « protocole decision:block partagé Claude/Codex » (aucun changement de logique VCS) ; `copier.yml` (question enable_codex_hooks) ; `tests/smoke-test.sh` (étape [28d/28]). Aucun changement du contrat provider VCS.
- Validation portée par `workflow/codex-hooks-parity`.

## 2026-07-06 — couverture incidente (workflow/codex-hooks-parity, commit docs)
- `README_AI_CONTEXT.md` (+ miroir jinja) et `copier.yml` (`_message_after_copy`) : documentation des hooks Codex natifs opt-in. Aucun changement du contrat provider VCS.
- Validation portée par `workflow/codex-hooks-parity`.

## 2026-07-06 12:03 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh

## 2026-07-06 — couverture incidente (core/agents-md-shim-canonical, P2)
- Surfaces partagées touchées : `copier.yml` (question enable_copilot_shim) et `tests/smoke-test.sh` (étape [28e/28]). Aucun changement du contrat provider VCS. Validation portée par `core/agents-md-shim-canonical`.

## 2026-07-06 — couverture incidente (core/agents-md-shim-canonical, P2 commit ③)
- `copier.yml`, `tests/smoke-test.sh` (bloc [28b] cursor), `template/README_AI_CONTEXT.md.jinja` (ligne Cursor conditionnelle — le rendu minimal, sans cursor, est inchangé). Aucun changement du contrat provider VCS.
