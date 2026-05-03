# AI Context Index — ai_context

> Template copier pour industrialiser le contexte des agents IA

Entrée unique pour tout agent AI. Les shims à la racine (AGENTS.md, CLAUDE.md, …) pointent ici. Ne jamais dupliquer de règles en dehors de `.ai/`.

## Séquence de chargement obligatoire (Pack A)

À lire à chaque nouvelle tâche, avant toute action :

1. Ce fichier (`.ai/index.md`)
2. `.ai/quality/QUALITY_GATE.md` — critères BLOQUANTS avant DONE
3. Couche agent behavior — à charger une fois en début de session ou pour toute tâche importante :
   - `.ai/agent/posture.md` — posture, écoute, diagnostic, prise de position
   - `.ai/agent/initiative-contract.md` — quand agir, proposer, ou demander confirmation
   - `.ai/agent/response-style.md` — réponses concrètes, persuasion saine, prochaine action
4. `.ai/guardrails.md` — non-goals + glossaire métier (si présent ; cadré via `/aic-frame`)

Puis **identifier le scope primaire** et charger :

5. `.ai/rules/<scope>.md` (Pack B, scope-dépendant)
6. **Lister** `ls .docs/features/<scope>/` — obligatoire à chaque tâche (pas conditionnel).
7. Si la tâche touche une feature existante → charger `.docs/features/<scope>/<id>.md` **et** suivre récursivement ses `depends_on`.
8. Si la tâche crée une nouvelle feature → créer le fichier depuis `.docs/FEATURE_TEMPLATE.md` AVANT tout commit.


## Scopes disponibles

| Scope | Rules | Features |
|---|---|---|
| `core` | [.ai/rules/core.md](rules/core.md) | — |
| `quality` | [.ai/rules/quality.md](rules/quality.md) | — |
| `workflow` | [.ai/rules/workflow.md](rules/workflow.md) | — |
| `product` | [.ai/rules/product.md](rules/product.md) | [`.docs/features/product/`](../.docs/features/product/) |




## Feature mesh (règle transverse, systématique)

Toute feature DOIT avoir son fichier sous `.docs/features/<scope>/<id>.md`.

- **Organisation par scope** — un front peut dépendre d'un back via `depends_on: ["back/<id>"]`, un back peut dépendre d'une security via `depends_on: ["security/<id>"]`, etc.
- **Product Traceability Loop** — les initiatives produit vivent sous `scope: product`; les features dev les relient via `product.initiative`, pas via `depends_on` sauf vraie dépendance technique. Les specs, stories ou tickets externes se relient via `external_refs`.
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
| Hook git `pre-commit` (`.githooks/pre-commit`) | `git commit` | tous (claude, codex, humain CLI) | au commit |

Les deux partagent le même script et snapshotent chaque transition dans `.ai/.progress-history.jsonl` (append-only, 50 dernières, gitignored) pour permettre `/aic undo`.

Règles inférées automatiquement (V1, conservatrice) :
- Édits couverts par `touches:` d'une feature en `phase: spec` → bascule en `phase: implement`.
- `progress.updated` bumpée à chaque édition.
- Worklog appendé avec la liste des fichiers modifiés.

Les transitions `implement → review` et `review → done` restent manuelles (via `/aic` ou `/aic-ship`) pour éviter les faux positifs.

### Skill `/aic` (override, rare)

À n'utiliser que quand l'auto-progression se trompe :
- `/aic repasse en spec` — rollback d'une bascule mal inférée
- `/aic marque ça blocked, j'attends X` — bloqueur explicite
- `/aic rouvre feature-X pour Y` — réouverture d'une fiche `done`
- `/aic force done` — clôture sans attendre inférence evidence
- `/aic undo` — annule la dernière transition auto

Interfaces Claude Code accessibles directement (intentionnelles) :
- `/aic-frame` — cadrer une tâche/feature avant implémentation : plan, spécificités métier/technique, validation
- `/aic-status` — où en est-on ? features en cours, blockers, stale, delta courant
- `/aic-diagnose` — pourquoi ça bloque ? bottleneck principal + prochaine action minimale
- `/aic-review` — quels risques dans le delta courant ? features impactées, doc, checks
- `/aic-ship` — est-ce prêt à commit/PR ? quality gate + freshness + commit proposé

Procédures internes agent-agnostic :
- Les primitives procédurales ne sont plus exposées comme skills Claude. Elles vivent sous `.ai/workflows/` pour Claude et Codex : `feature-new`, `feature-resume`, `feature-update`, `feature-handoff`, `feature-audit`, `quality-gate`, `feature-done`, `project-guardrails`.
- Les skills publics peuvent s'y référer comme procédure interne, mais l'utilisateur ne doit plus avoir à invoquer `/aic-feature-*`, `/aic-quality-gate` ou `/aic-project-guardrails`.

### Compatibilité Claude / Codex

- **Claude Code** : peut utiliser les skills intentionnels `.claude/skills/aic-*` quand ils existent.
- **Codex** : ne dépend d'aucun skill Claude. Il lit `AGENTS.md` → `.ai/index.md`, charge `.ai/agent/*`, puis applique les mêmes contrats en langage naturel.
- Pour Codex, demander en langage naturel : "cadre cette feature", "montre le status", "diagnostique le blocage", "review le delta", "prépare le ship". Codex applique les mêmes formats via `.ai/agent/*`.

## Runtime enforcement

- Hook `UserPromptSubmit` (Claude Code) → `.ai/scripts/pre-turn-reminder.sh` injecte ce rappel à chaque tour.
- Hook `PreToolUse` sur `Bash(git commit*)` → `.ai/scripts/check-commit-features.sh` bloque `feat:` sans doc feature.
- Git hook `commit-msg` (via `git config core.hooksPath .githooks`) → même check pour les commits hors Claude.
- `.ai/scripts/check-shims.sh` → à lancer localement + en CI pour prévenir la dérive.
- `.ai/scripts/check-features.sh` → valide le maillage feature (frontmatter, scope, depends_on).
- `.ai/scripts/check-ai-references.sh` → vérifie les liens markdown internes.

## Source du template

Projet scaffoldé depuis [`ai_context`](https://github.com/qhuy/ai_context). `copier update` pour remonter la dernière version.
