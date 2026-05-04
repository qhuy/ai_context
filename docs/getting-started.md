# Getting Started

## Prérequis

- Python 3.9+ (requis par copier)
- `copier` ≥ 9.x : `pip install --user copier` ou `brew install copier`
- `jq` (pour le hook Claude Code) : `brew install jq` sur macOS, `apt install jq` sur Linux
- `yq` v4 (recommandé) : <https://github.com/mikefarah/yq>

## Plateformes supportées

| Plateforme | Statut | Notes |
|---|---|---|
| Linux (Ubuntu, Debian, Arch...) | ✅ Supporté | CI matrix `ubuntu-latest` |
| macOS | ✅ Supporté | CI matrix `macos-latest` |
| Windows + WSL2 | ✅ Supporté (best-effort) | Recommandé pour les devs Windows ; comportement identique à Linux |
| Windows + Git Bash | ⚠️ Best-effort | Marche en pratique (mkdir-lock, mktemp, find -print0 sont portables), pas de CI dédiée. Installer `jq`/`yq` via Scoop ou Chocolatey |
| Windows + PowerShell pur | ❌ Non supporté | Les scripts `.ai/scripts/*.sh` et les git hooks sont en bash |

Sous Windows + Git Bash :

```powershell
# Scoop (recommandé)
scoop install jq yq

# Ou Chocolatey
choco install jq yq
```

Puis ouvrir Git Bash dans le projet et lancer les commandes habituelles.

## Scaffold

```bash
copier copy gh:qhuy/ai_context ./mon-projet
cd mon-projet
bash .ai/scripts/check-shims.sh      # → ✅ PASS attendu
bash .ai/scripts/check-features.sh   # → ⚠️ aucune feature (normal au départ)
bash .ai/scripts/check-feature-docs.sh # → ⚠️ aucune feature (normal au départ)
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

Ça génère un projet dans `/tmp/ai-context-smoke-*` et valide check-shims, pre-turn-reminder, check-features, check-feature-docs et check-commit-features.
