---
id: agents-md-native-collapse-path
scope: core
title: Chemin de collapse — AGENTS.md auto-suffisant, indirection .ai/index.md optionnelle
status: done
type: feature
description: "Préparer la dégradation où AGENTS.md (lu nativement par 30+ agents) porte assez pour que l'indirection .ai/index.md devienne OPTIONNELLE — sans la retirer ni violer l'invariant '.ai/ source unique'. Hedge contre la convergence écosystème (#34235)."
depends_on:
  - core/agents-md-shim-canonical
  - core/aic-surface-canonical
touches:
  - .docs/features/core/agents-md-native-collapse-path.md
  - .docs/features/core/agents-md-native-collapse-path.worklog.md
  - .ai/native-context-support.tsv
  - template/.ai/native-context-support.tsv
  - .ai/scripts/check-agent-native-context.sh
  - template/.ai/scripts/check-agent-native-context.sh.jinja
  - tests/unit/test-agents-md-self-sufficient.sh
  - tests/unit/test-agent-native-context.sh
touches_shared:
  - AGENTS.md
  - CLAUDE.md
  - template/AGENTS.md.jinja
  - template/CLAUDE.md.jinja
  - .ai/index.md
  - .ai/scripts/check-shims.sh
  - template/.ai/scripts/check-shims.sh.jinja
  - MIGRATION.md
  - docs/upgrading.md
  - CHANGELOG.md
product: {}
external_refs:
  pilot: ".docs/pilots/2026-06-30-ze-solution.md"
  github: "https://github.com/anthropics/claude-code/issues/34235"
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: done
  step: "kill_criterion #34235 matérialisé par registre + check require-confirmed ; statut Claude pending, CLAUDE.md conservé"
  blockers: []
  resume_hint: "surveiller .ai/native-context-support.tsv ; ne rendre CLAUDE.md optionnel que si check-agent-native-context.sh --require-confirmed claude passe."
  updated: 2026-07-03
---

# Chemin de collapse — AGENTS.md auto-suffisant, indirection .ai/index.md optionnelle

## Résumé

L'écosystème mi-2026 lit `AGENTS.md` nativement (30+ agents). L'architecture
ai_context route tout via shims → `.ai/index.md` → règles/mesh. Les *shims*
redondants sont déjà traités (`agents-md-shim-canonical`) ; **l'indirection
`.ai/index.md` elle-même** ne l'est pas. Cette feature prépare le **chemin de
collapse** : rendre `AGENTS.md` assez auto-suffisant pour que l'indirection
devienne **optionnelle** si la lecture native se confirme — **sans la retirer**
aujourd'hui et **sans violer** l'invariant « `.ai/` source unique de contenu ».
C'est une assurance (hedge), pas un pivot.

## Objectif

Éviter que l'indirection `.ai/index.md` devienne de la dette nette si/quand les
agents lisent `AGENTS.md` nativement et de façon fiable. On veut pouvoir
*dégrader* proprement (indirection optionnelle) plutôt que devoir *refondre* dans
l'urgence. La décision de pilotage (P2) est : préparer le collapse, pas le
déclencher.

## Périmètre

### Inclus

- Définir ce qu'`AGENTS.md` doit porter **inline** pour être auto-suffisant comme entrée : hard rules + pointeur de chargement lean minimal (sans dupliquer tout `.ai/index.md`).
- **Opérationnaliser le kill_criterion** : un signal/veille (et idéalement un check) qui acte « lecture native d'AGENTS.md confirmée par agent X » → l'indirection peut devenir optionnelle pour cet agent.
- Documenter la **migration downstream** (warn) : ce qui change si l'indirection devient optionnelle.
- Garder un mode où `.ai/index.md` reste pleinement actif (défaut).

### Hors périmètre

- Le modèle de shim multi-agent (`@AGENTS.md` + imports) → `core/agents-md-shim-canonical`.
- La surface `aic` et l'invariant « `.ai/` source unique » → `core/aic-surface-canonical` (cette feature le **respecte**, ne le redéfinit pas).
- **Retirer** `.ai/index.md` ou pivoter AGENTS.md en source primaire de contenu → décision future, hors hedge (rejetée à ce stade en P2).
- Le moteur d'index/mesh (P4) et la taxe dual-tree (P5).

### Granularité / nommage

Une fiche pour le **chemin de collapse de l'indirection**, distincte du modèle de
shim (`agents-md-shim-canonical`) et de la surface (`aic-surface-canonical`).

## Invariants

- `.ai/` **reste la source unique de contenu** (invariant `aic-surface-canonical`) ; AGENTS.md devient une **entrée auto-suffisante**, pas une copie du contenu.
- Le défaut livré garde `.ai/index.md` **actif** ; l'optionnalité est un mode, pas une suppression.
- Aucune dégradation de l'expérience agent tant que la lecture native n'est pas confirmée pour l'agent considéré.
- Parité runtime/template tenue (dogfood drift) sur tout édit `AGENTS.md`/`check-shims`.

## Décisions

- **Hedge, pas pivot** (tranché 2026-06-30, pilot P2) : préparer l'optionnalité, ne pas retirer l'indirection.
- AGENTS.md auto-suffisant = **entrée + protocole lean minimal inline**, pas duplication de `.ai/index.md` (sinon on regrossit Pack A et on viole l'invariant source).
- Le collapse est **gouverné par le kill_criterion #34235**, par agent, pas global.
- Le signal externe est matérialisé dans `.ai/native-context-support.tsv` ; un statut `pending` bloque tout retrait du shim dédié via `check-agent-native-context.sh --require-confirmed <agent>`.

## Comportement attendu

- Aujourd'hui : inchangé — shims + `.ai/index.md` actifs.
- Après confirmation native (par agent) : `AGENTS.md` suffit à cadrer le travail de base ; `.ai/index.md` reste disponible pour le chargement lean avancé mais n'est plus un point de passage obligé pour cet agent.
- `check-shims` continue de valider la base AGENTS.md et les contraintes lean.
- Tant que `claude` reste `pending`, `CLAUDE.md` est conservé ; la tentative de collapse doit échouer explicitement.

## Contrats

- **Entrée auto-suffisante** : `AGENTS.md` porte hard rules + pointeur de chargement minimal.
- **Mode indirection** : `.ai/index.md` actif par défaut ; optionnel seulement quand le kill_criterion est satisfait pour l'agent.
- **check-shims** : la base AGENTS.md reste valide dans les deux modes (lean conservé).
- **Registre natif** : `.ai/native-context-support.tsv` trace `agent`, `shared_entrypoint`, `status`, `checked_at`, `evidence` et `note`.
- **check-agent-native-context** : `--require-confirmed <agent>` sort non-zéro tant que le statut n'est pas `confirmed`.

## Validation

- `AGENTS.md` seul permet à un agent de respecter les hard rules sans charger `.ai/index.md` (test : lecture AGENTS.md → règles connues).
- `.ai/index.md` reste fonctionnel et défaut (non-régression).
- `check-shims` + `check-dogfood-drift` verts ; migration downstream documentée.
- `check-agent-native-context.sh` valide le registre ; `--require-confirmed claude` échoue tant que la lecture native reste non confirmée.
- DONE : AGENTS.md auto-suffisant livré + kill_criterion opérationnalisé (veille/check) + doc migration warn, sans violer l'invariant source.

## Droits / accès

Non requis (`doc.requires.auth: false`). Édition de fichiers repo-local uniquement.

## Données

Non requis (`doc.requires.data: false`). Concernés : shims, `.ai/index.md`, `.copier-answers.yml` (liste d'agents).

## UX

Non requis (`doc.requires.ux: false`). UX = expérience agent/mainteneur : une entrée AGENTS.md suffisante, indirection non imposée quand inutile.

## Observabilité

Non requis (`doc.requires.observability: false`). Preuves = sorties `check-shims`, `check-dogfood-drift`, `check-agent-native-context.sh`, et la veille kill_criterion.

## Déploiement / rollback

- Release N : AGENTS.md auto-suffisant + kill_criterion opérationnalisé ; `.ai/index.md` actif par défaut ; doc migration **warn**.
- Release N+1 : activer l'optionnalité par agent dont la lecture native est confirmée.
- Rollback : repasser en indirection obligatoire (les deux modes restent valides).
- Vérifs : `check-shims`, `check-agent-native-context.sh --require-confirmed <agent>`, `check-dogfood-drift`, smoke multi-agents verts.

## Risques

- **Confirmation native incertaine** hors Claude → optionnalité par agent, jamais globale ; défaut prudent.
- **Régression Pack A** si AGENTS.md duplique trop de contenu → garder inline minimal (entrée + pointeur).
- **Violation invariant** si AGENTS.md devient source de contenu → interdit : AGENTS.md = entrée, `.ai/` = source.
- **Signal externe obsolète** → `checked_at` et `evidence` du registre doivent être mis à jour avant toute bascule.

## Cross-refs

- `core/agents-md-shim-canonical` : a traité le modèle de shim et a explicitement mis l'indirection `.ai/index.md` **hors-périmètre** (« chantier séparé ») ; cette feature EST ce chantier. Partage le kill_criterion #34235.
- `core/aic-surface-canonical` : invariant « `.ai/` source unique » que ce hedge **respecte**.
- Pilot directeur : `.docs/pilots/2026-06-30-ze-solution.md` (item P2, posture hedge).
- `external_refs.github` : #34235 (lecture native AGENTS.md) = déclencheur du collapse.

## Historique / décisions

- 2026-06-30 : création via pilotage `aic-pilot` (pilot `2026-06-30-ze-solution`, item P2),
  après HANDOFF product→core. Posture tranchée = **hedge** (préparer le collapse sans pivoter
  ni retirer l'indirection). Cadre : AGENTS.md auto-suffisant = entrée + protocole lean minimal
  inline (pas de duplication de `.ai/index.md`) ; collapse gouverné par le kill_criterion #34235,
  par agent. Décision ouverte : opérationnalisation concrète du kill_criterion (veille/check).
- 2026-06-30 : **incrément 1 livré** — self-suffisance d'AGENTS.md **verrouillée par `check-shims`** :
  nouvelle assertion exigeant les hard rules inline dans `AGENTS.md` (échoue si réduit à un simple
  pointeur). Runtime + `.jinja` (parité), test `tests/unit/test-agents-md-self-sufficient.sh`
  (cas pointeur nu → échec). Surface `check-shims.sh` possédée par `core/agents-md-shim-canonical`
  (worklog mis à jour). Invariant `.ai/ source` préservé. Reste : opérationnaliser le kill_criterion
  + migration downstream + HANDOFF smoke.
- 2026-07-03 : **incrément 2 livré** — migration downstream documentée (`docs/upgrading.md` + `CHANGELOG.md`) et HANDOFF smoke exécuté (`tests/unit/test-agents-md-self-sufficient.sh` branché en `[0h1/28]`). Il ne reste pas de pivot runtime : le kill_criterion #34235 reste le seul déclencheur futur pour rendre `CLAUDE.md` optionnel.
- 2026-07-03 : **DONE** — kill_criterion opérationnalisé par `.ai/native-context-support.tsv` et `check-agent-native-context.sh`. Le registre note `claude=pending` (issues #34235/#6235 ouvertes), donc `--require-confirmed claude` échoue et `CLAUDE.md` reste requis.
