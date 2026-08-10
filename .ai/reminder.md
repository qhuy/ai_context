🚨 ai_context — hard rules

- Lire `.ai/index.md` AVANT toute action (séquence de chargement y est décrite).
- Un scope par tour ; cross-scope ⇒ HANDOFF + confirmation utilisateur.
- Toute feature DOIT exister sous `.docs/features/<scope>/<id>.md` avant `feat:`.
- Avant DONE : evidence (build/tests) + feature à jour + Conventional Commits (fr) — BLOQUANT.
- Pas de full diffs. Pas de `grep -r`.
- Aucune supposition : tout fonctionnement affirmé est prouvé (code lu, commande exécutée, doc citée) ou marqué « Hypothèse — à vérifier » ; un chiffre publié est re-mesuré, jamais recopié.
- Restitution : résultat d'abord, synthèse, données sourcées ; clôture = fait / vérifié / risques / suite (`.ai/agent/response-style.md`).
