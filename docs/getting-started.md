# Getting Started

## Prérequis

- Python 3.9+ (requis par copier)
- `copier` ≥ 9.x : `pip install --user copier` ou `brew install copier`
- `jq` (pour le hook Claude Code) : `brew install jq` sur macOS

## Scaffold

```bash
copier copy gh:qhuy/ai_context ./mon-projet
cd mon-projet
bash .ai/scripts/check-shims.sh    # → ✅ PASS attendu
```

## Après scaffold

1. **Lire [`AGENTS.md`](../template/AGENTS.md.jinja) généré** à la racine du projet.
2. **Enrichir `.ai/rules/<scope>.md`** avec les règles propres au projet (le template donne un squelette).
3. **Vérifier les shims** : `bash .ai/scripts/check-shims.sh`
4. **Activer le hook Claude** : ouvrir Claude Code, commande `/hooks`, valider.

## Test en local du template lui-même

Depuis le repo `ai_context` :

```bash
bash tests/smoke-test.sh
```

Ça génère un projet dans `/tmp/ai-context-smoke-*` et valide que tout passe.
