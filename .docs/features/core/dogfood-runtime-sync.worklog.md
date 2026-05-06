# Worklog — core/dogfood-runtime-sync

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` et `.docs/FEATURE_TEMPLATE.md` restent compatibles avec le runtime dogfood.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` ajoute une validation explicite avant écriture sans changer les invariants dogfood.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-features.sh` et `check-feature-docs.sh workflow/feature-new-approval-step` PASS.

## 2026-05-04 — dogfood
- `bash .ai/scripts/dogfood-update.sh --apply` exécuté après propagation des règles feature-new dans le template Copier.
- Drift initial détecté sur `.ai/workflows/feature-new.md` et `.docs/FEATURE_TEMPLATE.md`, puis résolu après mise à jour des fichiers `template/...`.
- Validations associées : `check-dogfood-drift.sh`, `check-shims.sh`, `check-features.sh` PASS.

## 2026-05-05 — freshness
- Impact transversal : l'overlay projet stable ajoute `.ai/OWNERSHIP.md`, `.ai/templates/project-overlay/README.md` et adapte les scripts dogfood pour préserver `.ai/project/**`.
- Validation associée : dogfood-update appliqué puis `check-dogfood-drift.sh`, `check-shims.sh`, `check-features.sh` PASS.

## 2026-05-06 — dogfood
- `bash .ai/scripts/dogfood-update.sh --apply` exécuté après ajout de `document-feature` au template.
- Runtime synchronisé : `.ai/workflows/document-feature.md`, `.claude/skills/aic-document-feature/**`, `.agents/skills/aic-document-feature/**`, `README_AI_CONTEXT.md`.
- Validation prévue : `check-dogfood-drift.sh`, `check-shims.sh`, `check-features.sh`.

## 2026-05-06 — freshness commit
- Impact couvert : runtime `.ai/workflows/**`, `.claude/skills/**`, `.agents/skills/**` et `README_AI_CONTEXT.md` synchronisés.
- Aucun changement sur le contrat source-only de dogfood.
- Validation associée : `check-dogfood-drift.sh`, `check-shims.sh`, smoke-test PASS.
## 2026-05-06 — freshness
- Intent : documenter l'impact du renommage runtime `ai-context.sh` -> `aic.sh` sur les surfaces dogfoodées.
- Validation : couvert par `check-shims`, `check-features` et `tests/smoke-test.sh`.

## 2026-05-06 — retours review
- Intent : garder le runtime dogfoodé aligné avec les corrections staged-delta et surface `aic`.
- Fichiers/surfaces : `.ai/scripts/aic.sh`, `.ai/scripts/review-delta.sh`, `.ai/scripts/check-feature-freshness.sh`.
- Décision : les suppressions et renommages staged restent visibles dans les rapports et contrôles du runtime source.
- Validation : prévue via `bash -n`, `check-shims`, `check-feature-freshness --staged --strict`.

## 2026-05-06 21:46 — dogfood skills
- Audit skills relu côté runtime dogfoodé : wrappers Codex/Claude minces, workflows canoniques sous `.ai/workflows/`, Pack A toujours lean.
- Derniers commits vérifiés : surfaces runtime/template touchées (`aic.sh`, `review-delta.sh`, `check-feature-freshness.sh`, `document-feature`, skills Claude/Codex, `README_AI_CONTEXT.md`).
- Validation : `dogfood-update.sh` dry-run PASS, `check-dogfood-drift.sh` PASS, `check-shims.sh` PASS, `check-features.sh` PASS, `measure-context-size.sh` à 2627 chars.
- Décision : pas de `dogfood-update.sh --apply` nécessaire, le runtime source est déjà aligné avec le rendu Copier minimal ; les écarts `*.jinja` vs fichiers rendus sont des substitutions attendues (`{{ docs_root }}`, raw Jinja, variables projet).
- Dette hors scope primaire : `workflow/intentional-skills` reste à remettre au format documentaire strict (`Résumé`, `Périmètre`, `Invariants`, `Décisions`, `Validation`).

## 2026-05-06 21:57 — dogfood skills
- Impact runtime/template : workflows `aic` et `aic-frame`, wrappers Codex procéduraux, templates `.agents/.claude` et message Copier.
- Décision : garder runtime et template synchronisés pendant le resserrage de la surface skills.
- Validation : `check-dogfood-drift.sh` et `dogfood-update.sh` dry-run à relancer après édition.

## 2026-05-06 22:46 — auto
- Fichiers modifiés :
  - .agents/skills/aic-feature-done/SKILL.md
  - .agents/skills/aic-feature-done/workflow.md
  - .agents/skills/aic-feature-handoff/SKILL.md
  - .agents/skills/aic-feature-handoff/workflow.md
  - .agents/skills/aic-feature-new/SKILL.md
  - .agents/skills/aic-feature-new/workflow.md
  - .agents/skills/aic-feature-resume/SKILL.md
  - .agents/skills/aic-feature-resume/workflow.md
  - .agents/skills/aic-feature-update/SKILL.md
  - .agents/skills/aic-feature-update/workflow.md
  - .agents/skills/aic-frame/workflow.md
  - .agents/skills/aic-quality-gate/SKILL.md
  - .agents/skills/aic-quality-gate/workflow.md
  - .agents/skills/aic-ship/SKILL.md
  - .agents/skills/aic-status/SKILL.md
  - .claude/skills/aic-frame/workflow.md
  - .claude/skills/aic-ship/SKILL.md
  - .claude/skills/aic-status/SKILL.md

## 2026-05-07 — freshness
- Impact indirect : `_lib.sh` et `review-delta.sh` (runtime + templates) étendus pendant l'implémentation de `quality/review-delta-uncommitted-coverage`.
- Aucun changement sur le dogfood-update.sh ni la sémantique de drift. `check-dogfood-drift` PASS.

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/review-delta.sh
