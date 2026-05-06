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
