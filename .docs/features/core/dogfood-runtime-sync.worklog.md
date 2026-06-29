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

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/review-delta.sh

## 2026-05-07 00:11 — auto
- Fichiers modifiés :
  - .ai/scripts/review-delta.sh

## 2026-05-07 — freshness
- Impact indirect : `_lib.sh` et `features-for-path.sh` (runtime + templates) étendus
  pour matcher path-aware + ranking (livraison Phase 2 #2).
- Validation : check-dogfood-drift PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/features-for-path.sh

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/features-for-path.sh

## 2026-05-07 01:16 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh

## 2026-05-07 — freshness
- Impact direct : 2 nouveaux scripts (`context-relevance-log.sh`, `context-relevance-report.sh`) + templates correspondants + modifs hooks `features-for-path.sh`, `auto-worklog-log.sh`, `.claude/settings.json` + `.ai/.gitignore` + exclusions `check-dogfood-drift.sh` (livraison Phase 2 #3).
- Validation associée : `check-dogfood-drift.sh` PASS.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .ai/.gitignore
  - .ai/scripts/auto-worklog-log.sh
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/scripts/context-relevance-log.sh
  - .ai/scripts/context-relevance-report.sh
  - .ai/scripts/features-for-path.sh
  - .claude/settings.json

## 2026-05-07 14:45 — auto
- Fichiers modifiés :
  - .ai/scripts/features-for-path.sh

## 2026-05-07 14:53 — auto
- Fichiers modifiés :
  - .ai/scripts/features-for-path.sh

## 2026-05-07 — freshness
- Impact direct : `.ai/scripts/auto-progress.sh` modifié pour utiliser `is_structural_feature_edit` (livraison Phase 2 #4).
- Parité template appliquée : `_lib.sh.jinja` + `auto-progress.sh.jinja`.
- Validation : check-dogfood-drift PASS.

## 2026-05-07 17:33 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/auto-progress.sh

## 2026-05-07 18:04 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/auto-progress.sh

## 2026-05-07 — freshness
- Impact direct : `auto-worklog-log.sh` modifié pour filtrer via `is_structural_feature_edit` (livraison Phase 2 #5). Parité template.

## 2026-05-08 — stabilisation drift README
- Intent : retirer le drift runtime cause par une note locale dans `README_AI_CONTEXT.md`.
- Changement : note mainteneur deplacée vers `PROJECT_STATE.md`; le README runtime redevient strictement aligne avec le rendu Copier.
- Ajustement template : whitespace de la boucle `agents` dans `template/README_AI_CONTEXT.md.jinja` resserre pour produire le meme rendu que le dogfood runtime.
- Validation : `check-dogfood-drift.sh` PASS local.

## 2026-05-11 — aic-frame durable
- Intent : dogfooder la nouvelle sortie `aic-frame` durable dans les wrappers runtime et templates.
- Changement : runtime Claude/Codex et templates alignes sur challenge IA, routage enum et `execution_ref`.
- Validation : `check-dogfood-drift.sh` PASS ; smoke complet PASS sur copie Git propre.

## 2026-05-12 — alignement README dogfood
- Impact : `README_AI_CONTEXT.md` reste synchronise avec le rendu template apres retrait du drift local.
- Validation : `check-dogfood-drift.sh` PASS.

## 2026-05-12 — impact partagé contrat lock index

- Fichiers/surfaces : `.ai/scripts/_lib.sh`.
- Contexte : `quality/index-lock-contract` corrige `with_index_lock` pour echouer explicitement au timeout au lieu d'executer sans verrou.
- Impact : le runtime dogfood conserve une ecriture d'index protegee et verifiee par `check-dogfood-drift`.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `.ai/scripts/check-commit-features.sh`.
- Impact : correction minimale du parsing heredoc revelee par la couverture ciblee Q4 ; le guard runtime reste aligne avec le template.
- Validation : `bash .ai/scripts/check-dogfood-drift.sh` PASS.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : synchronisation dogfood runtime/template des nouveaux contrats workflow, du check `check-agent-config.sh`, du branchement `doctor`, de la quality gate et des workflows CI.
- HANDOFF : changements `workflow` et `quality` propages dans `template/` via le scope `core`.
- Validation : `check-dogfood-drift.sh`, `doctor` et smoke-test PASS avant revue finale.

## 2026-05-12 — frames dogfood
- Impact direct : `.docs/frames/**` rejoint les surfaces synchronisees et comparees par le dogfood runtime.
- Test : `tests/unit/test-dogfood-drift-extra.sh` detecte maintenant un drift sur `.docs/frames/0000-template.md`.
- Validation prévue : test unitaire dogfood, `check-dogfood-drift`, `check-shims`, `check-features`.
# Worklog — core/dogfood-runtime-sync

## 2026-05-14 — implement / frames locaux source-only

- Ajustement du drift check pour ignorer les frames locaux datés `.docs/frames/YYYY-MM-DD-*.md`.
- Le frame template `0000-template.md` reste comparé au rendu Copier, donc le contrat de dogfooding du runtime est conservé.
- Ajout d'une assertion dans `tests/unit/test-dogfood-drift-extra.sh`.
- Contexte : l'officialisation du cadrage `product/ai-context-stability-migration` crée un frame durable repo-local qui ne doit pas être rendu dans les projets downstream.

## 2026-06-01 — HANDOFF depuis quality (audit U1) : rsync dans test-dogfood-drift-extra

- HANDOFF reçu depuis le batch quality/test-infra. `tests/unit/test-dogfood-drift-extra.sh` (possédé par cette feature) : clone `cp -R .` → `rsync --exclude=.git`. Assertions de drift inchangées.
- Aucun changement de `check-dogfood-drift.sh` ni du contrat de dogfooding.
- Validation : `test-dogfood-drift-extra.sh` PASS (3s).

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - tests/unit/test-dogfood-drift-extra.sh

## 2026-06-01 14:22 — auto
- Fichiers modifiés :
  - .ai/scripts/review-delta.sh

## 2026-06-01 — HANDOFF depuis quality : pr-report runtime/template

- HANDOFF reçu depuis `quality/pr-report`.
- Surface dogfood : `.ai/scripts/pr-report.sh` et `template/.ai/scripts/pr-report.sh.jinja` restent synchronisés sur la correction perf/json.
- Aucun changement du contrat global de drift ; validation portée par les checks dogfood et le test pr-report.

## 2026-06-01 — HANDOFF depuis quality : ownership .gitignore runtime

- HANDOFF reçu depuis l'audit `pr-report` du delta journalier.
- `.gitignore` rejoint les surfaces directes de `core/dogfood-runtime-sync` pour couvrir les exclusions locales du runtime dogfoodé, notamment les verrous `.claude/*.lock`.
- Aucun changement fonctionnel du runtime ; correction de traçabilité feature mesh.

## 2026-06-01 22:26 — auto
- Fichiers modifiés :
  - .ai/scripts/pr-report.sh

## 2026-06-01 22:47 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/pr-report.sh

## 2026-06-02 00:27 — auto
- Fichiers modifiés :
  - .agents/skills/aic/SKILL.md
  - .claude/skills/aic/SKILL.md

## 2026-06-02 10:13 — auto
- Fichiers modifiés :
  - .agents/skills/aic-ship/SKILL.md
  - .claude/skills/aic-ship/SKILL.md

## 2026-06-19 11:47 — auto
- Fichiers modifiés :
  - .docs/frames/2026-06-19-project-overlay-scope-registry.md

## 2026-06-19 12:39 — auto
- Fichiers modifiés :
  - .ai/OWNERSHIP.md
  - .ai/index.md
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/templates/project-overlay/README.md

## 2026-06-19 14:24 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/templates/project-overlay/README.md

## 2026-06-19 — fix frames préservés par --apply
- Bug : `dogfood-update.sh --apply` supprimait `.docs/frames/AAAA-MM-JJ-*.md` (rsync `--delete`, rendu ne fournit que `0000-template.md`). Asymétrie avec le drift check qui les ignore. Détecté pendant le chantier overlay (frames restaurés via git).
- Fix : `--exclude='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md'` sur la sync des frames (ligne ~99 de dogfood-update.sh).
- Test : `tests/unit/test-dogfood-update-preserves-frames.sh` (exerce le vrai `--apply` sur copie jetable, skip si copier absent) ; enregistré dans `tests/smoke-test.sh` ([0d2]) ; CI le globe déjà via `tests/unit/*.sh`.

## 2026-06-19 17:52 — auto
- Fichiers modifiés :
  - .ai/scripts/dogfood-update.sh
## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - .ai/scripts/check-features.sh

## 2026-06-26 11:17 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/check-feature-freshness.sh

## 2026-06-26 11:34 — auto
- Fichiers modifiés :
  - .ai/quality/QUALITY_GATE.md
  - .ai/scripts/stop-doc-gate.sh
  - .ai/scripts/stop-sequence.sh
  - .claude/settings.json

## 2026-06-26 11:43 — auto
- Fichiers modifiés :
  - .ai/workflows/quality-gate.md

## 2026-06-26 — couverture incidente (workflow/codex-hooks-parity)
- Édition de `.ai/workflows/codex-hooks-parity.md` (+ jinja mirroir) — couvert par le glob `.ai/**` / `template/**` de cette feature. Parité runtime↔template préservée (recette parité fraîcheur Codex). Aucun changement du contrat dogfood.

## 2026-06-26 15:03 — auto
- Fichiers modifiés :
  - .ai/workflows/codex-hooks-parity.md

## 2026-06-26 — couverture incidente (workflow/auto-worklog fix churn date)
- Surface partagée touchée (tests/smoke-test.sh, gabarit flush, ou tests/unit) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-26 16:56 — auto
- Fichiers modifiés :
  - .ai/scripts/auto-worklog-flush.sh

## 2026-06-26 17:25 — auto
- Fichiers modifiés :
  - .ai/scripts/fiche-consolidation-nudge.sh
  - .ai/workflows/feature-update.md
  - .claude/settings.json

## 2026-06-28 20:34 — auto
- Fichiers modifiés :
  - .ai/scripts/check-touches-breadth.sh
  - .ai/workflows/quality-gate.md

## 2026-06-26 — couverture incidente (core/feature-index-cache fix robustesse)
- Surface partagée touchée (build-feature-index.sh + jinja, tests, ou tests/smoke-test.sh) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-28 20:51 — auto
- Fichiers modifiés :
  - .ai/scripts/build-feature-index.sh

## 2026-06-28 22:05 — auto
- Fichiers modifiés :
  - .docs/frames/2026-06-28-audit-strategique-remediation.md

## 2026-06-28 — guardrails.md projet-spécifique + exclusion drift (Phase 0 audit : B0 + A4)
- Création `.ai/guardrails.md` (runtime, projet-spécifique) : non-goals ai_context, glossaire, et règle de gouvernance **B0** (budget méta-process) décidée dans le frame 2026-06-28. Corrige A4 (fichier référencé par l'index Pack A mais absent).
- `check-dogfood-drift.sh` : `.ai/guardrails.md` ajouté aux exclusions (projet-spécifique, même catégorie que `.ai/project/**`) + ligne de transparence en sortie. Drift ✅ aligné.
- Squelette template couvert par core/template-engine (`template/.ai/guardrails.md.jinja`).
- Fichiers : .ai/guardrails.md, .ai/scripts/check-dogfood-drift.sh

## 2026-06-28 — frame remédiation : avancement Phase 0
- `.docs/frames/2026-06-28-audit-strategique-remediation.md` : section Avancement + next_hint mis à jour (Phase 0 close). Aucun changement runtime.

## 2026-06-28 — couverture incidente (A1 : fix fallback build-feature-index)
- `build-feature-index.sh.jinja` touché via glob `touches:`. Aucun changement propre à cette feature. (Taxe sur-couverture `touches:` — cf. quality/touches-breadth-guard.)

## 2026-06-28 — couverture incidente (frame remédiation : avancement A1/A2)
- `.docs/frames/2026-06-28-audit-strategique-remediation.md` mis à jour (avancement Phase 1). Aucun changement de comportement.

## 2026-06-28 — couverture incidente (A9 : anti-churn auto-worklog)
- Surface partagée touchée (auto-worklog-log/flush, .ai/.gitignore ou tests/unit/**) via glob/touches:. Aucun changement de comportement propre à cette feature. (Taxe sur-couverture — cf. quality/touches-breadth-guard.)

## 2026-06-28 — couverture incidente (frame remédiation : avancement 2e vague + A9)
- `.docs/frames/2026-06-28-audit-strategique-remediation.md` mis à jour. Aucun changement de comportement.

## 2026-06-28 23:10 — auto
- Fichiers modifiés :
  - .ai/scripts/auto-worklog-flush.sh
  - .ai/scripts/auto-worklog-log.sh
  - .docs/frames/2026-06-28-audit-strategique-remediation.md

## 2026-06-29 10:46 — auto
- Fichiers modifiés :
  - .ai/scripts/build-feature-index.sh

## 2026-06-28 — couverture incidente (frame remédiation : C1 cadré + fiche)
- `.docs/frames/2026-06-28-audit-strategique-remediation.md` mis à jour (C1 cadré, fiche créée). Aucun changement de comportement.

## 2026-06-29 — couverture incidente (C1 : shims derives d AGENTS.md)
- Surface partagee touchee (shims AGENTS.md/CLAUDE.md ou gabarits). Aucun changement de comportement propre a cette feature.

## 2026-06-29 — couverture incidente (frame remediation : C1 core livre)
- Frame mis a jour (C1 implemente). Aucun changement de comportement.

## 2026-06-29 11:39 — auto
- Fichiers modifiés :
  - .docs/frames/2026-06-28-audit-strategique-remediation.md
  - AGENTS.md
  - CLAUDE.md

## 2026-06-29 — couverture incidente (frame remediation : C2c livre)
- Frame mis a jour (C2c fait, C2a/b routes vers feature-mesh). Aucun changement de comportement.

## 2026-06-29 11:57 — auto
- Fichiers modifiés :
  - .docs/frames/2026-06-28-audit-strategique-remediation.md

## 2026-06-29 — couverture incidente (C2b : reconciliation id schema/checker)
- Surface partagee touchee (check-features.sh via .ai/** ou touches:, ou tests/unit/**). Aucun changement de comportement propre. (Taxe sur-couverture touches: — cf. quality/touches-breadth-guard.)

## 2026-06-29 — couverture incidente (frame remediation : C2b livre)
- Frame mis a jour (C2b fait, C2a = enhancement a cadrer). Aucun changement de comportement.

## 2026-06-29 — fix regression : .session-docs.log dans les exclusions drift
- Le marqueur volatil .ai/.session-docs.log (introduit par A9/auto-worklog) etait gitignore mais PAS dans les exclusions de check-dogfood-drift → drift le flaguait extra-runtime, cassant test-dogfood-drift-extra ET test-project-overlay (qui rsync le repo + lancent drift).
- Fix : ajout .session-docs.log au rsync --exclude ET a is_ignored_runtime_extra de check-dogfood-drift.sh (a cote des autres .session-*).
- Verif : 27/27 unit PASS, drift aligne. (Bug de mon propre A9 — aligne les exclusions partout : gitignore + drift.)
- Fichiers : .ai/scripts/check-dogfood-drift.sh

## 2026-06-29 — couverture incidente (C2a-doc : role du schema)
- Surface partagee touchee (feature.schema.json via .ai/** ou touches:). Aucun changement de comportement propre. (Taxe sur-couverture touches: — cf. quality/touches-breadth-guard.)

## 2026-06-29 — couverture incidente (clôture frame : C2a-doc + A7)
- Frame mis a jour (C2a resolu, cloture session). Aucun changement de comportement.

## 2026-06-29 — couverture runtime/template (P0 audit hebdo)
- Runtime et miroirs `.jinja` synchronises pour `check-features.sh` et `check-commit-features.sh` dans les commits P0.
- Ajout de tests unitaires et branchement smoke ; `check-dogfood-drift.sh` repasse vert apres patch.
