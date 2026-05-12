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
