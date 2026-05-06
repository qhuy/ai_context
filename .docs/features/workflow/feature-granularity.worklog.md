# Worklog — workflow/feature-granularity

## 2026-05-04 — création
- Feature créée par /aic-feature-new
- Scope : workflow
- Intent initial : formaliser une règle de granularité anti fourre-tout pour les fiches feature

## 2026-05-04 — implémentation
- Fichiers modifiés :
  - `.ai/workflows/feature-new.md`
  - `.agents/skills/aic-feature-new/workflow.md`
  - `.docs/FEATURE_TEMPLATE.md`
- Check anti fourre-tout ajouté avant le check de collision d'id.
- Note de granularité et exemples `passage` ajoutés au template.
- Pas de quality gate automatisée ajoutée.

## 2026-05-04 — correction gate
- Fiche nettoyée des placeholders conditionnels du template.
- Modules non requis explicités comme non applicables.

## 2026-05-04 19:12 — DONE

### Evidence
- Build : `bash .ai/scripts/check-shims.sh && bash .ai/scripts/check-ai-references.sh && bash .ai/scripts/check-features.sh` ✅
- Tests : `bash .ai/scripts/check-feature-docs.sh --strict workflow/feature-granularity && bash .ai/scripts/check-feature-coverage.sh` ✅
- Observabilité lean context : `bash .ai/scripts/measure-context-size.sh` ✅

### Résumé livré
- Check anti fourre-tout ajouté à `.ai/workflows/feature-new.md`.
- Workflow du skill `/aic-feature-new` aligné avec la même règle.
- Template feature enrichi avec note de granularité, exemples OK et slugs à éviter.
- Aucun quality gate automatisée fragile ajoutée.

### Commit suggéré
docs(workflow): formaliser la granularité des fiches feature

(Respecte Conventional Commits — fr.)

## 2026-05-06 — freshness
- Impact indirect : le wrapper Codex `aic-feature-new` a été resynchronisé depuis le rendu Copier minimal.
- Aucun changement de règle de granularité ; la procédure canonique reste `.ai/workflows/feature-new.md`.
