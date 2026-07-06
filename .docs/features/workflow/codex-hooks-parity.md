---
id: codex-hooks-parity
scope: workflow
title: Pilote hooks Codex déterministes
status: active
depends_on:
  - workflow/git-hooks
  - workflow/subagent-contract
touches:
  - .ai/rules/workflow.md
  - template/.ai/rules/workflow.md.jinja
  - .ai/workflows/codex-hooks-parity.md
  - template/.ai/workflows/codex-hooks-parity.md.jinja
  - template/.codex/hooks.json.jinja
touches_shared:
  - README.md
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - copier.yml
  - tests/smoke-test.sh
  - .ai/scripts/stop-doc-gate.sh
  - template/.ai/scripts/stop-doc-gate.sh.jinja
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
  phase: implement
  step: "config .codex/hooks.json générée opt-in (enable_codex_hooks) + contrat mis à jour sur la doc officielle ; reste README (Honnêteté runtime) et _message_after_copy"
  blockers: []
  resume_hint: "livrer le commit docs (README table Honnêteté runtime, conclusion, FAQ, _message_after_copy) puis clôturer avec preuve"
  updated: 2026-07-06
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
- Limiter le pilote au reminder borné par tour, au gate de fraîcheur fin de turn, aux commandes destructives, au commit et aux checks feature mesh.
- Documenter que les hooks Git restent la garantie stable cross-agent.
- Générer opt-in la configuration `.codex/hooks.json` conforme au contrat (`enable_codex_hooks`, défaut false).

### Hors périmètre

- Injection de contexte par édition (équivalent `features-for-path.sh`) : la sortie PreToolUse documentée côté Codex n'offre aucun canal `additionalContext` et l'outil d'édition est `apply_patch`.
- Auto-worklog côté Codex : le payload PostToolUse `apply_patch` n'est pas validé pour `auto-worklog-log.sh`.
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

- La config `.codex/hooks.json` est générée opt-in (`enable_codex_hooks`, défaut `false`) — jamais par défaut (décision « pas de `.codex/` par défaut » maintenue pour le défaut).
- Format retenu : `hooks.json` (sidecar JSON) plutôt que `[hooks]` dans `config.toml` — validable par le `jq` déjà requis, schéma quasi identique à `.claude/settings.json`, pas de collision avec un éventuel `config.toml` du consommateur.
- `stop-doc-gate.sh` est réutilisé tel quel sur l'événement `Stop` : contrat vérifié identique à Claude (doc officielle 2026-07-06, `stop_hook_active` + `decision:block`). Le primitive brut `check-feature-freshness.sh --worktree --strict` ne doit PAS être branché sur `Stop` (exit 1 = non bloquant côté Codex).
- L'injection bornée du reminder par tour est adoptée (`pre-turn-reminder.sh --format=text` sur `UserPromptSubmit`, stdout = contexte documenté) ; l'injection par édition reste rejetée (aucun canal documenté).
- Documenter le pilote dans `.ai/workflows/` et valider toute config via `check-agent-config.sh` (validation stricte livrée par `quality/agent-config-validation`).

## Comportement attendu

Un projet scaffoldé avec `codex` + `enable_codex_hooks=true` reçoit `.codex/hooks.json` : reminder borné injecté à chaque tour (`UserPromptSubmit`) et gate de fraîcheur documentaire en fin de turn (`Stop`, bloquant via `decision:block`, échappatoire `AIC_DOC_GATE=off`). Codex ne charge ces hooks qu'après trust de la couche projet ; si le hook ne s'exécute pas, les hooks Git (`commit-msg`) et la CI restent les protections principales. Un projet peut aussi ajouter des hooks locaux (commande dangereuse, commit) dans le cadre du contrat.

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
- 2026-07-06 : réouverture (chantier P1 d'ANALYSE.md). API hooks Codex vérifiée sur la doc officielle : repo-level `<repo>/.codex/hooks.json` supporté (trust model), événement `Stop` au contrat identique à Claude, stdout `UserPromptSubmit` injecté comme contexte, PAS de canal d'injection PreToolUse. Génération opt-in de `.codex/hooks.json` (reminder + gate), contrat corrigé (l'ancien exemple TOML `[hooks.Stop]` sur le primitive brut était non bloquant), `stop-doc-gate.sh` requalifié protocole partagé Claude/Codex, étape smoke `[28d/28]`. Validation stricte des configs portée par `quality/agent-config-validation`.
- 2026-06-26 : ajout de la recette « Parité fraîcheur fin de turn » (workflow/stop-turn-doc-gate). Le gate Stop étant Claude-only, on documente la parité Codex à deux niveaux — `commit-msg --staged --strict` universel (toujours actif) + hook Codex opt-in appelant le primitive `check-feature-freshness.sh --worktree --strict`. Surface Codex `Stop` (config.toml `[hooks]`) notée « à valider » ; aucun `.codex/` livré par défaut (décision inchangée).
- 2026-07-03 : DONE. Pilote documenté seulement ; aucune config `.codex/` livrée par défaut.
