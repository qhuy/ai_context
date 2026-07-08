---
pilot_id: "2026-07-07-audit-remediation"
status: "done"
source: "docs/audit/reports/AUDIT-2026-07-07.md"
scope_primary: "quality"
created_at: "2026-07-07"
updated_at: "2026-07-07"
active_item: "none"
active_question: "Cloture : second audit (Claude) traite (1 P0 + 3 P1 + 7 P2 + 1 P3 corriges, CI-6/CI-13 reportes) ; gates passantes."
next_hint: "Faire relire ce delta par Codex (prompt dedie fourni a l'utilisateur), puis proposer un commit francais si Codex confirme GO."
---

# Pilot 2026-07-07 — Remediation audit complet

## Intention

Traiter les findings de l'audit complet `ai_context` du 2026-07-07 sans créer une feature globale fourre-tout.

## Résultat attendu

- Les P1/P2 de l'audit sont corrigés ou explicitement convertis en décision documentée.
- Les P3 automatisables sont corrigés ; les P3 de décision sont documentés.
- Chaque changement reste rattaché à une fiche existante ou documente le handoff de scope.
- La quality gate de clôture passe, ou les risques résiduels sont nommés.

## Carte des sujets

| ID | Sujet | Statut | Scope probable | Route | Preuve attendue |
|---|---|---|---|---|---|
| CI-7 | Docs/freshness/coverage non bloquants en CI | validated | quality | fix | Workflow CI appelle les modes stricts ou documente les limites restantes |
| CI-8 | Quality gate DONE non représentée en CI | validated | quality | docs/fix | Frontière auto/humain explicite + checks automatisables branchés |
| DOC-A | CHANGELOG promet un `AGENTS.md.jinja` enrichi inexistant | validated | product | docs | CHANGELOG aligné avec shim réel |
| DOC-D | `vcs_provider` absent CHANGELOG/PROJECT_STATE | validated | product/core | docs | Questions Copier et docs mainteneur alignées |
| DOC-E | `PROJECT_STATE` périmé | validated | product/core | docs | Inventaire courant des skills/questions/chantiers |
| RUN-8 | Sous-système `knowledge` indécouvrable | validated | workflow/product | docs/feature | Pointeur canonique ou statut rétrogradé |
| RUN-6 | `project-guardrails` orphelin vis-a-vis de `aic-frame` | validated | workflow | docs/fix | Câblage documenté ou promesse retirée |
| SCR-2 | Classe glob contenant `/` sur-matche | validated | core/quality | fix | Test no-match + runtime/template corrigés |
| N1 | Fallback awk conserve les commentaires inline | validated | core | fix | Test fallback sans yq + runtime/template corrigés |
| SCR-5 | `auto-progress` lit TSV sans `IFS=$'\t'` | validated | workflow | fix | Test path avec espace + runtime/template corrigés |
| AGT-7 | Extraction commit live ne gère pas `-F`/`--message=` | validated | workflow | fix | Test PreToolUse JSON couvre les formes ajoutées |
| AGT-8 | Pre-commit re-stage les worklogs inconditionnellement | validated | workflow | docs/fix | Comportement corrigé ou documenté explicitement |
| CI-1 | Vrais hooks git peu exercés en smoke | validated | quality | fix | Smoke teste commit-msg réel et post-checkout |
| CI-10 | Test `copier update` skippable si tag absent | validated | quality | fix | Tags fetchés en CI + skip durci |
| CI-12 | Migration pruning shims non testée | validated | quality/core | fix | Smoke couvre le comportement update des shims retirés |
| P3-docs | Drifts doc P3 DOC-B/F/G/H/I/DOC-CI-1/RUN-F4/RUN-7/RUN-F7/RUN-10/AGT-N2 | validated | product/workflow/quality | docs | Docs alignées sur code courant |
| P3-code | Durcissements P3 SCR-1/SCR-4/SCR-6/N2/N3/N4/AGT-5/AGT-N1/MESH | validated | core/quality/workflow | fix/docs | Tests ou décisions explicites |
| CI-6/CI-13 | Couplage smoke↔copier (audit-features/migrate-features) non extrait ; liste hand-listée des étapes smoke sans garde d'exhaustivité | reported | quality | docs (reporté) | Décision de report documentée ci-dessous (retiré du lot P3-code après le second audit, qui l'avait trouvé marqué "validated" sans trace de traitement réelle) |

## Question active

Contexte affiché :

- L'utilisateur a donné un mandat autopilot pour traiter tous les points.
- Les changements ont été séquencés par scope primaire avec handoff transverse explicite.

Question à traiter maintenant :

- Aucune question bloquante ; faire relire le delta avant commit.

## Décisions actées

| Date | Item | Décision | Raison | Suite |
|---|---|---|---|---|
| 2026-07-07 | Tous | Autopilot accepté comme confirmation de traitement séquentiel multi-scope | Demande utilisateur explicite | HANDOFF à chaque changement de scope primaire |
| 2026-07-07 | `copier update` | Utiliser `--conflict=rej` dans la commande documentée et le smoke | Evite les marqueurs de conflit inline dans les scripts générés pendant update ; les conflits restent visibles en `.rej` | Auditer les `.rej` avant commit dans les projets consommateurs |
| 2026-07-07 | `check-shims` skills | Exiger les pairs `.agents/skills` ↔ `.claude/skills` uniquement quand les deux surfaces existent | Un projet Claude-only ne doit pas échouer parce que Codex n'a pas été sélectionné | Garder un test dédié pour Claude-only et Claude+Codex |
| 2026-07-07 | CI-6/CI-13 | Reporté, retiré du lot "validated" P3-code | Périmètre P3 de décision (durcissement test/CI, pas un correctif de contrat) ; le second audit (Claude) a trouvé ces deux IDs marqués "validated" sans aucune trace de traitement dans le delta — statut corrigé plutôt que le travail fait dans cette passe pour ne pas élargir le lot déjà volumineux | CI-6 : extraire les assertions `audit-features`/`migrate-features` de `tests/smoke-test.sh` vers des tests unitaires à fixtures locales. CI-13 : remplacer la liste hand-listée `[Na/28]` par une boucle sur les fichiers de test ou une garde d'exhaustivité. Traiter dans un futur tour dédié. |

## Handoffs

```text
HANDOFF
  from_scope: quality
  to_scope: core/workflow/product
  status: completed
  files_touched: [scripts runtime, templates Copier, git hooks, workflows CI, docs produit/workflow/quality, worklogs, tests]
  pending: []
  risks: [delta volumineux a relire par second agent avant commit]
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| SCR-2/N1/SCR-5/AGT-7 | Correctifs scripts + tests | Codex | done | tests unitaires ciblés + boucle unit complète |
| CI-7/CI-8/CI-1/CI-10/CI-12 | Durcissement CI/smoke | Codex | done | smoke complet + gates strictes locales |
| DOC/RUN | Alignements docs/discoverability | Codex | done | check-ai-references + checks docs |
| P3-code/P3-docs | Durcissements et décisions documentées | Codex | done | coverage stricte, dogfood drift, shellcheck runtime |
| CI-6/CI-13 | Retiré du lot "validated", reporté avec décision documentée | Claude (second audit) | done (décision) | ligne dédiée dans Carte des sujets + Décisions actées ci-dessus |

## Second audit (Claude, 2026-07-07) — findings et remédiation

Verdict initial : **NO-GO**. Toutes les commandes de référence passaient (exit 0), mais la revue de code (13 dimensions, chacune vérifiée de façon adversariale par un second agent qui a rejoué le code réel) a trouvé 1 régression **P0** et 3 **P1** que ces gates ne détectaient pas, plus 7 **P2** et 1 **P3**. Tous corrigés dans cette même passe, sauf CI-6/CI-13 (reportés, décision documentée ci-dessus) :

| Sévérité | Sujet | Fichier(s) | Fix |
|---|---|---|---|
| P0 | AGT-8 : le worklog n'était plus jamais re-stagé (condition `staged_before` structurellement toujours fausse pour le cas nominal) | `.githooks/pre-commit` (+ template) | Remplacé par `current_features` (clés dérivées des fichiers réellement stagés dans le commit) |
| P1 | AGT-7 : `--message=` testé avant `-m`, un `-m "..."` valide contenant `--message=` était mal-extrait et rejeté | `.ai/scripts/check-commit-features.sh` (+ template) | Réordonné `-m` avant `--message=` |
| P1 | CI-7/8 : `check-feature-docs.sh --strict` câblé hors du bloc `adoption_mode == 'strict'`, casse la CI par défaut sur toute fiche `draft` | `template/.github/workflows/ai-context-check.yml.jinja` | Aligné sur le traitement conditionnel de `check-feature-coverage` |
| P1 | Ce registre marquait CI-6/CI-13 "validated" sans trace de traitement | ce fichier | Statut corrigé (voir Carte des sujets + Décisions actées) |
| P2 | SCR-2 : le warning "pattern non supporté" était avalé (`2>/dev/null`) dans le seul gate branché sur le hook commit-msg | `.ai/scripts/check-feature-freshness.sh` (+ template) | Pattern capture-puis-replay repris de `features-for-path.sh` |
| P2 | N1 : test insuffisant sur la troncature quote+# (limite connue non verrouillée) | `.ai/scripts/build-feature-index.sh` + test | Limite documentée en commentaire + cas de test dédié |
| P2 | AGT-7 : couverture de test partielle (2/12 formes exercées) | `tests/unit/test-check-commit-features-relevance.sh` | Étendu à toutes les formes + régression P1 |
| P2 | CI-12 : pairing skills basé sur la présence disque, pas sur les agents sélectionnés (résidu de désélection non détecté) | `.ai/scripts/check-shims.sh` (+ template) | Gate sur `AGENTS_SELECTED` via nouveau helper `agent_selected()` |
| P2 | AGT-8 : en-têtes `.githooks/pre-commit`/`README.md` restés sur l'ancien comportement inconditionnel | `.githooks/pre-commit`, `.githooks/README.md` (+ templates) | Alignés sur le comportement réel |
| P2 | DOC-B : seul le volet SECURITY.md était corrigé, README.md/MIGRATION.md gardaient `--trust` sans justification | `README.md`, `MIGRATION.md` | `--trust` retiré (uniformisé avec SECURITY.md et le quickstart) |
| P3 | AGT-7 : forme collée `-Fmsg.txt` (sans espace, valide en git) non reconnue | `.ai/scripts/check-commit-features.sh` (+ template) | Branche `-F([^[:space:]...]+)` ajoutée |

Deux findings candidats supplémentaires ont été réfutés après vérification factuelle (couverture déjà assurée ailleurs / cause non liée à ce delta) — non listés ci-dessus.

## Validation de clôture

Première passe (Codex) :

- `bash tests/smoke-test.sh` : PASS.
- `for t in tests/unit/*.sh; do bash "$t"; done` : PASS.
- `bash .ai/scripts/check-feature-freshness.sh --worktree --strict` : PASS.
- `bash .ai/scripts/check-feature-docs.sh --strict` : PASS.
- `bash .ai/scripts/check-feature-coverage.sh --strict` : PASS, 94/94 fichiers couverts, 0 orphelin.
- `bash .ai/scripts/check-features.sh --no-write` : PASS.
- `bash .ai/scripts/check-agent-config.sh` : PASS.
- `bash .ai/scripts/check-ai-references.sh` : PASS.
- `bash .ai/scripts/check-shims.sh` : PASS.
- `bash .ai/scripts/check-dogfood-drift.sh` : PASS.
- `bash .ai/scripts/measure-context-size.sh` : OK.
- `git diff --check` : PASS.
- `shellcheck -S error` sur scripts runtime, hooks et tests modifiés : PASS.
- `bash tests/unit/test-template-jinja-raw-braces.sh` : PASS.
- Note : `shellcheck` direct sur templates `.jinja` bruts n'est pas pertinent quand ils contiennent `{% raw %}` ; la preuve template passe par les rendus Copier, le smoke et le test Jinja dédié.

Seconde passe (Claude, après remédiation du second audit ci-dessus — toutes ces commandes rejouées à nouveau sur l'état final) :

- `bash tests/smoke-test.sh` : PASS.
- `for t in tests/unit/*.sh; do bash "$t"; done` : PASS (aucun échec sur les 12 nouveaux/étendus cas de test).
- `bash .ai/scripts/check-feature-freshness.sh --worktree --strict` : PASS.
- `bash .ai/scripts/check-feature-docs.sh --strict` : PASS.
- `bash .ai/scripts/check-feature-coverage.sh --strict` : PASS, 95/95 fichiers couverts, 0 orphelin (95 = 94 + `tests/unit/test-freshness-unsupported-pattern-warning.sh`, nouveau, couvert par `quality/doc-freshness`).
- `bash .ai/scripts/check-features.sh --no-write` : PASS.
- `bash .ai/scripts/check-agent-config.sh` : PASS.
- `bash .ai/scripts/check-ai-references.sh` : PASS.
- `bash .ai/scripts/check-shims.sh` : PASS.
- `bash .ai/scripts/check-dogfood-drift.sh` : PASS.
- `git diff --check` : PASS.
- `shellcheck -S error` sur les 10 fichiers runtime/hooks/tests modifiés par cette seconde passe : PASS.
- Parité runtime/template revérifiée fichier par fichier (`diff`) sur chaque paire touchée : aucun écart hors variables Jinja attendues (`project_name`, `docs_root`, `agents`, `{% raw %}`, `scopes`).
- Rendu Copier réel (rsync du working tree, comme `tests/smoke-test.sh`) de `template/.github/workflows/ai-context-check.yml.jinja` en `adoption_mode=strict` ET `standard`, YAML validé (`yaml.safe_load`) dans les deux cas.
- Repro directe (hors suite de tests) du P0 AGT-8 confirmant la casse avant fix et la correction après fix.

## Next hint

Second audit (Claude) traité : 1 P0 + 3 P1 + 7 P2 + 1 P3 corrigés, CI-6/CI-13 reportés (décision documentée). Faire relire ce delta par Codex avant de proposer un commit français.
