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

## 2026-07-06 — done (commit ④)
- Intent : clôturer avec preuve et tracer au CHANGELOG.
- Validation (exécutée ce jour) : `check-shims` PASS (AGENTS.md 15 lignes, auto-suffisant, Pack A 87 mots) ; `test-agents-md-self-sufficient` PASS ; `check-feature-docs --strict workflow/evidence-discipline` PASS ; `check-features` PASS ; `check-dogfood-drift` PASS ; smoke complet PASS ×3 (un par commit) ; `measure-context-size` : reminder statique 560 chars.
- Limite assumée (documentée au contrat) : discipline outillée, pas garantie machine — aucun gate de véracité possible.
- Next : phase 2 éventuelle — exiger l'evidence des analyses dans QUALITY_GATE.md avant review.

## 2026-08-08 — diagnostic R3 : § « Chiffres publiés » (Fix A)
- Intent : traiter la persistance des suppositions malgré la règle injectée à chaque tour (item R3 du pilot `2026-08-07-retour-ux-restitution`).
- Diagnostic : la règle interdisait l'affirmation nue mais laissait trois trous — pas d'exigence de **re-mesure** après la dernière édition, pas de **contexte** d'exécution publié, pas de re-exécution d'un chiffre **hérité**. Les deux exhibits du 2026-08-08 passaient par ces trous sans enfreindre la lettre : Codex a publié « mesure reproductible : 535 → 674, +139 » (irreproductible sur le repo source) ; Claude a publié « AGENTS.md : 28 lignes » depuis une mesure périmée (réel : 27).
- Surfaces : `.ai/workflows/evidence-discipline.md` (+ miroir) § Chiffres publiés ; `.ai/reminder.md` (+ miroir FR/EN) hard rule étendue de 50 caractères ; `.ai/agent/response-style.md` (+ miroir) § Précision technique. Aucun impact sur le bloc `AIC-RESTITUTION-CONDENSE` (section distincte) — parité des trois rendus intacte.
- Mesure, re-exécutée APRÈS la dernière édition (règle appliquée à elle-même), sur le repo source : `bash .ai/scripts/measure-context-size.sh` → statique **759** caractères (contre 706 avant ce fix, soit +53) ; `grep '^- Aucune supposition' .ai/reminder.md | wc -c` → **206** ; `wc -c .ai/reminder.md` → **760**.
- Validation : `check-shims`, `check-dogfood-drift`, `check-agent-config`, `check-features`, `test-dogfood-drift-extra`, `test-agents-md-self-sufficient`, `check-feature-docs --strict` (×3 fiches), freshness worktree — PASS ; smoke complet PASS.
- Limite inchangée : enforcement comportemental, aucun gate de véracité possible (hooks LLM-juges interdits par `workflow/codex-hooks-parity`).
- Next : observer si la classe « chiffre faux » réapparaît ; le cas échéant, envisager un nudge à l'écriture des artefacts durables (précédent : `fiche-consolidation-nudge`).
