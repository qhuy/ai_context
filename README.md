# ai_context

Template [copier](https://copier.readthedocs.io/) pour industrialiser le setup AI context (shims multi-agents, hooks runtime, quality gate, garde-fous CI) dans n'importe quel projet.

## Pourquoi

Chaque nouveau projet nécessite aujourd'hui un setup manuel (shims CLAUDE/AGENTS/GEMINI, hook Claude, reminder, scripts de garde-fou). Lent, oublis fréquents, écarts entre projets. Ce template industrialise tout ça.

## Installation prérequise (une fois)

```bash
pip install --user copier   # ou : brew install copier / pipx install copier
copier --version            # ≥ 9.x attendu
```

## Utilisation

### Scaffold un nouveau projet

```bash
copier copy gh:qhuy/ai_context ./mon-nouveau-projet
```

Copier pose 6 questions (nom, profil de scopes, langue commits, docs root, agents activés, CI).

### Mettre à jour un projet existant

Quand le template évolue :

```bash
cd mon-projet
copier update
```

Les réponses précédentes sont relues depuis `.copier-answers.yml`. Un diff t'est proposé — tu contrôles ce qui est appliqué.

## Profils de scope

| Profil | Scopes générés |
|---|---|
| `minimal` | core, quality, workflow |
| `backend` | core, quality, workflow, back, architecture, security, handoff |
| `fullstack` | backend + front |
| `custom` | minimal (tu ajoutes tes scopes à la main) |

## Ce que tu obtiens

Voir [`docs/variables.md`](docs/variables.md) pour la référence complète des questions.
Voir [`docs/getting-started.md`](docs/getting-started.md) pour un tour complet.
Voir [`docs/upgrading.md`](docs/upgrading.md) pour les updates.

## Contribuer

Ce template est versionné. Toute évolution non-cassante → bump minor. Toute refonte → bump major (les consommateurs devront résoudre le diff de `copier update`).

Voir [`CHANGELOG.md`](CHANGELOG.md).

## Licence

MIT — voir [`LICENSE`](LICENSE).
