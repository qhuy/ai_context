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
- `post-checkout` → rebuild `.ai/.feature-index.json` après un switch de branche.
- `pre-commit` → auto-progression universelle (agent-agnostic) :
  - Dérive les features touchées depuis les fichiers stagés.
  - Invoque `.ai/scripts/auto-progress.sh` (même logique que le hook Claude `Stop`).
  - Re-stage les fiches/worklogs modifiés pour que la bascule soit dans le commit.
  - Non bloquant (best-effort : toute erreur → exit 0).
  - Garantit que Codex, Cursor, Gemini, Copilot ou un humain en CLI bénéficient
    du même automatisme que Claude Code.
