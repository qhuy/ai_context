# Worklog — workflow/evidence-discipline

## 2026-07-06 — création (cadrage aic-frame, commit ①)
- Feature créée après cadrage `aic-frame` niveau high (demande utilisateur : « éliminer les suppositions, tout fonctionnement supposé doit avoir des preuves »).
- Scope : workflow. Route : feature, confirmée par l'utilisateur (« go »).
- Livré dans ce commit : contrat transverse `.ai/workflows/evidence-discipline.md` (+ miroir jinja identique) — trois étiquettes (Prouvé / Hypothèse / À vérifier), interdit de l'affirmation nue, application graduée selon l'enjeu, précédents internes, limites d'enforcement assumées.
- Décisions : hard rule Pack A plutôt que posture on-demand (l'invariant de `workflow/agent-behavior` reste intact — c'est une hard rule, pas du style) ; pas de gate mécanique de véracité (impossible en bash, LLM-juge interdit).
- Validation : `check-feature-docs --strict workflow/evidence-discipline` + `check-features` au commit.
- Next : commit ② — hard rule FR/EN dans reminder + AGENTS.md condensé à 15 lignes.

## 2026-07-06 — hard rule Pack A (commit ②)
- Intent : rendre la discipline effective par défaut — injectée à chaque tour (Claude, Codex via enable_codex_hooks) et lue nativement (Cursor/Copilot via AGENTS.md).
- Fichiers/surfaces : `.ai/reminder.md` (+ `template/.ai/reminder.md.jinja`, variantes FR et EN), `AGENTS.md` (+ `template/AGENTS.md.jinja`) — paragraphe « Shim lean » condensé de 2 lignes à 1 pour rester à 15 lignes pile (limite check-shims), hard rule courte ajoutée.
- Mesures (preuves) : reminder statique = 560 chars (~140-186 tokens) après ajout ; AGENTS.md = 15 lignes ; Pack A index = 87 mots (inchangé) — `measure-context-size.sh` et `check-shims` exécutés ce jour.
- Validation : `check-shims` PASS ; `test-agents-md-self-sufficient` PASS ; `check-dogfood-drift` PASS ; smoke complet au commit.
- Next : commit ③ — wiring NON-NEGOTIABLE des 4 skills d'analyse.

## 2026-07-06 — wiring des skills d'analyse (commit ③)
- Intent : enforcement structurel — les quatre skills qui produisent des analyses portent la règle dans leurs règles non négociables.
- Fichiers/surfaces : `workflow.md` de `aic-review`, `aic-diagnose`, `aic-pilot`, `aic-frame` — 16 fichiers (Claude + Codex, racine + template), ligne identique insérée (aucune variable jinja dedans ; les variantes docs_root des templates sont intactes).
- Preuves : parité Claude/Codex vérifiée par diff sur les 4 skills ; `check-dogfood-drift` PASS (rendu template == racine).
- Validation : smoke complet au commit.
- Next : commit ④ — CHANGELOG + clôture avec preuve.
