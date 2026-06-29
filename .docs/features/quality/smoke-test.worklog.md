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

## 2026-05-06 — update
- Étape [19/28] étendue pour vérifier `aic-document-feature` côté Claude/Codex et le workflow interne `document-feature`.
- Validation prévue : `bash tests/smoke-test.sh`.
## 2026-05-06 — freshness
- Intent : documenter les assertions smoke ajoutées pour `aic.sh` et l'absence de l'ancien wrapper rendu.
- Validation : `bash tests/smoke-test.sh` PASS.

## 2026-05-07 — freshness
- Impact indirect : ajout d'un nouveau test unit `tests/unit/test-review-delta-uncommitted.sh` autonome (livraison `quality/review-delta-uncommitted-coverage`). Aucun changement sur `tests/smoke-test.sh` ni sur la matrice smoke.
- Validation associée : smoke-test PASS et nouveau test unit PASS.

## 2026-05-06 23:57 — auto
- Fichiers modifiés :
  - tests/unit/test-review-delta-uncommitted.sh

## 2026-05-07 00:06 — auto
- Fichiers modifiés :
  - tests/unit/test-review-delta-uncommitted.sh

## 2026-05-07 — freshness
- Impact indirect : ajout d'un nouveau test unit `tests/unit/test-matcher-multi-level.sh` autonome (livraison Phase 2 #2). Extension de `test-path-matches-touch.sh` (8 cas no-overmatch ajoutés).
- Aucun changement sur `tests/smoke-test.sh` ni sur la matrice smoke.
- Validation associée : 49 cas test unit PASS, smoke-test PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - tests/unit/test-matcher-multi-level.sh
  - tests/unit/test-path-matches-touch.sh

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - tests/unit/test-matcher-multi-level.sh

## 2026-05-07 01:16 — auto
- Fichiers modifiés :
  - tests/unit/test-matcher-multi-level.sh

## 2026-05-07 — freshness
- Impact indirect : ajout d'un nouveau test unit autonome `tests/unit/test-context-relevance.sh` (livraison Phase 2 #3). Aucune modif sur la matrice smoke.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - tests/unit/test-context-relevance.sh

## 2026-05-07 14:45 — auto
- Fichiers modifiés :
  - tests/unit/test-context-relevance.sh

## 2026-05-07 14:53 — auto
- Fichiers modifiés :
  - tests/unit/test-context-relevance.sh

## 2026-05-07 — freshness
- Impact indirect : nouveau test unit autonome `tests/unit/test-auto-progress-filter.sh` (livraison Phase 2 #4). Aucune modif sur `tests/smoke-test.sh`.

## 2026-05-07 17:33 — auto
- Fichiers modifiés :
  - tests/unit/test-auto-progress-filter.sh

## 2026-05-07 18:04 — auto
- Fichiers modifiés :
  - tests/unit/test-auto-progress-filter.sh

## 2026-05-07 — freshness
- Impact indirect : ajout d'un nouveau test unit autonome `tests/unit/test-stop-hook-idempotence.sh` (livraison Phase 2 #5). Aucune modif `tests/smoke-test.sh`.

## 2026-05-12 — impact partagé contrat lock index

- Fichiers/surfaces : `tests/smoke-test.sh`.
- Contexte : `quality/index-lock-contract` ajoute un cas `[9b/28]` prouvant qu'un timeout de lock n'execute pas la commande protegee.
- Impact : le smoke test couvre explicitement la regression du fallback sans verrou.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — impact Q4 régressions ciblées

- Surfaces : `tests/smoke-test.sh`, `tests/unit/test-targeted-regressions.sh`.
- Impact : ajout d'une suite unitaire ciblee branchee dans le smoke pour isoler les regressions Q4 avant le parcours bout-en-bout.
- Validation : `bash tests/unit/test-targeted-regressions.sh` PASS ; `bash tests/smoke-test.sh` PASS.

## 2026-05-12 — agent-config unit dans smoke
- Impact direct : `tests/smoke-test.sh` lance désormais `tests/unit/test-check-agent-config.sh` en étape `[0h/28]`.
- Changement porté par `quality/agent-config-validation`.
- Validation : `tests/smoke-test.sh` PASS.

## 2026-06-01 — clones de tests en rsync (audit U1)

- Les tests unitaires joués en prélude du smoke ([0c]–[0g]) ne clonent plus via `cp -R .` (copiait `.git`) : passage à `rsync --exclude=.git`. Comportement asserté inchangé.
- Aucune modification de `tests/smoke-test.sh` lui-même.
- Validation : tests prélude relancés individuellement, PASS.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - tests/unit/test-check-feature-freshness.sh
  - tests/unit/test-dogfood-drift-extra.sh
  - tests/unit/test-project-overlay.sh
  - tests/unit/test-review-delta-shared.sh
  - tests/unit/test-targeted-regressions.sh

## 2026-06-01 — test unitaire pr-report JSON

- `tests/unit/test-review-delta-shared.sh` ajoute une assertion JSON pr-report ; le smoke couvre ce test via son prélude unitaire.
- Aucun changement du script smoke lui-même.

## 2026-06-01 22:26 — auto
- Fichiers modifiés :
  - tests/unit/test-pr-report-glob-match.sh

## 2026-06-19 14:09 — auto
- Fichiers modifiés :
  - tests/unit/test-project-overlay.sh

## 2026-06-19 14:24 — auto
- Fichiers modifiés :
  - tests/unit/test-project-overlay.sh

## 2026-06-19 14:53 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-19 17:52 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
  - tests/unit/test-dogfood-update-preserves-frames.sh

## 2026-06-19 — [28c] tolère le crash de cleanup Copier (py3.14)
- Symptôme : smoke rouge à [28c] — `copier update` sort non-zéro car Copier 9.14.3 + Python 3.14 crashe dans `_cleanup` (rmtree du clone temp `.git/objects`, OSError Directory not empty). L'update est pourtant appliqué.
- Fix : tolérer uniquement cette signature (« Updating to template version » + `_cleanup`/`Directory not empty`/`copier._vcs.clone`) ; tout autre échec reste bloquant. Assertions d'outcome inchangées (verdict réel).
- Vérif : signature confrontée à un log de crash réel (match ✅) ; smoke complet PASS ; CI non concernée (pas de copier, pas de smoke en CI).
- Origine : task_0a39c907, découvert pendant le fix dogfood-update.

## 2026-06-19 18:03 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
## 2026-06-26 11:34 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
  - tests/unit/test-read-only-checks-contract.sh
  - tests/unit/test-stop-turn-doc-gate.sh

## 2026-06-26 11:43 — auto
- Fichiers modifiés :
  - tests/unit/test-stop-turn-doc-gate.sh

## 2026-06-26 — couverture incidente (workflow/auto-worklog fix churn date)
- Surface partagée touchée (tests/smoke-test.sh, gabarit flush, ou tests/unit) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-26 16:56 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
  - tests/unit/test-auto-worklog-flush.sh

## 2026-06-26 17:25 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
  - tests/unit/test-fiche-consolidation-nudge.sh

## 2026-06-28 20:34 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
  - tests/unit/test-check-touches-breadth.sh

## 2026-06-26 — couverture incidente (core/feature-index-cache fix robustesse)
- Surface partagée touchée (build-feature-index.sh + jinja, tests, ou tests/smoke-test.sh) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-28 20:51 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
  - tests/unit/test-build-feature-index-robust.sh

## 2026-06-28 — couverture incidente (A1 : fix fallback build-feature-index)
- Surface partagée touchée (`tests/unit/**` ou `build-feature-index.sh.jinja`) via glob `touches:`. Aucun changement de comportement propre à cette feature. (Taxe de sur-couverture `touches:` — cf. quality/touches-breadth-guard.)

## 2026-06-29 — assertion schema_version relachee (C2c)
- L'etape index schema_version du smoke verifie desormais la presence+type (string) au lieu de pinner "1". Le pin de version vit dans test-build-feature-index-contract.sh.

## 2026-06-29 — branchement tests P0 audit hebdo
- Ajout des etapes unitaires `test-check-features-frontmatter-boundary.sh` et `test-check-commit-features-relevance.sh` en prelude du smoke.

## 2026-06-29 — branchement test YAML strict (finding #3)
- Ajout de l'étape `[0p]` : `test-check-features-yaml-strict.sh` (le gate `check-features` bloque une fiche au frontmatter YAML invalide). HANDOFF depuis `core/feature-mesh`.
