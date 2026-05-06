# Worklog — quality/context-relevance-tracker

## 2026-05-06 23:15 — création
- Feature créée en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`.
- Scope : quality.
- Intent initial : tracker minimal viable de pertinence du contexte injecté (logger + reporter), sans MCP, sans bloquer.
- Format précis (Codex round 2-3) :
  - 3 événements : `inject` (PreToolUse), `touch` (PostToolUse), `summary` (Stop).
  - Logger : `.ai/.context-relevance.jsonl` (runtime local, ignoré en commit).
  - Reporter : `context-relevance-report.sh --last N` agrège, calcule précision/rappel approximés par feature.
- Décision Phase 2 : positionnée en #3, après matcher correct (#2) car les ratios sont biaisés tant que le matcher est buggé.
- Approche par défaut : remontée en Phase 2 (vs Phase 3 originale) après cross-check Claude. Codex round 2 : "version minimale viable sans MCP, juste logger en sortie de tour, donne un proxy calibrable".
- Prérequis non bloquant : le tracker peut être livré sans le matcher fixé, mais ses ratios deviennent **calibrés** seulement après. Documenter cette nuance dans le rapport.
- Next : à reprendre dans un turn dédié pour passer en `status: active`, vérifier que les hooks PostToolUse/Stop existent côté Claude, implémenter logger + reporter best-effort, ajouter rotation, tests.
