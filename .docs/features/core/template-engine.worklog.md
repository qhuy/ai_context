# Worklog — core/template-engine

## 2026-05-05 — freshness
- Impact template : ajout de `_skip_if_exists` pour `.ai/project/**`, de l'ownership template et de l'exemple `.ai/templates/project-overlay/README.md`.
- Validation associée : smoke-test et `check-dogfood-drift.sh` PASS.


## 2026-04-24 11:34 — auto
- Fichiers modifiés :
  - template/.claude/settings.json.jinja

## 2026-04-24 11:42 — auto
- Fichiers modifiés :
  - template/.ai/.gitignore
  - template/.ai/scripts/auto-progress.sh.jinja
  - template/.ai/scripts/auto-worklog-flush.sh.jinja

## 2026-04-24 11:57 — auto
- Fichiers modifiés :
  - template/.githooks/README.md.jinja
  - template/.githooks/pre-commit.jinja

## 2026-04-24 12:23 — auto
- Fichiers modifiés :
  - copier.yml
  - template/.ai/index.md.jinja
  - template/AGENTS.md.jinja

## 2026-04-24 14:10 — auto
- Fichiers modifiés :
  - template/.ai/scripts/auto-progress.sh.jinja

## 2026-04-24 16:37 — auto
- Fichiers modifiés :
  - template/.claude/skills/aic-feature-audit/SKILL.md.jinja
  - template/.claude/skills/aic-feature-audit/workflow.md.jinja

## 2026-04-24 16:40 — auto
- Fichiers modifiés :
  - README.md

## 2026-04-24 17:26 — auto
- Fichiers modifiés :
  - template/.ai/rules/tech-dotnet.md.jinja

## 2026-04-24 18:02 — auto
- Fichiers modifiés :
  - template/.ai/rules/tech-react.md.jinja

## 2026-04-24 18:13 — auto
- Fichiers modifiés :
  - template/.ai/rules/stack-fullstack-dotnet-react.md.jinja

## 2026-04-24 18:27 — auto
- Fichiers modifiés :
  - copier.yml
  - template/docs/atomic-design-map.md.jinja
  - template/docs/design-system-registry.md.jinja

## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - README.md
  - copier.yml
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/ai-context.sh.jinja
  - template/.ai/scripts/audit-features.sh.jinja
  - template/.ai/scripts/check-features.sh.jinja
  - template/.ai/scripts/pr-report.sh.jinja

## 2026-04-28 11:57 — auto
- Fichiers modifiés :
  - template/.ai/index.md.jinja
  - template/.claude/skills/aic-project-guardrails/SKILL.md.jinja
  - template/.claude/skills/aic-project-guardrails/workflow.md.jinja
  - template/README_AI_CONTEXT.md.jinja

## 2026-04-28 12:04 — auto
- Fichiers modifiés :
  - README.md
  - copier.yml
  - template/.ai/scripts/doctor.sh.jinja

## 2026-05-03 — docs
- Correction du diagramme Mermaid de la section Architecture du README :
  - labels `/aic-*` rendus avec guillemets Mermaid ;
  - label d'arête `dry-run` reformulé sans parenthèses.

## 2026-05-04 — update robustness
- Fichiers modifiés :
  - README.md
  - README_AI_CONTEXT.md
  - docs/upgrading.md
  - docs/variables.md
  - template/README_AI_CONTEXT.md.jinja
  - template/.ai/scripts/ai-context.sh.jinja
  - .ai/scripts/ai-context.sh
- Intention :
  - rendre le cycle install → customize → update plus robuste après retour projet réel ;
  - documenter `copier update --vcs-ref=HEAD` ;
  - fournir un repair explicite des métadonnées Copier et une preview externe du template sans toucher au worktree courant.

## 2026-05-04 — freshness
- Impact transversal : le template Copier génère désormais `.agents/skills/` quand `codex` est sélectionné.
- Validation associée : smoke-test complet PASS.

## 2026-05-04 — freshness
- Impact template : `template/.ai/workflows/feature-new.md.jinja` et `template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja` intègrent les règles feature-new récentes.
- Changement porté par dogfood runtime sync et les features workflow associées.
- Validation associée : `check-dogfood-drift.sh` PASS.

## 2026-05-06 — update
- Template enrichi avec `template/.ai/workflows/document-feature.md.jinja` et les wrappers Claude/Codex `aic-document-feature`.
- `_message_after_copy` et les README exposent le nouveau geste documentaire sans modifier les scopes Copier.
- Validation prévue : rendu dogfood et smoke-test.

## 2026-05-06 — freshness commit
- Impact couvert : templates skill/workflow et README template synchronisés avec le rendu runtime.
- Aucun changement sur le moteur Copier/Jinja lui-même.
- Validation associée : `check-dogfood-drift.sh`, smoke-test PASS.

## 2026-05-06 — freshness README
- Intent : verifier que le README simplifié conserve les informations Copier critiques : scaffold, migration, update, profils et modes d'adoption.
- Validation : `check-ai-references`, `check-features`.

## 2026-05-06 — retours review
- Intent : synchroniser les corrections runtime dans les templates Copier.
- Fichiers/surfaces : `template/.ai/scripts/aic.sh.jinja`, `template/.ai/scripts/review-delta.sh.jinja`, `template/.ai/scripts/check-feature-freshness.sh.jinja`.
- Décision : même comportement staged que le runtime source pour éviter une régression au prochain scaffold/update.
- Validation : prévue via `bash -n` et checks AIC.

## 2026-05-06 22:46 — auto
- Fichiers modifiés :
  - template/.agents/skills/aic-feature-done/SKILL.md.jinja
  - template/.agents/skills/aic-feature-done/workflow.md.jinja
  - template/.agents/skills/aic-feature-handoff/SKILL.md.jinja
  - template/.agents/skills/aic-feature-handoff/workflow.md.jinja
  - template/.agents/skills/aic-feature-new/SKILL.md.jinja
  - template/.agents/skills/aic-feature-new/workflow.md.jinja
  - template/.agents/skills/aic-feature-resume/SKILL.md.jinja
  - template/.agents/skills/aic-feature-resume/workflow.md.jinja
  - template/.agents/skills/aic-feature-update/SKILL.md.jinja
  - template/.agents/skills/aic-feature-update/workflow.md.jinja
  - template/.agents/skills/aic-frame/workflow.md.jinja
  - template/.agents/skills/aic-quality-gate/SKILL.md.jinja
  - template/.agents/skills/aic-quality-gate/workflow.md.jinja
  - template/.agents/skills/aic-ship/SKILL.md.jinja
  - template/.agents/skills/aic-status/SKILL.md.jinja
  - template/.claude/skills/aic-frame/workflow.md.jinja
  - template/.claude/skills/aic-ship/SKILL.md.jinja
  - template/.claude/skills/aic-status/SKILL.md.jinja
