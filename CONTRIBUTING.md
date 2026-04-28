# CONTRIBUTING — ai_context

Merci de contribuer ! Ce projet est un template `copier` — toute évolution doit rester rétro-compatible côté consommateurs (`copier update` ne doit pas casser un projet déjà scaffoldé) et synchronisée des deux côtés (template + dogfooding).

## Installation dev

```bash
# Cloner le repo
git clone https://github.com/qhuy/ai_context.git
cd ai_context

# Activer les git hooks (Conventional Commits + auto-progression)
git config core.hooksPath .githooks
chmod +x .githooks/*

# Prérequis runtime
brew install jq yq shellcheck             # macOS
# ou : apt install jq shellcheck + yq depuis https://github.com/mikefarah/yq

# Copier (pour rendre le template)
pip install --user 'copier>=9'

# Lancer le smoke-test (28+ étapes)
bash tests/smoke-test.sh
```

## Synchronisation template ↔ runtime dogfoodé

Le repo contient **deux** copies de chaque script runtime :

| Emplacement | Rôle |
|---|---|
| `.ai/scripts/<name>.sh` | runtime dogfoodé — utilisé pour valider sur ce repo |
| `template/.ai/scripts/<name>.sh.jinja` | source du template — rendue par `copier copy` |

**Règle** : si une correction touche un script qui existe des deux côtés, applique-la des deux côtés dans le même chantier. Une divergence accidentelle est un bug.

Cas spéciaux :
- Les scripts `audit-features`, `doctor`, `migrate-features`, `pr-report`, `ai-context` n'existent pour l'instant que côté template — la synchronisation dogfoodée est une piste P1 (voir `PROJECT_STATE.md`).
- Le template peut contenir des constructs Jinja (`{{ project_name }}`, `{% raw %}${#arr[@]}{% endraw %}`) absents côté runtime. Ne supprime pas ces blocs sans comprendre ce qu'ils protègent.

## Ajouter un script runtime

1. Décide où il vit : seulement template (rare) ou des deux côtés (par défaut).
2. Sourcer `_lib.sh` au début (`require_cmd`, `path_matches_touch`, etc.).
3. Préfère les helpers existants : ne ré-implémente pas le matching `touches:`.
4. Compatibilité Bash 3.2 (macOS) — voir section dédiée.
5. Ajoute au moins une assertion dans `tests/smoke-test.sh`.
6. Documente dans le tableau « Scripts runtime » du `README.md`.
7. Si le script est utile depuis le wrapper, ajoute une route dans `template/.ai/scripts/ai-context.sh.jinja`.

## Ajouter un skill Claude

1. Crée le squelette `template/.claude/skills/<verb>/SKILL.md.jinja` + `workflow.md.jinja`.
2. Frontmatter `name: <verb>` exact (vérifié par `tests/smoke-test.sh`).
3. Distingue clairement « commande exposée » vs « skill interne » dans la table du `README.md`.
4. Si la commande modifie l'état projet, ajoute un test smoke (ex: scaffold, exécution, vérif effet).

## Compatibilité Bash 3.2 (macOS)

macOS livre Bash 3.2 par défaut. Les scripts générés **doivent** rester compatibles sauf justification :

- ❌ `mapfile` / `readarray` (Bash 4+)
- ❌ `declare -A` (associative arrays — Bash 4+)
- ❌ Substitutions GNU-only (`sed -i ''` vs `sed -i`, `date -d` vs `date -r`, etc.) sans fallback
- ❌ `${var,,}` / `${var^^}` (case modification — Bash 4+)
- ✅ `[[ ${#arr[@]} -gt 0 ]]` puis `for x in "${arr[@]}"` pour itérer en safety set -u

Le smoke-test vérifie l'absence de `mapfile` dans `pr-report.sh`. Étends-le si tu introduis un nouveau script critique.

## Conventions de commit

Conventional Commits **bloquant** via `.githooks/commit-msg`. Format :

```
<type>[(scope)][!]: <description>

<body optionnel>
```

Types : `feat`, `fix`, `refactor`, `chore`, `test`, `docs`, `style`, `perf`, `ci`, `build`, `revert`.

Règles spécifiques :
- `feat:` exige une fiche feature touchée dans le même commit (`.docs/features/<scope>/*.md`). Bloqué par `commit-msg`.
- `fix:` / `refactor:` sur du code de feature → mettre à jour la section **Historique** de la fiche.
- Commits en **français** (règle projet héritée par les scaffolds via `commit_language`).

## Anti-doc-drift (BLOQUANT)

Quand une feature change, vérifie dans le même chantier :

- `README.md` (référence utilisateur)
- `CHANGELOG.md` (`Unreleased` regroupé pour la prochaine release)
- `PROJECT_STATE.md` (état + roadmap)
- `MIGRATION.md` (si la migration utilisateur change)
- `copier.yml` (questions + `_message_after_copy`)
- `template/.claude/skills/**/*.jinja` (workflows skill alignés)
- `tests/smoke-test.sh` (au moins une assertion)
- Scripts dogfoodés **et** template si applicable

Tu as raté un fichier ? Ajoute-le ici, pour la prochaine fois.

## Release

Voir [`RELEASE.md`](RELEASE.md) pour la checklist complète. En résumé :

```bash
bash tests/smoke-test.sh
# Tester les rendus Copier sur les profils critiques (lite/strict/docs/en/codex)
# Mettre à jour CHANGELOG.md (Unreleased → vX.Y.Z)
# Mettre à jour PROJECT_STATE.md
# Tag : git tag vX.Y.Z && git push --tags
```

## Sécurité

Voir [`SECURITY.md`](SECURITY.md) pour la politique de signalement et les règles de logging des hooks (worklogs, `.progress-history.jsonl`, `.session-edits.log`).
