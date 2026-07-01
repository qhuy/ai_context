# Protocole — Benchmark d'efficacité agent (ai_context)

> Initiative `product/agent-efficacy-benchmark` (pilot `2026-06-30-ze-solution`, P1).
> **But** : prouver, de façon reproductible, qu'un agent travaille plus fiablement
> AVEC la couche `ai_context` que sur un repo nu. **v1 maintainer-only.**

## Métrique

- **Primaire** : **taux de succès de tâche** — % de tâches d'une suite figée
  complétées correctement, jugé objectivement, `AVEC` vs `SANS` ai_context.
- **Leading indicator** : coût de contexte en tokens par tâche (disponible avant
  le grader complet ; valide tôt la direction, ne confère pas le titre).
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

## Design expérimental

- **≥ 2 repos de référence**, dont **≥ 1 externe** (non taillé pour ai_context)
  → validité externe.
- **N runs** par (repo × tâche × condition) pour absorber la stochasticité du
  modèle. `N` calibré pour que le Δ dépasse le bruit (démarrer petit, élargir si
  signal).
- **Ordre randomisé** des conditions pour éviter tout biais d'ordre/cache.

## Grader (objectivité)

- Chaque tâche fournit un **`check.sh` exécutable** qui retourne `0` = succès,
  `≠0` = échec, **sans jugement subjectif** (assertions sur fichiers, sortie,
  build, tests).
- Si une tâche ne peut être jugée par assertion, un **LLM-judge cadré** est admis
  MAIS : critères explicites écrits + **échantillon vérifié à la main**. À éviter
  tant qu'une assertion objective est possible.

## Contrats d'artefacts

- **Suite de tâches** : `tests/bench/tasks/<id>/` = `task.md` (prompt + critère
  humain-lisible) + `check.sh` (grader objectif, exécuté dans le repo de travail
  après l'agent).
- **Runner** : `tests/bench/run-bench.sh` — orchestre repos × tâches × conditions
  × N, invoque l'agent via le **seam `AGENT_CMD`**, applique le grader, agrège.
- **Rapport** : `docs/benchmarks/reports/<date>-<repo>.md` — succès par condition,
  tokens, Δ, intervalle, conditions exactes (rejouable).

## Seam d'invocation d'agent

Le runner n'embarque **aucun** agent : il appelle `AGENT_CMD` (variable d'env),
une commande non-interactive qui reçoit le prompt de la tâche et opère dans le
répertoire de travail courant. Exemple attendu :

```bash
export AGENT_CMD='claude -p --output-format json'   # ou codex, ou tout runner maison
```

Raison : rester agnostique de l'agent/CLI/clés, et garder le harnais
reproductible et versionné sans secret.

## Garde-fous (anti-preuve-creuse)

- **Grader faible = preuve creuse** → critères objectifs + échantillon vérifié.
- **Sur-ajustement** → imposer ≥1 repo externe.
- **N trop petit** → résultat non significatif ; publier l'intervalle.
- **Résultat négatif = résultat valide** → publié tel quel (kill_criterion de la
  fiche : aucun Δ significatif après itération ⇒ réévaluer l'initiative).

## Reproductibilité

Tout ce qui influe sur le résultat est versionné (tâches, prompts, graders,
liste de repos, `N`) ou loggé (modèle, date, seed d'ordre). Un tiers doit pouvoir
relancer et retrouver le même Δ (aux intervalles près).

## Statut d'implémentation (incrément 1)

- ✅ Protocole (ce fichier), format de suite de tâches, runner **self-checkable**,
  1 tâche exemple, format de rapport.
- ⏳ À venir : câbler `AGENT_CMD` sur un agent réel, ajouter la suite de tâches
  complète, choisir les ≥2 repos, calibrer `N`, produire le 1ᵉʳ rapport.
- Le runner tourne en `--self-check` (valide le plumbing sans invoquer d'agent) ;
  les **runs réels sont une action mainteneur** (clés + coût + non-déterminisme).
