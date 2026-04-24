---
id: template-engine
scope: core
title: Moteur de template copier (profils + scopes conditionnels)
status: active
depends_on: []
touches:
  - copier.yml
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

## Cross-refs

Ce moteur produit le squelette consommé par `feature-mesh`, `feature-index-cache`, `claude-skills`, `git-hooks`. Toute évolution structurelle (nouveau scope, nouveau hook) passe par `copier.yml` + `template/`.

## Historique / décisions

- v0.1 : profil unique fullstack.
- v0.4 : introduction des 4 profils + agents multiselect.
- v0.7.2 : `_envops.keep_trailing_newline` pour préserver les `\n` finaux après rendu jinja.
