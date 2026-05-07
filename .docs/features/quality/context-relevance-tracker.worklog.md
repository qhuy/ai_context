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

## 2026-05-07 — cross-check Codex pre-implémentation (5 choix tranchés)
- Avant de coder, 5 choix + 3 questions ouvertes envoyés à Codex. Verdict initial : pas « go » tel quel, 4 corrections + 2 résolutions à acter.
- **Choix 1 — Branchement hooks** : A1 **partiel**. `features-for-path.sh` log inject ; `auto-worklog-log.sh` log touch. **Refus** de mettre summary dans `auto-worklog-flush.sh` (early exit raterait le cas critique inject-sans-touch). Solution : Stop hook **séparé** `context-relevance-log.sh summary` ajouté en chaîne après les hooks existants.
- **Choix 2 — tour_id** : B3 (fenêtre temporelle) confirmé. Contrat explicite ajouté : `window_start_ts`/`window_end_ts`, no-op si fenêtre vide.
- **Choix 3 — Rotation** : C1 (taille 10 MB) confirmé. **Retrait** de la promesse atomicité PIPE_BUF (confusion pipes/FIFOs, pas applicable au fichier régulier). Best-effort accepté, race append/rotation non bloquante. `.ai/.gitignore` ajoute `.context-relevance.jsonl*`.
- **Choix 4 — Reporter** : D1 confirmé mais wording corrigé : `.ai/scripts/context-relevance-report.sh` (pas le test). Pas d'intégration `aic.sh` dans ce scope.
- **Choix 5 — Tests** : E3 (unit + E2E) confirmé. 6 cas obligatoires définis (logger 3 events, reporter 10 summaries synthétiques, E2E inject-sans-touch, E2E touch-sans-inject, rotation seuil bas, best-effort écriture impossible).
- **Q1 résolu** : pas de UUID, fenêtre last-summary suffit.
- **Q2 résolu** : logger même si unsupported. Champs structurés (matcher_policy, unsupported_patterns, direct_features, dependency_features, injected_features, omitted_count, top_k).
- **Q3 résolu** : pas de promesse atomicité.
- Mesh : `touches:` étendu (context-relevance-log.sh, context-relevance-report.sh, features-for-path.sh, auto-worklog-log.sh, .claude/settings.json, .ai/.gitignore, templates).
- Risque « matcher contaminé bash 3.2 » retiré : Phase 2 #2 livrée.
- Phase bumpée spec → implement.
- Next : implémenter dans un turn dédié.
