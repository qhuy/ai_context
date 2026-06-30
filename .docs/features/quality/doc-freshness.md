---
id: doc-freshness
scope: quality
title: Fraicheur documentaire des features
status: active
depends_on: []
touches:
  - .ai/scripts/check-feature-freshness.sh
  - .ai/scripts/check-commit-features.sh
  - tests/unit/test-check-feature-freshness.sh
  - tests/unit/test-freshness-primary-coverer.sh
  - tests/unit/test-review-delta-shared.sh
  - .ai/quality/QUALITY_GATE.md
  - .github/workflows/ai-context-check.yml
  - template/.ai/scripts/check-feature-freshness.sh.jinja
  - template/.ai/scripts/check-commit-features.sh.jinja
  - template/.ai/quality/QUALITY_GATE.md.jinja
  - template/.github/workflows/ai-context-check.yml.jinja
progress:
  phase: implement
  step: "quality gate alignée sur Pack A lean"
  blockers: []
  resume_hint: "vérifier check-feature-freshness --warn et staged strict avant commit"
  updated: 2026-06-26
type: feature
---

# Fraicheur documentaire des features

## Résumé

Filet de sécurité qui empêche de committer une évolution de comportement couverte par une feature sans toucher sa fiche ou son worklog. Bloque en local au commit et signale en CI les fiches plus anciennes que le code qu'elles couvrent.

## Objectif

Garantir qu'une evolution de comportement couverte par une feature ne puisse pas etre committee sans trace documentaire explicite.

## Périmètre

### Inclus

- Le contrôle staged au commit local (`check-feature-freshness.sh --staged --strict`) appelé par le hook `commit-msg`.
- Le rapport de fraîcheur en CI / quality gate (modes `--warn` et `--strict` sur l'historique Git).
- La résolution des features candidates via `touches:` (bloquant) et `touches_shared:` (reporting/review seulement).
- Le filet sémantique côté fiche via `check-feature-docs.sh` : sections noyau, modules conditionnels `doc.requires.*`, warnings par défaut et strict avant DONE.

### Hors périmètre

- La validation structurelle du mesh (portée par `check-features.sh`) : ici on couvre la maintenance sémantique, pas la cohérence des liens.
- Le contenu rédactionnel des fiches : le check vérifie la présence/fraîcheur, pas la justesse du texte.
- L'enforcement réseau : le contrôle bloquant local repose sur les git hooks (contournables via `--no-verify`), rattrapé par la CI.

## Invariants

- Le contrôle bloquant reste fondé sur `touches:` uniquement ; `touches_shared:` ne déclenche jamais l'obligation de fiche/worklog staged.
- Un fichier stagé couvert par plusieurs fiches exige le worklog/fiche du **coverer primaire** (rang de spécificité `touches:` le plus élevé) ; en cas d'**égalité de rang** (revendications exactes multiples), tous les ex-aequo sont requis. Les coverers moins spécifiques (glob large) sont advisory, non bloquants. Contrat (a') — audit D / arbitrage Codex : tue la cascade sur l'infra partagée sans rendre muet le vrai co-ownership.
- En staged strict, un fichier couvert sans doc ni worklog stage bloque le commit ; aucune feature couverte ne peut passer silencieusement.
- Le hook `commit-msg` appelle le mode staged strict **après** la validation Conventional Commits, jamais avant.
- La quality gate `QUALITY_GATE.md` reste bloquante avant DONE sans imposer son chargement initial (cohérence Pack A lean).

## Comportement attendu

- En commit local, les changements stages sur des fichiers couverts par `touches:` doivent etre accompagnes d'une modification de la fiche feature ou de son worklog.
- En CI / quality gate, un rapport signale les features dont le code couvert est plus recent que la fiche ou le worklog.
- Le controle bloquant reste base sur `touches:`. `touches_shared:` sert au reporting/review et ne déclenche pas l'obligation de fiche/worklog staged.

## Contrats

- Script expose : `.ai/scripts/check-feature-freshness.sh`.
- Modes :
  - `--staged --strict` bloque si un fichier stage matche une feature sans doc/worklog stage.
  - `--warn` rapporte les features potentiellement stale sans bloquer.
  - `--strict` bloque sur les features stale detectees dans l'historique Git.
- Le hook `commit-msg` appelle le mode staged strict apres validation Conventional Commits.

## Décisions

- Contrôle bloquant restreint à `touches:` ; `touches_shared:` n'alimente que reporting/review pour réduire le bruit sur les fichiers transverses (`tests/smoke-test.sh`, CHANGELOG, états projet).
- Pré-calcul des fiches/worklogs stages au lieu de rescanner tous les fichiers stages par feature candidate : évite un crash local silencieux sur les gros commits dogfood.
- `check-feature-docs.sh` complète `check-feature-freshness.sh` : la fraîcheur garantit qu'on touche la doc, le docs check garantit que la fiche reste structurée.
- Sévérité graduée : `--warn` par défaut (ne casse pas le legacy), `--strict` avant DONE et en CI bloquante.
- **Obligation par coverer primaire, pas par tous (contrat a')** : parmi les coverers `touches:` directs, seul le rang de spécificité le plus élevé bloque (helper `blocking_coverers` ; spécificité via `_score_touch_pattern`). Égalité de rang ⇒ tous les ex-aequo (force la documentation ou la reclassification en `touches_shared`). Rejette l'auto-classification par fan-out (b), qui rendrait silencieux le co-ownership légitime. Le moat est préservé : 0 coverer documenté reste bloquant.

## Validation

- `tests/unit/test-check-feature-freshness.sh` couvre le staged strict, le multi-feature et la non-régression du crash gros commit.
- `tests/unit/test-review-delta-shared.sh` vérifie que `touches_shared:` reste non bloquant pour la fraîcheur staged.
- `tests/unit/test-freshness-primary-coverer.sh` verrouille le contrat (a') : exact-primaire documenté passe, 0 doc bloque, tie 1/N bloque, tie N/N passe, dispatcher reclassé → owner seul, `--worktree` idem `--staged` sans écrire l'index.
- Au commit local : `check-feature-freshness.sh --staged --strict` via le hook `commit-msg` (un fichier couvert sans doc/worklog stage bloque).
- En CI : `check-feature-freshness.sh --warn` puis `--strict` selon le contexte ; `check-feature-docs.sh` en warning sur les projets legacy.

## Cross-refs

Aucune dependance de feature declaree.

## Historique / décisions

- 2026-05-03 : correction d'une regression multi-feature : un fichier couvert par plusieurs fiches exige maintenant une fiche/worklog stage pour chaque feature candidate. Ajout d'un test unitaire dédié.
- 2026-05-03 : introduction de `touches_shared` comme surface non bloquante pour la fraîcheur staged. Objectif : réduire le bruit sur les fichiers transverses (`tests/smoke-test.sh`, CHANGELOG, états projet) sans perdre la visibilité dans les rapports.
- 2026-05-03 : simplification du controle staged. Le script pre-calcule les fiches/worklogs stages au lieu de rescanner tous les fichiers stages pour chaque feature candidate, ce qui evite un crash local silencieux sur gros commits dogfood.
- 2026-04-29 : creation du filet de securite doc/code freshness pour completer `check-features.sh`, qui valide la structure mais pas la maintenance semantique.
- 2026-05-04 : quality gate reformulée pour ne plus impliquer le chargement initial de `QUALITY_GATE.md`; elle reste bloquante avant DONE, en cohérence avec Pack A lean.
- 2026-05-04 : ajout de `check-feature-docs.sh` pour compléter le filet sémantique côté fiche : sections noyau, modules conditionnels via `doc.requires.*`, warnings par défaut et strict avant DONE.
