# Getting Started

## Prérequis

- Python 3.9+ (requis par copier)
- `copier` ≥ 9.x : `pip install --user copier` ou `brew install copier`
- `jq` (pour le hook Claude Code) : `brew install jq` sur macOS

## Scaffold

```bash
copier copy gh:qhuy/ai_context ./mon-projet
cd mon-projet
bash .ai/scripts/check-shims.sh      # → ✅ PASS attendu
bash .ai/scripts/check-features.sh   # → ⚠️ aucune feature (normal au départ)
```

## Après scaffold

1. **Lire [`AGENTS.md`](../template/AGENTS.md.jinja) généré** à la racine du projet.
2. **Activer les git hooks** (commit-msg pour Conventional Commits + feature mesh) :
   ```bash
   git config core.hooksPath .githooks
   chmod +x .githooks/*
   ```
3. **Enrichir `.ai/rules/<scope>.md`** avec les règles propres au projet (le template donne un squelette).
4. **Première feature** : créer `.docs/features/<scope>/<id>.md` à partir de `.docs/FEATURE_TEMPLATE.md`.
5. **Activer le hook Claude** : ouvrir Claude Code, commande `/hooks`, valider (UserPromptSubmit + PreToolUse).

## Test en local du template lui-même

Depuis le repo `ai_context` :

```bash
bash tests/smoke-test.sh
```

Ça génère un projet dans `/tmp/ai-context-smoke-*` et valide check-shims, pre-turn-reminder, check-features et check-commit-features.
