# Worklog — quality/doctor


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - PROJECT_STATE.md
  - README.md
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
  - template/.ai/scripts/doctor.sh.jinja
  - tests/smoke-test.sh

## 2026-04-28 12:16 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - PROJECT_STATE.md

## 2026-05-12 — veille Claude/Codex
- Impact direct : `doctor` execute maintenant le check non destructif `check-agent-config.sh` avant les checks de references.
- Parite template : `template/.ai/scripts/doctor.sh.jinja` alignee.
- Validation : `bash .ai/scripts/doctor.sh` PASS.

## 2026-05-14 — impact read-only-checks-contract

- `doctor.sh` utilise désormais `check-features.sh --no-write` pour respecter son contrat non destructif.
- Le comportement strict/default reste inchangé côté verdict ; seul le rebuild implicite de `.ai/.feature-index.json` est supprimé.
- Validation portée par `quality/read-only-checks-contract`.

## 2026-07-03 — HANDOFF depuis core/vcs-provider-abstraction
- Surface partagée touchée : `doctor.sh` ajoute le diagnostic `vcs provider` et ne signale plus l'absence de Git comme anomalie quand `vcs.provider=tfvc`.
- Validation portée par `core/vcs-provider-abstraction`.

## 2026-07-03 — done
- Intent : clôturer `quality/doctor` après stabilisation du MVP Bash et validation provider VCS.
- Fichiers/surfaces : `.docs/features/quality/doctor.md`, `.docs/features/quality/doctor.worklog.md`.
- Décision : statut `done` ; l'extraction future vers une CLI `ai-context doctor --json/--strict` n'est pas un blocker de livraison.
- Validation : `bash .ai/scripts/doctor.sh` PASS ; `bash .ai/scripts/doctor.sh --strict` PASS ; `tests/smoke-test.sh` PASS deux fois dans la clôture `quality/smoke-test`.
- Next : aucune action immédiate.
