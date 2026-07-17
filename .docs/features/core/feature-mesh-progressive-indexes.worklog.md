# Worklog — core/feature-mesh-progressive-indexes

## 2026-07-16 — création
- Feature créée via `.ai/workflows/feature-new.md` et `.ai/workflows/document-feature.md`.
- Scope : core.
- Intent initial : ajouter des index Markdown progressifs au feature mesh avec une migration Copier non cassante.
- Décisions : index générés et versionnés ; cache JSON conservé ; dry-run par défaut ; rollout `warn -> fail` sur deux versions ; refus d'écraser un index manuel.
- HANDOFF confirmés : quality pour les tests et l'enforcement ; workflow pour la compatibilité des hooks.
- Validation prévue : génération idempotente, tests Copier d'upgrade, dogfood drift, smoke-test et quality gate avant DONE.
- Next : centraliser la classification des documents réservés avant de créer le générateur Markdown.

## 2026-07-16 — validation initiale
- Validation : `build-feature-index.sh --write`, `check-features.sh`, `check-feature-docs.sh core/feature-mesh-progressive-indexes` et quality gate repo passent.
- Evidence : couverture stricte 95/95 fichiers, 0 orphelin ; freshness worktree OK ; `git diff --check` OK.
- Advisory non bloquant : `_lib.sh` et `build-feature-index.sh` restent des surfaces partagées par plusieurs features ; leur modification devra garder un delta ciblé.
- Doc impact : fiche et worklog uniquement à ce stade ; `MIGRATION.md`, `docs/upgrading.md` et `CHANGELOG.md` seront mis à jour pendant l'implémentation.

## 2026-07-16 12:08 — implement / démarrage vN
- L'utilisateur autorise l'implémentation de la navigation Markdown progressive et de sa migration Copier.
- Décision : livrer le mode vN warn-only ; rendre le comportement strict testable explicitement sans activer encore l'enforcement par défaut.
- blockers : aucun.
- next : centraliser la classification des documents réservés, puis construire le générateur et le contrôle de fraîcheur.

## 2026-07-16 12:28 — review / implémentation vN vérifiée
- Implémentation : classificateur central des documents réservés, générateur/migrateur transactionnel, check de fraîcheur warn-only, mode strict explicite, commande `aic`, miroirs Jinja et index dogfood.
- Migration Copier : aucune écriture sous le feature mesh pendant `copier update` ; dry-run puis `--apply` documentés dans le message post-update, `MIGRATION.md` et `docs/upgrading.md`.
- Tests unitaires : 45/45 scripts passent, dont `test-feature-markdown-indexes.sh` et la régression du consolidation nudge.
- Test d'intégration : `bash tests/smoke-test.sh` ✅, incluant l'upgrade v0.11 vers HEAD et la préservation d'une fiche project-owned.
- Alignement template : `bash .ai/scripts/check-dogfood-drift.sh` ✅ pour les profils minimal, fullstack-cursor et codex-hooks.
- Décision : le passage warn-only vers bloquant par défaut reste hors vN et devra être revalidé pour vN+1.
- blockers : aucun.
- next : régénérer les index après cette mise à jour documentaire, exécuter le quality gate, puis sceller la fiche si GO.

## 2026-07-16 15:29 — review / audit Claude remédié
- Source relue : mémoire Claude `codex-mesh-indexes-audit-findings.md`, puis vérification sur le delta avec `aic-review` ; verdict initial `blocked`.
- Majeurs corrigés : marqueur de propriété limité à la première ligne ; root/scope `index.md` ignorés comme artefacts réservés par le gate `feat:` sans pouvoir satisfaire l'obligation de fiche ; test discriminant de `feature_docs_newer_than`.
- Robustesse corrigée : index écrits en `0644`, temporaire atomique nettoyé, tabs encodés/normalisés, symlinks refusés, `docs_root` lexical ou physique hors repo refusé, clé auto-worklog stable avec préfixe `./`.
- Contrats alignés : `--apply` ne liste plus les index inchangés ; le dry-run couvre explicitement `delete` ; collision manuelle testée avec remédiation actionnable.
- Copier renforcé : second `--apply` vérifié sans diff, puis rollback `git revert` vérifié sans mutation de la fiche project-owned.
- Evidence : `bash tests/unit/test-feature-markdown-indexes.sh` ✅ ; 45/45 tests unitaires ✅ ; `bash tests/smoke-test.sh` ✅ ; `bash .ai/scripts/check-dogfood-drift.sh` ✅ ; couverture stricte 98/98 ✅ ; `git diff --check` ✅.
- Nuance audit : le strict non câblé par défaut en CI n'est pas un défaut vN ; l'enforcement reste volontairement différé à vN+1.
- Blocker restant : `check-feature-freshness.sh --worktree --strict` échoue sur des propriétaires historiques qui revendiquent les scripts partagés en `touches:` direct. La mémoire `signal-a-reclassify-before-dependent-commit.md` prescrit une reclassification séparée sous `quality/touches-breadth-guard`.
- HANDOFF proposé, non exécuté sans confirmation : `core -> quality/touches-breadth-guard`, avec impacts documentaires core/product/quality/workflow.
- next : obtenir la confirmation du HANDOFF transverse, reclasser les propriétaires non canoniques, puis relancer le gate strict et la clôture.

## 2026-07-16 15:46 — review / HANDOFF quality clôturé
- L'utilisateur confirme le HANDOFF `core -> quality/touches-breadth-guard` ; la fiche quality a été rouverte, la 4ᵉ vague appliquée, validée puis scellée DONE.
- Les consommateurs des surfaces partagées passent en `touches_shared:` ; les propriétaires directs de `_lib.sh`, `aic.sh`, hooks/checks/reminder/tests restent explicites. La co-propriété légitime de `build-feature-index.sh` est conservée.
- Validation : `check-feature-freshness.sh --worktree --strict` ✅ ; staging complet simulé via index Git alternatif ✅ ; `check-commit-features.sh` avec message `feat(core)` ✅ ; couverture 98/98 ✅.
- blockers : aucun.
- next : exécuter le quality gate final de `core/feature-mesh-progressive-indexes`, puis sceller DONE si GO.

## 2026-07-16 15:49 — DONE

### Evidence
- Build : `bash .ai/scripts/check-dogfood-drift.sh` ✅ ; `bash .ai/scripts/build-feature-index.sh --write` ✅
- Tests : suite unitaire 45/45 ✅ ; `bash tests/smoke-test.sh` ✅
- Gates : index Markdown strict ✅ ; freshness worktree strict ✅ ; staging complet simulé strict + gate `feat:` ✅ ; quality gate ✅
- Documentation : fiche, migration, upgrading, README, CHANGELOG et propriétaires cross-scope alignés ✅

### Résumé livré
- Navigation Markdown progressive racine → scopes → fiches, déterministe et versionnée, sans remplacer l'index JSON.
- Classification centrale des fiches canoniques et documents réservés partagée par scanners, migrateurs et hooks.
- Migration Copier non cassante : dry-run, `--apply`, warning vN, strict explicite, collision transactionnelle et rollback.
- Revue Claude/Codex remédiée et dette Signal A du delta nettoyée via HANDOFF quality confirmé.

### Commit suggéré
feat(core): ajouter les index Markdown progressifs

## 2026-07-17 — reprise après re-audit Claude
- Intent : prendre en compte uniquement les remarques encore valides du re-audit mémorisé par Claude.
- Review applicative : verdict `go avec réserves` ; aucun blocker, mais la couverture de trois sous-shells est trompeuse et deux cas limites portables restent à corriger.
- Fichiers/surfaces : `tests/unit/test-feature-markdown-indexes.sh`, `_lib.sh` et son miroir Jinja, `migrate-okf-indexes.sh` et son miroir Jinja, `CHANGELOG.md`, fiche et worklog.
- Décision : rouvrir la feature ; rendre chaque assertion des sous-shells discriminante, restaurer une comparaison mtime sub-seconde, compter les scopes sans interprétation d'antislash, puis couvrir les statuts dry-run et le scope symlinké.
- Validation prévue : test unitaire ciblé, mutation locale des régressions, parité runtime/template, suite unitaire, smoke Copier et quality gate.
- Next : appliquer les correctifs ciblés puis repasser le DONE-check.

## 2026-07-17 — DONE après re-audit Claude

### Corrections soldées
- Les assertions des sous-shells de classification, fraîcheur et gate `feat:` utilisent désormais des échecs explicites ; une assertion intermédiaire ne peut plus être neutralisée par une commande ultérieure réussie.
- `feature_docs_newer_than` utilise `find -newer` : la précision sub-seconde du filesystem est conservée sur Bash 3.2 sans lancer un processus par fiche.
- Le compteur de l'index racine compare les scopes en shell et n'interprète plus les antislashs via `awk -v`.
- Les tests couvrent le dry-run `unchanged`/`conflict`, un scope contenant un antislash et l'absence de traversée d'un répertoire de scope symlinké.
- Le CHANGELOG rend explicite le changement historique de classification ; la fiche énumère les cinq statuts de dry-run, dont `delete`.

### Evidence
- Test ciblé : `bash tests/unit/test-feature-markdown-indexes.sh` ✅.
- Suite unitaire : 45 scripts `tests/unit/test-*.sh` exécutés, aucun échec ✅.
- Intégration : `bash tests/smoke-test.sh` ✅, incluant l'upgrade Copier, l'idempotence et le rollback.
- Build/template : `bash .ai/scripts/check-dogfood-drift.sh` ✅.
- Gates : couverture stricte 98/98, freshness worktree strict, références AI, feature docs strict, index Markdown strict et `git diff --check` ✅.
- Review finale : `go`, aucun finding résiduel confirmé.

### Risk ledger
- Breaking : non ; les correctifs restaurent ou prouvent le contrat documenté.
- Migration de données / schéma : non ; le plan Copier opt-in reste inchangé.
- Sécurité / auth / tenancy : aucun impact.
- Compatibilité arrière : conservée, notamment Bash 3.2 et runtime/template.

### Doc Impact Decision
- **C — Fiche feature mise à jour** : précision du contrat dry-run, evidence du re-audit et historique de classification alignés avec le comportement livré.

### Commit suggéré
feat(core): ajouter les index Markdown progressifs
