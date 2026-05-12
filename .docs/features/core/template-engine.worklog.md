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

## 2026-05-07 — freshness
- Impact template : `template/.ai/scripts/_lib.sh.jinja` et `template/.ai/scripts/review-delta.sh.jinja` étendus pour parité runtime (livraison `quality/review-delta-uncommitted-coverage`).
- Aucun changement de profil, agents, scopes ou variables Copier. `check-dogfood-drift` PASS.

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-05-07 00:11 — auto
- Fichiers modifiés :
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-05-07 — freshness
- Impact template : `template/.ai/scripts/_lib.sh.jinja` et
  `template/.ai/scripts/features-for-path.sh.jinja` étendus pour parité runtime
  (livraison `quality/features-for-path-ranking-and-matcher-correctness`).
- Note Jinja : tous les `${#var}` protégés par `{% raw %}` pour éviter `{#` interprété
  comme début de commentaire Jinja.
- Validation : check-dogfood-drift PASS, copier copy direct PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 01:16 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 — freshness
- Impact template : 2 nouveaux templates (`context-relevance-log.sh.jinja`, `context-relevance-report.sh.jinja`) + extensions `features-for-path.sh.jinja`, `auto-worklog-log.sh.jinja`, `settings.json.jinja`, `.ai/.gitignore` (livraison Phase 2 #3).
- Validation associée : copier copy direct PASS, check-dogfood-drift PASS.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - template/.ai/.gitignore
  - template/.ai/scripts/auto-worklog-log.sh.jinja
  - template/.ai/scripts/features-for-path.sh.jinja
  - template/.claude/settings.json.jinja

## 2026-05-07 14:45 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 14:53 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 — freshness
- Impact template : `template/.ai/scripts/_lib.sh.jinja` (ajout helper) et `template/.ai/scripts/auto-progress.sh.jinja` (consumer du helper) — livraison Phase 2 #4.
- Aucun changement profil/agents/scopes/variables Copier.
- Validation : check-dogfood-drift PASS.

## 2026-05-07 17:33 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/auto-progress.sh.jinja

## 2026-05-07 18:04 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/auto-progress.sh.jinja

## 2026-05-07 — freshness
- Impact template : `template/.ai/scripts/auto-worklog-log.sh.jinja` étendu pour parité runtime (livraison Phase 2 #5).
- Validation : check-dogfood-drift PASS.

## 2026-05-08 — docs variables + Jinja freshness
- Intent : corriger la reference des variables et garder les templates rendables apres optimisation freshness.
- Changement docs : `docs/variables.md` aligne `scope_profile=minimal` sur `product`, ajoute `adoption_mode` et precise la generation des skills Codex/Claude.
- Changement template : `template/.ai/scripts/check-feature-freshness.sh.jinja` evite la forme Bash `${#...}` incompatible avec Jinja (`{#`).
- Validation : rendu Copier via `check-dogfood-drift.sh` PASS local.

## 2026-05-11 — aic-frame durable
- Impact template : `template/.agents/skills/aic-frame/*` et `template/.claude/skills/aic-frame/*` propagent le contrat de cadrage durable.
- Compatibilite : conservation des variables `docs_root` pour les chemins de features et frames.
- Validation : `check-dogfood-drift.sh` PASS ; smoke complet PASS sur copie Git propre.

## 2026-05-12 — variables et README template
- Impact : `docs/variables.md` et `template/README_AI_CONTEXT.md.jinja` alignent la documentation des variables et le rendu README.
- Validation : `check-dogfood-drift.sh` PASS.
## 2026-05-12 — impact partagé contrat lock index

- Fichiers/surfaces : `template/.ai/scripts/_lib.sh.jinja`.
- Contexte : `quality/index-lock-contract` aligne le template Copier sur le runtime `_lib.sh`.
- Impact : le rendu Copier garde le meme contrat de lock que le repo dogfood.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — documentation variables runtime

- Fichiers/surfaces : `docs/variables.md`.
- Contexte : l'item AI Debate `0013/Q2` demande de distinguer les questions Copier des variables runtime `AI_CONTEXT_*`.
- Documentation :
  - ajout d'une separation explicite entre variables Copier et overrides runtime ;
  - inventaire des variables `AI_CONTEXT_*` exposees par `.ai/scripts/` et les templates correspondants ;
  - precision des valeurs par defaut, surfaces de lecture et effets.
- Validation portée par les checks documentaires de `core/template-engine`.
## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `template/.ai/scripts/check-commit-features.sh.jinja`.
- Impact : parite template/runtime appliquee pour le parsing heredoc du guard commit.
- Validation : `bash .ai/scripts/check-dogfood-drift.sh` PASS.
