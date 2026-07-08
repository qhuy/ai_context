---
id: git-hooks
scope: workflow
title: Git hooks (commit-msg + post-checkout + pre-commit)
status: done
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
  - workflow/auto-worklog
touches:
  - template/.githooks/**
  - template/.ai/scripts/check-commit-features.sh.jinja
  - .githooks/**
  - tests/unit/test-check-commit-features-relevance.sh
  - tests/unit/test-pre-commit-worklog-stage.sh
progress:
  phase: done
  step: "hooks commit-msg/post-checkout/pre-commit livrés ; assertion pre-commit spec->implement couverte par le smoke"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si le contrat des hooks Git ou la convergence pre-commit change"
  updated: 2026-07-03
type: feature
---

# Git hooks

## Résumé

Trois hooks Git (`commit-msg`, `post-checkout`, `pre-commit`) font respecter le mesh au moment du commit, tiennent `.feature-index.json` à jour entre branches et garantissent une auto-progression agent-agnostic. C'est le point de convergence universel qui assure la parité Claude / Codex / Cursor / Gemini / Copilot / humain CLI.

## Objectif

Faire respecter le mesh au moment du commit et tenir l'index à jour entre branches.

## Périmètre

### Inclus

- Les trois hooks livrés : `commit-msg` (validation Conventional + garde `feat:`), `post-checkout` (rebuild d'index) et `pre-commit` (auto-progression universelle).
- Activation via `git config core.hooksPath .githooks && chmod +x .githooks/*` (étape 2 du `_message_after_copy`).
- Le matching des fichiers stagés contre `touches:`, mutualisé avec les hooks Claude via `_lib.sh` (`features_matching_path`).

### Hors périmètre

- Le rejouage CI des validations en cas de contournement local (`--no-verify`, `core.hooksPath` désactivé) : couvert par `quality/ci-guard`.
- La logique d'auto-progression elle-même (`auto-progress.sh`) et le hook Claude `Stop`, portés par `workflow/conversational-skills`.
- La construction de l'index (`workflow/auto-worklog`, `core/feature-index-cache`) : le hook ne fait que l'invoquer.

## Invariants

- `commit-msg` bloque un commit `feat:` tant qu'aucun fichier `<docs_root>/features/**` n'est touché.
- `pre-commit` **ne bloque jamais** : toute erreur interne (index absent, jq manquant, pattern non résolu) se résout en exit 0 silencieux.
- `pre-commit` est idempotent : si le hook Claude `Stop` a déjà auto-progressé dans le tour, `.session-edits.flushed` est vide ou les phases sont déjà basculées → no-op.
- Le matching stagé ↔ `touches:` partage exactement la sémantique des hooks Claude (même `_lib.sh`), sans logique `jq startswith/endswith` dupliquée.
- La langue du message est imposée par `commit_language` (fr/en).

## Comportement attendu

- `commit-msg` : valide Conventional Commits ; si type `feat:`, exige qu'au moins un fichier `<docs_root>/features/**` soit touché par le commit.
- `post-checkout` : rebuild de `.feature-index.json` (le mesh peut diverger entre branches).
- `pre-commit` : **auto-progression universelle**. Dérive les features couvertes par les fichiers stagés, matérialise `.ai/.session-edits.flushed`, invoque `auto-progress.sh`, re-stage les fiches modifiées et ne re-stage un worklog que si sa feature est couverte par un fichier stagé dans ce commit (évite d'embarquer un historique hors intention issu d'un trace résiduel d'une session interrompue). Non bloquant (exit 0 garanti).
- Activation : `git config core.hooksPath .githooks && chmod +x .githooks/*` (étape 2 du `_message_after_copy`).

## Contrats

- Bloquant pour `feat:` sans feature touchée.
- Non bloquant pour `chore`, `docs`, `fix` (warning si message hors Conventional).
- `pre-commit` **ne bloque jamais** un commit : toute erreur interne (absence d'index, jq manquant, pattern non résolu) → exit 0 silencieux.
- Langue du message imposée par `commit_language` (fr/en).
- Idempotence : si le hook Claude `Stop` a déjà auto-progressé dans le même tour, `.session-edits.flushed` est vide ou les phases sont déjà basculées → `pre-commit` est un no-op.

## Décisions

- `pre-commit` retenu comme **point de convergence universel** de l'auto-progression (option B) : le hook Claude `Stop` seul ne couvrait que Claude Code, rupture de garantie pour les autres agents du multiselect `agents`. Option A (acter Claude-first) rejetée — rupture de promesse multi-agent ; option C (wrapper script) rejetée — friction d'invocation.
- `pre-commit` **non bloquant par construction** : il améliore l'état du mesh sans jamais empêcher un commit, donc une défaillance d'outillage ne casse pas le flux de l'utilisateur.
- Garde `feat:` **bloquante** mais types `chore`/`docs`/`fix` **non bloquants** (simple warning hors Conventional) : on force la doc là où elle est due sans freiner le travail courant.
- Sémantique de matching factorisée dans `_lib.sh` plutôt que dupliquée : une seule source de vérité partagée avec les hooks Claude évite les divergences.

## Validation

- Smoke-test : un commit `feat:` sans fiche `features/**` stagée doit être rejeté par `commit-msg` ; avec fiche stagée, il passe.
- Smoke-test `pre-commit` : des fichiers stagés couvrant une feature en phase `spec` déclenchent la bascule `spec→implement` au `git commit`, fiche ET worklog re-stagés. Test unitaire : le worklog d'une feature touchée par un fichier stagé dans le commit est re-stagé ; le worklog d'une trace résiduelle (feature non touchée par ce commit) ne l'est pas.
- Non-blocage `pre-commit` : un environnement sans `jq` ou sans `.feature-index.json` doit aboutir à exit 0 sans bloquer le commit.
- Idempotence : un second `git commit` immédiat (phases déjà basculées) est un no-op.

Preuve de clôture 2026-07-03 :

- Relecture `tests/smoke-test.sh` : bloc `[18/28] auto-progress : pre-commit bascule spec -> implement + snapshot history` couvre le resume hint.
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/git-hooks` PASS.
- `bash .ai/scripts/check-features.sh --no-write` PASS.
- `bash .ai/scripts/check-feature-freshness.sh --worktree --strict` PASS.
- `bash tests/smoke-test.sh` PASS.

## Cross-refs

- Côté CI : `ci-guard` rejoue `check-features.sh` même si le hook local a été contourné (`--no-verify`).
- `pre-commit` est le **point de convergence universel** de l'auto-progression : garantit parité Claude / Codex / Cursor / Gemini / Copilot / humain CLI. Le hook Claude `Stop` (`auto-progress.sh` décrit dans `workflow/conversational-skills`) reste comme bonus de latence pour les utilisateurs Claude (bascule visible avant commit).
- Le matching des fichiers stagés contre `touches:` passe par `_lib.sh` pour partager exactement la même sémantique que les hooks Claude.

## Historique / décisions

- Heuristique d'extraction du message commit (`-m "..."`, heredoc) : si format atypique, validation passe silencieusement. Limitation tracée dans PROJECT_STATE.md.
- **2026-04-24** — Réouverture (phase=implement) : ajout du hook `pre-commit` pour parité agent-agnostic. Décision prise dans le cadre de `workflow/conversational-skills` v3 (auto-progression invisible) : le hook Claude `Stop` seul ne couvrait que Claude Code, rupture de garantie pour les autres agents du multiselect `agents` copier. Option B retenue (git pre-commit = point de convergence universel) après comparaison avec option A (acter Claude-first — rejetée, rupture de promesse multi-agent) et option C (wrapper script — rejetée, friction d'invocation).
- **2026-04-24** — Refactor : `pre-commit` source `_lib.sh` et utilise `features_matching_path`, au lieu de dupliquer une logique `jq startswith/endswith`.
- 2026-05-03 : freshness documentaire rafraîchie après dogfood ; les contrats `commit-msg`, `post-checkout` et `pre-commit` restent inchangés.
- **2026-06-28** — **dogfooding de l'enforcement** (Phase 0 / A2 du frame `2026-06-28-audit-strategique-remediation`). Le repo source avait `core.hooksPath=/dev/null` (moat désactivé chez lui) — incohérent avec la promesse « convergence universelle au commit » qu'il vend. Réactivation : `git config core.hooksPath .githooks` sur le clone mainteneur (config git locale, non versionnable). Décision : `doctor` signale déjà l'absence (warn + action explicite) ; **pas** de hard-fail en `--strict` car les clones CI n'ont jamais `core.hooksPath` défini → faux positif garanti. La garantie en CI reste portée par `quality/ci-guard` (rejoue `check-features`), pas par les hooks locaux. L'activation reste donc un geste local documenté (`_message_after_copy` étape 2 + README).
- 2026-07-03 : DONE. Le smoke couvre la bascule pre-commit `spec -> implement`, snapshot history et idempotence.
