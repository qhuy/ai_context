# Worklog — quality/doc-freshness

## 2026-04-29 00:00

- Creation de la fiche pour le controle de fraicheur documentaire.
- Ajout de `.ai/scripts/check-feature-freshness.sh` et de son template Copier.
- Branchement du controle staged strict dans `check-commit-features.sh`.
- Ajout du mode warn dans le workflow `ai-context-check` et documentation dans la quality gate.

## 2026-05-06 — retours review
- Intent : aligner le contrôle freshness staged avec la visibilité des suppressions/renommages.
- Fichiers/surfaces : `.ai/scripts/check-feature-freshness.sh`, `template/.ai/scripts/check-feature-freshness.sh.jinja`.
- Décision : ne plus ignorer les suppressions staged via `--diff-filter=AM`.
- Validation : prévue via `check-feature-freshness --staged --strict`.

## 2026-05-08 — stabilisation mode historique
- Intent : rendre `check-feature-freshness.sh --warn` exploitable sur le repo source sans scan exhaustif ni blocage silencieux.
- Changement : le mode historique compare uniquement l'historique Git committe ; le prochain commit reste couvert par `--staged`.
- Implementation : un `git log` par feature avec tous ses pathspecs `touches:` et cache timestamp pour les fiches/worklogs.
- Parite : runtime dogfoode et template `.jinja` synchronises.
- Validation : `check-feature-freshness.sh --warn` OK, `check-feature-freshness.sh --staged --warn` OK, test unitaire freshness OK.

## 2026-05-12 — impact Q4 régressions ciblées

- Surfaces : `.ai/scripts/check-commit-features.sh`, `template/.ai/scripts/check-commit-features.sh.jinja`.
- Impact : le guard de commit extrait d'abord les messages heredoc avant la capture generique `-m "..."`, afin de preserver la fraicheur documentaire sur les commits complexes.
- Validation : `bash .ai/scripts/check-feature-docs.sh --strict quality/targeted-regression-coverage` PASS ; `bash tests/unit/test-targeted-regressions.sh` PASS.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : le workflow CI reste aligne avec la freshness staged stricte tout en ajoutant le check agent-config adjacent.
- Aucun changement de logique `check-feature-freshness.sh`.
- Validation : `check-feature-freshness.sh --staged --strict` relance avant commit.

## 2026-05-14 — impact read-only-checks-contract

- `check-feature-freshness.sh` ne reconstruit plus `.ai/.feature-index.json` implicitement.
- Le script génère un index temporaire hors repo pour `--warn` et `--staged --strict`; fallback lecture du cache existant seulement si la génération temporaire échoue.
- Validation portée par `quality/read-only-checks-contract` : tests freshness existants PASS + test no-write ciblé PASS.

## 2026-06-01 — fix test-infra rsync (audit U1/U2)

- `tests/unit/test-check-feature-freshness.sh` et `test-review-delta-shared.sh` : `cp -R .` → `rsync --exclude=.git` ; fixture review-delta rebasée sur `git add -A` (timeout >120s → 14s). Aucun changement de `check-feature-freshness.sh`.
- CI `ai-context-check.yml` : boucle sur `tests/unit/*.sh` + trigger `tests/**`.
- Validation : tests PASS + `check-feature-freshness --staged --strict`.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - .github/workflows/ai-context-check.yml
  - tests/unit/test-check-feature-freshness.sh
  - tests/unit/test-review-delta-shared.sh

## 2026-06-01 17:38 — auto
- Fichiers modifiés :
  - .github/workflows/ai-context-check.yml
  - template/.github/workflows/ai-context-check.yml.jinja

## 2026-06-01 — test pr-report JSON sur fixture freshness/shared

- `tests/unit/test-review-delta-shared.sh` conserve l'assertion freshness staged `touches_shared` non bloquante et ajoute un contrôle `pr-report --format=json`.
- Objectif : prévenir la régression `[""]` sur tableaux vides sans changer la politique freshness.

## 2026-06-01 — politique freshness/docs : --warn assumé (audit U4)

- Décision actée après investigation : **`--warn` reste le steady-state**, `--strict` n'est pas imposé sur freshness ni check-feature-docs.
- Freshness « stale » (≈29) = artefact de timestamps : le code touché par une feature (via `touches:`) est plus récent que sa fiche ; en repo actif, viser 0 est un treadmill (re-stale au commit suivant). Non bloquant par design.
- check-feature-docs : 97 warnings répartis sur ~20 fiches **legacy**. Les features livrées en 0.13.0 (read-only-checks-contract, index-contract-v2, feature-mesh-contract-alignment, ai-context-stability-migration, index-lock-contract) passent toutes `--strict` (vérifié). Le résidu est de la dette doc legacy ; un remplissage mécanique créerait des sections creuses (anti-valeur) → à compléter au cas par cas si une fiche legacy est rouverte.

## 2026-06-26 11:17 — auto
- Fichiers modifiés :
  - .ai/scripts/check-feature-freshness.sh

## 2026-06-26 11:34 — auto
- Fichiers modifiés :
  - .ai/quality/QUALITY_GATE.md
  - template/.ai/quality/QUALITY_GATE.md.jinja

## 2026-06-26 — mode --worktree (HANDOFF workflow/stop-turn-doc-gate)
- Ajout du mode `check-feature-freshness.sh --worktree` (+ jinja) : fraîcheur **présence-based** sur tout le working tree (staged ∪ non-stagé ∪ untracked via `collect_uncommitted_paths`), filtré « substantiel » via `path_in_coverage_scope` (config `coverage`). Sert au gate Stop de fin de tour.
- Distinct du mode historique (timestamps) : pas de treadmill staleness, cohérent avec la politique `--warn` du 2026-06-01.
- Section « Fraîcheur en fin de tour » ajoutée à `QUALITY_GATE.md` (+ jinja).
- Validation : `test-stop-turn-doc-gate` PASS, `test-check-feature-freshness` PASS, smoke-test PASS, dogfood-drift PASS.
