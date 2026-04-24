# AI Context Index — ai_context

> Template copier pour industrialiser le contexte des agents IA

Entrée unique pour tout agent AI. Les shims à la racine (AGENTS.md, CLAUDE.md, …) pointent ici. Ne jamais dupliquer de règles en dehors de `.ai/`.

## Séquence de chargement obligatoire (Pack A)

À lire à chaque nouvelle tâche, avant toute action :

1. Ce fichier (`.ai/index.md`)
2. `.ai/quality/QUALITY_GATE.md` — critères BLOQUANTS avant DONE

Puis **identifier le scope primaire** et charger :

3. `.ai/rules/<scope>.md` (Pack B, scope-dépendant)
4. **Lister** `ls .docs/features/<scope>/` — obligatoire à chaque tâche (pas conditionnel).
5. Si la tâche touche une feature existante → charger `.docs/features/<scope>/<id>.md` **et** suivre récursivement ses `depends_on`.
6. Si la tâche crée une nouvelle feature → créer le fichier depuis `.docs/FEATURE_TEMPLATE.md` AVANT tout commit.

## Scopes disponibles

| Scope | Rules | Features |
|---|---|---|
| `core` | [.ai/rules/core.md](rules/core.md) | — |
| `quality` | [.ai/rules/quality.md](rules/quality.md) | — |
| `workflow` | [.ai/rules/workflow.md](rules/workflow.md) | — |


## Feature mesh (règle transverse, systématique)

Toute feature DOIT avoir son fichier sous `.docs/features/<scope>/<id>.md`.

- **Organisation par scope** — un front peut dépendre d'un back via `depends_on: ["back/<id>"]`, un back peut dépendre d'une security via `depends_on: ["security/<id>"]`, etc.
- **Frontmatter obligatoire** : `id`, `scope`, `title`, `status`, `depends_on`, `touches`. Squelette dans `.docs/FEATURE_TEMPLATE.md`.
- **Enforcement** : `.githooks/commit-msg` bloque tout `feat:` qui ne touche aucun fichier `.docs/features/`. `.ai/scripts/check-features.sh` valide le maillage en CI.

## Règles transverses

- **Un scope par tour** — si une tâche traverse plusieurs scopes, STOP + émettre un HANDOFF + attendre confirmation.
- **Pas de pré-chargement** — charger uniquement ce que la tâche nécessite. Pas `grep -r`.
- **Pas de full diffs par défaut** — présenter les changements ciblés.
- **Conventional Commits BLOQUANTS** — voir `.ai/quality/QUALITY_GATE.md` section Commits.
- **Commits en français** (imposé par règles projet).

## Auto-progression

**Par défaut : zéro skill à invoquer.** L'utilisateur prompte en langage naturel, l'agent code/teste/commit, les transitions de phase feature sont appliquées automatiquement par deux canaux convergents :

| Canal | Déclenché par | Agents bénéficiaires | Latence |
|---|---|---|---|
| Hook Claude `Stop` (`auto-progress.sh`) | fin de tour Claude Code | Claude | immédiat (avant commit) |
| Hook git `pre-commit` (`.githooks/pre-commit`) | `git commit` | tous (claude, codex, cursor, gemini, copilot, humain CLI) | au commit |

Les deux partagent le même script et snapshotent chaque transition dans `.ai/.progress-history.jsonl` (append-only, 50 dernières, gitignored) pour permettre `/aic undo`.

Règles inférées automatiquement (V1, conservatrice) :
- Édits couverts par `touches:` d'une feature en `phase: spec` → bascule en `phase: implement`.
- `progress.updated` bumpée à chaque édition.
- Worklog appendé avec la liste des fichiers modifiés.

Les transitions `implement → review` et `review → done` restent manuelles pour éviter les faux positifs.

### Skill `/aic` (override, rare)

À n'utiliser que quand l'auto-progression se trompe :
- `/aic repasse en spec`, `/aic marque blocked`, `/aic rouvre feature-X`, `/aic force done`, `/aic undo`.

Skills accessibles directement (lecture/CI) :
- `/aic-feature-resume` — buckets EN COURS / BLOQUÉES / STALE / À FAIRE
- `/aic-quality-gate` — check go/no-go complet

Les autres `/aic-feature-{new,update,handoff,done}` sont **internes** (invoqués par les hooks et par `/aic`).

## Runtime enforcement

- Hook `UserPromptSubmit` (Claude Code) → `.ai/scripts/pre-turn-reminder.sh` injecte ce rappel à chaque tour.
- Hook `PreToolUse` sur `Bash(git commit*)` → `.ai/scripts/check-commit-features.sh` bloque `feat:` sans doc feature.
- Git hook `commit-msg` (via `git config core.hooksPath .githooks`) → même check pour les commits hors Claude.
- `.ai/scripts/check-shims.sh` → à lancer localement + en CI pour prévenir la dérive.
- `.ai/scripts/check-features.sh` → valide le maillage feature (frontmatter, scope, depends_on).
- `.ai/scripts/check-ai-references.sh` → vérifie les liens markdown internes.

## Source du template

Projet scaffoldé depuis [`ai_context`](https://github.com/qhuy/ai_context). `copier update` pour remonter la dernière version.
