# Worklog — workflow/conversational-skills

## 2026-04-24 — création

- Feature créée par /aic-feature-new
- Scope : workflow
- Intent initial : skill ombrelle `/aic` qui accepte une phrase libre et infère intent + cible + champs avant d'invoquer le bon skill `/aic-*` sous le capot
- Déclencheur : friction UX rencontrée par le créateur lui-même pendant le dog-fooding (cf commit c4d504e + discussion qui a suivi)
- Décision : approche A (sucre syntaxique additif), pas de hook auto, pas de TUI
- Prochaine étape : valider la liste exhaustive des intents détectables + écrire SKILL.md + workflow.md sous `template/.claude/skills/aic/`
