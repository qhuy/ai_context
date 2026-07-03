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

## 2026-06-28 — couverture incidente (A1 : fix fallback build-feature-index)
- `build-feature-index.sh.jinja` touché via glob `touches:`. Aucun changement propre à cette feature. (Taxe sur-couverture `touches:` — cf. quality/touches-breadth-guard.)

## 2026-06-29 — couverture incidente (clôture A1 : résiduel fallback build-feature-index)
- `build-feature-index.sh` + `.jinja` touchés via glob `touches:` (bornage external_refs/product/progress du fallback). Le contrat JSON émis est inchangé : aucun champ ni sémantique modifié ; correction de fidélité du parseur fallback seulement. (Taxe sur-couverture `touches:` — cf. quality/touches-breadth-guard.)

## 2026-06-29 — schema_version operationnalise (C2c)
- test-build-feature-index-contract.sh : snapshot des cles emises (top-level/feature/progress) couple a schema_version. Changer une cle echoue tant que version+snapshot pas MAJ ensemble (incitation inversee).
- smoke : assertion schema_version relachee (presence+string), le pin de version vit dans le test de contrat.
- Verifs : contract test PASS, smoke PASS, trio build-index PASS.
- Reste C2 (hors scope, check-features.sh / feature-mesh) : C2a appliquer le schema, C2b reconcilier divergence id/depends_on.
- Fichiers : tests/unit/test-build-feature-index-contract.sh, tests/smoke-test.sh

## 2026-06-29 — C2a-doc : role du schema clarifie (closing)
- $comment ajoute dans feature.schema.json (runtime+template) : source d'enums + pattern id, PAS validateur full runtime. Pas de dependance ajv/check-jsonschema (ethos bash/jq/yq).
- Verifs : JSON valide, read_schema_enum ok, check-features PASS, drift aligne.
- Clot les 3 "contrats qui mentent" de l'audit (C2a-doc + C2b + C2c).
- Fichiers : .ai/schema/feature.schema.json, template/.ai/schema/feature.schema.json

## 2026-07-03 — HANDOFF depuis core/vcs-provider-abstraction
- Surface partagée touchée : `_lib.sh` source le provider VCS avec fallback Git. Aucun changement du contrat JSON `.ai/.feature-index.json`.
- Validation portée par `core/vcs-provider-abstraction` : tests provider et build/check feature index.

## 2026-07-03 — done
- Intent : clôture documentaire de `core/index-contract-v2`.
- Fichiers/surfaces : `.docs/features/core/index-contract-v2.md`, `.docs/features/core/index-contract-v2.worklog.md`.
- Décision : statut `done` ; le contrat v2 de l'index est livré avec stdout non-mutant, cache `--write` idempotent, format snapshoté par `schema_version`, et résiduels C2 clarifiés/routés.
- Doc Impact Decision : C — fiche feature et worklog mis à jour.
- Validation prévue : `check-feature-docs --strict core/index-contract-v2`, `test-build-feature-index-contract`, build index JSON, checks feature/freshness et gate ship avant commit.
- Next : aucune action immédiate ; rouvrir seulement si le format `.ai/.feature-index.json` ou `schema_version` change.
