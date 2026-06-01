# Worklog — quality/read-only-checks-contract

## 2026-05-14 — création

- Feature créée comme chantier technique P0 lié à `product/ai-context-stability-migration`.
- Scope : quality.
- Intent initial : rendre les checks et diagnostics non mutants par défaut, avec modes de réparation ou écriture explicites.
- HANDOFF product → quality : l'initiative produit chapeau délègue l'exécution du contrat read-only au scope quality.
- Blocker : dépend de `core/index-contract-v2` pour stabiliser la manière de lire ou reconstruire l'index.
- next : cartographier les scripts qui écrivent aujourd'hui, définir les modes read-only/repair, puis ajouter tests no-write.

## 2026-05-14 — implement / diagnostics quality non mutants

- `check-feature-freshness.sh`, `review-delta.sh` et `pr-report.sh` génèrent un index temporaire via stdout de `build-feature-index.sh` au lieu d'écrire `.ai/.feature-index.json`.
- `check-features.sh` expose `--no-write`; `doctor.sh` et le workflow `quality-gate` l'utilisent pour rester non mutants.
- Parité template appliquée pour les scripts et workflows concernés.
- Ajout de `tests/unit/test-read-only-checks-contract.sh`, qui vérifie l'absence de création `.ai/.feature-index.json` sur les commandes ciblées.
- Validations : `test-read-only-checks-contract` PASS, `test-check-feature-freshness` PASS, `test-review-delta-uncommitted` PASS, `test-review-delta-shared` PASS, `bash -n` PASS.
- next : traiter les scripts hors scope immédiat qui écrivent encore l'index (`check-feature-coverage`, `product-*`, hooks JIT) dans des features dédiées ou phases suivantes.

## 2026-05-14 — implement / coverage read-only

- `check-feature-coverage.sh` génère désormais un index temporaire et ne reconstruit plus `.ai/.feature-index.json` implicitement.
- Parité template appliquée.
- `tests/unit/test-read-only-checks-contract.sh` couvre maintenant `check-feature-coverage.sh`.
- Ajustement défensif côté `build-feature-index.sh` : un repo sans fiche feature produit un index vide valide sans parser un chemin vide.
- Validations : `test-read-only-checks-contract` PASS, `test-build-feature-index-contract` PASS, `check-feature-coverage` PASS, `check-features --no-write` PASS.
- Handoff quality -> product : le contrat read-only des scripts product est traité dans `product/product-portfolio-loop`, car cette feature possède déjà les scripts product et documente leur invariant read-only.
- CI : `ai-context-check.yml` runtime/template utilise `check-features.sh --no-write`; le workflow source lance aussi les tests read-only/index. Impact tracé dans `quality/ci-guard`.
- Documentation migration/downstream : `docs/upgrading.md`, `MIGRATION.md`, `CHANGELOG.md` et `README_AI_CONTEXT.md` expliquent `--no-write`, l'index temporaire et le rebuild explicite.
- next : relancer les validations documentaires et décider si la phase peut passer en review.

## 2026-05-14 — implement / surface aic read-only

- Suite à l'arbitrage AI Debate `0016`, ajout de `.ai/scripts/aic.sh` et de son template dans le périmètre de `quality/read-only-checks-contract`.
- `aic.sh status`, `ship`, `frame` et `diagnose` lisent désormais un index temporaire généré via stdout de `build-feature-index.sh` au lieu de reconstruire `.ai/.feature-index.json`.
- Les checks agrégés par `aic.sh status`, `repair` et `ship` appellent `check-features.sh --no-write`.
- `tests/unit/test-read-only-checks-contract.sh` vérifie l'absence de création `.ai/.feature-index.json` pour la surface publique `aic.sh`.
- next : relancer le test read-only, `bash -n` runtime/template, puis les checks feature/doc avant clôture.

## 2026-06-01 — fix test-infra : rsync + suite CI complète (audit U1/U2/U11)

- Les 4 tests unitaires qui clonaient le repo via `cp -R .` (copiait ~21 Mo de `.git` + socket fsmonitor) passent à `rsync -a --exclude=.git` (+ caches), alignés sur `check-dogfood-drift.sh` / `test-targeted-regressions.sh`.
- `test-review-delta-shared.sh` : cause réelle du timeout >120s = `review-delta.sh --staged` forke 2 jq par fichier untracked, or `git init` laissait tout l'arbre untracked ; fixture rebasée sur `git add -A` (base committée réaliste) → 14s.
- CI `ai-context-check.yml` : liste manuelle de 6 tests remplacée par une boucle `for t in tests/unit/*.sh` (couvre les 5 orphelins + tout futur test) ; triggers élargis à `tests/**`.
- Validation : 9 tests relancés sous guard timeout, tous PASS ; `check-feature-freshness --staged --strict` ; YAML workflow valide.
- Suivi : explosion O(fichiers) de `review-delta.sh` (2 jq/fichier untracked) = vrai durcissement perf à traiter dans le batch U7 (review-delta-uncommitted-coverage).

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - .github/workflows/ai-context-check.yml
  - tests/unit/test-check-feature-freshness.sh
  - tests/unit/test-dogfood-drift-extra.sh
  - tests/unit/test-project-overlay.sh
  - tests/unit/test-review-delta-shared.sh
  - tests/unit/test-targeted-regressions.sh

## 2026-06-01 14:22 — auto
- Fichiers modifiés :
  - .ai/scripts/review-delta.sh
  - template/.ai/scripts/review-delta.sh.jinja

## 2026-06-01 17:38 — auto
- Fichiers modifiés :
  - .github/workflows/ai-context-check.yml
  - CHANGELOG.md
  - template/.github/workflows/ai-context-check.yml.jinja

## 2026-06-01 — coverage : override projet drift-safe (audit U3)

- `check-feature-coverage.sh` (+ `.jinja`) lit `.ai/project/config.yml` s'il existe, sinon `.ai/config.yml`. `.ai/project/` est `_skip_if_exists` (copier) et ignoré par `check-dogfood-drift` → un repo dont le code ne vit pas sous `src/app/lib` (ex. ce template Bash) peut adapter ses roots de couverture sans diverger du template. Bénéficie aussi aux projets consommateurs (override per-projet).
- Repo dogfood : ajout de `.ai/project/config.yml` (roots `.ai/scripts`, `tests` ; ext `sh`). `check-feature-coverage` passe de **0 fichier scanné** (faux signal) à **50 scannés / 50 couverts / 0 orphelin**.
- Validation : coverage 50/50, `check-dogfood-drift` PASS (parité + `.ai/project` ignoré), `check-shims`/`check-ai-references` PASS.

## 2026-06-01 — fix pr-report read-only large diff

- `pr-report.sh` (+ `.jinja`) garde le contrat read-only : index temporaire hors repo, tables intermédiaires en `/tmp`, cleanup par trap.
- Correction du JSON vide pour éviter que les consommateurs read-only interprètent `[""]` comme un vrai résultat.
- Test ajouté dans `test-review-delta-shared.sh` sur le JSON `touches_shared`.

## 2026-06-01 22:26 — auto
- Fichiers modifiés :
  - .ai/scripts/pr-report.sh
  - template/.ai/scripts/pr-report.sh.jinja
  - tests/unit/test-pr-report-glob-match.sh
