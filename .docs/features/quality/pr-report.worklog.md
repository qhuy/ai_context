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
