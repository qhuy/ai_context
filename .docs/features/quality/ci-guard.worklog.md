# Worklog — quality/ci-guard

## 2026-07-07 — fix P1 : check-feature-docs --strict câblé hors du bloc adoption_mode=strict

- Constat (second audit du delta CI-7/CI-8 non commité) : `template/.github/workflows/ai-context-check.yml.jinja` câblait `check-feature-docs.sh --strict` (sans cible) hors du bloc `{%- if adoption_mode == 'strict' %}`, contrairement à `check-feature-coverage.sh --strict` correctement cantonné à ce bloc dans le même diff. Repro : une fiche `status: draft` avec sections encore vides (cas nominal d'une feature en cours, cf. AGENTS.md "fiche feature avant feat:") fait échouer `check-feature-docs.sh --strict` — donc la CI casse par défaut (`adoption_mode=standard`) au premier commit touchant des fiches feature, sans aucun avertissement dans `copier.yml`/CHANGELOG contrairement à `check-feature-coverage`.
- Fix : `template/.github/workflows/ai-context-check.yml.jinja` — `check-feature-docs.sh` (sans --strict) au step de base, `check-feature-docs.sh --strict` déplacé dans le bloc `{%- if adoption_mode == 'strict' %}`, symétrique à `check-feature-coverage`. `.ai/quality/QUALITY_GATE.md` (+ template) : ligne "Complétude fiche" alignée sur la formulation déjà utilisée pour "Couverture code→feature" (`adoption_mode=strict côté template`).
- Runtime `.github/workflows/ai-context-check.yml` (ce repo, dogfoodé en `adoption_mode=strict` permanent) inchangé à raison : les deux `--strict` inconditionnels y sont corrects, `check-dogfood-drift.sh` exclut explicitement ce fichier de la comparaison automatique (liste "source-only ignored").
- Validation : rendu Copier réel (rsync du working tree, comme `tests/smoke-test.sh`) en `adoption_mode=strict` → les deux `(strict)` présents et symétriques ; en `adoption_mode=standard` → aucun `--strict` sur check-feature-docs/coverage, YAML valide (`yaml.safe_load` PASS) dans les deux cas. `bash tests/smoke-test.sh` PASS.

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

## 2026-07-03 — A6 shellcheck hooks/tests
- Intent : fermer l'item A6 du frame de remédiation 2026-06-28 en lintant le code d'enforcement réel au-delà de `.ai/scripts/*.sh`.
- Fichiers/surfaces : `.github/workflows/ai-context-check.yml`, `.github/workflows/template-smoke-test.yml`, `template/.github/workflows/ai-context-check.yml.jinja`.
- Décision : utiliser `find` portable Linux/macOS pour collecter les hooks exécutables et `tests/**/*.sh`, au lieu de `globstar` qui n'est pas disponible sur le bash macOS 3.2.
- Validation : `shellcheck -S error` sur 83 fichiers collectés PASS ; YAML source OK ; `check-feature-docs --strict quality/ci-guard` PASS ; `check-features --no-write` PASS avec warnings OKF préexistants ; `check-feature-freshness --worktree --strict` OK ; `git diff --check` OK ; `check-dogfood-drift` PASS ; `tests/smoke-test.sh` PASS.
- Next : commit dédié A6, puis reprendre le frame de remédiation.

## 2026-07-03 — done
- Intent : clôturer `quality/ci-guard` après livraison A6 et revalidation du workflow source/template.
- Fichiers/surfaces : `.docs/features/quality/ci-guard.md`, `.docs/features/quality/ci-guard.worklog.md`.
- Décision : statut `done` ; la CI reste le filet d'enforcement au-dessus des hooks locaux, avec Windows best-effort.
- Validation : `shellcheck -S error` sur 90 fichiers collectés PASS ; YAML source chargé par `yaml.safe_load` ; `bash .ai/scripts/check-dogfood-drift.sh` PASS ; `bash .ai/scripts/check-feature-docs.sh --strict quality/ci-guard` PASS ; `bash .ai/scripts/check-feature-freshness.sh --worktree --strict` OK.
- Next : aucune action immédiate.
