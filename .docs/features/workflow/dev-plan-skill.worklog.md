# Worklog — workflow/dev-plan-skill

## 2026-06-02 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : workflow
- Intent initial : Structurer les développements multi-techno

## 2026-06-02 — implémentation runtime
- `.ai/workflows/dev-plan.md` : workflow canonique avec phases (surfaces, ordre, handoffs, risques), format de sortie fixe 5 sections, NON-NEGOTIABLE RULES
- `.claude/skills/aic-dev-plan/SKILL.md` + `workflow.md` : wrapper mince Claude, délègue au canonique
- `.agents/skills/aic-dev-plan/SKILL.md` + `workflow.md` : wrapper mince Codex, délègue au canonique
- `README_AI_CONTEXT.md` : ligne "Structurer le développement" ajoutée dans le tableau workflow quotidien
- Template non propagé (décision explicite) : HANDOFF `core` requis avant de toucher `template/.ai/workflows/`, `template/.claude/skills/aic-dev-plan/`, `template/.agents/skills/aic-dev-plan/`
- Décisions retenues : règle `subagents: aucun` si pas de délégation (audit point 3) ; wrappers thin pattern identique à `aic-quality-gate`

## 2026-06-02 — propagation template (Codex)
- Codex a propagé vers template/ sans HANDOFF explicite (violation processus, résultat correct).
- `template/.ai/workflows/dev-plan.md.jinja` + wrappers `.claude/` et `.agents/` créés.
- `README.md`, `copier.yml` (`_message_after_copy`), `template/README_AI_CONTEXT.md.jinja` mis à jour.
- `tests/smoke-test.sh` : `aic-dev-plan` ajouté au loop skills + `dev-plan` au loop workflows (9→10).
- Checks post-propagation : smoke PASS, dogfood-drift PASS.
- `touches` fiche corrigés vers paths spécifiques (était wildcards `**`).

## 2026-06-02 12:03 — auto
- Fichiers modifiés :
  - .agents/skills/aic-dev-plan/SKILL.md
  - .agents/skills/aic-dev-plan/workflow.md
  - .ai/workflows/dev-plan.md
  - .claude/skills/aic-dev-plan/SKILL.md
  - .claude/skills/aic-dev-plan/workflow.md
  - README_AI_CONTEXT.md
