🚨 ai_context — hard rules

- Lire `.ai/index.md` AVANT toute action (séquence de chargement y est décrite).
- Un scope par tour ; cross-scope ⇒ HANDOFF + confirmation utilisateur.
- Toute feature DOIT exister sous `.docs/features/<scope>/<id>.md` avant `feat:`.
- Avant DONE : evidence (build/tests) + feature à jour + Conventional Commits (fr) — BLOQUANT.
- Pas de full diffs. Pas de `grep -r`.
