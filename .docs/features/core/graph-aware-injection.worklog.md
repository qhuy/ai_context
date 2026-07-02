# Worklog — core/graph-aware-injection

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-07-02 — couverture co-owner pre-turn-reminder

- Surface touchée : `template/.ai/scripts/pre-turn-reminder.sh.jinja`, co-déclarée par `core/graph-aware-injection` pour le focus `AI_CONTEXT_FOCUS`.
- Changement : suppression des reverse deps globales hors `UserPromptSubmit`, sans changement du contrat focus 1-hop bidirectionnel.
- Décision : pas de HANDOFF core nécessaire sur le contrat graph-aware ; la bascule du graphe détaillé vers le JIT reste portée par `workflow/pre-turn-reminder` + `features-for-path.sh`.
