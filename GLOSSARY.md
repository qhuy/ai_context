# Glossaire — vocabulaire ai_context

Ce glossaire définit le vocabulaire maison employé par `ai_context` lui-même
(le framework). Pour le glossaire **métier** de ton projet (tes propres termes
de domaine), voir `.ai/guardrails.md` § Glossaire métier — un concept
différent, à ne pas confondre.

## Pack A

Le socle de contexte chargé systématiquement en début de tâche par un agent :
la requête utilisateur, `.ai/index.md`, `git status --short`, et les fichiers
d'implémentation les plus proches trouvés par recherche ciblée. Défini dans
`.ai/index.md` § « Pack A — always load ». Tout le reste (rules de scope,
workflows, catalogues, worklogs) est chargé **on-demand**, seulement quand un
signal concret le justifie — c'est le mécanisme qui garde le contexte lean.

## Shim

Un fichier minimal qui redirige un agent vers la source unique de vérité au
lieu de dupliquer son contenu. Exemple : `CLAUDE.md` (7 lignes, `@AGENTS.md`)
est un shim vers `AGENTS.md`, qui est lui-même auto-suffisant
et pointe vers `.ai/index.md`. Un shim existe uniquement parce qu'un agent
donné ne lit pas encore `AGENTS.md` nativement (voir `.ai/native-context-support.tsv`
pour le registre de qui lit quoi nativement).

## Feature mesh

Le graphe de fiches Markdown sous `.docs/features/<scope>/<id>.md`
qui documentent chaque comportement livré : statut, dépendances
(`depends_on`), fichiers couverts (`touches`), progression (`progress`). Le
mesh permet à un script ou un agent de répondre à « quel contexte charger pour
ce fichier ? », « quelles features sont impactées par ce diff ? », « qu'est-ce
qui est bloqué ou à reprendre ? ». Détaillé dans `README_AI_CONTEXT.md` §
Feature mesh (systématique).

## `touches:` / `touches_shared:`

Deux champs frontmatter d'une fiche feature qui listent les fichiers qu'elle
couvre.

- `touches:` — couverture directe et **bloquante** : si un de ces fichiers
  change sans que la fiche/worklog soit aussi mise à jour, le gate de
  fraîcheur (`check-feature-freshness.sh --staged --strict`) refuse le commit.
- `touches_shared:` — couverture **non bloquante**, pour les surfaces
  transverses (ex. `README.md`, `CHANGELOG.md`) que beaucoup de features
  touchent en même temps : visible en review (`pr-report`, `review-delta`)
  mais n'entre pas dans le calcul de fraîcheur, pour éviter qu'un glob trop
  large ne déclenche du bruit sur chaque commit.

## Freshness (fraîcheur documentaire)

La garantie que le code et sa documentation de fiche restent synchronisés.
Vérifiée par `check-feature-freshness.sh`, appelée automatiquement au commit
(`check-commit-features.sh`, hook `commit-msg`) et en fin de tour Claude (hook
`Stop` → `stop-doc-gate.sh`). Le mode `--staged` vérifie le prochain commit ;
`--worktree` vérifie l'état courant sans commit.

## HANDOFF

Un bloc structuré (`from_scope`, `to_scope`, `status`, `files_touched`,
`pending`, `risks`) qui documente un changement de scope primaire en cours de
tâche. Produit et soumis à confirmation utilisateur **avant** toute édition
hors du scope de départ. Règle : un scope primaire par tâche ; cross-scope
exige ce HANDOFF explicite (`.ai/rules/workflow.md`).

## Frame

Un artefact durable de cadrage produit par le skill `aic-frame`, stocké sous
`.docs/frames/<YYYY-MM-DD>-<slug>.md`. Utilisé pour les décisions
structurantes qui doivent survivre à la conversation courante (ex. un audit
stratégique, une migration majeure) — contrairement à un cadrage ponctuel qui
reste conversationnel. Un frame a un `frame_id`, un `status`, un `next_hint`
exploitable en reprise. À distinguer du **pilot** (`.docs/pilots/`),
qui suit un ensemble de constats/décisions plutôt qu'une intention unique —
`aic-frame` débraye vers `aic-pilot` quand la demande est un audit ou un
paquet de sujets.

## Overlay projet

Le dossier `.ai/project/<scope>/index.md`, réservé à ton projet et jamais
écrasé par `copier update` (`_skip_if_exists` dans `copier.yml`). Il
enregistre les conventions tribales propres au projet (structure de dossiers,
règles locales) qu'aucun scan de code ne peut inférer. Peuplé par le skill
`aic-onboard`. Voir `.ai/OWNERSHIP.md` pour la séparation exacte
template-owned / project-owned.

## OKF (Open Knowledge Format)

Un profil de frontmatter optionnel qui aligne les fiches feature sur un
format de concept générique (`type: feature | contract | workflow |
reference`), pour rendre le mesh consommable par des outils externes au-delà
d'`ai_context`. Introduit en profil « strict Phase 0 » : `type` est optionnel
et son absence ne fait qu'avertir (`check-features.sh`), jamais échouer — le
futur enforcement (vN+1) le rendra requis. Voir `MIGRATION.md` § Profil strict
OKF.

## Dogfood(ing)

Le fait que le repo mainteneur d'`ai_context` (`gh:qhuy/ai_context`) utilise
son propre système sur lui-même : chez lui, `.ai/`, `.claude/`,
`.docs/features/` à la racine ne sont pas de la documentation à propos de
l'outil, ce sont le runtime réel en action. Ce repo mainteneur n'a pas de
`.copier-answers.yml` et ne fait jamais `copier update` sur lui-même. Ce terme
ne concerne pas ton projet — il concerne uniquement le développement d'`ai_context`
lui-même.

## Mots apparentés (renvoi rapide)

- **`aic` / skills `aic-*`** : la surface utilisateur canonique (voir
  README_AI_CONTEXT.md § Workflow quotidien) — dix intentions (`frame`,
  `pilot`, `status`, `diagnose`, `document-feature`, `review`, `ship`,
  `dev-plan`, `onboard`) plus l'override conversationnel `aic`.
- **Workflow** (`.ai/workflows/*.md`) : une procédure interne partagée par
  Claude et Codex, jamais exposée directement à l'utilisateur — les skills
  `aic-*` la suivent en interne.
- **Pilot** (`.docs/pilots/*.md`) : le registre durable produit par
  `aic-pilot` pour un audit ou un suivi transverse de plusieurs constats — pas
  une feature, jamais une fiche `.docs/features/`.
