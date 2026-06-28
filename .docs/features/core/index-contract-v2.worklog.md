# Worklog — core/index-contract-v2

## 2026-05-14 — création

- Feature créée comme chantier technique P0 lié à `product/ai-context-stability-migration`.
- Scope : core.
- Intent initial : stabiliser le contrat de `.ai/.feature-index.json`, son déterminisme, ses modes stdout/`--write`, et sa migration downstream.
- HANDOFF product → core : l'initiative produit chapeau délègue l'exécution technique du contrat d'index au scope core.
- next : trancher `generated_at`, tri stable, fallback sans `yq`, et tests de déterminisme avant modification runtime.

## 2026-05-14 — implement / tri stable + cache idempotent

- `build-feature-index.sh` et son template trient les fiches avant agrégation pour rendre l'ordre des features stable.
- `--write` compare la représentation contractuelle existante et nouvelle avec `del(.generated_at)` ; si elle est identique, le cache n'est pas réécrit.
- Ajout de `tests/unit/test-build-feature-index-contract.sh` pour couvrir stdout non mutant, ordre stable, stabilité contractuelle et réécriture après changement réel.
- Validation lancée : `bash tests/unit/test-build-feature-index-contract.sh` ✅ ; `bash .ai/scripts/build-feature-index.sh | jq -e ...` ✅ ; `bash .ai/scripts/check-feature-docs.sh core/index-contract-v2` ✅.
- next : cadrer les impacts consommateurs read-only et décider le niveau de support fallback sans `yq` pour les champs product/portfolio.

## 2026-05-14 — review / contrat index validé

- Ajustement complémentaire : un repo sans fiche feature produit un index vide valide, sans tentative de parser un chemin vide.
- Consommateurs branchés : les checks quality et product utilisent la sortie stdout temporaire au lieu d'écrire le cache.
- Validations : `test-build-feature-index-contract` PASS, `test-read-only-checks-contract` PASS, `test-product-reports-read-only` PASS, `check-features --no-write` PASS.
- Décision : le cache `.ai/.feature-index.json` reste utile pour hooks/performance, mais sa mise à jour est explicite.
- next : traiter le fallback produit/portfolio sans `yq` dans une feature séparée si l'audit de pertinence le confirme.

## 2026-06-01 22:47 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/schema/feature.schema.json
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/build-feature-index.sh.jinja

## 2026-06-26 11:17 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-06-26 — couverture incidente (core/feature-index-cache fix robustesse)
- Surface partagée touchée (build-feature-index.sh + jinja, tests, ou tests/smoke-test.sh) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-28 20:51 — auto
- Fichiers modifiés :
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
