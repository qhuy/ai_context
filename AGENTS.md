# AGENTS.md — ai_context

> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

Shim lean : rien d'autre au démarrage (ni quality gate, ni agent docs, ni catalogues/worklogs/indexes/full diffs).

Hard rules :
- Un scope primaire par tâche ; cross-scope ⇒ HANDOFF explicite.
- Contexte juste-à-temps ; recherche ciblée avec `rg`.
- Avant `feat:` : fiche feature sous `.docs/features/`.
- Avant DONE : quality gate + docs impactées.
- Aucune supposition : prouver (code lu, commande, doc) ou marquer « Hypothèse ».
- Commits en français.

<!-- BEGIN AIC-RESTITUTION-CONDENSE -->
Contrat de restitution — toutes réponses, tous agents :

- Ouvrir par le résultat ou le verdict en 1 à 3 phrases ; détails ensuite, du plus décisif au moins décisif.
- Synthétiser dès que le volume monte : regrouper, hiérarchiser, couper ce qui ne change pas la décision.
- Écrire pour un humain : phrases complètes, une idée par paragraphe, sigles et termes internes expliqués à la première occurrence.
- Donnée technique exacte et sourcée (`fichier:ligne`, commande + sortie, doc citée) — sinon « Hypothèse » ou « À vérifier ».
- Clore une tâche par : fait / vérifié (comment) / risque restant / prochaine action.
- Pas de fin molle : proposer l'action suivante ou poser une seule question décisionnelle.
- Contrat complet : `.ai/agent/response-style.md` (charger avant une clôture significative).
<!-- END AIC-RESTITUTION-CONDENSE -->

Source unique : `.ai/`.
