# Worklog — core/migration-orchestrator

## 2026-07-17 — création
- Feature créée via `.ai/workflows/feature-new.md` après validation explicite.
- Scope : `core`.
- Intention initiale : fournir un cockpit read-only/apply pour les migrations post-Copier.
- Contrat retenu : `migrate plan`, `migrate all`, `migrate all --apply` ; aucun lancement automatique de Copier ou `aic-onboard`.
- Validation prévue : tests ciblés, parité runtime/template, dogfood drift, smoke Copier et quality gate.

## 2026-07-17 — correction du périmètre du batch
- Preuve : `bash .ai/scripts/aic.sh migrate plan` sur le dogfood propose d'ajouter `schema_version` aux 65 fiches canoniques via `migrate-features.sh`.
- Cause : la migration historique ajoute ce champ, mais `.docs/FEATURE_TEMPLATE.md` ne l'émet plus ; l'inclure créerait un état perpétuellement pending.
- Décision : `migrate all` orchestre uniquement `okf-type` puis `okf-indexes` ; `aic migrate` reste l'opt-in legacy compatible.

## 2026-07-17 — overlay config-only
- Preuve dogfood : `.ai/project/` contient uniquement `config.yml`.
- Alignement avec le contrat `aic-onboard` : cet état est un quasi no-op, pas une migration recommandée.
- Test ajouté pour distinguer absent, config-only, legacy et registre stampé.

## 2026-07-17 — implémentation core
- Ajout de `migrate-all.sh` et du miroir Copier, dispatch `aic migrate plan/all`, aide et message Copier.
- Préflight : `.rej`, métadonnées Copier, sorties des migrations actives, état overlay ; aucun appel à Copier ou aic-onboard.
- Apply : second préflight implicite dans le même run, `okf-type` puis `okf-indexes`, ensuite shims/features/indexes stricts.
- Tests ciblés : preview sans mutation, apply, idempotence, collision transactionnelle connue, overlay, arguments et parité template.

## 2026-07-17 18:23 — review / prêt pour clôture
- Implémentation runtime/template, documentation publique et message post-Copier terminés.
- Tests unitaires complets et smoke Copier 28/28 verts ; quality gate core verte.
- blockers : aucun
- next : vérifier les preuves de quality gate puis sceller la feature

## 2026-07-17 18:24 — DONE

### Evidence
- Build : `bash .ai/scripts/check-dogfood-drift.sh` ✅
- Statique : `shellcheck -S error .ai/scripts/migrate-all.sh .ai/scripts/aic.sh tests/unit/test-migration-orchestrator.sh` ✅
- Tests ciblés : `bash tests/unit/test-migration-orchestrator.sh` ✅ (7 scénarios)
- Tests unitaires : `for t in tests/unit/test-*.sh; do bash "$t" || exit 1; done` ✅
- Smoke Copier : `bash tests/smoke-test.sh` ✅ (28/28)
- Quality gate : shims, agents, références, features, docs strictes, couverture 100/100, freshness stricte et diff check ✅

### Résumé livré
- Cockpit read-only `aic migrate plan` et preview `aic migrate all`.
- Application explicite `aic migrate all --apply` avec préflight et validations post-migration.
- Migration legacy conservée hors batch ; `aic-onboard` reste une décision humaine séparée.
- Runtime dogfood, template Copier, documentation publique et tests maintenus en parité.

### Commit suggéré
`feat(core): orchestrer les migrations post-Copier`
