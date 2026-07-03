---
id: codex-hooks-parity
scope: workflow
title: Pilote hooks Codex déterministes
status: done
depends_on:
  - workflow/git-hooks
  - workflow/subagent-contract
touches:
  - .ai/rules/workflow.md
  - template/.ai/rules/workflow.md.jinja
  - .ai/workflows/codex-hooks-parity.md
  - template/.ai/workflows/codex-hooks-parity.md.jinja
touches_shared:
  - README.md
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
product: {}
external_refs:
  codex_hooks: "https://developers.openai.com/codex/hooks"
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
  step: "pilote hooks Codex documenté, opt-in, sans .codex/ par défaut"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si une configuration .codex/ est ajoutée ou si le contrat hooks Codex change"
  updated: 2026-07-03
type: feature
---

# Pilote hooks Codex déterministes

## Résumé

Décrire comment ajouter des hooks Codex uniquement comme garde-fous opt-in, déterministes et non LLM, sans remplacer les hooks Git ni les checks existants.

## Objectif

Codex expose une surface de hooks en évolution. ai_context doit pouvoir l'exploiter quand elle apporte une protection vérifiable, tout en évitant les garanties fantômes ou l'injection de contexte non fiable.

## Périmètre

### Inclus

- Cadrer les hooks Codex autorisés pour un projet ai_context.
- Limiter le pilote aux commandes destructives, au commit et aux checks feature mesh.
- Documenter que les hooks Git restent la garantie stable cross-agent.
- Préparer un contrat vérifiable pour une future configuration `.codex/`.

### Hors périmètre

- Ajouter une injection de contexte Codex équivalente à Claude.
- Utiliser Auto-review, prompt hooks ou un agent LLM comme gate.
- Rendre Codex obligatoire pour les projets scaffoldés.
- Modifier Pack A.

### Granularité / nommage

Cette fiche couvre la parité de garde-fous Codex. Les scripts quality qui valident les configs agents sont documentés dans `quality/agent-config-validation`.

## Invariants

- Les hooks Codex sont opt-in.
- Les hooks Codex ne sont pas la source de vérité de non-régression.
- Aucun hook Codex ne doit charger de contexte lourd par défaut.
- Tout hook doit être déterministe, testable et non interactif.

## Décisions

- Ne pas créer de config `.codex/` par défaut tant que le contrat runtime n'est pas stabilisé dans le dépôt.
- Documenter le pilote dans `.ai/workflows/` et valider toute config future via un check quality.
- Rejeter l'injection `additionalContext` côté Codex tant qu'elle n'offre pas un contrat fiable et testé.

## Comportement attendu

Un projet peut activer des hooks Codex pour alerter ou bloquer une commande dangereuse, un `git commit` incohérent ou une tentative de contournement du feature mesh. Si le hook échoue à s'exécuter, les hooks Git et la CI restent les protections principales.

## Contrats

- Hook autorisé : commande shell déterministe, timeout explicite, script versionné sous `.ai/scripts/`.
- Hook interdit : appel LLM, Auto-review, téléchargement réseau non nécessaire, mutation hors repo, injection de contexte non bornée.
- Sortie attendue : message court, code retour explicite, aucune écriture de fichier sauf trace runtime ignorée.

## Validation

- Vérifier la documentation : `bash .ai/scripts/check-feature-docs.sh --strict workflow/codex-hooks-parity`.
- Vérifier les hooks futurs : `bash .ai/scripts/check-agent-config.sh`.
- Garder la protection stable : `bash .ai/scripts/check-commit-features.sh` et hooks Git.

Preuve de clôture 2026-07-03 :

- Dépendance `workflow/git-hooks` clôturée dans le même change ; `workflow/subagent-contract` déjà clôturée.
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/codex-hooks-parity` PASS.
- `bash .ai/scripts/check-agent-config.sh` PASS.
- `bash .ai/scripts/check-features.sh --no-write` PASS.
- `bash tests/smoke-test.sh` PASS.

## Risques

- Une API hooks Codex mouvante peut rendre une config obsolète.
- Un hook fail-open peut donner une illusion de protection.
- Un hook trop intrusif peut bloquer des agents non Codex.

## Cross-refs

`workflow/git-hooks` reste le point de convergence universel. `workflow/subagent-contract` fixe les règles quand un hook ou une tâche déclenche du travail délégué.

`workflow/stop-turn-doc-gate` : le gate Stop de fraîcheur est Claude-only ; sa parité Codex est documentée ici (recette opt-in « Parité fraîcheur fin de turn » dans `.ai/workflows/codex-hooks-parity.md`). Garantie universelle = `commit-msg --staged --strict` ; signal working-tree plus précoce = primitive agnostique `check-feature-freshness.sh --worktree --strict`, branché opt-in dans un hook Codex de fin de turn. Pas de `.codex/` livré par défaut (décision inchangée).

## Historique / décisions

- 2026-05-12 : création suite à la veille officielle OpenAI Codex hooks.
- 2026-06-26 : ajout de la recette « Parité fraîcheur fin de turn » (workflow/stop-turn-doc-gate). Le gate Stop étant Claude-only, on documente la parité Codex à deux niveaux — `commit-msg --staged --strict` universel (toujours actif) + hook Codex opt-in appelant le primitive `check-feature-freshness.sh --worktree --strict`. Surface Codex `Stop` (config.toml `[hooks]`) notée « à valider » ; aucun `.codex/` livré par défaut (décision inchangée).
- 2026-07-03 : DONE. Pilote documenté seulement ; aucune config `.codex/` livrée par défaut.
