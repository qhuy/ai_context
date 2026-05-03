# AI Context — ai_context

Ce projet a été scaffoldé depuis le template [`ai_context`](https://github.com/qhuy/ai_context). Le setup cross-agent (Claude / Codex / Cursor / Gemini / Copilot) est industrialisé.

## Premier pas

1. **Lire [`AGENTS.md`](AGENTS.md)** puis **[`.ai/index.md`](.ai/index.md)**.
2. **Activer les git hooks** (une fois par clone) :
   ```bash
   git config core.hooksPath .githooks
   chmod +x .githooks/*
   ```
3. Enrichir les fichiers `.ai/rules/<scope>.md` avec les règles spécifiques à ai_context.
4. **Cadrer avant d'implémenter** (recommandé) : dans Claude Code, lancer `/aic-frame` pour produire objectif, plan, spécificités métier/technique, validation et non-goals éventuels. Peut créer `.ai/guardrails.md` si le cadrage projet le justifie.
5. Vérifier l'intégrité :
   ```bash
   bash .ai/scripts/check-shims.sh
   bash .ai/scripts/check-features.sh
   ```

## Agents activés

- claude
- codex


## Scopes

- `core` → `.ai/rules/core.md`
- `quality` → `.ai/rules/quality.md`
- `workflow` → `.ai/rules/workflow.md`




## Feature mesh (systématique)

Toute feature ajoute ou met à jour un fichier `.docs/features/<scope>/<id>.md` basé sur `.docs/FEATURE_TEMPLATE.md`.

- Organisation par scope (`back/`, `front/`, `architecture/`, `security/`).
- Cross-refs via `depends_on` (ex : une feature front liste les features back consommées).
- Enforcement : `.githooks/commit-msg` bloque tout commit `feat:` sans fichier feature.

## Mettre à jour depuis le template

Quand le template évolue sur GitHub :

```bash
copier update
```

Les réponses déjà données sont relues depuis `.copier-answers.yml`. Tu contrôles le diff appliqué.

## Runtime

- Claude Code : hooks `UserPromptSubmit` (reminder) + `PreToolUse` sur `git commit` (feature mesh guard) configurés dans `.claude/settings.json` — activer avec `/hooks` au premier démarrage.
- Git : hook `commit-msg` sous `.githooks/` (active via `git config core.hooksPath .githooks`). Bloque les `feat:` sans feature doc, même hors Claude.
- Contenu du reminder : `.ai/reminder.md` (éditable librement).

## Checks

- `bash .ai/scripts/check-shims.sh` — garde-fou structure shims.
- `bash .ai/scripts/check-features.sh` — maillage feature (frontmatter + scope + depends_on).
- `bash .ai/scripts/check-ai-references.sh` — vérifie les liens markdown internes.
- `bash .ai/scripts/check-commit-features.sh` — Conventional Commits + feat: touche features/.
