# Git hooks — ai_context

Hooks locaux versionnés. À activer **une fois** par clone :

```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```

## Hooks inclus

- `commit-msg` → appelle `.ai/scripts/check-commit-features.sh` :
  - Valide Conventional Commits (feat/fix/refactor/chore/test/docs/style/perf/ci/build/revert)
  - Bloque `feat:` si aucun fichier `.docs/features/**/*.md` n'est touché
