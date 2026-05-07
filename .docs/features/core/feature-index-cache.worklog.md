# Worklog — core/feature-index-cache


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 — freshness
- Impact direct : ajout de `collect_uncommitted_paths` dans `.ai/scripts/_lib.sh` (et template) pour exposer la liste des paths uncommitted via `git status --short --untracked-files=all`. Réutilisable au-delà de `review-delta.sh` (futurs callers checks/CI/aic).
- Aucun changement sur la sémantique de l'index ni sur les helpers de matching. `check-features` PASS.

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 — freshness
- Impact direct : 3 nouvelles fonctions dans `.ai/scripts/_lib.sh` (et template) :
  `_glob_pattern_supported`, `_glob_to_regex`, `features_matching_path_ranked`,
  `_score_touch_pattern`. Refactor `path_matches_touch` (regex path-aware).
- Compat ascendante : `features_matching_path` à 3 colonnes inchangée.
- Validation : check-features PASS, 28 tests path-matches PASS, 21 tests multi-level PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 01:16 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 — freshness
- Impact direct : nouveau helper `is_structural_feature_edit` ajouté dans `.ai/scripts/_lib.sh` (et template). Filtre metadata/noise pour distinguer édits structurels des édits documentaires (livraison Phase 2 #4).
- Aucun changement sur la sémantique de l'index ni sur les helpers de matching existants.
- Validation : 22 cas test-auto-progress-filter PASS.
