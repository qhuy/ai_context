# Worklog — quality/smoke-test


## 2026-04-24 14:10 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-04-24 18:27 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-04-28 12:04 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-05-04 — freshness
- Smoke-test étendu : vérifie la génération des skills Codex sous `.agents/skills/`.
- Validation associée : smoke-test complet PASS.
## 2026-05-05 — freshness
- Ajout d'un test `tests/unit/test-project-overlay.sh` et d'assertions smoke pour vérifier l'absence d'overlay par défaut et la présence de la section Project Overlay.
- Validation associée : `bash tests/smoke-test.sh` PASS.
