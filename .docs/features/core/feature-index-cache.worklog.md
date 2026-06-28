# Worklog — core/feature-index-cache


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 — freshness
- Impact direct : ajout de `collect_uncommitted_paths` dans `.ai/scripts/_lib.sh` (et template) pour exposer la liste des paths uncommitted via `git status --short --untracked-files=all`. Réutilisable au-delà de `review-delta.sh` (futurs callers checks/CI/aic).
- Aucun changement sur la sémantique de l'index ni sur les helpers de matching. `check-features` PASS.

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 — freshness
- Impact direct : 3 nouvelles fonctions dans `.ai/scripts/_lib.sh` (et template) :
  `_glob_pattern_supported`, `_glob_to_regex`, `features_matching_path_ranked`,
  `_score_touch_pattern`. Refactor `path_matches_touch` (regex path-aware).
- Compat ascendante : `features_matching_path` à 3 colonnes inchangée.
- Validation : check-features PASS, 28 tests path-matches PASS, 21 tests multi-level PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 01:16 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 — freshness
- Impact direct : nouveau helper `is_structural_feature_edit` ajouté dans `.ai/scripts/_lib.sh` (et template). Filtre metadata/noise pour distinguer édits structurels des édits documentaires (livraison Phase 2 #4).
- Aucun changement sur la sémantique de l'index ni sur les helpers de matching existants.
- Validation : 22 cas test-auto-progress-filter PASS.

## 2026-05-07 17:33 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-05-07 18:04 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
## 2026-05-12 — impact partagé contrat lock index

- Fichiers/surfaces : `.ai/scripts/_lib.sh`, `template/.ai/scripts/_lib.sh.jinja`.
- Contexte : `quality/index-lock-contract` durcit le lock utilise par `build-feature-index.sh --write`.
- Impact : le cache JSON conserve un lock atomique `mkdir`, sans fallback concurrent apres timeout.
- Validation portée par `quality/index-lock-contract`.

## 2026-06-01 — impact pr-report : consommation index en une passe

- `pr-report.sh` (+ `.jinja`) conserve l'index temporaire read-only, mais extrait désormais les tables `touches` / `touches_shared` une seule fois avant l'analyse du diff.
- Objectif : éviter le coût `jq` répété par fichier sur les rapports larges, sans changer le format de `.ai/.feature-index.json`.

## 2026-06-01 22:26 — auto
- Fichiers modifiés :
  - .ai/scripts/pr-report.sh
  - template/.ai/scripts/pr-report.sh.jinja

## 2026-06-01 — HANDOFF depuis quality : fast-path `src/`

- HANDOFF reçu depuis `quality/pr-report`.
- `pr-report.sh` conserve les tables préchargées depuis l'index feature, mais le fast-path sans glob normalise désormais le slash final (`src/`) comme le matcher canonique `_lib.sh`.
- Aucun changement du format `.ai/.feature-index.json`.

## 2026-06-01 22:47 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/pr-report.sh
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/pr-report.sh.jinja

## 2026-06-01 — HANDOFF depuis quality : matcher no-glob rapide

- HANDOFF reçu depuis `quality/features-for-path-ranking-and-matcher-correctness` et `quality/pr-report`.
- Le cache/index n'est pas modifié ; seul le consommateur canonique `path_matches_touch` évite le coût de validation glob pour les `touches:` exacts ou dossiers.
- Aucun changement de format `.ai/.feature-index.json`.

## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/build-feature-index.sh.jinja

## 2026-06-26 11:17 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-06-26 — fix robustesse build-feature-index (fiches YAML malformées)
- Symptôme (vécu en session) : une fiche au titre non quoté finissant par `:` → YAML invalide → `build-feature-index.sh` (chemin `yq`) plantait sous `set -e`, et la cascade cassait `features-for-path`, `pre-turn-reminder`, auto-worklog → deadlock d'édition (l'outil Edit déclenche le hook qui re-plante).
- Fix (+ jinja, parité conservée) : validation `yq -e -o=json` du frontmatter AVANT extraction (warn + `return 1` si illisible) + isolation par fiche dans la boucle de build. L'index reste valide et contient les fiches saines. Honore l'invariant déjà documenté de la fiche.
- Test : `tests/unit/test-build-feature-index-robust.sh` (smoke [0m]) — build exit 0, fiche malformée exclue + warning (yq), fiches valides présentes, JSON valide, gated sur yq v4.
- `check-features` vérifié : reste strict (signale la fiche + exit 1) sans cascade-crash → bonne division resilient (build-index) / strict (check-features).
- Validation : `bash -n`, build réel 53 features OK, dogfood-drift + smoke (voir commit).

## 2026-06-28 20:51 — auto
- Fichiers modifiés :
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja

## 2026-06-28 — fix fallback body-leak + flow-style (A1)
- `extract_scalar_awk` / `extract_list_awk` bornés au 1er bloc frontmatter (`---...---`) : fin du body-leak (le corps markdown ne peut plus injecter status/depends_on/touches). `extract_list_awk` gère aussi le flow-style `key: [a, b]`.
- Parité : même fix dans `template/.ai/scripts/build-feature-index.sh.jinja` (aucun hazard {% raw %}). drift ✅.
- Test : `tests/unit/test-build-feature-index-fallback-frontmatter.sh` (yq masqué). contract/fallback/robust toujours ✅.
- Fichiers : .ai/scripts/build-feature-index.sh, template/.ai/scripts/build-feature-index.sh.jinja, tests/unit/test-build-feature-index-fallback-frontmatter.sh
