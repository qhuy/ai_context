# Workflow — aic-ship

**Goal** : décider si le changement est prêt à être commité ou poussé.

## Actions

1. Lire `.ai/index.md` et `.ai/quality/QUALITY_GATE.md`.
2. Exécuter :
   ```bash
   bash .ai/scripts/check-feature-freshness.sh --staged --strict
   bash .ai/scripts/check-shims.sh
   bash .ai/scripts/check-ai-references.sh
   bash .ai/scripts/check-features.sh
   bash .ai/scripts/measure-context-size.sh
   ```
3. Exécuter les tests ciblés pertinents si l'utilisateur ne les a pas déjà fournis.
4. Produire un verdict `GO` ou `NO-GO`.
5. Si `GO`, proposer un message de commit en français. Attendre confirmation avant `git commit` ou `git push`.

## Format

```markdown
## Ship

Verdict :
GO / NO-GO

Evidence :
- ...

Risques :
- ...

Commit proposé :
- ...

Prochaine action minimale :
- ...
```

Ne jamais commit/push sans confirmation explicite.
