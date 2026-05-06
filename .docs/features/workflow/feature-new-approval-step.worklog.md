# Worklog — workflow/feature-new-approval-step

## 2026-05-04 — création
- Feature créée par /aic-feature-new
- Scope : workflow
- Intent initial : ajouter une proposition validable avant création de fiche et développement

## 2026-05-04 — implémentation
- Fichiers modifiés :
  - `.ai/workflows/feature-new.md`
  - `.agents/skills/aic-feature-new/workflow.md`
- Ajout d'une phase `Proposition avant écriture` avec synthèse des tâches, impacts, risques, validations et conseils.
- Ajout d'une règle non négociable : pas d'écriture de fiche sans validation explicite.
- Sortie clarifiée : le skill ne démarre pas le développement applicatif.

## 2026-05-04 — dogfood
- Fichiers modifiés :
  - `template/.ai/workflows/feature-new.md.jinja`
- La phase `Proposition avant écriture` est propagée au template Copier.
- `bash .ai/scripts/dogfood-update.sh --apply` a confirmé que le runtime source reste aligné avec le rendu minimal.

## 2026-05-06 — freshness
- Impact indirect : le wrapper Codex `aic-feature-new` a été resynchronisé depuis le rendu Copier minimal.
- Aucun changement du contrat d'approbation avant écriture ; la source de vérité reste `.ai/workflows/feature-new.md`.

## 2026-05-06 22:46 — auto
- Fichiers modifiés :
  - .agents/skills/aic-feature-new/workflow.md
