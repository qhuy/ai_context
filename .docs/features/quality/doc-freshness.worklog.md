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
