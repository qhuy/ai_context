---
id: git-hooks
scope: workflow
title: Git hooks (commit-msg + post-checkout + pre-commit)
status: active
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
  - workflow/auto-worklog
touches:
  - template/.githooks/**
  - template/.ai/scripts/check-commit-features.sh.jinja
  - .githooks/**
progress:
  phase: implement
  step: "freshness documentaire rafraîchie après dogfood"
  blockers: []
  resume_hint: "écrire assertion smoke-test pour pre-commit (staged → bascule phase spec→implement via git commit)"
  updated: 2026-05-03
---

# Git hooks

## Objectif

Faire respecter le mesh au moment du commit et tenir l'index à jour entre branches.

## Comportement attendu

- `commit-msg` : valide Conventional Commits ; si type `feat:`, exige qu'au moins un fichier `<docs_root>/features/**` soit touché par le commit.
- `post-checkout` : rebuild de `.feature-index.json` (le mesh peut diverger entre branches).
- `pre-commit` : **auto-progression universelle**. Dérive les features couvertes par les fichiers stagés, matérialise `.ai/.session-edits.flushed`, invoque `auto-progress.sh`, re-stage les fiches/worklogs modifiés. Non bloquant (exit 0 garanti).
- Activation : `git config core.hooksPath .githooks && chmod +x .githooks/*` (étape 2 du `_message_after_copy`).

## Contrats

- Bloquant pour `feat:` sans feature touchée.
- Non bloquant pour `chore`, `docs`, `fix` (warning si message hors Conventional).
- `pre-commit` **ne bloque jamais** un commit : toute erreur interne (absence d'index, jq manquant, pattern non résolu) → exit 0 silencieux.
- Langue du message imposée par `commit_language` (fr/en).
- Idempotence : si le hook Claude `Stop` a déjà auto-progressé dans le même tour, `.session-edits.flushed` est vide ou les phases sont déjà basculées → `pre-commit` est un no-op.

## Cross-refs

- Côté CI : `ci-guard` rejoue `check-features.sh` même si le hook local a été contourné (`--no-verify`).
- `pre-commit` est le **point de convergence universel** de l'auto-progression : garantit parité Claude / Codex / Cursor / Gemini / Copilot / humain CLI. Le hook Claude `Stop` (`auto-progress.sh` décrit dans `workflow/conversational-skills`) reste comme bonus de latence pour les utilisateurs Claude (bascule visible avant commit).
- Le matching des fichiers stagés contre `touches:` passe par `_lib.sh` pour partager exactement la même sémantique que les hooks Claude.

## Historique / décisions

- Heuristique d'extraction du message commit (`-m "..."`, heredoc) : si format atypique, validation passe silencieusement. Limitation tracée dans PROJECT_STATE.md.
- **2026-04-24** — Réouverture (phase=implement) : ajout du hook `pre-commit` pour parité agent-agnostic. Décision prise dans le cadre de `workflow/conversational-skills` v3 (auto-progression invisible) : le hook Claude `Stop` seul ne couvrait que Claude Code, rupture de garantie pour les autres agents du multiselect `agents` copier. Option B retenue (git pre-commit = point de convergence universel) après comparaison avec option A (acter Claude-first — rejetée, rupture de promesse multi-agent) et option C (wrapper script — rejetée, friction d'invocation).
- **2026-04-24** — Refactor : `pre-commit` source `_lib.sh` et utilise `features_matching_path`, au lieu de dupliquer une logique `jq startswith/endswith`.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; les contrats `commit-msg`, `post-checkout` et `pre-commit` restent inchangés.
