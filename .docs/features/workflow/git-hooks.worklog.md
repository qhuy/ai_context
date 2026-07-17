# Worklog — workflow/git-hooks


## 2026-04-24 11:57 — auto
- Fichiers modifiés :
  - template/.githooks/README.md.jinja
  - template/.githooks/pre-commit.jinja
## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `template/.ai/scripts/check-commit-features.sh.jinja`.
- Impact : le hook commit-msg rendu par Copier herite de la correction heredoc du guard commit.
- Validation : `bash tests/unit/test-targeted-regressions.sh` PASS.

## 2026-06-28 — dogfooding de l'enforcement (Phase 0 / A2)
- Réactivation du moat sur le clone source : `git config core.hooksPath .githooks` (était `/dev/null`). commit-msg + pre-commit + post-checkout désormais actifs chez le mainteneur.
- Décision tracée : `doctor` warn (pas hard-fail) car les clones CI n'ont pas `core.hooksPath` → faux positif ; garantie CI portée par `ci-guard`.
- Evidence : `doctor` « git hooks path configured (.githooks) » + commit-msg rejette un `feat:` sans fiche.
- Fichiers : .docs/features/workflow/git-hooks.md (+ worklog)

## 2026-07-03 — HANDOFF depuis core/vcs-provider-abstraction
- Surface partagée touchée : `template/.ai/scripts/check-commit-features.sh.jinja` lit le delta via provider VCS. En Git, le hook commit-msg garde la même sémantique staged.
- En TFVC, `.githooks` n'est pas scaffoldé ; les checks sont exposés en commandes manuelles/CI.
- Validation portée par `core/vcs-provider-abstraction`.

## 2026-07-07 — fix P0 : re-stage worklog jamais déclenché (AGT-8 cassé)

- Constat (second audit du delta AGT-8 non commité) : la condition `staged_before` était capturée avant l'appel à `auto-progress.sh`, donc jamais vraie pour le cas nominal (worklog créé/complété PAR le hook) — les worklogs n'étaient plus jamais re-stagés automatiquement, casse silencieuse de la garantie "auto-worklog universel".
- Fix : `.githooks/pre-commit` + `template/.githooks/pre-commit.jinja` — remplacer `staged_before` par `current_features` (clés de features dérivées des fichiers RÉELLEMENT stagés dans ce commit, calculées dans la même boucle que l'écriture du trace). Le worklog est re-stagé si sa feature est dans `current_features` ; sinon (trace résiduelle d'une session interrompue), il ne l'est pas — préserve l'intention réelle d'AGT-8 sans casser le cas nominal.
- Doc alignée : `.githooks/README.md` + `template/.githooks/README.md.jinja`, en-tête du hook (étape 4), section "Comportement attendu"/"Validation" de cette fiche.
- Test réécrit : `tests/unit/test-pre-commit-worklog-stage.sh` couvre désormais les deux cas (nominal → re-stage ; résiduel → pas de re-stage), alors que l'ancienne version verrouillait le comportement cassé.
- Validation : `bash tests/unit/test-pre-commit-worklog-stage.sh` PASS ; `bash tests/smoke-test.sh` PASS ; `diff .githooks/pre-commit template/.githooks/pre-commit.jinja` ne montre plus d'écart que la ligne Jinja `{{ agents | join(', ') }}`.

## 2026-07-07 — fix P1/P3 : ordre -m/--message= et forme -F collée (AGT-7)

- Constat (second audit du delta AGT-7 non commité) : les branches `--message=...` étaient testées avant les branches `-m "..."` préexistantes ; un commit `-m "..."` valide contenant littéralement `--message=` était mal-extrait et rejeté à tort. Repro : `git commit -m "fix: gérer --message=... et -F dans check-commit-features"` → refusé avant fix.
- Fix P1 : `.ai/scripts/check-commit-features.sh` (+ template) — réordonné pour tester `-m` avant `--message=`.
- Fix P3 : ajout de la forme collée `-Fmsg.txt` (sans espace, valide en git) via une branche `-F([^[:space:]\;\&\|]+)` après les formes avec espace.
- Test étendu : `tests/unit/test-check-commit-features-relevance.sh` couvre désormais -F quoté (simple/double/chemin absolu), -F collé, les 6 variantes --file/--file=, --message=' '/--message=sansespace, et verrouille la régression P1 (`-m` contenant `--message=`).
- Validation : `bash tests/unit/test-check-commit-features-relevance.sh` PASS ; `diff .ai/scripts/check-commit-features.sh template/.ai/scripts/check-commit-features.sh.jinja` → aucun écart ; `bash tests/smoke-test.sh` PASS.

## 2026-07-03 — done
- Intent : clôturer `git-hooks` après vérification que l'assertion pre-commit demandée existe déjà dans le smoke.
- Fichiers/surfaces : `.docs/features/workflow/git-hooks.md`, `.docs/features/workflow/git-hooks.worklog.md`.
- Décision : statut `done`; hooks Git restent le point de convergence universel, activation locale documentée.
- Validation : relecture `tests/smoke-test.sh` bloc `[18/28]`; `bash .ai/scripts/check-feature-docs.sh --strict workflow/git-hooks`; `bash .ai/scripts/check-features.sh --no-write`; `bash .ai/scripts/check-feature-freshness.sh --worktree --strict`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-16 — HANDOFF gate commit
- Le template `check-commit-features.sh.jinja` devient une dépendance partagée ; son propriétaire direct reste `quality/doc-freshness`.
- Le contrat des hooks Git reste inchangé : le commit-msg exécute toujours le même checker et la freshness stricte.
