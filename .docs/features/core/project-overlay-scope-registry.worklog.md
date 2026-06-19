# Worklog — core/project-overlay-scope-registry

## 2026-06-19 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : Overlay projet comme registre de scopes
- Source : cadrage `aic-frame` → `.docs/frames/2026-06-19-project-overlay-scope-registry.md`
- HANDOFF `workflow → core` confirmé par l'utilisateur avant création
- Prérequis de la 2ᵉ feature à venir : `workflow/project-overlay-onboarding` (skill `aic-onboard`)

## 2026-06-19 — implémentation contrat
- `aic-dev-plan` produit : 7 étapes, 2 arbitrages bloquants tranchés (documentaire + prose agent-driven)
- Contrat de forme livré : `.ai/templates/project-overlay/README.md` + `.jinja` — front-matter `overlay_contract_version`, `paths`, `meta` ; sections `Conventions`, `Derived`, `Selon les chemins touchés` ; tableau durable/volatile
- Contrat de chargement étendu : `.ai/index.md` + `template/.ai/index.md.jinja` — descente d'un niveau par pointeur explicite, jamais récursion
- Ownership documenté : `.ai/OWNERSHIP.md` + `.jinja` — section « Registre de scopes » ajoutée
- `check-dogfood-drift.sh` : patterns `project/*/*` et `project/*/*/*` ajoutés (bash case ne croise pas `/`)
- `check-ai-references.sh` : aucun changement nécessaire (exemples en code blocks, pas de liens markdown)
- Checks verts : dogfood-drift ✅, ai-references ✅, check-shims ✅, check-features ✅, smoke-test ✅
- Reste : test unitaire dédié + quality gate + commit

## 2026-06-19 — quality gate + DONE
- `test-project-overlay.sh` étendu : 2 nouveaux cas — dogfood-drift avec `project/<scope>/index.md` (bo-front + sql), check-ai-references avec lien vers `project/payments/index.md`
- Battery complète verte : check-features ✅, check-ai-references ✅, check-dogfood-drift ✅, smoke-test ✅
- Feature passée `status: active`, `phase: done`
- Prochain : HANDOFF `core → workflow` pour `workflow/project-overlay-onboarding` (skill `aic-onboard`)

## 2026-06-19 — auto-review avant commit (2 défauts corrigés)
- **Défaut 1** : modif `check-dogfood-drift.sh` (`project/*/*`…) était un no-op — en bash `case`, `*` matche `/`, donc `project/*` couvrait déjà la profondeur. Reverté. Scripts retirés de `touches` → déplacés en `touches_shared` (surfaces vérifiées, non modifiées).
- **Défaut 2** : `overlay_contract_version` avait deux domiciles (ligne libre racine + front-matter scope). Consolidé : stamp **global unique** dans le front-matter de `.ai/project/index.md` ; retiré des index de scope. README ×2 + fiche + fixtures de test alignés.
- Décision schéma documentaire (pas de JSON Schema v1) inscrite au contrat.
- Re-validation complète après corrections.

## 2026-06-19 12:39 — auto
- Fichiers modifiés :
  - .ai/OWNERSHIP.md
  - .ai/index.md
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/templates/project-overlay/README.md
  - template/.ai/OWNERSHIP.md.jinja
  - template/.ai/index.md.jinja
  - template/.ai/templates/project-overlay/README.md.jinja

## 2026-06-19 14:09 — auto
- Fichiers modifiés :
  - tests/unit/test-project-overlay.sh

## 2026-06-19 14:24 — auto
- Fichiers modifiés :
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/templates/project-overlay/README.md
  - template/.ai/templates/project-overlay/README.md.jinja
  - tests/unit/test-project-overlay.sh
