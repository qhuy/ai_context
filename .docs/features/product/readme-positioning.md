---
id: readme-positioning
scope: product
title: README accessible et vendeur
status: active
depends_on:
  - core/aic-surface-canonical
touches:
  - README.md
product:
  type: initiative
  bet: "Un README plus clair, plus court et plus orienté valeur augmente l'adoption du template par des développeurs qui découvrent ai_context."
  target_user: "Développeurs et équipes qui veulent rendre Claude/Codex fiables sur un repo mature"
  success_metric: "Un lecteur comprend en moins de cinq minutes le problème, la promesse, l'installation, le workflow quotidien et les limites actuelles."
  leading_indicator: "Le README expose d'abord la valeur, puis le quickstart, puis la référence technique."
  decision_state: commit
  next_decision_date: 2026-07-31
  kill_criteria:
    - "Le README devient marketing au détriment des commandes nécessaires."
    - "Le README cache les limites réelles entre Claude, Codex et les autres agents."
  portfolio:
    appetite: small
    confidence: high
    expected_impact: high
    urgency: high
    strategic_fit: high
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: review
  step: "A5/A10 intégrés : README canonique clarifié, honnêteté runtime en tête, pitch AGENTS.md aligné C1"
  blockers: []
  resume_hint: "relire le delta README puis décider si la fiche peut passer DONE après checks ; product-review signale encore l'absence de dev slice liée, acceptable ou à router séparément"
  updated: "2026-07-03"
type: feature
---

# README accessible et vendeur

## Résumé

Réécrire le README racine pour qu'il vende mieux `ai_context` sans perdre les
informations opérationnelles importantes.

## Objectif

Le README actuel est complet mais trop dense pour un premier lecteur. Le chantier
vise à réduire la charge cognitive : comprendre vite la promesse, installer vite,
puis accéder à la référence technique seulement quand nécessaire.

## Périmètre

### Inclus

- Repositionner le haut du README autour de la valeur utilisateur.
- Simplifier le sommaire et le parcours de lecture.
- Mettre en avant `aic`, Codex/Claude, le contexte lean et les garde-fous.
- Clarifier que `README.md` est l'entrée canonique du repo source, tandis que
  `README_AI_CONTEXT.md` est le guide rendu dans les projets consommateurs.
- Refléter le pitch C1 : `AGENTS.md` est l'entrée agent standard, `.ai/index.md`
  reste la source lean chargée juste-à-temps.
- Conserver les informations critiques : installation, migration, capacités par agent,
  fichiers générés, scripts, variables, FAQ.

### Hors périmètre

- Modifier le runtime, Copier, les scripts ou les skills.
- Changer `README_AI_CONTEXT.md`.
- Ajouter un site docs ou une landing page externe.

### Granularité / nommage

Un seul livrable : README racine plus accessible et plus convaincant.

## Invariants

- Ne pas masquer les limites actuelles : Claude garde plus d'automatisation runtime
  que Codex et les autres agents.
- Ne pas présenter Codex comme une parité runtime Claude : c'est le pilote
  multi-agent le plus outillé après Claude, avec intervention plus explicite.
- Le langage public reste `aic` / `aic-*`.
- Le README doit rester utile à un mainteneur, pas seulement à un visiteur GitHub.

## Décisions

- Garder un README unique : pitch + quickstart + référence.
- Déplacer la complexité après l'installation et le workflow quotidien.
- Préférer des tableaux courts et commandes copiables aux longs paragraphes.
- Garder `README_AI_CONTEXT.md` à la racine pour le dogfood/template, mais
  nommer explicitement `README.md` comme porte d'entrée canonique du repo source.

## Comportement attendu

Un lecteur doit pouvoir répondre rapidement à quatre questions :

1. À quoi sert `ai_context` ?
2. Pourquoi c'est utile pour Claude/Codex ?
3. Comment l'installer et l'utiliser aujourd'hui ?
4. Quelles sont les limites et les garde-fous ?

## Contrats

- `README.md` reste la page d'accueil canonique du repo.
- Les liens internes doivent rester valides.
- Les commandes affichées doivent utiliser `aic.sh` et `/aic-*`.

## Validation

- `bash .ai/scripts/check-ai-references.sh`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh product/readme-positioning`
- `bash .ai/scripts/check-product-links.sh`
- `bash .ai/scripts/check-feature-freshness.sh --staged --strict`

## Risques

- Trop condenser peut cacher des détails nécessaires à la migration brownfield.
- Trop vendre peut créer une promesse fausse sur les capacités non-Claude.

## Cross-refs

- `core/aic-surface-canonical` : la surface utilisateur du README doit rester
  alignée sur `aic`.

## Historique / décisions

- 2026-05-06 : création du chantier après validation de la surface `aic`.
- 2026-06-28 : `decision_state` explore→commit. Le bet « README vendeur » est validé (le README réécrit existe et tient) ; le chantier reste ouvert et absorbe les items du frame de remédiation 2026-06-28 — A5 (canonicité de `README_AI_CONTEXT.md`, sorti de la racine), A10 (honnêteté multi-agent remontée dès la 1ère ligne, Codex requalifié « pilote »), et le futur cadrage C1 (`AGENTS.md` source unique + symlink/import). `next_decision_date` re-datée au 2026-07-31.
- 2026-07-03 : A5/A10 exécutés dans `README.md`. C1 est reflété côté pitch
  produit sans rouvrir le scope core : `AGENTS.md` est décrit comme entrée agent
  standard et `.ai/index.md` comme source de contexte lean. `README_AI_CONTEXT.md`
  reste présent comme guide généré, mais n'est plus ambigu comme porte d'entrée
  canonique du repo source.
