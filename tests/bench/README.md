# tests/bench — Benchmark d'efficacité agent (maintainer-only)

Harnais pour prouver que `ai_context` améliore le **taux de succès de tâche**
d'un agent vs un repo nu. Protocole complet : [../../docs/benchmarks/PROTOCOL.md](../../docs/benchmarks/PROTOCOL.md).

> **v1 maintainer-only** : non rendu dans le template (comme les scripts de
> dogfooding). Les projets consommateurs ne reçoivent pas ce dossier.

## Structure

```
tests/bench/
├── run-bench.sh              # orchestrateur (seam AGENT_CMD ; --self-check)
└── tasks/<id>/
    ├── task.md               # prompt + critère humain-lisible
    ├── task.class            # classe de tâche pour agréger les coûts tokens
    └── check.sh              # grader OBJECTIF (exit 0/≠0), exécuté après l'agent
```

## Valider le plumbing (sans agent)

```bash
bash tests/bench/run-bench.sh --self-check
```

Vérifie que chaque tâche a `task.md` + `check.sh` exécutable, que les repos
(si `BENCH_REPOS`) existent, que les garde-fous de suppression et le tie-break
de matrice fonctionnent, que le calcul de Δ tokens par classe et les intervalles
de confiance de succès sont stables, et affiche la matrice de runs. N'invoque
aucun agent.

## Run réel (action mainteneur)

```bash
export AGENT_CMD='claude -p --output-format json'   # ou codex, ou runner maison
export BENCH_REPOS='/chemin/repo-a /chemin/repo-b'   # ≥2, dont ≥1 externe
export BENCH_N=5                                     # runs par cellule
export BENCH_AGENT_LABEL='claude-sonnet-...'
export BENCH_TIMEOUT_SECONDS=300                     # timeout par cellule agent
bash tests/bench/run-bench.sh
```

Coûteux + non-déterministe (vraies invocations d'agent). Rapports sous
`docs/benchmarks/reports/`, logs sous `docs/benchmarks/runs/<stamp>/`.
Les artefacts publiés référencent les repos par nom/slug et les logs par chemins
relatifs au repo ; les copies de travail temporaires sont notées `<tmp>/...`.
Si `BENCH_RUN_DIR` est personnalisé, il doit rester sous `docs/benchmarks/runs`
ou sous le répertoire temporaire, et son nom de dossier doit être égal à
`BENCH_STAMP`, car le runner remplace ce répertoire en fin de matrice.
Quand le log agent contient un bloc `tokens used`, le runner renseigne aussi
`tokens_used` dans les TSV/JSONL et les rapports Markdown. Chaque tâche peut
déclarer une classe via `task.class` ; le runner écrit alors `task_class` dans
les TSV/JSONL et ajoute au rapport un tableau de Δ tokens/run par classe
(`with` - `without`) pour éviter qu'une moyenne globale masque des tâches de
nature différente. La synthèse succès expose aussi un IC Wilson 95% par condition
et un IC approximatif Newcombe pour le Δ `with` - `without`.
Le champ `failure_kind` distingue `task_fail`, `timeout`, `agent_error`,
`agent_infra_error` et `task_invalid` (check exit 3 : vérité terrain
reconstructible hors mesh dans la copie `without` — la cellule ne prouve rien
et le run sort en non-zéro). Une erreur infra agent (quota, auth, provider) invalide le
run comme preuve benchmark ; le runner publie les artefacts de diagnostic puis
sort en non-zéro. La classification `agent_infra_error` requiert une commande
agent sortie non-zéro : un contenu de repo qui mentionne du rate limiting ne doit
pas invalider un run agent réussi.

Le runner :

- copie chaque repo dans un dossier temporaire en excluant `.git`, le harnais
  `tests/bench/` et les anciens rapports/logs `docs/benchmarks/{reports,runs}` ;
- applique la condition `without` en retirant `.ai/`, `.docs/`, les shims agents
  et les skills repo-locales (`.agents`, `.claude/skills`) ;
- envoie `task.md` sur `stdin` de `$AGENT_CMD` ;
- expose à l'agent uniquement `BENCH_TASK_ID` et `BENCH_WORKDIR` pour éviter de
  fuiter le chemin du repo source dans la condition `without` ;
- exécute ensuite `check.sh` dans la copie de travail ;
- expose au grader `BENCH_PROMPT_FILE`, `BENCH_TASK_DIR`, `BENCH_TASK_ID`,
  `BENCH_TASK_CLASS`, `BENCH_CONDITION`, `BENCH_RUN_INDEX`, `BENCH_REPO_NAME`,
  `BENCH_SOURCE_REPO`, `BENCH_WORKDIR` ;
- marque une cellule en échec si `$AGENT_CMD` dépasse `BENCH_TIMEOUT_SECONDS`
  (`agent_exit=124`) ;
- marque une erreur quota/auth/provider sur commande agent échouée comme
  `agent_infra_error`, sans la compter comme un échec métier exploitable ;
- refuse les suppressions dangereuses avant de nettoyer les répertoires de run ;
- agrège Markdown + TSV + JSONL et ne publie les artefacts dans
  `docs/benchmarks/` qu'une fois la matrice terminée.

Exemple Codex CLI, prompt lu depuis `stdin` et travail dans le `cwd` de la copie :

```bash
export AGENT_CMD='codex exec --skip-git-repo-check --ephemeral --sandbox workspace-write -'
export BENCH_AGENT_LABEL='codex exec / workspace-write'
```

`AGENT_CMD` n'est pas écrit dans les rapports pour éviter de consigner un secret
accidentel ; utiliser `BENCH_AGENT_LABEL` pour tracer le modèle/runner. Pour une
vérification non publiée, rediriger `BENCH_REPORT_DIR` et `BENCH_RUN_DIR` vers un
dossier temporaire.

## Ajouter une tâche

1. `tests/bench/tasks/<id>/task.md` — prompt + critère.
2. `tests/bench/tasks/<id>/task.class` — classe d'analyse courte (`trivial`,
   `contextual`, etc.) ; si absent ou vide, le runner utilise `<id>`.
3. `tests/bench/tasks/<id>/check.sh` (`chmod +x`) — grader objectif (assertions).
4. `bash tests/bench/run-bench.sh --self-check` pour valider.

Préférer un grader par **assertion**. LLM-judge seulement si aucune assertion
possible, avec critères écrits + échantillon vérifié à la main (cf. PROTOCOL).

## Suite actuelle

- `0001-example-file` (`trivial`) : tâche de fumée du format de tâche, non discriminante.
- `0002-feature-resume` : retrouve la feature active la plus fraîche depuis le
  feature mesh et écrit une reprise JSON objective (`contextual`).
- `0003-handoff-decision` (`handoff`) : vérifie la décision de handoff cross-scope
  pour le branchement du benchmark dans le smoke-test.
- `0004-next-handoff` (`handoff`) : retrouve la prochaine passation cross-scope
  encore ouverte dans le feature mesh, sans exposer la cible ni l'action dans le
  prompt. Probe publié comme non discriminant sur `ai_context` (`with` 2/3 vs
  `without` 2/3), utile pour diagnostiquer la difficulté de construction des
  tâches repo-spécifiques.
- `0005-resume-hors-traces` (`contextual`) : même reprise que `0002` (feature
  active la plus fraîche, `step` + `resume_hint` exacts), mais le grader vérifie
  d'abord en condition `without` que la vérité terrain n'apparaît nulle part
  hors mesh dans la copie de travail (exit 3 → `failure_kind=task_invalid`
  sinon). Réponse au constat 0002/0004 : un Δ nul par fuite d'information est
  détecté au lieu d'être compté.
