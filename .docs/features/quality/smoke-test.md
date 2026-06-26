---
id: smoke-test
scope: quality
title: Smoke-test end-to-end (28 assertions)
status: active
depends_on:
  - core/template-engine
  - core/feature-mesh
  - workflow/git-hooks
touches:
  - tests/**
progress:
  phase: review
  step: "smoke couvre Pack A lean et exclusions Codex"
  blockers: []
  resume_hint: "relancer tests/smoke-test.sh après toute évolution du Pack A ou de check-shims"
  updated: 2026-06-26
type: feature
---

# Smoke-test

## Résumé

Un script end-to-end (`tests/smoke-test.sh`, 28 assertions) qui scaffolde un projet jetable via Copier et exerce toute la chaîne du framework — des shims au commit-msg Conventional. Sert de filet anti-régression unique rejoué localement et en CI à chaque évolution du Pack A ou des scripts runtime.

## Objectif

Vérifier en un script que la chaîne complète tient : `copier copy` → check-shims → check-features → reminder text+json → commit-msg Conventional → features-for-path → cycles → coverage → focus graph → i18n → auto-worklog.

## Périmètre

### Inclus

- Le script orchestrateur `tests/smoke-test.sh` et ses 28 assertions end-to-end, plus les tests ciblés sur le matching `touches:` (`path_matches_touch` dans `_lib.sh`) et le rendu `docs_root=docs`.
- L'enchaînement réel des scripts générés sur un scaffold jetable dans `/tmp` : shims, mesh, reminder text+json, commit-msg, features-for-path, cycles, coverage, focus graph, i18n, auto-worklog.
- La couverture des variantes de rendu Copier : profils `tech_profile` (`dotnet-clean-cqrs`, `react-next`, `fullstack-dotnet-react`), `adoption_mode` (`lite`/`strict`), squelettes DS et budget Pack A lean.

### Hors périmètre

- La logique interne de chaque check (portée par leurs propres features : `doctor`, `cycle-detection`, `doc-freshness`…) ; le smoke ne fige que leur comportement observable depuis un scaffold.
- L'exécution en CI elle-même (orchestrée par `quality/ci-guard`) ; le smoke fournit l'assertion, pas le workflow.
- L'enforcement local des hooks (couvert par `workflow/git-hooks`).

## Invariants

- Idempotent : deux lancements consécutifs passent sans nettoyage manuel intermédiaire.
- Exit non-zéro à la première assertion qui casse ; aucune étape suivante n'est masquée par `|| true`.
- Compatible macOS bash 3.2 et Linux bash 5.x (interdit notamment `mapfile` dans les scripts générés vérifiés).
- Toujours exécuté sur un projet jetable sous `/tmp` rendu par Copier, jamais contre le workspace en place.

## Comportement attendu

- Lancement local : `bash tests/smoke-test.sh`.
- 28 étapes, exit non-zéro à la première qui casse.
- Crée un projet jetable dans `/tmp`, applique le template, exerce les scripts.

## Contrats

- Couverture : end-to-end + tests ciblés sur le matching `touches:` dans `_lib.sh` et `docs_root=docs`.
- Idempotent : 2 lancements consécutifs sans nettoyage manuel.
- Exécutable sur macOS bash 3.2 et Linux bash 5.x.

## Décisions

- Un **script monolithique** plutôt qu'une suite éclatée : une seule commande figeant toute la chaîne, exit à la première casse pour un diagnostic CI clair.
- Le scaffold se fait sur une **copie temporaire du workspace courant** dans `/tmp` : on teste le template réellement rendu par Copier, pas une fixture figée qui dériverait.
- Les **modules conditionnels** (`tech_profile`, `adoption_mode`, squelettes DS, Pack A lean) sont couverts par des assertions dédiées dans `[28/28]` et `[19/28]` plutôt que par des fiches isolées, pour fixer en un point les rendus générés/exclus.
- L'assertion `check-feature-docs.sh` couvre le **gradient warning → strict** : warning non bloquant sur legacy, `--strict` bloquant sur section manquante, puis PASS strict sur le noyau minimal — pour verrouiller le contrat de cette CLI sans casser les projets existants.

## Validation

- `bash tests/smoke-test.sh` en local : les 28 étapes passent, et un second lancement confirme l'idempotence.
- Rejeu automatique en CI via `quality/ci-guard` (repo template uniquement) sur `push`/`pull_request`.
- Tests ciblés inclus dans le script : `path_matches_touch` (matching exact, dossier, glob `**`, faux positifs proches) et rendu `docs_root=docs` (`check-features`, `features-for-path`, index JSON).
- Garde de compatibilité Bash 3.2 vérifiée sur les scripts générés (ex. absence de `mapfile` dans `pr-report.sh`).

## Cross-refs

Rejoué automatiquement par `ci-guard` sur push/PR.

## Historique / décisions

- 2026-05-03 : ajout des tests unitaires `[0c]` et `[0d]` dans le smoke-test : freshness multi-feature et drift dogfood destination-only.
- 2026-05-03 : ajout du test unitaire `[0e]` pour vérifier que `touches_shared` ne bloque pas `check-feature-freshness --staged` mais reste visible dans `review-delta.sh`.
- 2026-05-03 : l'assertion skills attend désormais les skills intentionnels `/aic-frame`, `/aic-status`, `/aic-review`, `/aic-ship` en plus des primitives historiques conservées.
- 2026-05-03 : l'assertion skills vérifiait alors 6 skills Claude publics et 8 workflows internes `.ai/workflows/`, et bloquait la réapparition des anciens skills procéduraux exposés.
- 2026-05-06 : l'assertion skills vérifie aussi `/aic-document-feature` côté Claude/Codex et le neuvième workflow interne `document-feature`.
- 2026-05-03 : étape `[7/28]` enrichie pour vérifier que le hook `features-for-path` injecte la fiche directe et une fiche `depends_on`, pas seulement la liste des features.
- 2026-05-03 : smoke-test enrichi pour figer l'UX `ai-context.sh status` (prochaine action minimale) et `ai-context.sh brief <path>` (contexte feature exposé hors hooks Claude).
- 2026-05-03 : smoke-test enrichi pour figer `ai-context.sh mission`, `repair`, `document-delta` et `ship-report` sur un scaffold sans git actif, afin de garantir une UX Codex/Claude utilisable dès le bootstrap.
- 2026-05-03 : smoke-test enrichi pour rendre depuis une copie temporaire du workspace courant, couvrir le scope `product`, `check-product-links`, `product-status`, `product-portfolio`, `product-review` et l'indexation `product.initiative`.
- 2026-05-04 : smoke-test enrichi pour couvrir `ai-context.sh first-run` et éviter la régression où `mission "roadmap produit"` était classé `front` à cause du motif `ui` dans `produit`.
- 2026-05-04 : smoke-test enrichi pour couvrir `ai-context.sh repair-copier-metadata` et `template-diff`, afin de figer la réparation de `.copier-answers.yml` et la preview externe du template.
- 2026-05-04 : étape [19/28] remplacée côté contexte par une assertion Pack A lean : présence de `.ai/context-ignore.md`, budget Pack A, absence de quality gate / `.ai/agent/*` / skills / listings obligatoires dans Pack A.
- 2026-05-04 : ajout de la couverture `check-feature-docs.sh` : aide CLI, warning non bloquant sur legacy, `--strict` bloquant sur section manquante, puis PASS strict quand la fiche contient le noyau minimal et les modules conditionnels requis.
- v0.7.2 : ajout assertion sur escaping JSON (régression).
- v0.9 : ajout assertion sur `AI_CONTEXT_FOCUS` graph + i18n FR/EN.
- 2026-04-24 : ajout [18/27] — vérifie que le pre-commit `auto-progress.sh` bascule `spec → implement`, écrit le snapshot dans `.progress-history.jsonl`, crée la ligne `auto-progress` dans le worklog, et est idempotent (second commit sans re-bump). HANDOFF reçu depuis `workflow/conversational-skills` (chantier 4). Révélé au passage un bug fixé : `auto-progress.sh` ne créait pas le worklog si absent — correctif appliqué dans `.ai/scripts/` + `template/.ai/scripts/`, cross-ref tracée dans `core/template-engine` Historique.
- 2026-04-24 : ajout [26/27] — vérifie le helper `_lib.sh path_matches_touch` sur matching exact, dossier, glob `**` et faux positifs proches.
- 2026-04-24 : ajout [27/27] — scaffold avec `docs_root=docs`, puis vérifie `check-features`, `features-for-path` et l'index JSON sur `docs/features`.
- 2026-04-24 : ajout [28/28] — vérifie les rendus conditionnels `tech_profile` pour `dotnet-clean-cqrs`, `react-next` et `fullstack-dotnet-react` (fichiers générés/exclus + références dans `.ai/index.md`).
- 2026-04-24 : extension [28/28] avec 6 assertions sur les squelettes DS (`docs/design-system-registry.md`, `docs/atomic-design-map.md`) — absents en profil `dotnet-clean-cqrs`, présents pour `react-next` et `fullstack-dotnet-react`. Maintenance portée par la fiche `core/preset-ds-skeletons`.
- 2026-04-25 : assertion [19/28] alignée sur 8 skills (`aic` + `aic-feature-audit` inclus). Assertion [20/28] étendue : vérifie un override simple `coverage.*` via `.ai/config.yml` pour confirmer que `check-feature-coverage.sh` lit la config runtime avec fallback defaults.
- 2026-04-27 : assertions renforcées pour la fondation schema : présence de `.ai/schema/feature.schema.json` dans le scaffold et warning `progress.phase` hors enum dans `check-features.sh` (alignement avec le schema).
- 2026-04-27 : étape [2/28] enrichie avec exécution de `doctor.sh` sur scaffold sain (doit passer).
- 2026-04-27 : étape [12/28] enrichie avec `audit-features.sh discover back` (en-tête, dry-run par défaut, détection `src/orphan.ts`).
- 2026-04-27 : étape [11/28] enrichie avec `migrate-features.sh` (dry-run détecte migration legacy, `--apply` applique `schema_version` + normalisation status).
- 2026-04-27 : étape [2/28] enrichie avec check `pr-report.sh --help` (présence/usage script).
- 2026-04-27 : étape [2/28] renforcée avec garde de compatibilité Bash 3.2 : `pr-report.sh` généré ne doit pas utiliser `mapfile`.
- 2026-04-27 : étape [28/28] enrichie pour valider `adoption_mode=lite` (pas de `.githooks`/workflows) et `adoption_mode=strict` (workflows conservés même avec `enable_ci_guard=false`).
- 2026-04-27 : libellé [28/28] clarifié dans `tests/smoke-test.sh` pour refléter le périmètre réel (`tech_profile` + `adoption_mode`) et améliorer le diagnostic CI.
- 2026-04-28 : étape [11/28] enrichie pour exiger `depends_on` et `touches` comme clés frontmatter obligatoires (acceptent `[]`), aligné sur `feature.schema.json`. Étape [12/28] enrichie avec `audit-features.sh --help` (annonce du périmètre MVP) et un cas `src/with space/file.ts` pour valider la robustesse aux chemins avec espaces. Étape [2/28] enrichie avec `pr-report.sh --format=json` (sortie JSON valide), `--include-docs` (lève les exclusions par défaut), assertion `docs_excluded ≥ 1` quand un README est touché. Étape [2/28] enrichie avec wrapper `ai-context.sh` (`--help` liste les commandes ; routage vers `shims` ; rejet d'une commande inconnue).
- **2026-04-28** : extension historique de [19/28] pour `aic-project-guardrails`. Cette attente est obsolète depuis le lean context : `guardrails.md` ne doit plus être forcé dans Pack A.
- 2026-05-03 : étape [28c/28] rendue compatible Copier 9.14 : le sous-projet d'upgrade est initialisé comme dépôt git-tracké propre, l'answers file local est explicite si Copier ne le matérialise pas, le fichier custom est versionné hors template, et l'échec de `copier update` n'est plus masqué par `|| true`. Le bonus big-mesh relie seulement une partie des features front aux back pour que `AI_CONTEXT_FOCUS=back` teste une vraie réduction au lieu d'un graphe entièrement connexe.
