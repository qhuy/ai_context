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
  phase: review
  step: "lecture produit 2026-07-15 prête"
  blockers: []
  resume_hint: "Readout produit prêt : tâches contextuelles 0002+0005 = with 12/12 vs without 4/12, Δ +66.7 pts, IC Newcombe [14.8 ; 86.2], tokens/run -39.6%. Prochaine reprise : arbitrer decision_state le 2026-07-15 (recommandation : commit avec réserves, pas scale public)."
  updated: 2026-07-03
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
- **Leading indicator** : coût de contexte en tokens par tâche et par classe de tâche.
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
publiable devra aussi documenter le coût tokens global, le Δ tokens par classe de tâche
et l'intervalle de confiance. Le
verdict alimente directement la décision de positionnement et le tri du backlog
(P2–P7).

## Contrats

- **Entrée** : suite de tâches versionnée (prompt + critère de succès objectif par tâche)
  + liste de repos de référence + N.
- **Sortie** : rapport `docs/benchmarks/reports/<stamp>-<repo-slug>.md`, TSV et JSONL
  exposant succès, IC Wilson/Newcombe, Δ observé, conditions exactes, `tokens_used`,
  `task_class` et logs de run.
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
- Leading indicator : tokens de contexte chargés par tâche et par classe de tâche.
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

- 2026-07-03 : incr.13 — tâche `0005-resume-hors-traces` (classe `contextual`) : reprise
  `feature/step/next` sur la feature active la plus fraîche, avec **garde de fuite** dans le
  grader : en condition `without`, si `step` ou `resume_hint` exacts sont trouvés hors mesh
  dans la copie de travail (hors `BENCH_RESULT/`), le check sort en exit 3 et le runner classe
  la cellule `failure_kind=task_invalid` + run non-zéro (même sémantique d'invalidation que
  `agent_infra_error`). Répond au constat 0002/0004 (« Δ nul par fuite, pas par capacité »)
  et au kill-criterion « preuve creuse ». Caveat documenté : l'agent peut techniquement
  écrire la réponse hors `BENCH_RESULT/` dans son workdir ; jugé acceptable v1.
- 2026-07-03 : incr.14 — run Codex `N=3` ciblé `0005-resume-hors-traces`,
  repos `ai_context` + worktree propre `ai_debate` (`d6cdc17`), seed `42`,
  timeout 300s, stamp `2026-07-03-codex-n3-0005-hors-traces`. Résultat global :
  `with` 6/6 vs `without` 2/6, Δ +66.7 points, IC approx. Newcombe [-9.0 ;
  90.3]. Signal externe fort sur `ai_debate` (`with` 3/3, `without` 0/3) ;
  `ai_context` reste partiellement discriminant (`with` 3/3, `without` 2/3 +
  un timeout). Hygiène : `agent_infra_error=0`, `task_invalid=0`, donc aucune
  fuite hors mesh détectée par la garde 0005.
- 2026-07-03 : incr.15 — lecture produit préparée pour la décision du 2026-07-15.
  L'agrégat contextuel exploitable (`0002-feature-resume` + `0005-resume-hors-traces`)
  donne `with` 12/12 vs `without` 4/12, Δ +66.7 points, IC approx. Newcombe
  [14.8 ; 86.2]. Les tokens moyens passent de 88752 (`without`) à 53566 (`with`),
  soit -39.6%. Recommandation du readout : `commit` avec réserves, pas `scale`
  public tant qu'un repo réellement indépendant et/ou un N plus grand ne confirme
  pas le signal.
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
- 2026-07-02 : **incrément 6 — run N=3 invalidé par quota agent**. Un run Codex
  `N=3` sur la même sous-suite portable a atteint la limite d'usage Codex sur deux
  cellules `with` finales (`agent_exit=1`), ce qui invalide le run comme preuve
  benchmark. Signal partiel utile : `ai_debate/0002/without` échoue 3/3 tandis que
  `ai_context/0002/without` passe 2/3 et timeout 1/3, donc la tâche `0002` est
  discriminante sur repo externe mais trop facile sur `ai_context`. Le runner sépare
  maintenant `failure_kind` (`task_fail`, `timeout`, `agent_infra_error`, etc.) et
  sort en non-zéro si une erreur infra agent contamine la matrice. Les artefacts N=3
  invalides ne sont pas publiés.
- 2026-07-02 : **incrément 7 — run N=3 complet et faux positif infra corrigé**.
  Rerun Codex `N=3` sur `ai_context` + worktree propre `ai_debate` à `HEAD`,
  sous-suite portable `0001`/`0002`, seed `42`, timeout 300s. Résultat exploitable
  après correction d'un faux positif : le classifieur `agent_infra_error` ne
  s'applique plus quand `agent_exit=0` et un contenu de repo mentionne simplement
  du `rate limiting`. Signal : global `with` 12/12 vs `without` 9/12 (Δ +25 points).
  Sur `ai_debate/0002-feature-resume`, `with` 3/3 vs `without` 0/3 ; sur
  `ai_context/0002`, `with` 3/3 vs `without` 3/3. Conclusion provisoire :
  la tâche portable prouve l'effet sur repo externe, mais elle ne discrimine pas
  le repo porteur ; il faut renforcer ou spécialiser la suite pour `ai_context`.
- 2026-07-02 : **incrément 4 — isolation runner corrigée après run réel contaminé**. Un
  premier run Codex `N=1` a montré que les copies de travail conservaient encore le harnais,
  les artefacts de benchmark et des skills repo-locales. Le runner exclut maintenant
  `tests/bench/` et `docs/benchmarks/{reports,runs}` de toutes les copies, retire `.agents`
  et `.claude/skills` en condition `without`, et borne chaque cellule via
  `BENCH_TIMEOUT_SECONDS` (`agent_exit=124`). Les artefacts contaminés/partiels ont été
  supprimés avant publication ; prochaine étape : relancer un run propre.
- 2026-07-02 : **incrément 8 — durcissement R4 du runner avant relance N=3**.
  Le runner refuse maintenant les cibles `rm -rf` dangereuses, impose que
  `BENCH_RUN_DIR` reste sous `docs/benchmarks/runs` ou sous le répertoire
  temporaire avec un basename `BENCH_STAMP`, et trie la matrice randomisée avec un
  tie-break déterministe par ordre d'entrée. Le prompt de `0002-feature-resume`
  aligne aussi son départage sur le grader : `scope/id` lexicalement le plus petit,
  pas `id` seul. Le `--self-check` et le test ciblé `0002` couvrent ces régressions
  pour éviter un run N=3 invalide par configuration, ordre instable ou faux échec
  du grader.
- 2026-07-02 : **incrément 9 — R3 : Δ tokens par classe de tâche**. Les tâches
  benchmark peuvent déclarer `task.class` (`trivial`, `contextual`, `handoff` dans
  la suite actuelle). Le runner écrit `task_class` dans le TSV/JSONL, expose
  `BENCH_TASK_CLASS` au grader, et ajoute au rapport Markdown un tableau `Δ tokens
  par classe de tâche` calculé sur la moyenne `with` - `without`. Le `--self-check`
  couvre le cas qui a motivé R3 : surcoût massif sur classe triviale et économie
  sur classe contextuelle, afin qu'un delta global ne masque plus deux réalités
  opposées.
- 2026-07-02 : **incrément 10 — run N=3 enrichi R3 tokens publié**. Rerun Codex
  `N=3`, repos `ai_context` (`789fd76`) + worktree propre `ai_debate` (`d6cdc17`),
  sous-suite portable `0001`/`0002`, seed `42`, timeout 300s, stamp
  `2026-07-02-codex-n3-portable-r3-tokens`. Résultat exploitable sans erreur infra :
  global `with` 12/12 vs `without` 8/12, soit Δ +33.3 points. Le signal externe
  `ai_debate/0002` est répliqué (`with` 3/3, `without` 0/3) et `ai_context/0002`
  devient partiellement discriminant (`with` 3/3, `without` 2/3). Coût tokens par
  classe : `contextual` économise -34848 tokens/run (-37.0%) avec ai_context,
  tandis que `trivial` coûte +10929 tokens/run (+47.7%). Synthèse :
  `docs/benchmarks/reports/2026-07-02-codex-n3-portable-r3-tokens-summary.md`.
- 2026-07-02 : **incrément 11 — IC succès + probe handoff ai_context**. Le runner
  enrichit les rapports avec un IC Wilson 95% par condition et un IC approximatif
  Newcombe sur le Δ `with` - `without`, couverts par `--self-check`. Run
  repo-spécifique `ai_context` sur `0003-handoff-decision`, `N=3`, seed `42`,
  stamp `2026-07-02-codex-n3-ai-context-handoff-ci` : `with` 3/3 vs `without` 2/3,
  Δ +33.3 points avec IC très large [-50.0 ; 79.2]. Lecture : tâche utile mais
  trop suggérée par le prompt pour servir seule de renforcement statistique ;
  concevoir ensuite une tâche ai_context moins devinable sans mesh.
- 2026-07-02 : **incrément 12 — tâche next-handoff moins devinable**. Ajout de
  `0004-next-handoff` : le prompt demande la prochaine passation cross-scope
  encore ouverte pour l'initiative benchmark, mais ne donne ni la cible
  `quality/smoke-test`, ni l'action `brancher run-bench.sh --self-check dans le
  smoke`. Le grader dérive la vérité terrain depuis `progress.resume_hint` de
  `product/agent-efficacy-benchmark` dans le repo source et exige un JSON exact.
  Validation ciblée : syntaxe, cas positif/négatif du grader, `run-bench.sh
  --self-check`, et run d'intégration factice `with` PASS / `without` FAIL.
  Run Codex `N=3` stampé `2026-07-02-codex-n3-ai-context-next-handoff` :
  `with` 2/3 vs `without` 2/3, Δ 0 point, IC très large [-73.1 ; 73.1].
  Lecture : la tâche est techniquement valide mais non discriminante, car la
  condition `without` reconstruit aussi la réponse ; ne pas rerun tel quel.
