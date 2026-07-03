# Worklog — core/graph-aware-injection

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-07-02 — couverture co-owner pre-turn-reminder

- Surface touchée : `template/.ai/scripts/pre-turn-reminder.sh.jinja`, co-déclarée par `core/graph-aware-injection` pour le focus `AI_CONTEXT_FOCUS`.
- Changement : suppression des reverse deps globales hors `UserPromptSubmit`, sans changement du contrat focus 1-hop bidirectionnel.
- Décision : pas de HANDOFF core nécessaire sur le contrat graph-aware ; la bascule du graphe détaillé vers le JIT reste portée par `workflow/pre-turn-reminder` + `features-for-path.sh`.

## 2026-07-03 — DONE : clôture du contrat graph-aware
- Intent : fermer la fiche bootstrap après validation que R1 n'a pas modifié le contrat `AI_CONTEXT_FOCUS`.
- Fichiers/surfaces : fiche/worklog `core/graph-aware-injection`.
- Evidence : `check-feature-docs --strict core/graph-aware-injection` PASS ; smoke complet `9affa45` PASS incluant le bonus big-mesh (`AI_CONTEXT_FOCUS` réduit la taille du reminder).
- Décision : Doc Impact Decision C — fiche feature mise à jour, aucun changement runtime dans ce commit de clôture.
- Risques : pas de breaking change, pas de migration de données, pas d'impact sécurité/auth/tenancy ; compatibilité arrière inchangée.
- Next : aucune action immédiate ; rouvrir seulement si le contrat focus ou le voisinage graphe change.
