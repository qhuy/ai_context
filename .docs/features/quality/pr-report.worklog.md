# Worklog — quality/pr-report


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - PROJECT_STATE.md
  - README.md
  - template/.ai/scripts/pr-report.sh.jinja
  - tests/smoke-test.sh

## 2026-04-28 11:38 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-04-28 11:57 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - PROJECT_STATE.md

## 2026-04-28 12:04 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - PROJECT_STATE.md
  - README.md
  - tests/smoke-test.sh

## 2026-04-28 12:16 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - PROJECT_STATE.md

## 2026-05-06 — retours review
- Intent : fiabiliser les rapports staged utilisés par `aic review` et `aic ship`.
- Fichiers/surfaces : `.ai/scripts/review-delta.sh`, `template/.ai/scripts/review-delta.sh.jinja`, `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`.
- Décision : remplacer le filtre staged `--diff-filter=AM` par une lecture sans renommage implicite pour exposer suppressions et chemins renommés.
- Validation : prévue via `review-delta --staged`, `aic ship` et checks qualité.

## 2026-05-07 — freshness
- Impact indirect : `review-delta.sh` (qui partage des helpers avec `pr-report.sh`) étendu pour couvrir le delta uncommitted. Aucun changement sur `pr-report.sh` lui-même.
- Validation associée : smoke-test PASS.

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - .ai/scripts/review-delta.sh
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - .ai/scripts/review-delta.sh
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-05-07 00:11 — auto
- Fichiers modifiés :
  - .ai/scripts/review-delta.sh
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-05-07 — freshness
- Impact indirect : refactor de `_lib.sh::path_matches_touch` (regex path-aware,
  no-overmatch) bénéficie à `pr-report.sh` qui utilise `features_matching_path`.
- Aucun changement sur `pr-report.sh` lui-même. Compat ascendante préservée.
- Validation : smoke-test PASS.

## 2026-05-14 — impact read-only-checks-contract

- `pr-report.sh` ne reconstruit plus `.ai/.feature-index.json` implicitement.
- Le rapport utilise un index temporaire hors repo et conserve ses formats `markdown` / `json`.
- Validation portée par `quality/read-only-checks-contract` : test no-write ciblé PASS.

## 2026-06-01 — fix fixture test review-delta (audit U1)

- `tests/unit/test-review-delta-shared.sh` (couvert par `touches: tests/unit/**`) : fixture rebasée sur `git add -A` pour éviter l'explosion O(fichiers) de `review-delta.sh --staged` sur un arbre untracked. Aucun changement de `pr-report.sh`.
- Validation : test PASS en 14s (était >120s timeout).

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - tests/unit/test-review-delta-shared.sh

## 2026-06-01 14:22 — auto
- Fichiers modifiés :
  - .ai/scripts/review-delta.sh
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-06-01 — fix perf/json pr-report

- `pr-report.sh` (+ `.jinja`) précharge les tables `touches` / `touches_shared` une seule fois depuis l'index temporaire, au lieu de rescanner l'index via `jq` pour chaque fichier du diff.
- Correction du contrat JSON : les tableaux vides sont sérialisés en `[]`, plus en `[""]`.
- `test-review-delta-shared.sh` couvre le cas `touches_shared` en JSON et vérifie l'absence de sentinelles vides.

## 2026-06-01 — fix sur-match fast-path matcher (audit du delta Codex)

- Le refacto perf de pr-report (fast-path `path_matches_touch_fast` évitant un fork jq par fichier) contenait un bug : `[[ "$touch" == */** ]]` **non quoté** → le `**` du motif matchait le `*` littéral, donc un touch en `dir/*` (ou `dir/*.ext`) était traité comme `dir/**` récursif et sur-matchait les chemins imbriqués / mauvaises extensions.
- Fix : quoter le suffixe → `[[ "$touch" == *'/**' ]]` et `${touch%'/**'}` (runtime + `.jinja`). Test différentiel fast-path vs canonique : 4 divergences → **0**.
- Régression ajoutée : `tests/unit/test-pr-report-glob-match.sh` (touch `src/*`, vérifie qu'un chemin imbriqué n'est PAS impacté, et qu'un enfant direct l'est). Dormant en pratique (aucune feature n'utilise `dir/*` aujourd'hui) mais verrouillé.
- Le fix JSON de Codex (sentinelles `[""]` → `[]`) est conservé tel quel (correct).

## 2026-06-01 22:26 — auto
- Fichiers modifiés :
  - .ai/scripts/pr-report.sh
  - template/.ai/scripts/pr-report.sh.jinja

## 2026-06-01 — review Codex : slash final dans le fast-path

- Fix : `path_matches_touch_fast` normalise les `touches:` sans glob avec `${touch%/}` pour préserver le contrat canonique `src/` = préfixe dossier.
- Régression ajoutée dans `test-pr-report-glob-match.sh` : `touches: src/` couvre bien un enfant direct et un chemin imbriqué, tandis que `src/*` reste limité à l'enfant direct.
- Parité runtime/template conservée.

## 2026-06-01 22:47 — auto
- Fichiers modifiés :
  - .ai/scripts/pr-report.sh
  - template/.ai/scripts/pr-report.sh.jinja

## 2026-06-01 — dédup matcher : pr-report consomme le canonique

- Retrait de `path_matches_touch_fast` (copie locale) ; le fast-path `dir/**` est désormais dans `_lib.sh::path_matches_touch`. `pr-report` garde son extraction de table touches en une passe, mais matche via le canonique. Plus de 2ᵉ implémentation à maintenir.

## 2026-06-01 — perf pr-report après dédup matcher

- Correction de la régression perf introduite par la dédup : le canonique court-circuite maintenant aussi les `touches:` sans glob (`src`, `src/`, fichiers exacts), au lieu de passer par `_glob_pattern_supported` pour chaque ligne de table.
- Objectif : conserver la source unique de vérité du matcher sans perdre le temps de réponse du rapport large.

## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/scripts/aic.sh.jinja
