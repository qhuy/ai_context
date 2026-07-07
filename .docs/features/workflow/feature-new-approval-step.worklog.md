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

## 2026-07-03 — done
- Intent : clôturer `feature-new-approval-step` après relecture de la propagation runtime/template et du wrapper Codex.
- Fichiers/surfaces : `.docs/features/workflow/feature-new-approval-step.md`, `.docs/features/workflow/feature-new-approval-step.worklog.md`.
- Décision : statut `done`; le contrat reste : proposition courte, validation explicite, aucune écriture avant feu vert.
- Validation : relecture `.ai/workflows/feature-new.md`, `template/.ai/workflows/feature-new.md.jinja`, `.agents/skills/aic-feature-new/workflow.md`; `bash .ai/scripts/check-feature-docs.sh --strict workflow/feature-new-approval-step`; `bash .ai/scripts/check-dogfood-drift.sh`; `bash .ai/scripts/check-features.sh --no-write`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-07 — couverture incidente (workflow/intentional-skills, P3)
- Retrait du wrapper `.agents/skills/aic-feature-new/workflow.md` de `touches` : fichier supprimé (chantier P3), jamais propriétaire du contrat de validation avant écriture — `.ai/workflows/feature-new.md` le porte seul. Prose alignée (skill → procédure). Aucun changement de comportement.
