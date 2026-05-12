# Worklog — workflow/git-hooks


## 2026-04-24 11:57 — auto
- Fichiers modifiés :
  - template/.githooks/README.md.jinja
  - template/.githooks/pre-commit.jinja
## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `template/.ai/scripts/check-commit-features.sh.jinja`.
- Impact : le hook commit-msg rendu par Copier herite de la correction heredoc du guard commit.
- Validation : `bash tests/unit/test-targeted-regressions.sh` PASS.
