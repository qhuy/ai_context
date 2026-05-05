# Worklog — core/codex-skills-install

## 2026-05-04 — création
- Feature créée par /aic-feature-new
- Scope : core
- Intent initial : Installer les skills Codex avec ai_context

## 2026-05-04 — implémentation
- Ajout de `.agents/skills/` au template quand `codex` est sélectionné.
- Ajout des wrappers `aic-*`, `aic-feature-*` et `aic-quality-gate`.
- Documentation README/CHANGELOG mise à jour.
- Validation : `check-shims`, `check-features`, `smoke-test` passent.

## 2026-05-04 16:37 CEST — DONE

### Evidence
- Build : non applicable (template/scripts shell)
- Tests : `bash tests/smoke-test.sh` OK
- Gate : `check-shims`, `check-ai-references`, `check-features`, `check-feature-docs --strict core/codex-skills-install`, `check-feature-coverage`, `measure-context-size` OK

### Résumé livré
- Installation conditionnelle de `.agents/skills/` quand `codex` est sélectionné.
- Wrappers Codex ajoutés pour `aic-*`, `aic-feature-*` et `aic-quality-gate`.
- Smoke-test étendu pour vérifier la génération des skills Codex.
- Documentation README et CHANGELOG mise à jour.

### Commit suggéré
feat(core): installer les skills Codex par défaut
## 2026-05-05 — freshness
- Impact documentaire : README et smoke-test mentionnent le nouvel overlay projet sans changer les wrappers Codex.
- Validation associée : smoke-test PASS.
