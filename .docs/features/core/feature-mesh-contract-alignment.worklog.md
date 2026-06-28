# Worklog — core/feature-mesh-contract-alignment

## 2026-05-14 — création

- Feature créée via `.ai/workflows/document-feature.md`.
- Scope : core.
- Intent initial : aligner le parser fallback sans `yq` sur les champs `product.portfolio.*` définis par le schema et consommés par les rapports product.
- HANDOFF product -> core : `product/product-portfolio-loop` consomme les champs portfolio, mais le contrat de parsing appartient au feature mesh et à l'index core.
- Validation prévue : test fallback sans `yq`, test contrat index, `check-features --no-write`, `check-feature-docs --strict`.
- next : implémenter le parser fallback ciblé et le test unitaire.

## 2026-05-14 — implement / fallback product portfolio

- `build-feature-index.sh` runtime/template extrait maintenant `product.portfolio.appetite`, `confidence`, `expected_impact`, `urgency` et `strategic_fit` en fallback sans `yq`.
- Ajout de `tests/unit/test-build-feature-index-fallback.sh`, qui masque `yq` via `PATH` tout en gardant `jq`.
- CI source : handoff vers `quality/ci-guard` pour lancer ce test dans `.github/workflows/ai-context-check.yml`.
- Documentation release : `CHANGELOG.md` mentionne l'amélioration du fallback.
- Validations : `test-build-feature-index-fallback` PASS, `test-build-feature-index-contract` PASS, `test-read-only-checks-contract` PASS, `test-product-reports-read-only` PASS, `check-features --no-write` PASS, `check-feature-docs --strict core/feature-mesh-contract-alignment` PASS, `check-ai-references` PASS, `check-dogfood-drift` PASS.
- next : revue du delta et décision sur `kill_criteria` ; non bloquant car aucun rapport ne le consomme aujourd'hui.

## 2026-06-19 15:14 — auto
- Fichiers modifiés :
  - CHANGELOG.md
## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - template/.ai/scripts/build-feature-index.sh.jinja

## 2026-06-26 15:48 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-06-26 — couverture incidente (core/feature-index-cache fix robustesse)
- Surface partagée touchée (build-feature-index.sh + jinja, tests, ou tests/smoke-test.sh) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-28 20:51 — auto
- Fichiers modifiés :
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
