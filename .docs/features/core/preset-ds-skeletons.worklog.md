# Worklog — core/preset-ds-skeletons

## 2026-04-24 — création
- Feature créée par /aic-feature-new
- Scope : core
- Intent initial : Squelettes bootstrap pour DS registry et atomic map
- Contexte : après enrichissement V1 des presets technos (commit 19b3798), la règle `tech-react` exige un `docs/design-system-registry.md` mais aucun squelette n'est moissonné par le template. À corriger pour rendre la convention vivante dès le bootstrap.

## 2026-04-24 18:27 — auto
- Fichiers modifiés :
  - copier.yml
  - template/docs/atomic-design-map.md.jinja
  - template/docs/design-system-registry.md.jinja

## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - copier.yml
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/ai-context.sh.jinja
  - template/.ai/scripts/audit-features.sh.jinja
  - template/.ai/scripts/check-features.sh.jinja
  - template/.ai/scripts/pr-report.sh.jinja

## 2026-04-28 11:57 — auto
- Fichiers modifiés :
  - template/.ai/index.md.jinja
  - template/.claude/skills/aic-project-guardrails/SKILL.md.jinja
  - template/.claude/skills/aic-project-guardrails/workflow.md.jinja
  - template/README_AI_CONTEXT.md.jinja

## 2026-04-28 12:04 — auto
- Fichiers modifiés :
  - copier.yml
  - template/.ai/scripts/doctor.sh.jinja

## 2026-05-04 — freshness
- Impact indirect : `copier.yml` ajoute l'exclusion conditionnelle `.agents` sans modifier les squelettes DS.
- Validation associée : smoke-test complet PASS.
## 2026-05-05 — freshness
- Impact transversal : `copier.yml` change hors logique DS, avec conservation des exclusions/presets existants.
- Validation associée : smoke-test matrice Copier PASS.
