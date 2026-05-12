# Worklog — core/codex-skills-install

## 2026-05-04 — création
- Feature créée par /aic-feature-new
- Scope : core
- Intent initial : Installer les skills Codex avec ai_context

## 2026-05-04 — implémentation
- Ajout de `.agents/skills/` au template quand `codex` est sélectionné.
- Ajout des wrappers `aic-*`, `aic-feature-*` et `aic-quality-gate`.
- Documentation README/CHANGELOG mise à jour.
- Validation : `check-shims`, `check-features`, `smoke-test` passent.

## 2026-05-04 16:37 CEST — DONE

### Evidence
- Build : non applicable (template/scripts shell)
- Tests : `bash tests/smoke-test.sh` OK
- Gate : `check-shims`, `check-ai-references`, `check-features`, `check-feature-docs --strict core/codex-skills-install`, `check-feature-coverage`, `measure-context-size` OK

### Résumé livré
- Installation conditionnelle de `.agents/skills/` quand `codex` est sélectionné.
- Wrappers Codex ajoutés pour `aic-*`, `aic-feature-*` et `aic-quality-gate`.
- Smoke-test étendu pour vérifier la génération des skills Codex.
- Documentation README et CHANGELOG mise à jour.

### Commit suggéré
feat(core): installer les skills Codex par défaut
## 2026-05-05 — freshness
- Impact documentaire : README et smoke-test mentionnent le nouvel overlay projet sans changer les wrappers Codex.
- Validation associée : smoke-test PASS.

## 2026-05-06 — alignement dogfood Codex/Claude
- Intent : aligner la surface de skills disponible localement pour Codex avec les skills intentionnels déjà présents côté Claude.
- Changement prévu : synchroniser `.agents/**` depuis le rendu Copier minimal et faire échouer `check-dogfood-drift.sh` en cas de divergence.

## 2026-05-06 — update
- Ajout du wrapper Codex `aic-document-feature`.
- Le skill délègue au workflow partagé `.ai/workflows/document-feature.md`.
- Validation prévue : smoke-test [19/28] et dogfood drift.

## 2026-05-06 — freshness commit
- Impact couvert : README, template Codex et smoke-test référencent le nouveau wrapper.
- Aucun changement sur le mécanisme d'installation Codex hors ajout du skill.
- Validation associée : `check-dogfood-drift.sh`, `check-shims.sh`, `check-ai-references.sh`, smoke-test PASS.
## 2026-05-06 — freshness
- Intent : tracer l'alignement README/CHANGELOG/smoke autour de la surface Codex `aic-*`, incluant `aic-document-feature`.
- Validation : couvert par `check-features` et `tests/smoke-test.sh`.

## 2026-05-06 — freshness README
- Intent : verifier que le README repositionné décrit correctement les skills Codex locaux `aic-*`.
- Validation : `check-ai-references`, `check-features`.

## 2026-05-06 21:57 — update
- Intent : réduire l'ambiguïté UX des primitives Codex.
- Changement : descriptions `aic-feature-*` et `aic-quality-gate` marquées `Primitive interne/fallback` dans `.agents/skills/**` et `template/.agents/skills/**`.
- Décision : conserver les wrappers pour les appels explicites, mais recommander la surface intentionnelle (`aic-frame/status/review/ship/document-feature`) et le langage naturel.
- Validation : dogfood drift et smoke-test à lancer.

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

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh

## 2026-05-11 — aic-frame durable
- Impact Codex : `.agents/skills/aic-frame/*` et `template/.agents/skills/aic-frame/*` alignés sur le cadrage durable référençable.
- Garde-fou maintenu : les wrappers Codex restent intentionnels ; aucune création de feature sans confirmation humaine.
- Validation : `check-dogfood-drift`, `check-features`, `check-feature-docs workflow/aic-frame-external-reference`, smoke sur copie Git propre.

## 2026-05-12 — impact partagé test lock index

- Fichiers/surfaces : `tests/smoke-test.sh`.
- Contexte : `quality/index-lock-contract` renforce le smoke test global.
- Impact : aucun changement des skills Codex ; la suite de validation couvre le lock d'index.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `tests/smoke-test.sh`.
- Impact : le smoke lance maintenant les tests unitaires Q4 avant les validations d'installation ; aucun changement des skills Codex.
- Validation : `bash tests/smoke-test.sh` PASS.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : README et smoke-test restent compatibles avec les skills Codex existants pendant l'ajout des contrats multi-agent.
- Aucun changement sur `.agents/skills/**` ni sur l'installation des skills Codex.
- Validation : `check-shims`, `check-ai-references` et smoke-test PASS.
