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
