# MIGRATION — projet existant → template `ai_context`

Guide pour adopter le template sur un projet déjà mature (code, docs, éventuel `CLAUDE.md` custom). L'objectif : introduire le feature mesh et les hooks **progressivement**, sans bloquer l'équipe.

---

## Prérequis

- `jq` installé (obligatoire). `yq` v4 recommandé.
  - macOS : `brew install jq yq`
  - Linux : `apt install jq` + `yq` depuis https://github.com/mikefarah/yq
- `copier` installé : `pip install --user copier`
- Une branche dédiée : `git checkout -b chore/adopt-ai-context`

---

## Étape 1 — Preview en dry-run

Scaffold dans un dossier temporaire pour voir ce que produit le template **sans toucher au projet**.

```bash
copier copy --trust gh:qhuy/ai_context /tmp/ai-ctx-preview
diff -r /tmp/ai-ctx-preview . | less
```

Identifie les fichiers qui **existent déjà** chez toi (`CLAUDE.md`, `AGENTS.md`, `.docs/`, `.github/workflows/`). Ce sont les points de conflit à traiter en étape 2.

---

## Étape 2 — Scaffold en place

```bash
copier copy --trust gh:qhuy/ai_context .
```

Copier demande pour chaque fichier existant : **skip / overwrite / merge**.

**Règle de décision** :

| Fichier | Action |
|---|---|
| `.ai/scripts/*` | **overwrite** (scripts = source template, pas de custom local) |
| `.ai/rules/<scope>.md` | **skip** si tu as du contenu métier ; sinon overwrite |
| `.ai/index.md`, `.ai/reminder.md` | **skip** si customisé ; sinon overwrite |
| `CLAUDE.md` / `AGENTS.md` | **merge** : garde tes instructions custom, ajoute le pointeur `.ai/index.md` du shim |
| `.claude/settings.json` | **merge** manuellement les hooks (voir étape 4) |
| `.githooks/*` | **overwrite** |
| `.github/workflows/ai-context-check.yml` | **skip** si tu as déjà une CI AI ; sinon overwrite |
| `.copier-answers.yml` | **overwrite** (nécessaire pour `copier update` futur) |

Vérifie immédiatement :
```bash
bash .ai/scripts/check-shims.sh
bash .ai/scripts/check-ai-references.sh
```

---

## Étape 3 — Bootstrap du feature mesh

Le template impose `{{ docs_root }}/features/<scope>/<id>.md` avec frontmatter. Sur projet mature, tu pars de zéro. Deux stratégies :

### 3a. Big bang (recommandé si < 200 fichiers source)

Une demi-journée, tu écris un stub par domaine fonctionnel. Vise 20-50 features — pas une par fichier.

Pour chaque feature, le stub minimal :
```markdown
---
id: auth-session
scope: back
title: Session JWT + refresh
status: active
depends_on: []
touches:
  - src/auth/**
  - src/middleware/auth.ts
---

## Contexte
(À remplir au fil des modifs.)
```

Puis :
```bash
bash .ai/scripts/build-feature-index.sh --write
bash .ai/scripts/check-features.sh   # valide scope + depends_on + touches
```

### 3b. Rolling (recommandé si projet legacy volumineux)

Tu ne documentes **que ce que tu touches maintenant**. Le reste reste orphelin.
- Nouvelle feature / modif → crée ou édite le `.md` correspondant.
- Laisse `check-feature-coverage.sh --warn` (défaut) tourner pour te lister les orphelins à couvrir plus tard.
- **Ne passe pas `--strict`** tant que la couverture n'est pas raisonnable (> 60-70%).

---

## Étape 4 — Activation progressive des hooks

**Ne pas tout activer en une fois.** Ordre recommandé (du moins intrusif au plus bloquant) :

### 4.1 — Git hooks commit-msg (1er jour)
```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```
Impact : **Conventional Commits** imposé. Message mal formé → commit rejeté. `feat:` sans feature touchée → rejeté aussi.

Laisse tourner une semaine pour que l'équipe s'habitue.

### 4.2 — Hook Claude `UserPromptSubmit` (contexte injecté)
Dans Claude Code, `/hooks` → activer `UserPromptSubmit` → `bash .ai/scripts/pre-turn-reminder.sh --format=json`.

**Zéro risque** : ajoute juste du contexte à chaque tour. Mesure le coût :
```bash
bash .ai/scripts/measure-context-size.sh
```
Si trop gros, active `AI_CONTEXT_SHOW_ALL_STATUS=0` (défaut) et passe les features stables en `status: done`.

### 4.3 — Hook Claude `PreToolUse` Write/Edit/MultiEdit
Même démarche : déjà configuré dans `.claude/settings.json.jinja`. Injecte les features pertinentes avant toute écriture.

### 4.4 — CI guard (en dernier)
Le workflow `.github/workflows/ai-context-check.yml` lance `check-shims` + `check-features` + `check-ai-references`. **Active-le seulement quand les 3 passent en local.**

Optionnel, plus tard :
```bash
bash .ai/scripts/check-feature-coverage.sh --strict   # fail si orphelins
```
À n'ajouter en CI que quand la couverture est ≥ 80%.

---

## Pièges fréquents

| Symptôme | Cause | Fix |
|---|---|---|
| `check-features.sh` fail : "touches morte" | Glob dans `touches:` ne résout aucun fichier | Corrige le glob ou supprime l'entrée |
| Reminder vide | Toutes les features sont `done/deprecated/archived` | `AI_CONTEXT_SHOW_ALL_STATUS=1` ou repasse une feature en `active` |
| Hook `PreToolUse` timeout | Trop de features + pas de cache | `bash .ai/scripts/build-feature-index.sh --write` puis rejoue |
| `copier update` écrase un fichier customisé | `.copier-answers.yml` absent ou corrompu | Restaure depuis git ou re-scaffold en skip |
| CI rouge sur `check-feature-coverage --strict` | Legacy non documenté | Passe en `--warn` jusqu'à couverture suffisante |

---

## Rollback

Tout est local et versionné. Pour annuler :
```bash
git checkout main -- .   # jette la branche de migration
git config --unset core.hooksPath   # désactive les git hooks
```
Dans Claude Code : `/hooks` → désactive les entrées ajoutées.

---

## Après la migration

- `copier update` régulier pour bénéficier des versions futures du template.
- Surveille `measure-context-size.sh` en CI (ou en dev) pour éviter la dérive tokens.
- Relis `CHANGELOG.md` à chaque `copier update` — les breaking notes y sont explicites.

## Utiliser les skills `/aic-*` (v0.7+)

Une fois le mesh bootstrappé, utilise les skills Claude pour encadrer les gestes récurrents :

| Skill | Quand |
|---|---|
| `/aic-feature-new` | Avant tout `feat:` — crée fiche + worklog init |
| `/aic-feature-resume` | Début de session — scanne EN COURS / BLOQUÉES / STALE, charge le contexte |
| `/aic-feature-update` | À chaque pause, blocker, ou switch de contexte (worklog append-only) |
| `/aic-feature-handoff` | Quand le travail bascule de scope ou de session |
| `/aic-quality-gate` | Avant commit `feat:` ou PR — verdict go/no-go factuel |
| `/aic-feature-done` | Clôture : evidence + status done + commit suggéré |

La règle d'or : **toujours** `/aic-feature-update` avant de quitter une session. Le coût est minime, la reprise via `/aic-feature-resume` devient déterministe au lieu de narrative.
