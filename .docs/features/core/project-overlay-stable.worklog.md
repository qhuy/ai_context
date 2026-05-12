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

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - tests/unit/test-review-delta-uncommitted.sh

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - tests/unit/test-review-delta-uncommitted.sh

## 2026-05-07 — freshness
- Impact indirect : ajout/extension de tests unit (`test-matcher-multi-level.sh` nouveau, `test-path-matches-touch.sh` étendu) pendant la livraison Phase 2 #2.
- Aucun changement sur le contrat overlay projet ni sur `.ai/project/**`.
- Validation associée : 49 cas test unit PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - tests/unit/test-matcher-multi-level.sh
  - tests/unit/test-path-matches-touch.sh

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - tests/unit/test-matcher-multi-level.sh

## 2026-05-07 01:16 — auto
- Fichiers modifiés :
  - tests/unit/test-matcher-multi-level.sh

## 2026-05-07 — freshness
- Impact indirect : ajout d'un nouveau test unit `tests/unit/test-context-relevance.sh` (livraison Phase 2 #3). Aucune modif sur le contrat overlay projet.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh
  - tests/unit/test-context-relevance.sh

## 2026-05-07 14:45 — auto
- Fichiers modifiés :
  - tests/unit/test-context-relevance.sh

## 2026-05-07 14:53 — auto
- Fichiers modifiés :
  - tests/unit/test-context-relevance.sh

## 2026-05-07 — freshness
- Impact indirect : ajout d'un nouveau test unit `tests/unit/test-auto-progress-filter.sh` (livraison Phase 2 #4).
- Aucun changement sur le contrat overlay projet.

## 2026-05-07 17:33 — auto
- Fichiers modifiés :
  - tests/unit/test-auto-progress-filter.sh

## 2026-05-07 18:04 — auto
- Fichiers modifiés :
  - tests/unit/test-auto-progress-filter.sh

## 2026-05-07 — freshness
- Impact indirect : ajout d'un nouveau test unit `tests/unit/test-stop-hook-idempotence.sh` (livraison Phase 2 #5).

## 2026-05-08 — freshness
- Impact indirect : nettoyage drift README runtime/template + note mainteneur PROJECT_STATE (driver core/dogfood-runtime-sync).
- Aucun changement de contrat propre a cette feature.

## 2026-05-12 — impact partagé test lock index

- Fichiers/surfaces : `tests/smoke-test.sh`.
- Contexte : `quality/index-lock-contract` ajoute une assertion smoke sans modifier le comportement project overlay.
- Impact : aucun changement fonctionnel du project overlay.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — impact partagé conventions commit

- Fichiers/surfaces : `.ai/index.md`, `template/.ai/index.md.jinja`.
- Contexte : l'item AI Debate `0013/Q3` ajoute un arbre de décision compact pour `feat:`, `fix:`, `refactor:`, `chore:`, `docs:` et `doc.level`.
- Impact : le chargement de l'overlay projet reste inchangé ; l'index expose seulement une règle de décision agentique supplémentaire.
- Validation portée par les checks Q3.

## 2026-05-12 — impact Q4 régressions ciblées

- Surfaces : `tests/smoke-test.sh`, `tests/unit/test-targeted-regressions.sh`.
- Impact : le test cible Q4 cree des copies temporaires du projet pour isoler fallback, lock et rendu Copier ; le smoke l'execute comme prevalidation.
- Validation : `bash tests/unit/test-targeted-regressions.sh` PASS ; `bash tests/smoke-test.sh` PASS.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : README/template et tests ajoutent le check agent-config sans modifier le contrat `.ai/project/index.md`.
- Aucun chargement additionnel de l'overlay projet au demarrage.
- Validation : `check-shims`, `check-features` et smoke-test PASS.
