# Worklog — workflow/evidence-discipline

## 2026-07-06 — création (cadrage aic-frame, commit ①)
- Feature créée après cadrage `aic-frame` niveau high (demande utilisateur : « éliminer les suppositions, tout fonctionnement supposé doit avoir des preuves »).
- Scope : workflow. Route : feature, confirmée par l'utilisateur (« go »).
- Livré dans ce commit : contrat transverse `.ai/workflows/evidence-discipline.md` (+ miroir jinja identique) — trois étiquettes (Prouvé / Hypothèse / À vérifier), interdit de l'affirmation nue, application graduée selon l'enjeu, précédents internes, limites d'enforcement assumées.
- Décisions : hard rule Pack A plutôt que posture on-demand (l'invariant de `workflow/agent-behavior` reste intact — c'est une hard rule, pas du style) ; pas de gate mécanique de véracité (impossible en bash, LLM-juge interdit).
- Validation : `check-feature-docs --strict workflow/evidence-discipline` + `check-features` au commit.
- Next : commit ② — hard rule FR/EN dans reminder + AGENTS.md condensé à 15 lignes.
