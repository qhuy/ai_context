# Worklog — quality/feature-schema-validator

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-06-30 — création (pilot ze-solution, P3, après HANDOFF product→quality)

- Fiche créée via `aic-pilot` (pilot `.docs/pilots/2026-06-30-ze-solution.md`, item P3).
- Objet : débloquer C2a — vrai validateur JSON-Schema des fiches, en remplacement de l'heuristique bash, avec **fallback bash conservé** (pas de dépendance dure).
- Décisions : validateur réel + fallback ; runtime recommandé `check-jsonschema` (pip, car Python/pip déjà requis par Copier) ; migration warn→fail alignée sur `core/okf-strict-profile`.
- Phase : spec. Décision ouverte : runtime exact (pip vs node vs lib) et emplacement (script dédié vs inline `check-features`).
- Prochaine étape : trancher le runtime, brancher en mode warn dans `check-features`, écrire tests valides/invalides.
