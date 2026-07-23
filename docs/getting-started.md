# Getting Started

Vocabulaire utilisé ci-dessous (Pack A, shim, mesh, touches, HANDOFF, frame, OKF...) : [`GLOSSARY.md`](../GLOSSARY.md).

## Prérequis

- Python 3.9+ (requis par copier)
- `copier` ≥ 9.x : `pip install --user copier` ou `brew install copier`
- `jq` (pour les checks et hooks) : `brew install jq` sur macOS, `apt install jq` sur Linux
- `yq` v4 (recommandé, parsing YAML propre) : <https://github.com/mikefarah/yq>

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
git init && git add -A && git commit -m "chore: installer ai_context"
```

Le message affiché après le scaffold (`_message_after_copy`) résume déjà les
prochaines étapes pour le mode d'adoption choisi — cette page les détaille.

## Vérifier l'installation

```bash
bash .ai/scripts/check-shims.sh              # → ✅ PASS attendu
bash .ai/scripts/check-features.sh --no-write # → ⚠️ aucune feature (normal au départ, mesh vide)
bash .ai/scripts/doctor.sh                    # → diagnostic complet (dépendances, hooks, checks)
```

`--no-write` est important : sans lui, `check-features.sh` régénère
`.ai/.feature-index.json` sur disque. Les checks read-only (`doctor`,
`quality-gate`, la CI) consomment tous un index temporaire ou le cache
existant — préfère `--no-write` pour toute vérification qui ne doit pas
modifier le workspace.

## Après scaffold

1. **Lire `AGENTS.md`** à la racine du projet généré, puis `.ai/index.md`.
2. **Activer les git hooks** (si le mode d'adoption choisi les génère —
   absent en mode `lite`) :
   ```bash
   git config core.hooksPath .githooks
   chmod +x .githooks/*
   ```
3. **Registre de scopes projet** (optionnel, recommandé si le projet a
   plusieurs apps/couches/préoccupations) : skill `aic-onboard` (Claude/Codex)
   — peuple `.ai/project/<scope>/index.md` avec les conventions tribales que
   le scan de code ne peut pas inférer. Garder `.ai/rules/<scope>.md`
   générique par ailleurs.
4. **Cadrer la première tâche** : skill `aic-frame` (une intention précise)
   ou `aic-pilot` (un audit, plusieurs constats, un suivi transverse). En
   CLI/Codex sans hook : `bash .ai/scripts/aic.sh frame "<objectif>"`.
5. **Créer la première fiche feature** quand une vraie feature démarre :
   skill `aic-document-feature`, ou directement `.docs/FEATURE_TEMPLATE.md`
   comme squelette sous `.docs/features/<scope>/<id>.md`.
6. **Activer les hooks Claude** : dans Claude Code, commande `/hooks`, activer
   ce que tu veux (`UserPromptSubmit` reminder, `PreToolUse` contexte +
   commit guard, `PostToolUse`/`Stop` auto-worklog/auto-progress).

## Quand utiliser quoi

| Situation | Commande |
|---|---|
| Une intention précise, avant d'écrire du code | `aic-frame` |
| Un audit, plusieurs constats/bugs/décisions à ne pas oublier | `aic-pilot` |
| Cadrage déjà posé, besoin de structurer l'exécution multi-étapes | `aic-dev-plan` |
| La demande ou la tâche est floue, bloquée, contradictoire | `aic-diagnose` |
| Où en est le travail (en cours, bloqué, stale) ? | `aic-status` |
| Documenter, auditer ou clôturer une fiche feature | `aic-document-feature` |
| Relire les risques du delta courant avant review/PR | `aic-review` |
| Est-ce prêt à commit/PR ? | `aic-ship` |

Détail des dix intentions et de leur surface CLI équivalente (Codex, agents
non hookés) : `README_AI_CONTEXT.md` § Workflow quotidien.

## Test en local du template lui-même

Depuis le repo `ai_context` (mainteneur du template, pas un projet
consommateur) :

```bash
bash tests/smoke-test.sh
```

Génère plusieurs projets dans `/tmp/ai-context-*` et valide l'ensemble des
checks (shims, features, docs, freshness, hooks réels, dogfood-drift) sur
une trentaine de combinaisons de profils.
