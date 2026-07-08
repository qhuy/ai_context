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

## 2026-06-02 00:27 — auto
- Fichiers modifiés :
  - template/.claude/skills/aic/SKILL.md.jinja

## 2026-06-02 10:13 — auto
- Fichiers modifiés :
  - template/.claude/skills/aic-ship/SKILL.md.jinja

## 2026-06-19 14:53 — auto
- Fichiers modifiés :
  - template/.ai/workflows/project-overlay-sync.md.jinja
  - template/.claude/skills/aic-onboard/SKILL.md.jinja
  - template/.claude/skills/aic-onboard/workflow.md.jinja
## 2026-06-26 — impact workflow/stop-turn-doc-gate
- `template/.ai/workflows/quality-gate.md.jinja` (+ runtime) : ajout d'une ligne inspecteur `check-feature-freshness.sh --worktree --warn` (fraîcheur fin de tour, informatif). Aucune logique de skill modifiée.

## 2026-06-26 — couverture incidente (workflow/codex-hooks-parity)
- `template/.ai/workflows/codex-hooks-parity.md.jinja` (couvert par le glob `touches:`) : recette parité fraîcheur Codex. Aucune logique de skill modifiée.

## 2026-06-26 — couverture incidente (workflow/feature-consolidation-nudge)
- Surface partagée touchée (.claude/settings.json, jinjas template, ou .ai/workflows/feature-update.md) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-26 17:25 — auto
- Fichiers modifiés :
  - template/.ai/workflows/feature-update.md.jinja

## 2026-07-03 — done
- Intent : clôturer le catalogue `/aic*` après vérification que les workflows internes restent accessibles sans être chargés par défaut.
- Fichiers/surfaces : `.docs/features/workflow/claude-skills.md`, `.docs/features/workflow/claude-skills.worklog.md`.
- Décision : statut `done`; catalogue public et procédures internes restent on-demand, hors contexte Codex obligatoire.
- Validation : `bash .ai/scripts/check-shims.sh`; `bash .ai/scripts/check-dogfood-drift.sh`; `bash .ai/scripts/check-feature-docs.sh --strict workflow/claude-skills`; `bash .ai/scripts/check-features.sh --no-write`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-07 — audit mesh
- Intent : traiter le stale artificiel signalé par l'audit 2026-07-07.
- Changement : `touches:` ne prend plus tout `template/.ai/workflows/**`; les workflows internes réellement consommés par le catalogue `/aic*` sont listés en `touches_shared`.
- Décision : un changement de procédure interne ne réouvre cette fiche que s'il change le catalogue ou le routage public des skills Claude.
- Validation prévue : `check-features --no-write`, `check-feature-docs --strict workflow/claude-skills`, `check-feature-coverage --strict`, freshness finale du delta.
