# Workflow — aic-review

**Goal** : aider à relire le changement courant avant commit ou PR.

## Actions

1. Lire `.ai/index.md` et `.ai/quality/QUALITY_GATE.md`.
2. Exécuter `bash .ai/scripts/review-delta.sh --staged` si des fichiers sont staged, sinon `bash .ai/scripts/review-delta.sh`.
3. Si une base/head est fournie, exécuter aussi `bash .ai/scripts/pr-report.sh --base=<base> --head=<head>`.
4. Prendre position sur le risque principal.

## Format

```markdown
## Review

Risque principal :
- ...

Features directes :
- ...

Features liées :
- ...

Doc / freshness :
- ...

Checks recommandés :
- ...

Prochaine action minimale :
- ...
```

Lecture seule. Ne pas corriger dans ce skill.
