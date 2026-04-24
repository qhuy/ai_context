---
id: template-engine
scope: core
title: Moteur de template copier (profils + scopes conditionnels)
status: active
depends_on: []
touches:
  - copier.yml
  - README.md
  - template/**
progress:
  phase: review
  step: "bootstrap dog-fooding (v0.9 historique)"
  blockers: []
  resume_hint: "aucune action requise — fiche bootstrap post-shipping ; rouvrir si modification du code touché"
  updated: 2026-04-24
---

# Moteur de template copier

## Objectif

Industrialiser la génération du contexte AI dans n'importe quel projet via `copier copy gh:huyqdt/ai_context .`. Quatre profils (`minimal`, `backend`, `fullstack`, `custom`) déterminent les scopes générés.

## Comportement attendu

- `copier copy` rend les fichiers `.jinja` et exclut conditionnellement les shims/règles selon `agents` et `scopes`.
- `_message_after_copy` guide les prochaines étapes (activation hooks, scripts à lancer).
- `copier update` re-applique les diffs sans casser les ajouts utilisateur.

## Contrats

- `project_name` requis ; validateur bloque si vide.
- `scope_profile` ∈ {minimal, backend, fullstack, custom} → dérive `scopes` (variable calculée).
- `agents` multiselect ∈ {claude, codex, cursor, gemini, copilot} → conditionne shims.
- `docs_root` (default `.docs`) configure le dossier feature mesh.
- `tech_profile` ∈ {generic, dotnet-clean-cqrs, react-next, fullstack-dotnet-react} → génère des règles stack optionnelles sans modifier les scopes métier.

## Cross-refs

Ce moteur produit le squelette consommé par `feature-mesh`, `feature-index-cache`, `claude-skills`, `git-hooks`. Toute évolution structurelle (nouveau scope, nouveau hook) passe par `copier.yml` + `template/`.

## Historique / décisions

- v0.1 : profil unique fullstack.
- v0.4 : introduction des 4 profils + agents multiselect.
- v0.7.2 : `_envops.keep_trailing_newline` pour préserver les `\n` finaux après rendu jinja.
- 2026-04-24 : ajout du script `template/.ai/scripts/auto-progress.sh.jinja` + entrée Stop dans `template/.claude/settings.json.jinja` + entrées `.session-edits.flushed` / `.progress-history.jsonl` dans `template/.ai/.gitignore`. Édité dans le cadre du HANDOFF workflow → core émis pendant l'implémentation de `workflow/conversational-skills` (v3, auto-progression invisible). Aucune dérive de profil ni de variable copier ; uniquement enrichissement de la moisson de fichiers rendus.
- 2026-04-24 : ajout de `template/.githooks/pre-commit.jinja` (hook universel d'auto-progression) + update `template/.githooks/README.md.jinja` pour le documenter. Édition cross-scope mineure depuis `workflow/git-hooks` (mini-chantier 1.5, parité agent-agnostic pour Codex/Cursor/Gemini/Copilot). Le template utilise la variable `{{ agents }}` pour lister les bénéficiaires dans le commentaire. Pas d'impact sur `copier.yml` ni sur la dérivation des scopes — simple fichier supplémentaire moissonné systématiquement (pas de condition jinja).
- 2026-04-24 : update `_message_after_copy` dans `copier.yml` + réécriture de `template/AGENTS.md.jinja` pour acter l'UX « 0 skill par défaut » (auto-progression invisible via hooks Stop + pre-commit, skills `/aic` et `/aic-feature-resume` en override/lecture seulement). HANDOFF reçu depuis `workflow/conversational-skills` (chantier 3). Aucune variable copier nouvelle, aucune dérive de profil — modification éditoriale des messages/docs.
- 2026-04-24 : patch `template/.ai/scripts/auto-progress.sh.jinja` — le script crée désormais le worklog s'il n'existe pas (au lieu de skipper). Bug révélé par le smoke-test [18/27] : pour les agents non-Claude (pre-commit sans hook Stop préalable), le worklog n'avait jamais été créé par `auto-worklog-flush.sh`, donc l'auto-progression ne laissait aucune trace lisible. Correctif miroir sur `.ai/scripts/auto-progress.sh`. Ajout section `## Auto-progression` dans `template/.ai/index.md.jinja`.
- 2026-04-24 : ajout des helpers de matching `touches:` dans `template/.ai/scripts/_lib.sh.jinja`. Objectif : éviter les divergences entre hook `PreToolUse`, auto-worklog, pre-commit et coverage.
- 2026-04-24 : les scripts template consomment désormais `AI_CONTEXT_DOCS_ROOT={{ docs_root }}` depuis `_lib.sh.jinja` pour supporter `docs_root=docs` sur les chemins runtime (`check-features`, index, reminder, commit guard).
- 2026-04-24 : README racine synchronisé avec le runtime actuel (`docs_root` configurable, matching `touches:` centralisé, pre-commit/auto-progress dans l'arbre généré).
- 2026-04-24 : ajout du preset `tech_profile` dans `copier.yml` + règles conditionnelles `tech-dotnet`, `tech-react`, `stack-fullstack-dotnet-react`. Les règles reprennent des patterns génériques observés sur `ticketing.apps` (Clean Architecture/CQRS, feature-sliced React, contrat back/front), sans copier les conventions métier/projet.
- 2026-04-24 : README enrichi avec une procédure de migration pour projet existant déjà équipé d'un contexte AI : preview hors repo, inventaire des fichiers à copier vs fusionner, migration progressive des features à plat vers `.docs/features/<scope>/`.
- 2026-04-24 : retour d'installation sur projet réel — correction du newline littéral dans `pre-turn-reminder.sh` et exclusion des dossiers générés (`node_modules`, `bin`, `obj`, `dist`, `wwwroot`, etc.) dans `check-feature-coverage.sh`, avec extension du coverage aux fichiers C#.
