# Worklog — quality/ci-guard


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - .github/workflows/template-smoke-test.yml

## 2026-05-08 — couverture dogfood source
- Intent : eviter qu'un drift runtime dogfoode puisse passer hors CI source.
- Changement : `template-smoke-test.yml` se declenche aussi sur `.agents/**`, `.ai/**`, `.claude/**`, `.githooks/**`, `AGENTS.md`, `CLAUDE.md`, `README_AI_CONTEXT.md`, `.docs/FEATURE_TEMPLATE.md` et `tests/unit/**`.
- Ajout : etape explicite `bash .ai/scripts/check-dogfood-drift.sh` avant le smoke test.
- Validation : `check-dogfood-drift.sh` PASS local.

## 2026-05-12 — veille Claude/Codex
- Impact direct : le workflow CI source lance `bash .ai/scripts/check-agent-config.sh` avant le smoke-test.
- Parite template : `template/.github/workflows/ai-context-check.yml.jinja` alignee.
- Validation locale : `check-agent-config`, `doctor` et smoke-test PASS.

## 2026-05-14 — read-only CI

- Intent : aligner le workflow généré sur le contrat read-only des checks.
- Fichiers/surfaces : `.github/workflows/ai-context-check.yml`, `template/.github/workflows/ai-context-check.yml.jinja`.
- Décision : `check-features` est lancé avec `--no-write` en CI ; les rebuilds d'index restent explicites hors gate.
- Couverture : ajout des tests `test-build-feature-index-contract`, `test-read-only-checks-contract` et `test-product-reports-read-only` au workflow source. Le workflow template reste limité aux commandes rendues dans les projets downstream.
- Validation : à relancer via les tests unitaires ciblés, `check-features --no-write`, `check-feature-docs quality/ci-guard` et contrôle dogfood.

## 2026-05-14 — handoff core / index fallback

- HANDOFF core -> quality : `core/feature-mesh-contract-alignment` ajoute `test-build-feature-index-fallback`.
- Impact CI source : le workflow lance maintenant ce test après `test-build-feature-index-contract`.
- Le workflow template reste inchangé : les tests unitaires source ne sont pas rendus dans les projets downstream.
- Validation : `test-build-feature-index-fallback` PASS et `check-feature-docs quality/ci-guard` PASS avec warnings historiques.

## 2026-06-01 — suite unitaire complète en CI (audit U2)

- `ai-context-check.yml` : la liste manuelle de 6 tests unitaires (qui laissait 5 orphelins jamais exécutés en CI) est remplacée par une boucle `for t in tests/unit/*.sh`. Tout futur test est désormais couvert sans édition du YAML.
- Triggers `push`/`pull_request` élargis à `tests/**` (+ le workflow lui-même) : une PR ne modifiant que des tests déclenche désormais ce workflow.
- Les tests dépendant de copier (drift, overlay, regressions) se court-circuitent proprement quand copier est absent — ce workflow ne l'installe pas (couverture complète via le smoke).
- Validation : YAML chargé (yaml.safe_load) ; 5 orphelins relancés localement, PASS.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - .github/workflows/ai-context-check.yml

## 2026-06-01 — intégrité supply-chain du binaire yq (audit U6)

- Les 3 workflows (`ai-context-check.yml`, `template-smoke-test.yml`, et le template `.jinja` livré aux consommateurs) téléchargeaient yq v4.44.3 puis `chmod +x` sans vérification d'intégrité.
- Ajout d'une vérification sha256 épinglée (checksums officiels mikefarah/yq v4.44.3) entre download et chmod : Linux via `sha256sum -c`, macOS via `shasum -a 256 -c` (hash par arch arm64/amd64). Un asset corrompu ou substitué fait échouer le job.
- Hashes vérifiés contre les vrais binaires : linux_amd64, darwin_arm64, darwin_amd64 → match exact. Template rendu OK (la CI générée hérite du checksum).
- NB : à mettre à jour si `YQ_VERSION` change (les 3 hashes sont liés à v4.44.3).
