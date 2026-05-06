# ai_context

Le template qui rend Claude, Codex et les autres agents beaucoup plus fiables sur
un repo réel.

`ai_context` installe une couche de contexte versionnée dans ton projet :
instructions agents, feature mesh, worklogs, hooks, checks, skills `aic-*` et
commandes CLI. L'objectif est simple : un agent doit comprendre quoi faire, où
reprendre, quels fichiers sont liés à quelle feature, et quand il peut vraiment
dire "c'est prêt".

## Pourquoi l'utiliser

Sans structure, les agents IA dérivent vite :

- ils relisent trop de fichiers ou pas les bons ;
- ils oublient les décisions prises dans les sessions précédentes ;
- ils modifient du code sans mettre la doc feature à jour ;
- ils valident trop tôt, sans preuve ;
- chaque repo finit avec un `CLAUDE.md` ou `AGENTS.md` différent.

`ai_context` remplace cette improvisation par un protocole léger, repo-native et
testé.

| Ce que tu veux | Ce que le template installe |
|---|---|
| Une source unique de vérité pour tous les agents | `.ai/index.md` + shims `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, Copilot, Cursor |
| Reprendre une feature sans redemander l'historique | fiches `.docs/features/<scope>/<id>.md` + worklogs append-only |
| Eviter le contexte géant | Pack A lean, règles on-demand, mesure de coût tokens |
| Relier code, doc, commit et review | `touches:`, `depends_on`, checks feature, freshness staged |
| Utiliser Claude et Codex avec le même langage | surface `aic` : frame, status, diagnose, document-feature, review, ship |
| Garder un projet mature propre | hooks git, checks CI, doctor, smoke-test, migration Copier |

## Pour qui

`ai_context` est utile si tu as :

- un projet qui va durer plus que quelques prompts ;
- plusieurs features en parallèle ;
- Claude Code, Codex, Cursor, Gemini ou Copilot sur le même repo ;
- une équipe qui veut que les agents suivent les mêmes règles ;
- un besoin de traçabilité entre décisions produit, docs et code.

Ce n'est pas un outil de roadmap, ni un remplaçant de Linear/Jira/BMAD/Spec Kit.
C'est la couche locale qui permet aux agents de travailler proprement avec ces
artefacts.

## Démarrage rapide

Prérequis :

```bash
pip install --user copier
brew install jq yq
```

Scaffold :

```bash
copier copy gh:qhuy/ai_context ./mon-projet
cd mon-projet
git init
git add -A
git commit -m "chore: installer ai_context"
```

Activer les hooks git si le mode choisi les génère :

```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```

Vérifier l'installation :

```bash
bash .ai/scripts/check-shims.sh
bash .ai/scripts/check-features.sh
bash .ai/scripts/check-feature-docs.sh
bash .ai/scripts/aic.sh frame "première tâche"
```

Dans Claude Code, lance ensuite `/hooks` et active les hooks proposés si tu veux
l'injection de contexte automatique à chaque tour.

## Le workflow quotidien

La surface utilisateur canonique est `aic`.

| Besoin | Claude | Codex / terminal |
|---|---|---|
| Cadrer avant d'écrire | `/aic-frame` | `bash .ai/scripts/aic.sh frame "<objectif>"` |
| Savoir où reprendre | `/aic-status` | `bash .ai/scripts/aic.sh status` |
| Diagnostiquer un blocage | `/aic-diagnose` | `bash .ai/scripts/aic.sh diagnose "<symptôme>"` |
| Charger le contexte d'un fichier | `/aic-document-feature` | `bash .ai/scripts/aic.sh document-feature <path>` |
| Relire le delta courant | `/aic-review` | `bash .ai/scripts/aic.sh review` |
| Préparer commit / PR | `/aic-ship` | `bash .ai/scripts/aic.sh ship` |

Flux recommandé :

```text
frame -> feature doc -> implémentation -> review -> ship -> commit
```

En langage naturel, ça donne :

```text
Cadre cette feature, crée la fiche si nécessaire, implémente, teste, puis prépare le ship.
```

L'agent doit garder un scope primaire. Si le travail sort du scope, il produit un
handoff explicite au lieu de mélanger les responsabilités.

## Ce que le template génère

Selon les agents, scopes et modes choisis :

```text
mon-projet/
├── AGENTS.md / CLAUDE.md / GEMINI.md
├── .ai/
│   ├── index.md                  # entrée canonique, chargement lean
│   ├── context-ignore.md         # exclusions de contexte Codex/on-demand
│   ├── rules/<scope>.md          # règles courtes par scope
│   ├── workflows/*.md            # procédures agent-agnostic
│   ├── agent/*.md                # posture/diagnostic/style, on-demand
│   ├── scripts/*.sh              # checks, aic CLI, hooks, reports
│   └── schema/feature.schema.json
├── .agents/skills/aic-*          # skills Codex locaux si codex est sélectionné
├── .claude/skills/aic-*          # skills Claude si claude est sélectionné
├── .claude/settings.json         # hooks Claude Code
├── .githooks/                    # commit-msg, pre-commit, post-checkout
├── .github/workflows/            # CI optionnelle
└── .docs/
    ├── FEATURE_TEMPLATE.md
    └── features/<scope>/
        ├── <id>.md               # fiche feature + frontmatter
        └── <id>.worklog.md       # journal append-only
```

## Comment ça marche

```mermaid
flowchart LR
  Prompt["Prompt utilisateur"] --> Index[".ai/index.md"]
  Index --> Rules["Règles on-demand"]
  Index --> Mesh["Feature mesh"]
  Mesh --> Agent["Claude / Codex / autre agent"]
  Agent --> Edits["Edits code/docs"]
  Edits --> Worklog["Worklog + progress"]
  Edits --> Checks["Checks feature / freshness / coverage"]
  Checks --> Ship["aic ship"]
```

Le principe :

1. Les shims racine pointent vers `.ai/index.md`.
2. `.ai/index.md` charge peu de contexte au départ.
3. Les fichiers ciblés déclenchent la recherche des fiches feature liées.
4. Les worklogs gardent la mémoire entre sessions.
5. Les hooks et checks empêchent les commits incohérents.
6. `aic` sert de langage commun entre humain, Claude, Codex et terminal.

## Honnêteté runtime

Tous les agents ne reçoivent pas le même niveau d'automatisation.

| Capacité | Claude Code | Codex | Cursor | Gemini | Copilot |
|---|---|---|---|---|---|
| Shim racine vers `.ai/index.md` | Oui | Oui | Oui | Oui | Oui |
| Git hooks et checks au commit | Oui | Oui | Oui | Oui | Oui |
| Skills `aic-*` locaux | Oui | Oui, si `codex` sélectionné | Non | Non | Non |
| Injection automatique au début du tour | Oui | Non | Non | Non | Non |
| Injection feature avant édition | Oui | Manuel via `aic.sh document-feature` | Partiel via MDC scopé | Non | Non |
| Auto-worklog en fin de tour | Oui | Non | Non | Non | Non |
| Auto-progression `spec -> implement` au commit | Oui | Oui | Oui | Oui | Oui |

Conclusion pragmatique :

- Claude Code a l'expérience la plus automatisée.
- Codex a une bonne expérience via skills locaux, `.ai/index.md` et `aic.sh`.
- Les autres agents bénéficient surtout des shims, règles, hooks git et checks.

## Feature mesh

Une feature est un fichier Markdown versionné :

```yaml
---
id: auth-session
scope: back
title: Session JWT + refresh token
status: active
depends_on: []
touches:
  - src/auth/**
progress:
  phase: implement
  step: "service layer"
  blockers: []
  resume_hint: "reprendre sur src/auth/service.ts"
  updated: 2026-05-06
---
```

Ce frontmatter permet aux scripts de répondre à des questions que les agents
ratent souvent :

- quel contexte charger pour `src/auth/service.ts` ?
- quelles features sont impactées par ce diff ?
- quelles docs doivent être dans le même commit ?
- qu'est-ce qui est bloqué, stale, done ou à reprendre ?

## Modes d'adoption

| Mode | Quand l'utiliser |
|---|---|
| `lite` | Tu veux seulement les shims, `.ai/`, les scripts et les docs, sans hooks git ni CI. |
| `standard` | Recommandé. Git hooks + CI optionnelle + hooks Claude si Claude est sélectionné. |
| `strict` | Projet déjà mature. CI forcée, `doctor --strict`, coverage strict. Peut rendre un jeune repo rouge. |

## Profils disponibles

Scopes :

| Profil | Scopes générés |
|---|---|
| `minimal` | core, quality, workflow, product |
| `backend` | minimal + back, architecture, security, handoff |
| `fullstack` | backend + front |
| `custom` | minimal, puis ajout manuel |

Presets techniques :

| Profil | Ajout |
|---|---|
| `generic` | aucune règle stack spécifique |
| `dotnet-clean-cqrs` | règles .NET Clean Architecture + CQRS |
| `react-next` | règles React / Next |
| `fullstack-dotnet-react` | règles .NET + React + contrats back/front |

## Installer sur un projet existant

Ne copie pas le template directement dans un repo mature sans preview.

```bash
cd mon-projet
git checkout -b codex/install-ai-context

rm -rf /tmp/ai-context-preview
copier copy --trust gh:qhuy/ai_context /tmp/ai-context-preview \
  --data project_name=mon-projet \
  --data scope_profile=backend \
  --data docs_root=.docs

diff -qr /tmp/ai-context-preview . | less
```

Copie en priorité les scripts, hooks, quality gate et templates. Fusionne
manuellement les shims, règles locales et features existantes.

Guide complet : [MIGRATION.md](MIGRATION.md).

## Mettre à jour le template

```bash
copier update --vcs-ref=HEAD
```

Si `.copier-answers.yml` manque :

```bash
bash .ai/scripts/aic.sh repair-copier-metadata
bash .ai/scripts/aic.sh repair-copier-metadata --apply
```

Pour estimer une update sans toucher au worktree courant :

```bash
bash .ai/scripts/aic.sh template-diff
```

Guide complet : [docs/upgrading.md](docs/upgrading.md).

## Checks utiles

| Commande | Rôle |
|---|---|
| `bash .ai/scripts/check-shims.sh` | vérifie que les shims restent minces et pointent vers `.ai/index.md` |
| `bash .ai/scripts/check-features.sh` | valide frontmatter, scopes, `depends_on`, `touches` |
| `bash .ai/scripts/check-feature-docs.sh` | vérifie les sections obligatoires des fiches |
| `bash .ai/scripts/check-feature-freshness.sh --staged --strict` | bloque si code stage sans fiche/worklog stage |
| `bash .ai/scripts/check-feature-coverage.sh` | détecte les fichiers non couverts par une feature |
| `bash .ai/scripts/check-product-links.sh` | valide les initiatives `product` et leurs liens |
| `bash .ai/scripts/measure-context-size.sh` | mesure le coût du contexte injecté |
| `bash .ai/scripts/doctor.sh` | diagnostic installation |
| `bash tests/smoke-test.sh` | test end-to-end du template |

## Variables d'environnement

| Variable | Effet |
|---|---|
| `AI_CONTEXT_DEBUG=1` | logs debug des hooks |
| `AI_CONTEXT_SHOW_ALL_STATUS=1` | inclut `done`, `deprecated`, `archived` dans le reminder |
| `AI_CONTEXT_FOCUS=<scope>` | réduit l'inventaire au scope + voisins 1-hop |
| `AI_CONTEXT_DOCS_ROOT=<dir>` | override du dossier de docs métier |

## FAQ

**Faut-il documenter tout le code dès le départ ?**

Non. Tu peux adopter progressivement. `check-feature-coverage.sh --warn` liste
les orphelins. Passe en `--strict` seulement quand le mesh couvre suffisamment le
projet.

**Est-ce que ça marche sans Claude ?**

Oui, mais avec moins d'automatisation par tour. Codex et les autres agents ont
les shims, règles, git hooks, checks et scripts `aic.sh`. Claude ajoute les hooks
runtime automatiques.

**Pourquoi ne pas tout mettre dans `AGENTS.md` ou `CLAUDE.md` ?**

Parce que ces fichiers grossissent vite et deviennent chers en tokens. Ici, les
shims restent minces et `.ai/index.md` charge le reste juste-à-temps.

**Où mettre les règles spécifiques à mon projet ?**

Dans `.ai/project/index.md` et les fichiers qu'il référence. Ce dossier est
project-owned et n'est pas écrasé par `copier update`.

**Comment éviter une roadmap parallèle ?**

Le scope `product` ne remplace pas ton outil produit. Il relie initiative,
références externes, features dev, evidence et prochaine décision.

**Le template supporte-t-il les monorepos ?**

Oui. Utilise `docs_root=docs` si nécessaire et crée des scopes adaptés
(`back-api`, `back-worker`, `front-web`, etc.).

## Documentation

- [README_AI_CONTEXT.md](README_AI_CONTEXT.md) - guide généré dans les projets consommateurs
- [docs/getting-started.md](docs/getting-started.md) - démarrage détaillé
- [MIGRATION.md](MIGRATION.md) - migration brownfield
- [docs/upgrading.md](docs/upgrading.md) - updates Copier
- [docs/variables.md](docs/variables.md) - variables Copier
- [CHANGELOG.md](CHANGELOG.md) - versions et breaking changes
- [PROJECT_STATE.md](PROJECT_STATE.md) - état et roadmap mainteneur

## Contribuer

Pour modifier le template :

```bash
bash tests/smoke-test.sh
```

Règles mainteneur :

- un sous-chantier = un commit ;
- commits en français ;
- si un script existe dans `.ai/scripts/` et `template/.ai/scripts/`, modifier les deux ;
- ne pas grossir Pack A sans raison.

Voir aussi :

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [RELEASE.md](RELEASE.md)

## Licence

MIT - voir [LICENSE](LICENSE).
