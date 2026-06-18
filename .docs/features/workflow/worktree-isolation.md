---
id: worktree-isolation
scope: workflow
title: Isolation worktree des tâches d'agent concurrentes
status: active
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
  phase: implement
  step: "section worktree ajoutée à la règle workflow (canonique + dogfood)"
  blockers: []
  resume_hint: "vérifier check-dogfood-drift + check-shims ; règle inline lean, pas de fichier .ai/workflows/ de détail"
  updated: 2026-06-18
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

### Hors périmètre

- Modifier le hook `auto-worklog-flush.sh` ou son idempotence (voir `workflow/stop-hook-idempotence`).
- Automatiser la création / le nettoyage (`git worktree prune`) des worktrees : règle d'opération seule, aucun script.
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

Une 2ᵉ tâche démarre alors qu'une session tourne sur le checkout principal : l'agent crée `git worktree add ../<repo>.worktrees/<tache> origin/<base>`, travaille isolé, et le hook `Stop` n'écrit que dans le worktree de la tâche → zéro churn sur le tree partagé.

## Contrats

- Tâche concurrente ⇒ worktree dédié `../<repo>.worktrees/<tache>` basé sur `origin/<base>`.
- Avant d'écrire dans le checkout principal : vérifier les sessions actives (`ps aux | grep 'claude --output-format'`, ou l'équivalent Codex).
- Aucune divergence entre la règle canonique et le dogfood (gardé par `check-dogfood-drift.sh`).

## Validation

- `bash .ai/scripts/check-dogfood-drift.sh` : parité canonique / dogfood.
- `bash .ai/scripts/check-shims.sh` : cohérence des shims générés.
- `bash .ai/scripts/check-feature-docs.sh workflow/worktree-isolation` : fiche complète.
- `bash .ai/scripts/check-features.sh` : intégrité du mesh.

## Risques

- `ps aux | grep 'claude --output-format'` peut rater une session non-Claude : atténué par l'annotation « ou l'équivalent Codex » et par la règle « worktree par défaut » (non conditionnée au grep).
- Édition d'un seul des deux fichiers de règle ⇒ `check-dogfood-drift.sh` rouge : acceptance impose les deux.

## Cross-refs

- `workflow/auto-worklog` : le hook `Stop` `auto-worklog-flush.sh` est la cause racine du churn que cette règle mitige.
- `core/dogfood-runtime-sync` : mécanisme de propagation canonique → dogfood → shims consommateurs.
- `workflow/subagent-contract` : délégation intra-session (distincte des sessions concurrentes).
- `workflow/codex-hooks-parity` : la règle est valable Claude ET Codex (surface workflow partagée, pas un hook).

## Historique / décisions

- 2026-06-18 : création suite au cas réel de double implémentation timezone en parallèle ; règle d'isolation worktree ajoutée à la règle workflow canonique et dogfoodée.
