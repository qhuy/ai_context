# RELEASE — ai_context

Checklist pour préparer une release du template. À suivre intégralement avant de poser un tag (et de l'utiliser via `copier copy --vcs-ref=vX.Y.Z`).

## Pré-requis

- Working tree propre (`git status` vide).
- Branche à jour avec `main`.
- Toutes les PRs prévues pour la version sont mergées.
- `bash tests/smoke-test.sh` PASS en local sur ta machine.

## Checklist version

### 1. Tests

```bash
bash tests/smoke-test.sh
```

Toutes les étapes ✅. Si une est rouge, **stop** : ne pas tagger.

### 2. Rendus Copier critiques

Tester les profils suivants — chacun doit rendre sans erreur Jinja/YAML :

```bash
copier copy --defaults --trust --vcs-ref=HEAD --data project_name=smoke-standard . /tmp/ai-context-standard
copier copy --defaults --trust --vcs-ref=HEAD --data project_name=smoke-lite --data adoption_mode=lite . /tmp/ai-context-lite
copier copy --defaults --trust --vcs-ref=HEAD --data project_name=smoke-strict --data adoption_mode=strict . /tmp/ai-context-strict
copier copy --defaults --trust --vcs-ref=HEAD --data project_name=smoke-docs --data docs_root=docs . /tmp/ai-context-docs
copier copy --defaults --trust --vcs-ref=HEAD --data project_name=smoke-en --data commit_language=en . /tmp/ai-context-en
copier copy --defaults --trust --vcs-ref=HEAD --data project_name=smoke-codex --data agents=codex . /tmp/ai-context-codex
copier copy --defaults --trust --vcs-ref=HEAD --data project_name=smoke-fullstack \
  --data scope_profile=fullstack --data tech_profile=fullstack-dotnet-react . /tmp/ai-context-fullstack
```

Vérifier pour chaque rendu :
- pas d'erreur Jinja / YAML
- fichiers attendus présents (`AGENTS.md`, `.ai/index.md`, `.ai/scripts/*`, `.docs/FEATURE_TEMPLATE.md`)
- fichiers exclus correctement absents (`.githooks` en `lite`, `.claude/` sans Claude, `tech-react.md` hors `react-next`, etc.)
- message post-copy cohérent avec les fichiers générés (pas d'instruction pour un fichier absent)

### 3. `copier update` sur un projet existant

Si un projet consommateur de référence est dispo :

```bash
cd <projet-consommateur>
copier update --vcs-ref=HEAD <chemin-vers-ai_context>
```

Vérifier qu'aucune surprise sur les fichiers customisés (mesh existant, rules métier).

### 4. Documentation

- `CHANGELOG.md` : `Unreleased` finalisé sous le bon numéro de version, regroupé par sections (Nouveau / Changé / Corrigé / Tests / Migration / Breaking).
- `PROJECT_STATE.md` : section « Dernière version publiée » à jour, roadmap actualisée.
- `MIGRATION.md` : si comportement utilisateur change, instructions claires.
- `README.md` : tableaux Modes d'adoption / Champs actifs `.ai/config.yml` / Variables d'env synchronisés.
- Toutes les fiches `.docs/features/**/*.md` impactées : section **Historique** mise à jour avec la date et un résumé.

### 5. Versioning

Schema [SemVer](https://semver.org/) : `vMAJOR.MINOR.PATCH`.

| Type de changement | Bump |
|---|---|
| Breaking pour `copier update` | MAJOR |
| Nouvelle option, nouveau script, nouveau hook (additif) | MINOR |
| Correction bug, doc-drift, sync template/runtime | PATCH |

### 6. Commit + tag

```bash
git add CHANGELOG.md PROJECT_STATE.md ...
git commit -m "chore(release): vX.Y.Z"
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

### 7. Sanity post-release

```bash
copier copy --trust --vcs-ref=vX.Y.Z gh:qhuy/ai_context /tmp/ai-context-released
bash /tmp/ai-context-released/.ai/scripts/check-shims.sh
bash /tmp/ai-context-released/.ai/scripts/doctor.sh
```

Si l'un échoue, créer un patch immédiat (`vX.Y.Z+1`) plutôt que rétracter le tag.

## Cas particuliers

### Breaking change (bump MAJOR)

- **Toujours** documenter dans `MIGRATION.md` une section dédiée `## vX.0.0 → vX+1.0.0`.
- Ajouter une note dans `CHANGELOG.md` avec un exemple concret de mise à jour.
- Préférer un message de dépréciation lors de la version précédente (`v(X-1).Y.Z`) qui annonce le breaking.

### Hotfix sur une release passée

Si `vX.Y.Z` a un bug critique, brancher depuis le tag :

```bash
git checkout -b hotfix/vX.Y.Z+1 vX.Y.Z
# fix + commit
git tag vX.Y.Z+1
git push origin vX.Y.Z+1
```

Puis cherry-pick / forward-port le fix sur `main`.

### Pré-release

Pour tester un changement risqué avec des early adopters :

```bash
git tag vX.Y.Z-rc.1
git push origin vX.Y.Z-rc.1
```

`copier copy --vcs-ref=vX.Y.Z-rc.1` permet de cibler la release candidate.
