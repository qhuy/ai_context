# Worklog — workflow/worktree-isolation

## 2026-06-18 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : workflow
- Intent initial : Isolation worktree des tâches d'agent concurrentes
- Cadrage : `aic-frame` (niveau high), route=feature confirmée par l'utilisateur.

## 2026-06-18 — amendement cycle de vie (challenge staleness)
- Déclencheur : challenge utilisateur — la branche locale « pas à jour » après usage worktree.
- Vérifié empiriquement : `git worktree add <path> origin/<base>` (sans `-b`) ⇒ HEAD détachée. Bug de la commande initiale.
- Correctifs règle (canonique + dogfood) : `git fetch` préalable, `-b <tache>` (vraie branche), refresh `git merge --ff-only origin/<base>` du checkout principal, teardown manuel `git worktree remove` + suppression de branche.
- Périmètre ajusté : teardown manuel désormais inclus ; automatisation (scripts/prune planifié/hook) reste hors périmètre.

## 2026-06-18 12:38 — auto
- Fichiers modifiés :
  - .ai/rules/workflow.md
  - template/.ai/rules/workflow.md.jinja
