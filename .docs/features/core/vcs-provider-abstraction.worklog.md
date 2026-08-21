# Worklog — core/vcs-provider-abstraction

## 2026-07-03 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : abstraction VCS Git / TFVC pour rendre ai_context compatible avec les projets TFS non-Git.

## 2026-07-03 — implementation provider
- Ajout de `.ai/scripts/_vcs.sh` et du miroir template pour abstraire `git`, `tfvc` et `none`.
- Branchement des scripts freshness, commit guard, review delta, pr-report, doctor, stop gate et surface `aic`.
- Ajout de `vcs.provider` dans la config source/template et dans Copier.
- Test unitaire `tests/unit/test-vcs-provider.sh` ajouté et branché dans le smoke.

## 2026-07-03 — HANDOFF cross-scope
- HANDOFF explicites ajoutés dans les worklogs des surfaces co-propriétaires touchées par freshness : `core/feature-index-cache`, `core/index-contract-v2`, `core/okf-strict-profile`, `core/aic-surface-canonical`, `quality/doc-freshness`, `quality/read-only-checks-contract`, `quality/pr-report`, `quality/doctor`, `quality/agent-config-validation`, `quality/review-delta-uncommitted-coverage`, `quality/features-for-path-ranking-and-matcher-correctness`, `quality/index-lock-contract`, `quality/targeted-regression-coverage`, `quality/smoke-test`, `workflow/auto-progress-file-filter`, `workflow/stop-turn-doc-gate`.
- Ces HANDOFFs documentent un impact partagé sans changer le statut ni le contrat propre de ces features.

## 2026-07-03 — préparation validation
- Intent : rendre le delta VCS cohérent avec le feature mesh avant gate.
- Fichiers/surfaces : runtime `.ai/scripts/*`, miroirs `template/.ai/scripts/*.jinja`, config Copier/runtime, README, tests unitaires et smoke.
- Décision : `README_AI_CONTEXT.md` et les tests touchés sont couverts directement par la fiche, car ils valident ou documentent le nouveau contrat VCS.
- Doc Impact Decision : C — nouveau contrat runtime, option Copier `vcs_provider`, comportement TFVC/pending changes documenté.
- Validation prévue : test provider VCS, tests build-index touchés, tests freshness/review/commit guard, drift dogfood, checks feature/freshness.
- Next : exécuter la gate et clôturer si tous les checks passent.

## 2026-07-03 — done
- Intent : clôture de `core/vcs-provider-abstraction`.
- Evidence : `bash tests/unit/test-vcs-provider.sh`, tests build-index ciblés, `test-check-commit-features-relevance`, `test-check-feature-freshness`, `test-review-delta-uncommitted`, `test-features-for-path-relevance-ranking`, `test-stop-hook-idempotence`, `test-auto-progress-filter`, `check-feature-docs --strict core/vcs-provider-abstraction`, `check-dogfood-drift`, `check-shims`, `check-agent-config`, `check-ai-references`, `check-features --no-write`, `check-feature-coverage`, `check-touches-breadth`, `measure-context-size`, `tests/smoke-test.sh` : PASS/OK.
- Risk ledger : pas de breaking change Git attendu ; pas de migration de données ; pas d'auth/data/UX ; nouveau contrat runtime `vcs.provider` documenté ; TFVC reste best-effort sur le parsing de `tf status`.
- Doc Impact Decision : C — fiche, worklog, README, config Copier et handoffs worklogs mis à jour.
- Next : commit `feat(core): abstraire le provider VCS`.
## 2026-07-03 — routage aic knowledge sans changement VCS

- Intent : tracer le changement de `aic.sh` imposé par `workflow/knowledge-publish-search-link`.
- Fichiers/surfaces : `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`.
- Décision : aucun comportement VCS modifié ; le wrapper route `knowledge` vers un script dédié, comme les autres sous-commandes.
- Validation : le test workflow passe via `aic.sh knowledge`; freshness stricte doit constater ce worklog core dans le delta.
- Next : aucune action VCS ; rouvrir seulement si les commandes knowledge doivent lire le provider VCS courant.

## 2026-07-06 — couverture incidente (workflow/codex-hooks-parity)
- Surfaces partagées touchées : header de `stop-doc-gate.sh` (+ miroir jinja) requalifié « protocole decision:block partagé Claude/Codex » (aucun changement de logique VCS) ; `copier.yml` (question enable_codex_hooks) ; `tests/smoke-test.sh` (étape [28d/28]). Aucun changement du contrat provider VCS.
- Validation portée par `workflow/codex-hooks-parity`.

## 2026-07-06 — couverture incidente (workflow/codex-hooks-parity, commit docs)
- `README_AI_CONTEXT.md` (+ miroir jinja) et `copier.yml` (`_message_after_copy`) : documentation des hooks Codex natifs opt-in. Aucun changement du contrat provider VCS.
- Validation portée par `workflow/codex-hooks-parity`.

## 2026-07-06 12:03 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh

## 2026-07-06 — couverture incidente (core/agents-md-shim-canonical, P2)
- Surfaces partagées touchées : `copier.yml` (question enable_copilot_shim) et `tests/smoke-test.sh` (étape [28e/28]). Aucun changement du contrat provider VCS. Validation portée par `core/agents-md-shim-canonical`.

## 2026-07-06 — couverture incidente (core/agents-md-shim-canonical, P2 commit ③)
- `copier.yml`, `tests/smoke-test.sh` (bloc [28b] cursor), `template/README_AI_CONTEXT.md.jinja` (ligne Cursor conditionnelle — le rendu minimal, sans cursor, est inchangé). Aucun changement du contrat provider VCS.

## 2026-07-06 15:08 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh

## 2026-07-06 — couverture incidente (core/agents-md-shim-canonical, fix post-review)
- `tests/smoke-test.sh` : étape [28f/28] anti dé-templatisation ajoutée. Aucun changement du contrat provider VCS. Validation portée par `core/agents-md-shim-canonical`.

## 2026-07-06 — couverture incidente (fix post-review ②, core/agents-md-shim-canonical)
- `tests/smoke-test.sh` : [28e] durci (answers file + chemin registre prouvé) et fuites temp corrigées. Aucun changement du contrat provider VCS.

## 2026-07-07 — couverture incidente (workflow/intentional-skills, P3)
- Les 6 wrappers Codex procéduraux `aic-feature-{new,done,handoff,resume,update}` et `aic-quality-gate` (racine `.agents/skills/` + miroirs `template/.agents/skills/`) sont supprimés — surface skills réduite (chantier P3). Aucun canal externe ne les référençait ; zéro perte de capacité (`.ai/workflows/*` reste la source canonique). `copier.yml` (message après copy) et `tests/smoke-test.sh` (étape [19/28], assertion d'absence) alignés. Aucun changement du contrat propre de cette fiche.
- Validation portée par `workflow/intentional-skills`.

## 2026-07-07 09:41 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh

## 2026-07-07 — requalification TFVC honnête (P5, commit ①)
- Intent : chantier P5 d'ANALYSE.md — le statut TFVC (option de premier niveau, zéro test e2e) devait être requalifié plutôt que laissé implicite ou l'option supprimée (contrainte non-négociable).
- Fichiers/surfaces : `copier.yml` (choices `vcs_provider` + `help`), `README_AI_CONTEXT.md` (+ miroir jinja) — mention explicite « best-effort, non testé end-to-end ». Fiche : nouveau risque assumé documenté.
- Décision : pas d'écriture de test e2e maintenant (nécessiterait un faux binaire `tf` exécutable depuis un scaffold Copier réel + reverse-engineering du contrat exact `tf status` — risque de test peu fiable plutôt qu'utile) ; honnêteté documentaire d'abord, test e2e en suivi si besoin réel confirmé.
- Validation : check-features/check-shims/check-dogfood-drift + smoke complet au commit.

## 2026-07-07 — audit 2026-07-07
- Intent : traiter les constats N2/CI/RUN liés aux surfaces VCS partagées.
- Changement : `_vcs.sh` mémoïse `vcs_provider`/`vcs_root` avec invalidation sur override/env ; `aic.sh` nettoie ses fichiers temporaires ; smoke-test ajoute des assertions audit/migrate négatives/idempotence et corrige le libellé de compte workflows.
- Surfaces incidentes : `_lib.sh`, `check-commit-features.sh`, `check-feature-freshness.sh`, tests unitaires/smoke déjà couverts par cette fiche.
- Validation ciblée : `test-vcs-provider`, `test-check-commit-features-relevance`, `test-check-feature-freshness`, `bash -n` des scripts modifiés.

## 2026-07-07 18:51 — auto
- Fichiers modifiés :
  - .ai/scripts/check-commit-features.sh
  - .ai/scripts/check-feature-freshness.sh
  - template/.ai/scripts/check-commit-features.sh.jinja
  - template/.ai/scripts/check-feature-freshness.sh.jinja
  - tests/unit/test-build-feature-index-fallback-frontmatter.sh
  - tests/unit/test-check-commit-features-relevance.sh
## 2026-07-17 — rollback VCS du cockpit de migration
- Les conseils de rollback de `core/migration-orchestrator` restent formulés en termes de revert du VCS, sans supposer Git dans le runtime.
- Les surfaces partagées `copier.yml` et `README_AI_CONTEXT.md` conservent les contrats provider existants ; aucun appel Git n'est ajouté au cockpit.

## 2026-07-24 — couverture incidente (pilotage P13)
- `README_AI_CONTEXT.md` (+ miroir template) reçoit un pointeur vers le nouveau `GLOSSARY.md`. Aucun changement du contrat provider VCS.

## 2026-07-24 — couverture incidente (pilotage P9b)
- `copier.yml` reçoit une entrée `_migrations` sans rapport avec le provider VCS (câblage d'une migration native `aic migrate plan`, lecture seule). Aucun changement du contrat provider. Détail dans `workflow/aic-release`.

## 2026-07-24 — couverture incidente (v1.0, retrait gemini)
- `README_AI_CONTEXT.md` (+ miroir template) : liste d'agents mise à jour. Aucun changement du contrat provider VCS.

## 2026-07-28 15:51 — auto
- Fichiers modifiés :
  - copier.yml

## 2026-07-24 — couverture incidente (v1.0, B9 clés context.*)
- `.ai/config.yml` (+ miroir template) : commentaires ajoutés sur la précédence de `context.show_statuses` / `context.default_focus`. La section `vcs.provider` est inchangée ; aucun impact sur le contrat provider VCS.

## 2026-07-24 — couverture incidente (v1.0, B8)
- `tests/unit/test-build-feature-index-contract.sh` : commentaire et messages d'échec du snapshot de clés reformulés (politique de bump). Aucun changement du contrat provider VCS.

## 2026-07-24 — v1.0 / B4+B6 : E2E TFVC + chemin d'upgrade (pilotage P16)
- **B4** : `tests/unit/test-tfvc-e2e.sh` créé — scaffold Copier `vcs_provider=tfvc` réel, faux `tf` piloté par un fichier de pending changes, puis 5 assertions : absence de `.githooks` (contrat de matrice), `doctor` PASS + provider détecté, `review` voit le pending change, freshness strict **BLOQUE** sur code couvert sans fiche, puis **PASSE** quand fiche+worklog sont dans le pending set. Branché en `[0s2b/28]`. Profil `tfvc` ajouté à RELEASE.md §2.
- **Vrai bug trouvé par ce test (fail-open du gate cœur)** : `_vcs_normalize_path` collapsait les slashes via `${path//\/\//\/}`, qui **insère un backslash littéral** au lieu de collapser (`/a/b//c` → `/a/b\/c`, vérifié en isolation). Conséquence en chaîne : relativisation échouée → chemin absolu → aucun `touches:` ne matche → `check-feature-freshness --staged --strict` **passait** au lieu de bloquer. Corrigé par un collapse `sed 's#//*#/#g'` (seule des 3 formes testées qui fonctionne). Régression verrouillée dans `test-vcs-provider.sh` (5 cas dont backslashes Windows), avec **vérification que le test échoue sur le code buggé** — sinon il ne discriminerait rien.
- **Second bug corrigé, dans mon propre test** : la boucle de cas était alimentée par un pipe (`printf | while`), donc exécutée en sous-shell — les incréments de `$failures` étaient perdus et le test affichait `FAIL` tout en sortant `0`. Passé en process substitution ; re-vérifié : exit 1 sur code buggé, exit 0 sur code corrigé.
- **B6** : vérifié que `copier update` refuse un workspace sans `.git` (« Updating is only supported in git-tracked subprojects »). Chemin retenu et **prouvé end-to-end** : copie Git jetable hors du workspace → `copier update` dans la copie → inspection du delta → `tf checkout` des fichiers → application par rsync. Résultat mesuré : `_commit` v0.14.0 → v0.14.0-34-g8caec18, code métier local préservé, 0 `.rej`, aucun `.git` dans le workspace, `check-shims`/`check-features` PASS. Documenté dans `docs/upgrading.md` § « Mettre à jour un workspace TFVC ».
- **B5 (validation réelle) requalifiée avec preuve** : le binaire `tf` (Team Explorer Everywhere 14.135, **locale FR**) et un workspace mappé existent sur la machine mainteneur, mais la collection exige des credentials interactifs — donc ni la CI ni un agent ne peut la valider. Étape mainteneur confirmée, pour une raison désormais vérifiée. **Risque nouveau consigné** : le parseur ne matche que des libellés anglais (`Local item:` etc.) alors que le client est en français — à vérifier lors de la validation mainteneur.

## 2026-07-24 — v1.0 / parseur tf status locale-agnostique
- Suite directe du risque consigné en B5 : le client mainteneur est en français, le parseur ne matchait que l'anglais. Sur un workspace FR réel : zéro pending change détecté → aucun `touches:` matché → gate de fraîcheur jamais bloquant. Même classe de fail-open que le bug de normalisation, déclenché par la locale.
- Décision : ne plus lire les libellés du tout. Règle structurelle — une ligne compte si la valeur après le premier `:` est un chemin absolu qui SE RELATIVISE sous la racine du workspace. Couvre toutes les locales sans les énumérer.
- Exclusions mécaniques vérifiées : chemins serveur `$/Projet/...`, valeurs non-chemin (`Change: edit`, `Verrou : aucun`, `Date : ...`), chemins hors workspace, plus support Windows (lettre de lecteur, backslashes) et slashes doublés.
- 3 fixtures ajoutées à `test-vcs-provider.sh` (EN, FR, faux-positifs), et **vérifié que l'implémentation EN-only fait échouer le cas FR** (exit 1) — sans quoi le test ne discriminerait rien.
- Non observable ici : la sortie FR réelle (collection protégée par credentials interactifs). Le risque est neutralisé par construction plutôt que par observation.
- Validation : test-vcs-provider PASS, test-tfvc-e2e PASS, miroir template aligné, dogfood-drift PASS.

## 2026-07-24 — couverture incidente (v1.0, requalification TFVC en doc)
- `README_AI_CONTEXT.md` (+ miroir), `copier.yml` (choix + help `vcs_provider`), `docs/variables.md` : l'aveu « best-effort, non testé end-to-end » est remplacé par l'état réel — couvert e2e en test, détection indépendante de la locale, validation serveur réel côté mainteneur, renvoi vers la procédure d'update workspace TFVC.

## 2026-08-07 14:27 — auto
- Fichiers modifiés :
  - README_AI_CONTEXT.md
  - copier.yml
  - template/README_AI_CONTEXT.md.jinja

## 2026-08-07 — remédiation couverture du test TFVC E2E
- `tests/unit/test-tfvc-e2e.sh` est ajouté au `touches:` de `core/vcs-provider-abstraction`, sa fiche propriétaire déjà citée dans le test et dans l'historique B4.
- Changement documentaire seulement ; aucune modification du provider ni du test.
- Validation : `check-feature-coverage.sh --strict` PASS, 114/114 tests rattachés et 0 orphelin.

## 2026-08-20 — impact core/feature-intent-retrieval

- Touchée seulement par le snapshot de clés de `tests/unit/test-build-feature-index-contract.sh`
  (ajout de `title` et `keywords` à l'index). Aucun impact sur l'abstraction VCS ; test PASS.

## 2026-08-21 — couverture incidente aide Copier Copilot

- `copier.yml` reformule `enable_copilot_shim` sans changer la question, son défaut, son prédicat ni aucune sélection de provider VCS.
- Validation : manifeste de surface et smoke Git/TFVC complet PASS.

## 2026-08-21 — HANDOFF portabilité du test d'index

- `tests/unit/test-build-feature-index-contract.sh`, partagé avec `core/index-contract-v2`, inverse l'ordre des variantes de `stat` afin d'obtenir un timestamp sur GNU/Linux comme sur BSD/macOS.
- Aucun comportement du provider VCS ni du contrat JSON ne change. La preuve finale est portée par le test ciblé local et la matrice CI Linux/macOS.
