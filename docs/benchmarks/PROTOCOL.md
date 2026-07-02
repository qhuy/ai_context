# Protocole — Benchmark d'efficacité agent (ai_context)

> Initiative `product/agent-efficacy-benchmark` (pilot `2026-06-30-ze-solution`, P1).
> **But** : prouver, de façon reproductible, qu'un agent travaille plus fiablement
> AVEC la couche `ai_context` que sur un repo nu. **v1 maintainer-only.**

## Métrique

- **Primaire** : **taux de succès de tâche** — % de tâches d'une suite figée
  complétées correctement, jugé objectivement, `AVEC` vs `SANS` ai_context.
- **Leading indicator** : coût de contexte en tokens par tâche et par classe de
  tâche (disponible avant le grader complet ; valide tôt la direction, ne confère
  pas le titre).
- **Dispersion** : intervalle de confiance sur `N` runs — sans quoi le Δ n'est
  pas interprétable.

## Conditions comparées

Pour chaque repo de référence et chaque tâche :

| Condition | Repo de travail |
|---|---|
| `with` | copie du repo **avec** `ai_context` (`.ai/`, `AGENTS.md`, `CLAUDE.md`, `.docs/`) |
| `without` | même copie **dépouillée** de la couche ai_context |

Seule la présence d'ai_context varie. Même modèle, même tâche, même prompt de
départ. Le repo nu n'est **pas** sciemment handicapé (invariant d'honnêteté).
Le harnais lui-même (`tests/bench/`) et les artefacts de runs précédents
(`docs/benchmarks/reports`, `docs/benchmarks/runs`) sont exclus de toutes les
copies de travail pour éviter que l'agent lise les tâches, graders ou résultats.
La condition `without` retire aussi les skills repo-locales (`.agents`,
`.claude/skills`), pas seulement les shims.
Chaque cellule est bornée par `BENCH_TIMEOUT_SECONDS` ; un timeout est compté comme
échec de tâche (`agent_exit=124`) et reste visible dans les logs.
Les résultats et logs sont écrits dans un répertoire temporaire pendant l'exécution,
puis publiés vers `docs/benchmarks/reports` et `docs/benchmarks/runs` seulement une
fois la matrice terminée, afin d'éviter de conserver des artefacts partiels.
Le répertoire de logs publié est remplacé uniquement s'il reste sous
`docs/benchmarks/runs` ou sous le répertoire temporaire, et si son basename correspond
au `BENCH_STAMP`, pour éviter qu'une configuration invalide déclenche une suppression large.

## Design expérimental

- **≥ 2 repos de référence**, dont **≥ 1 externe** (non taillé pour ai_context)
  → validité externe.
- **N runs** par (repo × tâche × condition) pour absorber la stochasticité du
  modèle. `N` calibré pour que le Δ dépasse le bruit (démarrer petit, élargir si
  signal).
- **Ordre randomisé** des conditions pour éviter tout biais d'ordre/cache, avec
  tie-break déterministe en cas d'égalité de clé pseudo-aléatoire.

## Grader (objectivité)

- Chaque tâche fournit un **`check.sh` exécutable** qui retourne `0` = succès,
  `≠0` = échec, **sans jugement subjectif** (assertions sur fichiers, sortie,
  build, tests).
- Si une tâche ne peut être jugée par assertion, un **LLM-judge cadré** est admis
  MAIS : critères explicites écrits + **échantillon vérifié à la main**. À éviter
  tant qu'une assertion objective est possible.

## Contrats d'artefacts

- **Suite de tâches** : `tests/bench/tasks/<id>/` = `task.md` (prompt + critère
  humain-lisible) + `task.class` (classe d'analyse tokens, fallback = `<id>`) +
  `check.sh` (grader objectif, exécuté dans le repo de travail après l'agent).
  La suite v1 contient une fumée de format (`0001`, classe `trivial`) et deux
  tâches discriminantes ai_context (`0002` reprise feature mesh, classe
  `contextual` ; `0003` handoff cross-scope, classe `handoff`).
- **Runner** : `tests/bench/run-bench.sh` — orchestre repos × tâches × conditions
  × N, invoque l'agent via le **seam `AGENT_CMD`**, applique le grader, agrège.
- **Rapport** : `docs/benchmarks/reports/<date>-<repo-slug>.md` — succès par condition,
  Δ et conditions exactes (rejouable), puis coût tokens global et Δ tokens/run
  par classe de tâche (`with` - `without`). Le runner produit aussi un TSV et un
  JSONL globaux incluant `tokens_used` quand le log agent expose un bloc
  `tokens used`, `task_class` pour l'agrégation par classe, et `failure_kind` pour
  distinguer échec de tâche, timeout et erreur infra agent, plus les logs
  d'agent/check sous `docs/benchmarks/runs/<stamp>/`.
  Les artefacts publiés référencent les repos par nom/slug et les logs par chemin
  relatif au repo, afin d'éviter de versionner des chemins absolus locaux.
  Les logs sont des sorties brutes d'agent : les relire avant publication externe
  et ne jamais versionner un run qui contient un secret brut.
  Un run contenant `failure_kind=agent_infra_error` (quota, auth, provider, etc.)
  est invalide comme preuve benchmark, même si les artefacts restent utiles au diagnostic.
  Cette classification ne s'applique qu'à une commande agent sortie non-zéro ; un
  contenu de repo ou un warning dans un run agent réussi reste un échec de tâche
  si le check échoue.

## Seam d'invocation d'agent

Le runner n'embarque **aucun** agent : il appelle `AGENT_CMD` (variable d'env),
une commande non-interactive qui reçoit le prompt de la tâche et opère dans le
répertoire de travail courant. Concrètement, `task.md` est passé sur `stdin`.
Pour préserver l'honnêteté de la condition `without`, l'agent ne reçoit pas le
chemin du repo source ; il ne voit que `BENCH_TASK_ID` et `BENCH_WORKDIR`.
Le grader reçoit, lui, les métadonnées nécessaires (`BENCH_SOURCE_REPO`,
`BENCH_CONDITION`, `BENCH_RUN_INDEX`, etc.) après l'exécution agent. Exemple attendu :

```bash
export AGENT_CMD='claude -p --output-format json'   # ou codex, ou tout runner maison
export BENCH_AGENT_LABEL='claude-sonnet-...'        # libellé écrit dans les rapports
```

Raison : rester agnostique de l'agent/CLI/clés, et garder le harnais
reproductible et versionné sans secret.

## Garde-fous (anti-preuve-creuse)

- **Grader faible = preuve creuse** → critères objectifs + échantillon vérifié.
- **Sur-ajustement** → imposer ≥1 repo externe.
- **N trop petit** → résultat non significatif ; publier l'intervalle.
- **Erreur infra agent** → ne pas la compter comme échec de tâche si la commande
  agent échoue elle-même ; invalider le run et relancer après correction/quota.
- **Résultat négatif = résultat valide** → publié tel quel (kill_criterion de la
  fiche : aucun Δ significatif après itération ⇒ réévaluer l'initiative).

## Reproductibilité

Tout ce qui influe sur le résultat est versionné (tâches, prompts, graders,
liste de repos, `N`) ou loggé (modèle, date, seed d'ordre). Un tiers doit pouvoir
relancer et retrouver le même Δ (aux intervalles près).

## Statut d'implémentation

- ✅ Protocole (ce fichier), format de suite de tâches, runner **self-checkable**,
  1 tâche exemple, format de rapport.
- ✅ Boucle de run réelle : copies isolées, randomisation par seed, condition
  `with/without`, invocation de `$AGENT_CMD`, grader, rapports Markdown + TSV +
  JSONL, logs.
- ✅ Suite discriminante initiale : reprise feature mesh + décision handoff
  cross-scope, avec graders objectifs.
- ✅ Premier run agent réel publié : Codex `N=1` sur `ai_context` + `ai_debate`,
  sous-suite portable `0001`/`0002`, signal `with` 4/4 vs `without` 2/4,
  coût tokens extrait depuis les logs Codex quand disponible.
- ✅ Runner durci : `failure_kind` sépare échec tâche, timeout et erreur infra agent ;
  un run contaminé par quota/provider sort en non-zéro.
- ✅ Runner protégé : suppressions bornées, `BENCH_RUN_DIR` attaché au stamp, et
  randomisation avec tie-break déterministe.
- ✅ Rapport tokens enrichi : les tâches déclarent `task.class`, les TSV/JSONL
  exposent `task_class`, et le rapport Markdown calcule le Δ tokens/run par classe.
- ✅ Run agent réel `N=3` publié : `with` 12/12 vs `without` 9/12 ; signal fort
  sur `ai_debate/0002` (`with` 3/3, `without` 0/3), mais `ai_context/0002`
  reste trop facile sans contexte (`without` 3/3).
- ⏳ À venir : renforcer la suite pour `ai_context`, puis décider si `0003`
  devient portable pour repos externes ou reste une tâche repo-spécifique.
- Le runner tourne en `--self-check` (valide le plumbing sans invoquer d'agent).
  Les **runs agents réels** restent une action mainteneur (clés + coût +
  non-déterminisme).
