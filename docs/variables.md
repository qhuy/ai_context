# Référence des variables du template

Les questions posées par `copier copy` et leurs effets.

| Variable | Type | Défaut | Effet |
|---|---|---|---|
| `project_name` | str | — (requis) | Nom injecté dans les shims et `.ai/index.md` |
| `project_description` | str | "" | Description 1 ligne dans l'index |
| `scope_profile` | choice | `fullstack` | Détermine la liste `scopes` (voir profils) |
| `tech_profile` | choice | `generic` | Ajoute des règles stack optionnelles (`dotnet-clean-cqrs`, `react-next`, `fullstack-dotnet-react`) |
| `commit_language` | choice | `fr` | Langue des commits imposée par les règles |
| `docs_root` | str | `.docs` | Dossier racine de la doc métier (`.docs` ou `docs`) |
| `agents` | multiselect | `[claude, codex]` | Shims / hooks générés |
| `enable_ci_guard` | bool | `true` | Ajoute `.github/workflows/ai-context-check.yml` |

## Profils `scope_profile`

| Profil | Scopes |
|---|---|
| `minimal` | core, quality, workflow |
| `backend` | core, quality, workflow, back, architecture, security, handoff |
| `fullstack` | backend + front |
| `custom` | minimal (tu ajoutes tes scopes à la main après scaffold) |

## Profils `tech_profile`

| Profil | Règles générées |
|---|---|
| `generic` | aucune règle stack spécifique |
| `dotnet-clean-cqrs` | `.ai/rules/tech-dotnet.md` |
| `react-next` | `.ai/rules/tech-react.md` |
| `fullstack-dotnet-react` | `.ai/rules/tech-dotnet.md`, `.ai/rules/tech-react.md`, `.ai/rules/stack-fullstack-dotnet-react.md` |

## Agents disponibles

| Agent | Fichiers générés |
|---|---|
| `claude` | `CLAUDE.md`, `.claude/settings.json` (hook UserPromptSubmit) |
| `codex` | `AGENTS.md` (toujours généré, canonical pour Codex) |
| `cursor` | `.cursor/rules/protocol-reminder.mdc` |
| `gemini` | `GEMINI.md` |
| `copilot` | `.github/copilot-instructions.md` |

`AGENTS.md` est toujours généré : c'est l'entrée canonique cross-agent (standard émergent).

## Fichiers toujours générés

- `AGENTS.md`
- `.ai/index.md`
- `.ai/OWNERSHIP.md`
- `.ai/reminder.md`
- `.ai/context-ignore.md`
- `.ai/quality/QUALITY_GATE.md`
- `.ai/rules/core.md`, `quality.md`, `workflow.md` (scopes minimum)
- `.ai/scripts/pre-turn-reminder.sh`, `check-shims.sh`, `check-ai-references.sh`, `check-feature-docs.sh`
- `.ai/templates/project-overlay/README.md` (exemple, pas un overlay actif)
- `README_AI_CONTEXT.md`
- `{{docs_root}}/.gitkeep`
- `.copier-answers.yml` (tracking du template appliqué ; doit être versionné pour permettre `copier update --vcs-ref=HEAD`)
