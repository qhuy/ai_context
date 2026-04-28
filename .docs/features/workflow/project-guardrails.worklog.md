# Worklog — workflow/project-guardrails

## 2026-04-28 — création
- Feature créée par décision utilisateur (question conversationnelle « manque-t-il un skill pour le contexte général projet ? »).
- Scope : workflow.
- Intent initial : skill `/aic-project-guardrails` (non-goals + glossaire métier) pour orienter l'agent sans dupliquer le README.
- Décisions clés :
  - Resserrage du périmètre original (Vision/Users écartés, redondants avec README).
  - Fichier généré sous `.ai/guardrails.md` (orientation agent), pas `{{ docs_root }}/` (doc métier).
  - Pas d'injection runtime — référencement Pack A uniquement (1 lecture/session, coût tokens nul).
  - Skill exposé utilisateur (pas interne), idempotent.

## 2026-04-28 11:57 — auto
- Fichiers modifiés :
  - template/.ai/index.md.jinja
  - template/.claude/skills/aic-project-guardrails/SKILL.md.jinja
  - template/.claude/skills/aic-project-guardrails/workflow.md.jinja
  - template/README_AI_CONTEXT.md.jinja

## 2026-04-28 12:04 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh
