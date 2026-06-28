# Worklog — workflow/git-hooks


## 2026-04-24 11:57 — auto
- Fichiers modifiés :
  - template/.githooks/README.md.jinja
  - template/.githooks/pre-commit.jinja
## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `template/.ai/scripts/check-commit-features.sh.jinja`.
- Impact : le hook commit-msg rendu par Copier herite de la correction heredoc du guard commit.
- Validation : `bash tests/unit/test-targeted-regressions.sh` PASS.

## 2026-06-28 — dogfooding de l'enforcement (Phase 0 / A2)
- Réactivation du moat sur le clone source : `git config core.hooksPath .githooks` (était `/dev/null`). commit-msg + pre-commit + post-checkout désormais actifs chez le mainteneur.
- Décision tracée : `doctor` warn (pas hard-fail) car les clones CI n'ont pas `core.hooksPath` → faux positif ; garantie CI portée par `ci-guard`.
- Evidence : `doctor` « git hooks path configured (.githooks) » + commit-msg rejette un `feat:` sans fiche.
- Fichiers : .docs/features/workflow/git-hooks.md (+ worklog)
