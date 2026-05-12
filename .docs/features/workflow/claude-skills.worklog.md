# Worklog — workflow/claude-skills


## 2026-04-24 16:37 — auto
- Fichiers modifiés :
  - template/.claude/skills/aic-feature-audit/SKILL.md.jinja
  - template/.claude/skills/aic-feature-audit/workflow.md.jinja

## 2026-04-28 11:57 — auto
- Fichiers modifiés :
  - template/.claude/skills/aic-project-guardrails/SKILL.md.jinja
  - template/.claude/skills/aic-project-guardrails/workflow.md.jinja

## 2026-05-04 — freshness
- Impact template : `template/.ai/workflows/feature-new.md.jinja` reste compatible avec les skills Claude qui délèguent aux workflows canoniques.
- Changement porté par dogfood runtime sync.
- Validation associée : `check-dogfood-drift.sh` PASS.

## 2026-05-06 — update
- Ajout du skill public Claude `/aic-document-feature`.
- Le wrapper reste mince (`SKILL.md` + `workflow.md`) et délègue à `.ai/workflows/document-feature.md`.
- Validation prévue : `check-dogfood-drift.sh`, `check-shims.sh`, `check-features.sh`, smoke-test.

## 2026-05-06 21:57 — update
- Intent : aligner le catalogue public avec les garde-fous DONE.
- Changement : `/aic done` et `/aic force done` passent par `feature-done` avec quality gate et evidence.
- Validation : incluse dans la passe `workflow/intentional-skills`.

## 2026-05-06 22:46 — auto
- Fichiers modifiés :
  - template/.claude/skills/aic-frame/workflow.md.jinja
  - template/.claude/skills/aic-ship/SKILL.md.jinja
  - template/.claude/skills/aic-status/SKILL.md.jinja

## 2026-05-11 — aic-frame durable
- Impact Claude : `/aic-frame` precise le challenge IA, les questions de cadrage, le routage et la sortie durable `execution_ref`.
- Garde-fou : le skill reste sans code et sans creation de feature avant confirmation humaine.
- Validation : `check-dogfood-drift`, `check-features`, `check-feature-docs workflow/aic-frame-external-reference`, smoke sur copie Git propre.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : templates de workflows canoniques ajoutes pour les contrats subagents/hooks/MCP ; aucun nouveau skill Claude expose.
- Les skills Claude existants restent des wrappers minces vers `.ai/workflows/**`.
- Validation : `check-dogfood-drift`, `check-shims` et smoke-test PASS.
