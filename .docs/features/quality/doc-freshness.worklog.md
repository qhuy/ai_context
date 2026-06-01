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
