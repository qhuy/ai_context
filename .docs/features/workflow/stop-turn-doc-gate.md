---
id: stop-turn-doc-gate
scope: workflow
title: Forcer la fraîcheur documentaire en fin de tour (gate Stop)
status: done
type: feature
description: "Hook Stop bloquant qui force la mise à jour de la fiche feature impactée avant de clore un tour, pas seulement au commit."
depends_on:
  - quality/doc-freshness
  - quality/read-only-checks-contract
  - quality/review-delta-uncommitted-coverage
  - workflow/stop-hook-idempotence
  - workflow/auto-worklog
  - workflow/codex-hooks-parity
touches:
  - .ai/scripts/stop-doc-gate.sh
  - template/.ai/scripts/stop-doc-gate.sh.jinja
  - .ai/scripts/stop-sequence.sh
  - template/.ai/scripts/stop-sequence.sh.jinja
  - .claude/settings.json
  - template/.claude/settings.json.jinja
  - tests/unit/test-stop-turn-doc-gate.sh
touches_shared:
  - .ai/scripts/check-feature-freshness.sh
  - template/.ai/scripts/check-feature-freshness.sh.jinja
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
  - .ai/scripts/auto-worklog-flush.sh
  - .ai/scripts/auto-progress.sh
  - .ai/scripts/context-relevance-log.sh
  - .ai/quality/QUALITY_GATE.md
  - template/.ai/quality/QUALITY_GATE.md.jinja
  - .ai/workflows/quality-gate.md
  - tests/unit/test-read-only-checks-contract.sh
  - tests/smoke-test.sh
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: done
  step: "gate Stop livré : --worktree, stop-doc-gate, sequencer, contrat read-only, dogfood drift et smoke complet validés"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si le contrat Stop, la fraîcheur --worktree ou l'ordre gate->archivage change"
  updated: 2026-07-03
---

# Forcer la fraîcheur documentaire en fin de tour (gate Stop)

## Résumé

Le gate de fraîcheur documentaire ne tournait qu'au `git commit` (`PreToolUse(Bash)` → `check-commit-features.sh` → `--staged --strict`). La fenêtre « édité → vérifié → *done* annoncé, mais ni commité ni doc à jour » — exactement le moment où l'agent rend la main — n'avait aucun garde-fou. Cette feature ajoute un hook `Stop` bloquant qui force la mise à jour de la fiche/worklog impactée avant qu'un tour puisse se clore, en réutilisant le moteur de fraîcheur existant via un nouveau mode **working-tree**.

## Objectif

Rendre déterministe la promesse « avant DONE, la doc de la feature impactée est à jour ; tout chemin touché est couvert par une feature ». Ne plus dépendre de la vigilance humaine (« pas de doc impactée ? ») pour déclencher la mise à jour.

## Périmètre

### Inclus

- Mode `--worktree` de `check-feature-freshness.sh` : logique **présence-based** comme `--staged`, mais sur tout le working tree (`collect_uncommitted_paths` = staged ∪ non-stagé ∪ untracked non-ignorés), restreinte aux chemins **substantiels** (périmètre `coverage`).
- `stop-doc-gate.sh` : orchestrateur read-only qui traduit l'échec de fraîcheur en `{"decision":"block","reason":…}` (mécanisme de blocage Claude Code), gère `stop_hook_active` (anti-boucle) et l'échappatoire `AIC_DOC_GATE=off`. Signale les **orphelins** (chemin substantiel couvert par aucune feature) en **avertissement non bloquant**.
- `stop-sequence.sh` : hook `Stop` unique qui **sérialise** le gate read-only AVANT l'archivage (`auto-worklog-flush` → `auto-progress` → `context-relevance-log summary`). Nécessaire car les hooks Stop tournent en parallèle.
- Câblage `Stop` dans `.claude/settings.json` (+ jinja) ramené à un seul hook (`stop-sequence.sh`).
- Helper `_lib.sh` `path_in_coverage_scope` (+ readers `coverage`) pour la définition « substantiel ».
- Documentation : `QUALITY_GATE.md` (section dédiée) + jinja.

### Hors périmètre

- La garantie **bloquante stable** reste `commit-msg` (`--staged --strict`) + CI, agent-agnostique. Ce gate Stop est une couche de forcing branchée par défaut côté Claude (`stop-sequence.sh`) et opt-in côté Codex (`.codex/hooks.json` généré, protocole `decision:block` partagé — voir `workflow/codex-hooks-parity`) ; le warn orphelins reste un canal Claude.
- La refonte du modèle `touches:`/`touches_shared:` (ex. reclasser `_lib.sh` en partagé pour alléger l'obligation multi-features). Noté en Risques.
- La factorisation du parseur de config `coverage` (dupliqué entre `check-feature-coverage.sh` et `_lib.sh`). Noté en Risques.
- L'idempotence du Stop sur tour non structurel (`workflow/stop-hook-idempotence`, livrée).

### Granularité / nommage

Surface = wiring `Stop` + orchestrateur. Scope primaire `workflow` (famille `stop-hook-idempotence`, `pre-turn-reminder`, `auto-worklog`). HANDOFF `quality` pour le moteur (`doc-freshness`) et le contrat read-only (`read-only-checks-contract`).

## Invariants

- **Présence-based, jamais timestamp** : le mode `--worktree` ne compare jamais des dates de commit (contrairement au mode historique). Il regarde uniquement si la fiche/worklog est présente dans le change set, comme `--staged`. Évite le « treadmill staleness » refusé par `doc-freshness` (audit U4).
- **Read-only** : index temporaire via `mktemp`, jamais d'écriture de `.ai/.feature-index.json` (contrat `read-only-checks-contract`). Le gate (`stop-doc-gate.sh`) ne mute rien ; seul l'archivage (déclenché par `stop-sequence.sh` après le gate) mute, comme avant.
- **Sévérité différenciée** : fraîcheur = bloquant ; orphelin/couverture = avertissement (créer/rattacher une fiche est un jugement scope/id non automatisable).
- **Gate AVANT archivage** : `stop-sequence.sh` observe le working tree avant que `auto-worklog-flush` ne touche le worklog. Sinon l'entrée worklog auto satisferait le gate.
- **Fail-open** : git/jq absents, timeout du hook, ou erreur d'archivage ⇒ le tour se termine (best-effort). La garantie dure reste git/CI.
- Le gate commit existant (`--staged --strict`) est inchangé : aucune régression.

## Décisions

- **Correction de la cause racine** : le mode sans `--staged` (historique) compare des timestamps de commits et est aveugle aux édits non commités. Vérifié empiriquement. Il fallait un nouveau mode `--worktree`, pas un re-câblage de l'existant.
- **Blocage Claude Code** : un `Stop` hook ne bloque pas avec `exit 1` (traité comme erreur non bloquante). Le gate émet `{"decision":"block","reason":…}` (exit 0). `stop_hook_active` relâche pour éviter la boucle.
- **Parallélisme des hooks Stop** (doc officielle : « All matching hooks run in parallel ») ⇒ on ne peut pas garantir l'ordre par position dans le tableau. D'où `stop-sequence.sh` qui sérialise gate → archivage dans un seul process. Sans cela, `auto-worklog-flush` (qui auto-appende au worklog des features dont le code a changé) neutraliserait le gate.
- **Anti-bruit (« substantiel »)** : réutilise `coverage.roots` + `coverage.extensions` (override `.ai/project/config.yml`). Zéro nouveau concept de config. Un chemin ne déclenche la fraîcheur que s'il est sous une racine de code avec une extension de code.
- **Échappatoire** : `AIC_DOC_GATE=off` (WIP multi-tour, refactor pur), tracée et documentée.
- **Parité non-Claude** : pas de réinvention. L'événement « fin de travail » d'un agent non-Claude est le commit, déjà couvert par `.githooks/commit-msg`. Le gate Stop est un confort Claude.

## Comportement attendu

1. Fin de tour Claude → `stop-sequence.sh` (hook `Stop` unique).
2. Lit `stop_hook_active` ; si vrai → relâche (archivage normal).
3. `AIC_DOC_GATE=off` → relâche.
4. Lance `stop-doc-gate.sh` (read-only) : `check-feature-freshness.sh --worktree --strict` sur les chemins substantiels. Si un chemin couvert a changé sans fiche/worklog dans le change set → `decision:block` avec le motif (features + fichiers + action + échappatoire + orphelins éventuels). Le tour ne peut pas se clore.
5. Sinon : exécute l'archivage (flush → progress → relevance) puis relaie l'éventuel avertissement orphelin (`additionalContext`).

## Contrats

- Variable d'env : `AIC_DOC_GATE=off|0|false|no` désactive le blocage (relâche tout).
- Entrée : payload Stop JSON sur stdin (`stop_hook_active`).
- Sortie blocage : `{"decision":"block","reason":<str>}` sur stdout, exit 0.
- Sortie warn orphelin : stderr + `{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":<str>}}`, exit 0.
- Code retour toujours 0 (le blocage passe par le JSON, pas l'exit code).
- Nouveau mode CLI réutilisable : `check-feature-freshness.sh --worktree [--warn|--strict]`.

## Validation

`tests/unit/test-stop-turn-doc-gate.sh` (enregistré dans `tests/smoke-test.sh`) :

1. Working tree propre → pas de block.
2. Code couvert modifié sans doc → `--worktree --strict` échoue ; gate émet `decision:block` nommant la feature.
3. `stop_hook_active=true` → jamais de block (anti-boucle).
4. `AIC_DOC_GATE=off` → jamais de block.
5. Worklog de la feature aussi modifié → gate passe.
6. Orphelin substantiel → avertissement (stderr), pas de block.
7. Sequencer : block → archivage sauté ; pass → archivage exécuté.

Read-only : `tests/unit/test-read-only-checks-contract.sh` étendu (`--worktree --warn` et `stop-doc-gate.sh` ne créent pas l'index).

Preuve attendue : `bash tests/smoke-test.sh` PASS + `bash .ai/scripts/check-dogfood-drift.sh` aligné.

Preuve de clôture 2026-07-03 :

- `bash tests/unit/test-stop-turn-doc-gate.sh` PASS.
- `bash tests/unit/test-read-only-checks-contract.sh` PASS.
- `bash -n .ai/scripts/stop-doc-gate.sh .ai/scripts/stop-sequence.sh .ai/scripts/check-feature-freshness.sh template/.ai/scripts/stop-doc-gate.sh.jinja template/.ai/scripts/stop-sequence.sh.jinja template/.ai/scripts/check-feature-freshness.sh.jinja` PASS.
- `bash .ai/scripts/check-dogfood-drift.sh` PASS.
- `bash tests/smoke-test.sh` PASS.

## Risques

- **Coverage multi-features de `_lib.sh`** : `_lib.sh` est dans le `touches:` direct de ~8 features. Toute édition déclenche l'obligation de toucher leurs docs (déjà vrai au commit gate ; le gate Stop le rend visible plus tôt). Atténuation : le filtre « substantiel » et l'échappatoire ; reclassement `touches_shared:` à envisager (hors périmètre).
- **`additionalContext` sur Stop non bloquant** : la prise en compte côté agent n'est pas garantie par tous les runtimes ; le warn orphelin reste émis sur stderr en complément.
- **Fail-open au timeout** : un mesh très large peut dépasser le timeout (20s) → le tour se termine sans gate. Acceptable (garantie = git/CI), mais surveiller la perf sur gros meshes.
- **Duplication du parseur `coverage`** entre `check-feature-coverage.sh` et `_lib.sh` : bénigne, à factoriser ultérieurement.

## Cross-refs

- `quality/doc-freshness` : moteur réutilisé (`check-feature-freshness.sh`) ; ajout du mode `--worktree`. HANDOFF : respecte la politique `--warn` historique (le `--worktree` présence-based est d'une autre nature).
- `quality/read-only-checks-contract` : le gate honore le contrat read-only ; test étendu.
- `quality/review-delta-uncommitted-coverage` : réutilise `collect_uncommitted_paths` pour le change set working-tree.
- `workflow/stop-hook-idempotence` : interaction critique avec `auto-worklog-flush` (raison du sequencer).
- `workflow/auto-worklog` / `workflow/auto-progress-file-filter` : archivage désormais invoqué par `stop-sequence.sh` (logique inchangée).
- `workflow/codex-hooks-parity` : la garantie agent-agnostique reste `commit-msg`/CI.

## Historique / décisions

- 2026-07-06 : requalification — le protocole du gate (`stop_hook_active` + `decision:block`) est partagé Claude/Codex (doc officielle vérifiée) ; `.codex/hooks.json` généré opt-in le branche sur `Stop` côté Codex. Le warn orphelins (`hookSpecificOutput`) reste Claude-only. Livré par `workflow/codex-hooks-parity`.

- 2026-06-26 : création. Cause racine corrigée (working-tree vs historique). Découverte du parallélisme des hooks Stop → design sequencer (confirmé avec l'utilisateur). 3 décisions de cadrage tranchées : cross-scope workflow+quality, blocage jusqu'à résolution, anti-bruit via `coverage`.
- 2026-07-03 : DONE. Gate Stop livré et validé par tests ciblés, contrat read-only, dogfood drift et smoke complet.
