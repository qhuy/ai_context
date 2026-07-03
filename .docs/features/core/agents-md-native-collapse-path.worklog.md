# Worklog — core/agents-md-native-collapse-path

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-06-30 — création (pilot ze-solution, P2, après HANDOFF product→core)

- Fiche créée via `aic-pilot` (pilot `.docs/pilots/2026-06-30-ze-solution.md`, item P2).
- Posture tranchée = **hedge** : préparer l'optionnalité de l'indirection `.ai/index.md`, sans la retirer ni pivoter AGENTS.md en source de contenu.
- Cadre : AGENTS.md auto-suffisant = entrée + protocole lean minimal inline (pas de duplication de `.ai/index.md`) ; respect strict de l'invariant `aic-surface-canonical` (`.ai/` source unique).
- Distinct de `agents-md-shim-canonical` qui a mis l'indirection hors-périmètre (« chantier séparé »).
- Phase : spec. Décision ouverte : comment opérationnaliser concrètement le kill_criterion #34235 (veille/check).
- Prochaine étape : définir le contenu inline minimal d'AGENTS.md + le signal kill_criterion.

## 2026-06-30 — incrément 1 : self-suffisance d'AGENTS.md verrouillée (check-shims)

- Constat : runtime `AGENTS.md` et `template/AGENTS.md.jinja` portent DÉJÀ les hard rules inline (self-suffisants). L'incrément = **verrou anti-régression** plutôt que réécriture.
- `check-shims.sh` : nouvelle assertion — `AGENTS.md` doit contenir un bloc `Hard rules` inline, sinon `ko` (« self-suffisance collapse-path, pas un simple pointeur »). Précondition du collapse rendue testable : un agent lisant AGENTS.md seul connaît les règles.
- Runtime + `.jinja` (parité dogfood vérifiée). Test `tests/unit/test-agents-md-self-sufficient.sh` : cas AGENTS.md auto-suffisant → OK, cas pointeur nu → échec + message.
- Surface `check-shims.sh` = possédée par `core/agents-md-shim-canonical` (worklog mis à jour) ; initiative = cette fiche (P2).
- Invariant `aic-surface-canonical` (`.ai/` source unique) préservé : AGENTS.md reste l'ENTRÉE, pas le contenu.
- **HANDOFF `quality/smoke-test`** : brancher `test-agents-md-self-sufficient.sh` dans le smoke — non fait ici (mono-scope core), même pattern que P3.
- Reste : opérationnaliser le kill_criterion #34235 (veille/signal par agent) ; doc migration warn downstream.

## 2026-07-03 — incrément 2 : migration warn + smoke handoff
- Intent : fermer les follow-ups livrables hors kill criterion : doc migration downstream et branchement du test self-sufficiency dans le smoke.
- Fichiers/surfaces : `docs/upgrading.md`, `CHANGELOG.md`, `tests/smoke-test.sh`, fiche/worklog core.
- Décision : documenter un mode prudent — `AGENTS.md` auto-suffisant, shims dérivés vérifiés par agents activés, mais `CLAUDE.md` conservé tant que #34235 n'est pas opérationnalisé.
- HANDOFF `quality/smoke-test` exécuté : `test-agents-md-self-sufficient.sh` devient l'étape `[0h1/28]`.
- Validation : test ciblé PASS, `bash tests/smoke-test.sh` PASS complet, freshness worktree stricte PASS.
- Next : opérationnaliser le kill_criterion #34235 (signal/veille par agent) avant toute optionnalité réelle de `CLAUDE.md`.
