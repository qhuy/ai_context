---
id: worktree-isolation
scope: workflow
title: Isolation worktree des tâches d'agent concurrentes
status: done
depends_on:
  - workflow/auto-worklog
  - core/dogfood-runtime-sync
touches:
  - .ai/rules/workflow.md
  - template/.ai/rules/workflow.md.jinja
touches_shared: []
product: {}
external_refs: {}
doc:
  level: brief
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: done
  step: "règle worktree + cycle de vie alignés runtime/template et validés"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si le cycle worktree, le teardown ou la règle de concurrence change"
  updated: 2026-07-03
type: feature
---

# Isolation worktree des tâches d'agent concurrentes

## Résumé

Règle d'opération cross-agent : toute tâche lancée en parallèle d'une autre session d'agent (Claude Code, Codex…) vit dans un `git worktree` dédié, jamais le checkout principal partagé. Évite le churn worklog, le WIP mélangé et le travail dupliqué.

## Objectif

Quand deux sessions d'agent travaillent dans le même working tree, elles se marchent dessus. Le hook `Stop` `auto-worklog-flush.sh` ré-écrit des entrées `## DATE — auto / Fichiers modifiés` et bump `updated:` à chaque fin de tour, ce qui re-salit le tree en boucle. Cas réel observé : deux agents ont implémenté la même conversion timezone en parallèle sur deux branches distinctes. La règle fixe l'isolation par worktree comme défaut d'opération.

## Périmètre

### Inclus

- Une section `## Isolation des tâches concurrentes (worktree)` dans la règle workflow canonique `template/.ai/rules/workflow.md.jinja` et son dogfood `.ai/rules/workflow.md`.
- Règle lean (≤ ~6 lignes), tool-agnostique, propagée aux consommateurs via `copier update`.
- Cycle de vie complet : `git fetch` + `git worktree add -b <tache>` (vraie branche, pas HEAD détachée), refresh `merge --ff-only` du checkout principal, teardown manuel `git worktree remove` + suppression de branche en fin de tâche.

### Hors périmètre

- Modifier le hook `auto-worklog-flush.sh` ou son idempotence (voir `workflow/stop-hook-idempotence`).
- Automatiser le cycle de vie (script de scaffolding, `git worktree prune` planifié, hook de teardown) : la règle reste manuelle et déclarative. Le teardown manuel (`git worktree remove` + suppression de branche) est en revanche inclus comme étape attendue.
- Figer une copie de la règle directement dans un shim consommateur.

### Granularité / nommage

Cette fiche couvre uniquement la règle d'isolation des sessions concurrentes. La délégation intra-session est couverte par `workflow/subagent-contract` ; la parité Claude/Codex des garde-fous par `workflow/codex-hooks-parity`.

## Invariants

- La règle vit dans `workflow.md` (surface partagée cross-agent), jamais dans une surface Claude-only.
- Le checkout principal reste sur la branche d'intégration, propre, pour lecture et opérations git.
- Source canonique = `template/.ai/rules/workflow.md.jinja` ; le dogfood `.ai/rules/workflow.md` doit rester identique (au `{{ project_name }}` près).

## Décisions

- Section dédiée plutôt que greffon sur `codex-hooks-parity` : `workflow.md` suit la convention « une section = une feature ».
- Pas de fichier `.ai/workflows/worktree-isolation.md` de détail : règle inline auto-suffisante pour respecter le lean context.
- `git worktree` brut (pas d'outil propriétaire ni de chemin machine) pour rester tool-agnostique côté consommateur.

## Comportement attendu

Une 2ᵉ tâche démarre alors qu'une session tourne sur le checkout principal : l'agent fait `git fetch origin && git worktree add -b <tache> ../<repo>.worktrees/<tache> origin/<base>` (vraie branche depuis une base fraîche), travaille isolé, et le hook `Stop` n'écrit que dans le worktree de la tâche → zéro churn sur le tree partagé. En fin de tâche, il retire le worktree et la branche mergée, et resynchronise le checkout principal (`git fetch && git merge --ff-only origin/<base>`).

## Contrats

- Tâche concurrente ⇒ worktree dédié `../<repo>.worktrees/<tache>`, créé via `git fetch origin && git worktree add -b <tache> … origin/<base>` (base fraîche, branche nommée — jamais une HEAD détachée).
- Avant d'écrire dans le checkout principal : vérifier les sessions actives (`ps aux | grep 'claude --output-format'`, ou l'équivalent Codex).
- Checkout principal maintenu à jour par fast-forward only (`git fetch && git merge --ff-only origin/<base>`) ; jamais de WIP dessus.
- Fin de tâche ⇒ `git worktree remove <path>` + suppression de la branche mergée (pas de worktree orphelin).
- Aucune divergence entre la règle canonique et le dogfood (gardé par `check-dogfood-drift.sh`).

## Validation

- `bash .ai/scripts/check-dogfood-drift.sh` : parité canonique / dogfood.
- `bash .ai/scripts/check-shims.sh` : cohérence des shims générés.
- `bash .ai/scripts/check-feature-docs.sh workflow/worktree-isolation` : fiche complète.
- `bash .ai/scripts/check-features.sh` : intégrité du mesh.

Preuve de clôture 2026-07-03 :

- `bash .ai/scripts/check-dogfood-drift.sh` PASS.
- `bash .ai/scripts/check-shims.sh` PASS.
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/worktree-isolation` PASS.
- `bash .ai/scripts/check-features.sh --no-write` PASS.
- `bash tests/smoke-test.sh` PASS.

## Risques

- `ps aux | grep 'claude --output-format'` peut rater une session non-Claude : atténué par l'annotation « ou l'équivalent Codex » et par la règle « worktree par défaut » (non conditionnée au grep).
- Édition d'un seul des deux fichiers de règle ⇒ `check-dogfood-drift.sh` rouge : acceptance impose les deux.
- `git worktree add <path> origin/<base>` **sans `-b`** ⇒ HEAD détachée (vérifié empiriquement) : commits récupérables uniquement par reflog. Mitigé par le `-b <tache>` désormais obligatoire dans la règle.
- Teardown oublié ⇒ worktrees orphelins (`prunable`) et bases périmées. Mitigé par l'étape de fin de tâche, mais reste manuel (pas de garde automatique).

## Cross-refs

- `workflow/auto-worklog` : le hook `Stop` `auto-worklog-flush.sh` est la cause racine du churn que cette règle mitige.
- `core/dogfood-runtime-sync` : mécanisme de propagation canonique → dogfood → shims consommateurs.
- `workflow/subagent-contract` : délégation intra-session (distincte des sessions concurrentes).
- `workflow/codex-hooks-parity` : la règle est valable Claude ET Codex (surface workflow partagée, pas un hook).

## Historique / décisions

- 2026-06-18 : création suite au cas réel de double implémentation timezone en parallèle ; règle d'isolation worktree ajoutée à la règle workflow canonique et dogfoodée.
- 2026-06-18 : challenge utilisateur sur la staleness. Vérifié que `git worktree add origin/<base>` produit une HEAD détachée → correction `-b <tache>` + `git fetch` préalable. Distinction posée : la staleness n'est pas intrinsèque au worktree (le checkout principal n'avance pas seul après un merge remote ; le worktree + sa branche survivent au ticket). Cycle de vie ajouté (refresh `merge --ff-only`, teardown `worktree remove` + branche), initialement classé hors périmètre.
- 2026-07-03 : DONE. Règle runtime/template alignée ; teardown manuel conservé hors automatisation.
