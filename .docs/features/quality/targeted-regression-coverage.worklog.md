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
