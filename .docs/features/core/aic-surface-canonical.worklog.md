# Worklog — core/aic-surface-canonical

## 2026-05-06 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : unifier la surface utilisateur canonique autour de `aic`

## 2026-05-06 — implementation
- Intent : migration breaking propre vers la surface `aic` sans alias legacy.
- Fichiers/surfaces : wrapper runtime/template `aic.sh`, README racine/downstream, message Copier, docs migration/update, smoke-test, fiches feature touchant l'ancien wrapper.
- Décision : `aic-document-feature` est expose comme intention officielle ; `diagnose` evite le faux positif `adr` sur `cadrage`.
- Validation : `bash -n`, `aic.sh --help`, `aic.sh frame`, `aic.sh diagnose`, `aic.sh document-feature`, `check-shims`, `check-ai-references`, `check-features`, `check-feature-docs core/aic-surface-canonical`, `check-feature-coverage`, `measure-context-size`, `tests/smoke-test.sh`.
- Next : relire le delta puis commit dedie du sous-chantier si le scope convient.

## 2026-05-06 — freshness README
- Intent : verifier que la réécriture README conserve la surface canonique `aic` sans réintroduire d'ancien alias public.
- Validation : `check-ai-references`, `check-feature-docs product/readme-positioning`.

## 2026-05-06 — retours review
- Intent : traiter les retours review sur la migration canonique `aic`.
- Fichiers/surfaces : `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`, contrat product `aic.sh product-*`.
- Décision : `aic ship` ne filtre plus les suppressions/renommages staged via `--diff-filter=AM`, le hint ne déduit plus `feat:` d'une fiche seule, et le contrat produit ne mentionne plus l'ancien wrapper.
- Validation : prévue via `bash -n`, `check-*`, `aic ship` et smoke ciblé.
- Next : commit dédié `fix:` après quality gate.

## 2026-05-06 22:46 — auto
- Fichiers modifiés :
  - template/.agents/skills/aic-feature-done/SKILL.md.jinja
  - template/.agents/skills/aic-feature-done/workflow.md.jinja
  - template/.agents/skills/aic-feature-handoff/SKILL.md.jinja
  - template/.agents/skills/aic-feature-handoff/workflow.md.jinja
  - template/.agents/skills/aic-feature-new/SKILL.md.jinja
  - template/.agents/skills/aic-feature-new/workflow.md.jinja
  - template/.agents/skills/aic-feature-resume/SKILL.md.jinja
  - template/.agents/skills/aic-feature-resume/workflow.md.jinja
  - template/.agents/skills/aic-feature-update/SKILL.md.jinja
  - template/.agents/skills/aic-feature-update/workflow.md.jinja
  - template/.agents/skills/aic-frame/workflow.md.jinja
  - template/.agents/skills/aic-quality-gate/SKILL.md.jinja
  - template/.agents/skills/aic-quality-gate/workflow.md.jinja
  - template/.agents/skills/aic-ship/SKILL.md.jinja
  - template/.agents/skills/aic-status/SKILL.md.jinja
  - template/.claude/skills/aic-frame/workflow.md.jinja
  - template/.claude/skills/aic-ship/SKILL.md.jinja
  - template/.claude/skills/aic-status/SKILL.md.jinja

## 2026-05-08 — freshness
- Impact indirect : nettoyage drift README runtime/template + note mainteneur PROJECT_STATE (driver core/dogfood-runtime-sync).
- Aucun changement de contrat propre a cette feature.

## 2026-05-12 — alignement dogfood
- Impact : `PROJECT_STATE.md`, `README_AI_CONTEXT.md` et `template/README_AI_CONTEXT.md.jinja` restent alignes avec la surface publique `aic-*`.
- Validation : `check-dogfood-drift.sh` PASS.

## 2026-05-12 — impact partagé test lock index

- Fichiers/surfaces : `tests/smoke-test.sh`.
- Contexte : `quality/index-lock-contract` ajoute une assertion smoke sur le timeout de `with_index_lock`.
- Impact : aucune evolution de surface AIC ; le smoke couvre une regression runtime supplementaire.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `tests/smoke-test.sh`.
- Impact : ajout d'un appel aux tests unitaires de regressions Q4 dans le smoke, sans modifier la surface utilisateur `aic`.
- Validation : `bash tests/smoke-test.sh` PASS.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : README, README runtime/template et smoke-test exposent les contrats subagents/hooks/MCP sans changer la commande canonique `aic`.
- Aucun alias legacy ou nouvelle surface CLI ajoute.
- Validation : `check-ai-references`, `check-shims` et smoke-test PASS.

## 2026-06-01 — copier.yml : ajout _min_copier_version (audit U10)

- `copier.yml` reçoit un plancher `_min_copier_version: "9.0.0"` (setting moteur, porté par core/template-engine). Aucun impact sur le périmètre de cette feature ; entrée de traçabilité car `copier.yml` reste dans son `touches:`.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - copier.yml

## 2026-06-02 10:13 — auto
- Fichiers modifiés :
  - template/.agents/skills/aic-ship/SKILL.md.jinja
  - template/.claude/skills/aic-ship/SKILL.md.jinja

## 2026-06-08 — freshness PROJECT_STATE v0.13.0 (audit DOC-1)
- Intent : corriger l'écart doc↔réalité relevé par l'audit hebdo (DOC-1) — `PROJECT_STATE.md` restait bloqué sur v0.12.0 alors que v0.13.0 est releasée (CHANGELOG + tag `v0.13.0`), en violation de la checklist `RELEASE.md:57`.
- Fichiers/surfaces : `PROJECT_STATE.md` (version publiée, section « État actuel » v0.13.0, liste des tags). Aucun changement de surface `aic`.
- Décision : ajouter une section « État actuel (v0.13.0) » (contrat read-only des checks, index contract v2, surface CLI `aic` breaking, installation Codex `.agents/`) et conserver l'état v0.12.0 en rappel.
- Validation : `check-ai-references`, `check-features --no-write`, `check-dogfood-drift.sh` (PROJECT_STATE root-only, non templaté).

## 2026-06-08 16:51 — auto
- Fichiers modifiés :
  - PROJECT_STATE.md
