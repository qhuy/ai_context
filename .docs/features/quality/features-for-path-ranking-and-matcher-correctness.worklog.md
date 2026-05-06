# Worklog — quality/features-for-path-ranking-and-matcher-correctness

## 2026-05-06 23:05 — création
- Feature créée en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`.
- Scope : quality.
- Intent initial : ranker l'injection PreToolUse par spécificité du glob (top-K) ET corriger le matcher globstar pour bash 3.2 sur les patterns multi-niveaux.
- Bug matcher confirmé en local :
  - `_lib.sh:82-84` : `enable_globstar()` est `shopt -s globstar 2>/dev/null || true`, no-op silencieux sur bash 3.2 macOS.
  - `_lib.sh:118-121` : branche spéciale couvre uniquement `prefix/**` simple. Les patterns `src/**/*.ts`, `foo-*/**`, etc. retombent sur le glob Bash standard ligne 116, qui sur 3.2 traite `**` comme `*` (un seul niveau).
  - Bash local : `/bin/bash 3.2.57(1)-release arm64-apple-darwin25`. Critère P1 satisfait.
- Bug ranking confirmé : aucun tri, aucun top-K, aucune métrique de spécificité dans `features-for-path.sh`. Une feature avec `touches: src/**` matche tout fichier sous src/ et est injectée comme une feature avec `touches: src/auth/payment/intent.ts`.
- Décision Phase 2 : positionnée en #2 selon convergence Claude/Codex round 4, après `quality/review-delta-uncommitted-coverage` (#1).
- Approche par défaut : Option B (Codex round 3) — fix matcher comme prérequis interne du ranking, acceptance bloque livraison.
- Top-K par défaut envisagé : 3, configurable via `AI_CONTEXT_FEATURES_TOP_K`.
- Critère de spécificité par défaut envisagé : longueur du préfixe non-glob (decroissante), puis nombre de wildcards (croissant) en départage.
- Next : à reprendre dans un turn dédié pour passer en `status: active`, lire le code complet de `features-for-path.sh` + `_lib.sh`, arbitrer entre fix matcher A/B/C, implémenter ranking + acceptance, ajouter tests reproductibles.

## 2026-05-07 — correction post-review Codex
- Codex post-review du commit `736b5e0` : risque pointé sur le contrat exit code.
- Vérification factuelle :
  - [.claude/settings.json:26-35](.claude/settings.json:26) : PreToolUse Write|Edit|MultiEdit invoque `bash .ai/scripts/features-for-path.sh` avec timeout 3.
  - Consommateurs identifiés (5) : `aic.sh`, `auto-worklog-log.sh` (via `features_matching_path`), `measure-context-size.sh`, hook PreToolUse direct, hook PostToolUse via `auto-worklog-log.sh`.
  - Selon la doc Claude Code, un hook PreToolUse exit code 2 bloque l'opération. Sans clause explicite, l'auteur de l'implémentation pourrait choisir exit 2 sur pattern cassé et casser tous les hooks.
- Fix : ajout du **contrat dual exit code** dans la fiche.
  - Mode strict (CLI/doctor) : exit ≠ 0 autorisé, fail hard utile pour debug.
  - Mode hook (défaut) : warning stderr + exit 0 toujours. Un pattern cassé dans une fiche ne doit JAMAIS bloquer l'agent.
  - Détection : flag `--strict` ou env var `AI_CONTEXT_FEATURES_STRICT=1`.
- Sections impactées : Invariants, Comportement attendu (point 4), Contrats (nouvelle sous-section dual exit code), Historique.

## 2026-05-07 — re-review Codex : contrat à 4 niveaux
- Codex re-review du commit `84cfbe9` : contrat dual encore trop étroit, mélange `features-for-path.sh` et `_lib.sh::features_matching_path`. 5 consommateurs directs de la fonction (pas du script) confirmés en local : `auto-worklog-log.sh`, `check-feature-freshness.sh`, `pr-report.sh`, `review-delta.sh`, `features-for-path.sh` lui-même.
- Ambiguïté résiduelle : "CLI direct = strict" contredisait "défaut = best-effort".
- Fix : section "Contrats" reformulée en 4 niveaux explicites :
  - Niveau 1 : matcher `_lib.sh::features_matching_path` (fonction interne, ne décide pas de la politique exit).
  - Niveau 2 : wrapper `features-for-path.sh` (best-effort par défaut, strict opt-in via `--strict` ou env var).
  - Niveau 3 : hooks Claude (best-effort imposé, jamais `--strict`).
  - Niveau 4 : checks/CI/doctor (strict requis, passent explicitement `--strict`).
- Décision tranchée : `bash features-for-path.sh <path>` sans flag = best-effort. Pas d'auto-détection CLI/hook qui pourrait mal classer. Strict = opt-in pur.
- Question ouverte (à arbitrer en phase implement) : `review-delta.sh` reste-t-il en best-effort (compat utilisateur) ou bascule strict pour traçabilité ?

## 2026-05-07 — micro-fix Invariants + Niveau 1 (re-review Codex)
- Codex re-review du commit `f200018` : 2 incohérences résiduelles.
  1. Ligne Invariants disait "exit ≠ 0 en mode CLI/check" alors que le défaut CLI sans flag est best-effort. Contradiction avec lignes suivantes.
  2. Niveau 1 matcher disait "silent no-match par défaut" alors que le wrapper best-effort doit produire un warning. Si le matcher est silencieux, le wrapper ne peut pas warning sans dupliquer la détection.
- Corrections :
  - Invariants : "CLI/check" remplacé par "strict/check". Les 3 politiques (silent compat / warn+exit 0 / error+exit≠0) explicitement listées en référence aux Contrats.
  - Niveau 1 matcher reformulé : le matcher **expose** les patterns non supportés (via stderr ou variable de sortie) et **n'impose pas** de politique exit. 3 politiques disponibles aux callers : silent compat opt-in (`_FEATURES_MATCHING_SILENT=1`), warn+exit 0 (défaut), error+exit≠0 (via `_FEATURES_MATCHING_STRICT=1`).
  - Validation : ajout de 2 tests d'acceptance — best-effort (pattern non supporté observable sur stderr sans bloquer) et strict (erreur + exit ≠ 0 avec flag).
- Justification ajoutée : « la fonction seule ne décide pas de la politique exit, c'est le wrapper/caller qui le fait. Mais elle doit toujours rendre l'info disponible (sauf en mode silent explicite), sinon un wrapper best-effort ne peut pas afficher de warning sans dupliquer la détection. »

## 2026-05-06 23:55 — auto-progress
- Bascule phase : spec → implement (édits réels détectés sur 1 fichier(s))
- Annulable via /aic undo (snapshot dans .ai/.progress-history.jsonl)

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh

## 2026-05-07 00:04 — auto-progress
- Bascule phase : spec → implement (édits réels détectés sur 1 fichier(s))
- Annulable via /aic undo (snapshot dans .ai/.progress-history.jsonl)

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh

## 2026-05-07 00:11 — auto-progress
- Bascule phase : spec → implement (édits réels détectés sur 1 fichier(s))
- Annulable via /aic undo (snapshot dans .ai/.progress-history.jsonl)

## 2026-05-07 — cross-check Codex pre-implémentation (5 choix tranchés)
- Avant de coder, 5 choix + 2 questions ouvertes envoyés à Codex. Verdict initial : pas « go » tel quel, A/B/Q1 à durcir.
- **Choix 1 — Matcher** : Codex a rejeté A1. Bug critique : globs `*` en bash matchent `/` (`app/*/page.tsx` matchait `app/a/b/page.tsx`). A2 retenu : conversion glob → regex POSIX path-aware (`*` → `[^/]*`, `?` → `[^/]`, `**` → multi-segments comme segment complet, `[abc]` si bien formé, ancrage `^...$`).
- **Choix 2 — Whitelist B2 élargie** : exact file, dossier préfixe, `*`/`?`/`[abc]` intra-segment, `prefix/**`, `glob-prefix/**` (`aic-*/**`), `prefix/**/suffix`, `**/suffix`. Unsupported : `**` hors segment complet, bracket mal formé, chaînes non explicites.
- **Choix 3 — Ranking** : C3 + 3 précisions Codex : scorer par meilleur `touches:` matchant ; hiérarchie exact > dossier > glob ; tie-break `scope/id`. `**` plus général que `*`.
- **Choix 4 — Truncation** : D2 + précision : « N omises » dans additionalContext (sortie hook), pas stderr. Top-K sur matches directs ; depends_on bornés par budgets docs.
- **Choix 5 — Tests** : E1 + extension `tests/unit/test-path-matches-touch.sh` (existant) pour le no-overmatch. Cas minimum définis.
- **Q1 résolu** : policy unique `_FEATURES_MATCHING_POLICY=silent|warn|strict`. Défaut `warn`.
- **Q2 résolu** : `review-delta.sh` best-effort par défaut. Note ouverte sur Niveau 4 strict.
- Section Décisions de la fiche reformulée (commit `166a3de`).
- Next : implémenter dans un turn dédié — `path_matches_touch` regex path-aware, ranking dans `features-for-path.sh`, tests étendus, parité template.

## 2026-05-07 — implémentation livrée
- **Matcher A2** : `path_matches_touch` réécrit dans `_lib.sh`. 3 helpers internes ajoutés :
  - `_glob_pattern_supported` : whitelist B2 (vérifie `**` segment complet + brackets équilibrés).
  - `_glob_to_regex` : conversion glob path-aware → regex POSIX ancrée. `*` → `[^/]*`, `?` → `[^/]`, `/**/` → `(/[^/]+)*/`, `**/` en début → `([^/]+/)*`, `/**` en fin → `(/.*)?`, brackets conservés, métacaractères regex échappés.
  - Politique unique `_FEATURES_MATCHING_POLICY=silent|warn|strict`. Défaut `warn`.
- **Bug `*` qui matche `/` corrigé** : `app/*/page.tsx` ne matche plus `app/a/b/page.tsx`. Test no-overmatch dans `test-path-matches-touch.sh`.
- **Ranking** : `features-for-path.sh` étendu. Récupère matches via nouveau `features_matching_path_ranked` (4 colonnes scope/id/path/touch). Score chaque match via `_score_touch_pattern` (tier exact/dossier/glob, longueur préfixe non-glob, nb wildcards pondéré ** vs *). Tri stable scope/id, top-K (`AI_CONTEXT_FEATURES_TOP_K=3` par défaut) + ligne « N omises » dans la sortie principale.
- **Compat ascendante stricte** : `features_matching_path` à 3 colonnes inchangée. Les callers historiques (auto-worklog-log, check-feature-freshness, pr-report, review-delta) ne sont pas cassés.
- **Tests** :
  - `test-path-matches-touch.sh` : 20 cas existants + 8 nouveaux no-overmatch = 28 PASS.
  - `test-matcher-multi-level.sh` (nouveau) : 21 cas (ranking, whitelist B2, politiques silent/warn/strict, bracket mal formé) PASS.
- **Parité template** : `_lib.sh.jinja` + `features-for-path.sh.jinja`. Bug Jinja corrigé : tous les `${#var}` protégés par `{% raw %}` (sinon `{#` interprété comme début de commentaire Jinja, `Missing end of comment tag`).
- **Validation** : check-shims, check-features, check-dogfood-drift, smoke-test, 49 cas test unit ALL PASS.
- Phase bumpée implement → review.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/features-for-path.sh
