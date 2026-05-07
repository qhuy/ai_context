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

## 2026-05-07 — implémentation livrée
- **Logger central** `.ai/scripts/context-relevance-log.sh` (3 sous-commandes) :
  - `inject` : 12 args (tool_name, file, direct/dep/injected/unsupported JSON, truncated, budget, index_mtime, matcher_policy, omitted, top_k).
  - `touch` : 3 args (tool_name, file, touched JSON).
  - `summary` : agrège fenêtre last-summary, calcule precision/recall via jq, no-op si fenêtre vide.
  - Rotation 10 MB (configurable via `AI_CONTEXT_RELEVANCE_ROTATION_MB`).
  - Désactivable via `AI_CONTEXT_RELEVANCE_DISABLED=1`.
  - Best-effort total : exit 0 toujours, jq absent → silent no-op, erreurs d'écriture silencieuses.
- **Reporter** `.ai/scripts/context-relevance-report.sh` :
  - `--last N`, `--feature scope/id`, `--format markdown|json`.
  - Markdown : tableau par feature avec injected/touched/intersection/precision/recall + 2 sections « top candidats à ranker plus bas » et « top candidats à matcher mieux ».
- **Hooks branchés** :
  - `features-for-path.sh` : appel `context-relevance-log.sh inject ...` à la fin (best-effort, bloc `{ ... } 2>/dev/null || true`).
  - `auto-worklog-log.sh` : appel `context-relevance-log.sh touch ...` (logue même si matches vide pour repérer touched_not_injected).
  - `.claude/settings.json` : Stop hook séparé `context-relevance-log.sh summary` ajouté en chaîne après auto-worklog-flush et auto-progress.
- **`.ai/.gitignore`** : `.context-relevance.jsonl` et `.context-relevance.jsonl.old`.
- **`.ai/scripts/check-dogfood-drift.sh`** : exclusions ajoutées pour les 2 fichiers runtime.
- **Parité templates** : 5 fichiers (2 nouveaux scripts copiés, 3 existants modifiés, .gitignore template mis à jour, settings.json.jinja mis à jour).
- **Tests** `tests/unit/test-context-relevance.sh` : 8 cas couvrant les 6 obligatoires + 2 robustesse :
  1. Logger 3 événements JSONL parsables.
  2. Reporter 10 summaries synthétiques (core/a injected=10 recall=1).
  3. E2E inject-sans-touch → injected_not_touched non vide.
  4. E2E touch-sans-inject → touched_not_injected non vide.
  5. Rotation taille basse → `.old` produit.
  6. Best-effort écriture impossible → exit 0.
  7. Sous-commande inconnue → silent no-op.
  8. `AI_CONTEXT_RELEVANCE_DISABLED=1` → no-op.
- Validation : check-shims, check-features, check-dogfood-drift, smoke-test, 8 cas test unit ALL PASS.
- Phase bumpée implement → review.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .ai/.gitignore
  - .ai/scripts/auto-worklog-log.sh
  - .ai/scripts/features-for-path.sh
  - .claude/settings.json
  - template/.ai/scripts/auto-worklog-log.sh.jinja
  - template/.ai/scripts/features-for-path.sh.jinja
  - template/.claude/settings.json.jinja
