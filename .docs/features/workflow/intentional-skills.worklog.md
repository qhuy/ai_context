# Worklog — workflow/intentional-skills

## 2026-05-04 — freshness
- Impact direct : la surface intentionnelle `aic-frame/status/diagnose/review/ship` est aussi générée sous `.agents/skills/` pour Codex.
- Les workflows canoniques restent sous `.ai/workflows/`.
- Validation associée : smoke-test complet PASS.

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` reçoit un check anti fourre-tout sans changer la mécanique des skills intentionnels.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact documentaire : `feature-new` devient explicitement validable avant écriture, sans changer les autres skills intentionnels.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-features.sh` et `check-feature-docs.sh workflow/feature-new-approval-step` PASS.

## 2026-05-04 — freshness
- Impact template : `template/.ai/workflows/feature-new.md.jinja` propage la validation explicite avant écriture aux projets générés.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-dogfood-drift.sh` PASS.
## 2026-05-05 — freshness
- Impact transversal : les messages de démarrage orientent les règles locales vers `.ai/project/index.md`.
- Validation associée : smoke-test PASS.

## 2026-05-06 — update
- Intent : ajouter `/aic-document-feature` comme intention explicite de documentation feature.
- Fichiers/surfaces : `.claude/skills/aic-document-feature/**`, `.agents/skills/aic-document-feature/**`, `.ai/workflows/document-feature.md`, README et smoke-test.
- Décision : `legacy` reste un scope custom documenté dans le workflow, non scaffoldé par défaut.
- Validation : dogfood + checks ciblés prévus.

## 2026-05-06 — freshness commit
- Impact couvert : wrappers runtime/template, workflow canonique, README, `copier.yml` et smoke-test.
- Aucun changement sur les autres skills intentionnels.
- Validation associée : `check-dogfood-drift.sh`, `check-shims.sh`, `check-ai-references.sh`, smoke-test PASS.
