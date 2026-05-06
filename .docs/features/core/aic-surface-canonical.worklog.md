# Worklog — core/aic-surface-canonical

## 2026-05-06 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : unifier la surface utilisateur canonique autour de `aic`

## 2026-05-06 — implementation
- Intent : migration breaking propre vers la surface `aic` sans alias legacy.
- Fichiers/surfaces : wrapper runtime/template `aic.sh`, README racine/downstream, message Copier, docs migration/update, smoke-test, fiches feature touchant l'ancien wrapper.
- Décision : `aic-document-feature` est expose comme intention officielle ; `diagnose` evite le faux positif `adr` sur `cadrage`.
- Validation : `bash -n`, `aic.sh --help`, `aic.sh frame`, `aic.sh diagnose`, `aic.sh document-feature`, `check-shims`, `check-ai-references`, `check-features`, `check-feature-docs core/aic-surface-canonical`, `check-feature-coverage`, `measure-context-size`, `tests/smoke-test.sh`.
- Next : relire le delta puis commit dedie du sous-chantier si le scope convient.

## 2026-05-06 — freshness README
- Intent : verifier que la réécriture README conserve la surface canonique `aic` sans réintroduire d'ancien alias public.
- Validation : `check-ai-references`, `check-feature-docs product/readme-positioning`.
