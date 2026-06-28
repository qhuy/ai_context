# Worklog — quality/targeted-regression-coverage

## 2026-05-12 — création

- Feature créée via `.ai/workflows/feature-new.md`.
- Scope : quality.
- Intent initial : Couverture ciblee des regressions critiques.

## 2026-05-12 — implementation

- Fichiers/surfaces : `tests/unit/test-targeted-regressions.sh`, `tests/smoke-test.sh`, `.ai/scripts/check-commit-features.sh`, `template/.ai/scripts/check-commit-features.sh.jinja`.
- Implementation :
  - ajout d'un test Q4 cible couvrant fallback sans `yq`, parsing commit heredoc/multiligne, timeout lock, drift `.jinja`, modes `standard`/`lite`/`strict` ;
  - branchement du test dans `tests/smoke-test.sh` ;
  - correction d'un bug revele : la detection heredoc doit preceder la capture generique `-m "..."`, sinon `$(cat <<'EOF'...)` est pris comme message invalide ;
  - parite runtime/template appliquee pour `check-commit-features.sh`.
- Decision Windows : hors support direct pour ces scripts shell ; compatibilite visee macOS/Linux Bash.
- Validation intermediaire : `bash tests/unit/test-targeted-regressions.sh` PASS ; `git diff --check` PASS.

## 2026-05-12 — done

- Statut : `done`.
- Evidence :
  - `bash tests/unit/test-targeted-regressions.sh` PASS ;
  - `bash tests/smoke-test.sh` PASS ;
  - `bash .ai/scripts/check-features.sh` PASS ;
  - `bash .ai/scripts/check-feature-docs.sh --strict quality/targeted-regression-coverage` PASS ;
  - `bash .ai/scripts/check-dogfood-drift.sh` PASS ;
  - `git diff --check` PASS.
- Résultat : Q4 couvre les regressions ciblees, corrige le parsing heredoc du guard commit et documente explicitement le support macOS/Linux Bash.
- Commit suggere : `feat(quality): couvrir les regressions ciblees`.

## 2026-05-12 — merge veille Claude/Codex

- Surfaces : `tests/smoke-test.sh`, `tests/unit/test-check-agent-config.sh`.
- Impact : resolution de merge conservant la suite Q4 et ajoutant le test agent-config sans modifier les assertions Q4.
- Validation : `tests/unit/test-targeted-regressions.sh`, `tests/unit/test-check-agent-config.sh` et smoke-test relances avant push main.

## 2026-06-01 — SKIP≠PASS sans copier + rsync (audit U11)

- `test-targeted-regressions.sh` : verdict final `⚠️ PARTIAL` au lieu de `✅ PASS` quand copier est absent (blocs drift .jinja + modes adoption non vérifiés) — supprime le faux sentiment de couverture en local.
- Validation : exécution locale (copier présent) PASS complet ; chemin PARTIAL relu.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/unit/test-check-feature-freshness.sh
  - tests/unit/test-dogfood-drift-extra.sh
  - tests/unit/test-project-overlay.sh
  - tests/unit/test-review-delta-shared.sh
  - tests/unit/test-targeted-regressions.sh

## 2026-06-01 — landing : tests de contrat ajoutés sous tests/unit/**

- Ajout des tests du contrat read-only/index portés par l'initiative stability-migration : `test-build-feature-index-contract.sh`, `test-build-feature-index-fallback.sh`, `test-read-only-checks-contract.sh`, `test-product-reports-read-only.sh` (couverts par `touches: tests/unit/**`).
- Aucun changement de logique de cette feature ; traçabilité du nouveau périmètre de tests.

## 2026-06-01 — régression ciblée pr-report JSON vide

- `tests/unit/test-review-delta-shared.sh` couvre désormais `pr-report --format=json` pour un diff uniquement relié par `touches_shared`.
- Cas verrouillé : tableaux vides attendus en `[]`, pas en `[""]`.

## 2026-06-01 22:26 — auto
- Fichiers modifiés :
  - tests/unit/test-pr-report-glob-match.sh

## 2026-06-19 12:39 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh

## 2026-06-19 14:09 — auto
- Fichiers modifiés :
  - tests/unit/test-project-overlay.sh

## 2026-06-19 14:24 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh
  - tests/unit/test-project-overlay.sh

## 2026-06-19 14:53 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-19 17:52 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
  - tests/unit/test-dogfood-update-preserves-frames.sh

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
  - .ai/scripts/build-feature-index.sh
  - tests/smoke-test.sh
  - tests/unit/test-build-feature-index-robust.sh
