---
id: agent-efficacy-benchmark
scope: product
title: Benchmark d'efficacité agent — preuve de valeur ai_context
status: active
type: feature
description: "Initiative produit : prouver de façon reproductible qu'ai_context améliore le taux de succès des tâches d'un agent vs un repo nu, pour transformer le claim de valeur en preuve."
depends_on: []
touches:
  - .docs/features/product/agent-efficacy-benchmark.md
  - .docs/features/product/agent-efficacy-benchmark.worklog.md
touches_shared:
  - README.md
  - PROJECT_STATE.md
# Surfaces planifiées (ajoutées à touches: à leur création, phase implement) :
#   tests/bench/**        — harnais maintainer-only
#   docs/benchmarks/**    — protocole + rapports publiables
product:
  type: initiative
  bet: "Avec ai_context, un agent complète correctement davantage de tâches qu'un agent sur repo nu, de façon reproductible et indépendante du repo — la valeur est mesurable, pas seulement affirmée."
  target_user: "Décideurs d'adoption ai_context (tech leads, mainteneurs) et l'auteur lui-même, qui doivent fonder le positionnement 'solution de référence' sur une preuve."
  success_metric: "Δ taux de succès de tâche (% de tâches d'une suite figée complétées correctement, jugé objectivement) entre un agent AVEC ai_context et le même agent sur repo NU, sur >=2 repos de référence et N runs pour absorber la stochasticité."
  leading_indicator: "Δ coût de contexte (tokens chargés par tâche) avec vs sans ai_context — disponible avant le grader complet, valide tôt la direction."
  decision_state: explore
  next_decision_date: 2026-07-15
  kill_criteria:
    - "Aucun Δ de succès significatif après itération du protocole sur >=2 repos réels."
    - "Le gain ne tient qu'à un repo artificiel taillé pour ai_context (pas de validité externe)."
    - "Le protocole n'est pas rejouable par un tiers (résultats non reproductibles)."
  portfolio:
    appetite: medium
    confidence: low
    expected_impact: high
    urgency: high
    strategic_fit: high
external_refs:
  pilot: ".docs/pilots/2026-06-30-ze-solution.md"
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: true
progress:
  phase: spec
  step: "cadrage via pilot ze-solution ; métrique primaire tranchée = taux de succès de tâche ; v1 maintainer-only"
  blockers: []
  resume_hint: "concevoir le protocole : suite de tâches figée + grader objectif + >=2 repos de référence + N runs ; choisir le runner (harnais maintainer-only sous tests/bench/)"
  updated: 2026-06-30
---

# Benchmark d'efficacité agent — preuve de valeur ai_context

## Résumé

`ai_context` repose sur un pari : un agent travaille plus fiablement quand le repo
porte la couche de contexte (mesh, worklogs, règles, gates). Ce pari est aujourd'hui
**affirmé mais jamais mesuré**. Cette initiative produit un **benchmark reproductible**
qui compare un agent AVEC ai_context au même agent sur repo NU, et mesure le Δ de
**taux de succès de tâche**. C'est la pièce manquante qui transforme « solution de
référence » d'une conviction en preuve.

## Objectif

Donner une preuve défendable, externe et rejouable de la valeur d'ai_context, pour :
fonder le positionnement, prioriser objectivement les autres chantiers (un gain nul
sur un axe = signal d'arrêt), et offrir aux décideurs d'adoption un chiffre plutôt
qu'un argument d'autorité.

## Périmètre

### Inclus

- Définition d'une **suite de tâches figée** représentative (lecture-pour-agir, reprise
  inter-session, édition+doc, navigation de contexte).
- Protocole **avec vs sans ai_context**, sur **>=2 repos de référence**, **N runs** pour
  la significativité.
- **Grader objectif** du succès de tâche (assertions automatiques quand possible ;
  LLM-judge cadré sinon, avec critères explicites).
- **Leading indicator** : coût de contexte en tokens par tâche.
- Harnais **maintainer-only** sous `tests/bench/`, rapport publiable sous `docs/benchmarks/`.

### Hors périmètre

- Livrer le harnais aux projets consommateurs (v1 maintainer-only ; packaging = décision ultérieure).
- Benchmarker la vitesse des hooks ou des checks (perf interne, pas efficacité agent).
- Comparer ai_context à d'autres outils (Linear/BMAD/Spec Kit) — hors sujet.
- Optimiser le moteur (P4) ou la cérémonie (P6) ; ce benchmark les *informe*, ne les traite pas.

### Granularité / nommage

Initiative produit unique. Les livrables exécutables seront des features distinctes si
besoin (ex. `quality/bench-task-suite`, `workflow/bench-runner`), pas une feature
fourre-tout. Ne pas confondre avec un test de non-régression du template (`smoke-test`).

## Invariants

- La comparaison doit être **honnête** : même modèle, mêmes tâches, seule la présence
  d'ai_context varie ; le repo nu n'est pas sciemment handicapé.
- Le protocole doit être **rejouable par un tiers** (données, prompts, graders versionnés).
- Au moins un repo de référence doit être **externe** (non taillé pour ai_context) pour
  la validité externe.
- Un résultat négatif est un résultat valide et doit être publié tel quel.

## Décisions

- **Métrique primaire = taux de succès de tâche** (tranché 2026-06-30, pilot ze-solution).
  Le coût tokens reste *leading indicator*, pas la métrique de titre.
- **v1 maintainer-only** : prouver d'abord dans `ai_context`, packager pour consommateurs ensuite.
- **>=2 repos + N runs** : un seul run/repo = bruit, pas preuve.
- Choix du **runner** et du **grader** : ouverts (voir Risques / prochaine décision).

## Comportement attendu

Un mainteneur lance le harnais ; il obtient, pour chaque repo de référence et chaque
condition (avec/sans ai_context), le taux de succès agrégé sur N runs, le coût tokens
moyen, et un rapport reproductible avec le Δ et son intervalle. Le verdict alimente
directement la décision de positionnement et le tri du backlog (P2–P7).

## Contrats

- **Entrée** : suite de tâches versionnée (prompt + critère de succès objectif par tâche)
  + liste de repos de référence + N.
- **Sortie** : rapport `docs/benchmarks/<date>-<repo>.md` (+ artefact machine-lisible)
  exposant succès, tokens, Δ, conditions exactes.
- **Reproductibilité** : tout ce qui influe sur le résultat est versionné ou loggé.

## Validation

- Le harnais produit un rapport rejouable sur >=2 repos, conditions avec/sans.
- Le grader est objectif (assertions) ou cadré (critères LLM-judge explicites + échantillon vérifié à la main).
- DONE = un premier rapport publié montrant le Δ de succès (positif, nul ou négatif) avec son intervalle de confiance, et un protocole qu'un tiers peut relancer.

## Droits / accès

Non requis (`doc.requires.auth: false`). Harnais maintainer-only, exécution locale ;
aucun secret. Si des clés API de modèle sont nécessaires pour exécuter les runs, elles
restent hors repo (env), jamais commitées.

## Données

Non requis (`doc.requires.data: false`). « Données » = prompts de tâches, repos de
référence et journaux de runs, tous versionnés ou loggés pour la reproductibilité ;
aucune donnée personnelle.

## UX

Non requis (`doc.requires.ux: false`). L'« UX » concernée est celle du mainteneur :
une commande lance le harnais et produit un rapport lisible (Δ, tokens, conditions).

## Observabilité

- Métrique primaire : taux de succès de tâche par condition et par repo.
- Leading indicator : tokens de contexte chargés par tâche.
- Dispersion : variance / intervalle de confiance sur N runs (sans quoi le Δ n'est pas interprétable).
- Méta : nombre de tâches, repos couverts, part jugée automatiquement vs LLM-judge.

## Déploiement / rollback

Non requis (`doc.requires.rollout: false`). Pas de déploiement runtime : le harnais
est un outil maintainer. « Rollback » = retirer/itérer le protocole ; les rapports
publiés restent datés et immuables (un résultat n'est pas réécrit, il est complété).

## Risques

- **Conception du grader** : un grader faible rend la preuve creuse → critères explicites + échantillon vérifié humainement.
- **Validité externe** : sur-ajuster les tâches à ai_context → imposer >=1 repo externe.
- **Stochasticité** : N trop petit → résultat non significatif ; calibrer N.
- **Coût** : N runs × repos × conditions peut être cher → commencer petit, élargir si signal.
- Décisions ouvertes : runner (script vs SDK), modèle(s) testé(s), choix des repos de référence.

## Cross-refs

- Pilot directeur : `.docs/pilots/2026-06-30-ze-solution.md` (item P1, axe « prouver & positionner »).
- Informe P6 (calibrage de la cérémonie d'adoption) qui dépend de cette evidence.
- Reliée conceptuellement à `product/readme-positioning` : le résultat alimente le pitch.
- Reprend la piste P3 « Benchmarks publics » de `PROJECT_STATE.md` (roadmap), désormais priorisée.

## Historique / décisions

- 2026-06-30 : création via pilotage `aic-pilot` (pilot `2026-06-30-ze-solution`, item P1).
  Axe directeur « prouver & positionner » retenu. Métrique primaire tranchée = **taux de
  succès de tâche** ; coût tokens = leading indicator. Cadres posés : v1 maintainer-only,
  >=2 repos de référence, N runs. Prochaine étape : concevoir le protocole (suite de tâches,
  grader, choix du runner). Prochaine décision produit : 2026-07-15.
