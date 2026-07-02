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
  - tests/bench/**
  - docs/benchmarks/**
touches_shared:
  - README.md
  - PROJECT_STATE.md
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
  phase: implement
  step: "incr.5 : premier run Codex N=1 publié — 2 repos, sous-suite portable 0001/0002, with=4/4 vs without=2/4"
  blockers: []
  resume_hint: "prochain incrément : augmenter N sur la sous-suite portable ou généraliser 0003 pour repo externe ; stabiliser la lecture tokens sur runs timeout ; HANDOFF quality/smoke-test restant = brancher run-bench.sh --self-check dans le smoke"
  updated: 2026-07-02
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
condition (avec/sans ai_context), le taux de succès agrégé sur N runs, les artefacts
bruts rejouables et un rapport Markdown avec le Δ observé. À terme, le premier rapport
publiable devra aussi documenter le coût tokens et l'intervalle de confiance. Le
verdict alimente directement la décision de positionnement et le tri du backlog
(P2–P7).

## Contrats

- **Entrée** : suite de tâches versionnée (prompt + critère de succès objectif par tâche)
  + liste de repos de référence + N.
- **Sortie** : rapport `docs/benchmarks/reports/<stamp>-<repo-slug>.md`, TSV et JSONL
  exposant succès, Δ observé, conditions exactes et logs de run.
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
- 2026-07-01 : **incrément 1 — scaffold exécutable livré**. `docs/benchmarks/PROTOCOL.md`
  (métrique, conditions with/without, ≥2 repos dont 1 externe, N, grader objectif, garde-fous),
  `tests/bench/run-bench.sh` (orchestrateur, seam `AGENT_CMD`, mode `--self-check`), tâche
  exemple `0001-example-file` (task.md + check.sh objectif), `tests/bench/README.md`. Self-check
  vérifié : happy-path OK + détection d'une tâche cassée. **Runs réels non exécutés** (action
  mainteneur : clés + coût + non-déterminisme) — le harnais est le livrable, pas des résultats
  fabriqués. Le runner reste `v1 maintainer-only` (non templé). Choix du runner = seam externe
  (tranche la décision « runner ouvert » sans embarquer d'agent).
- 2026-07-02 : **incrément 2 — boucle réelle du runner livrée**. `run-bench.sh` orchestre
  désormais la matrice repos × tâches × conditions × N : copies isolées, condition `without`
  dépouillée, randomisation par seed, prompt sur `stdin` de `$AGENT_CMD`, variables `BENCH_*`
  exposées, grader objectif, agrégation Markdown + TSV + JSONL et logs par cellule. Vérifié par
  `bash -n`, `--self-check`, run d'intégration déterministe sur 2 repos temporaires (4/4 PASS) et
  probe `codex exec` isolé. **Pas de rapport benchmark publiable encore** : la tâche `0001` reste
  une fumée non discriminante ; produire le premier rapport public exige une suite réelle et un
  budget d'agent explicite.
- 2026-07-02 : **incrément 3 — suite discriminante initiale**. Ajout des tâches
  `0002-feature-resume` (retrouver la feature active la plus fraîche depuis `.docs/features`) et
  `0003-handoff-decision` (décider le handoff `product/agent-efficacy-benchmark` →
  `quality/smoke-test` avant modification du smoke). Le runner ne fournit plus le chemin du repo
  source à `$AGENT_CMD`, pour éviter qu'un agent en condition `without` lise le repo original ; les
  métadonnées source restent réservées au grader. Prochaine étape : run agent réel sur repos
  ai_contextisés avec `N` calibré petit, puis rapport publiable.
- 2026-07-02 : **incrément 5 — premier run réel publié**. Run Codex `N=1` sur
  `ai_context` + `ai_debate`, sous-suite portable `0001`/`0002`, seed `42`, timeout 300s. Résultat global :
  `with` 4/4 (100%) vs `without` 2/4 (50%), soit Δ +50 points ; sur `0002-feature-resume` seul :
  `with` 2/2 vs `without` 0/2. Rapport résumé :
  `docs/benchmarks/reports/2026-07-02-codex-n1-portable-summary.md`. Limite : calibrage sans
  significativité (`N=1`) ; coût tokens extrait depuis les logs Codex pour 7/8 cellules
  (timeout sans mesure sur `ai_context/0002/without`) ; artefacts publiés avec références de
  chemins relatives/masquées.
- 2026-07-02 : **incrément 4 — isolation runner corrigée après run réel contaminé**. Un
  premier run Codex `N=1` a montré que les copies de travail conservaient encore le harnais,
  les artefacts de benchmark et des skills repo-locales. Le runner exclut maintenant
  `tests/bench/` et `docs/benchmarks/{reports,runs}` de toutes les copies, retire `.agents`
  et `.claude/skills` en condition `without`, et borne chaque cellule via
  `BENCH_TIMEOUT_SECONDS` (`agent_exit=124`). Les artefacts contaminés/partiels ont été
  supprimés avant publication ; prochaine étape : relancer un run propre.
