# Worklog — workflow/feature-audit

## 2026-04-24 — création
- Feature créée manuellement (cadrage issu de la conversation `/aic-feature-audit`)
- Scope : workflow
- Intent initial : skill exposé à deux modes (`discover` pour rétro-doc, `refresh` pour re-sync), dry-run par défaut
- Prochaine étape : écrire SKILL.md + workflow.md dans `.claude/skills/` et `template/.claude/skills/`

## 2026-04-24 16:37 — auto
- Fichiers modifiés :
  - .claude/skills/aic-feature-audit/SKILL.md
  - .claude/skills/aic-feature-audit/workflow.md
  - template/.claude/skills/aic-feature-audit/SKILL.md.jinja
  - template/.claude/skills/aic-feature-audit/workflow.md.jinja

## 2026-04-24 16:40 — auto-progress
- Bascule phase : spec → implement (édits réels détectés sur 4 fichier(s))
- Annulable via /aic undo (snapshot dans .ai/.progress-history.jsonl)

## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - template/.ai/scripts/audit-features.sh.jinja
  - tests/smoke-test.sh

## 2026-04-28 12:04 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-07-03 — HANDOFF workflow -> core
- Intent : valider que `/aic-review` peut s'appuyer sur `.ai/workflows/feature-audit.md` sans réexposer un skill procédural.
- Constat : `.ai/workflows/feature-audit.md` et son template existent ; `audit-features.sh --help` passe ; les tests smoke couvrent discover. En revanche, les wrappers `aic-review` ne pointent pas explicitement vers `feature-audit`.
- Fichiers/surfaces workflow : `.docs/features/workflow/feature-audit.md`, `.docs/features/workflow/feature-audit.worklog.md`.
- HANDOFF : `core/aic-review-application-skill` doit décider/ajouter le pointeur léger dans `.agents/skills/aic-review/**`, `.claude/skills/aic-review/**` et templates associés. Ces fichiers sont routés par `features-for-path` vers des fiches `core`, donc pas d'édition silencieuse depuis le scope `workflow`.
- Validation : `bash .ai/scripts/check-feature-docs.sh --strict workflow/feature-audit`; `bash .ai/scripts/audit-features.sh --help`; `rg "feature-audit|audit-features" ...`.
- Next : attendre confirmation pour basculer en scope `core`.

## 2026-07-03 — done
- Intent : lever le blocker après traitement du HANDOFF core.
- Fichiers/surfaces : `.docs/features/workflow/feature-audit.md`, `.docs/features/workflow/feature-audit.worklog.md`.
- Décision : statut `done`; `feature-audit` reste procédure interne, routée depuis `aic-review` en lecture seule.
- Validation : commit `2967507`; `bash .ai/scripts/check-feature-docs.sh --strict workflow/feature-audit`; `bash .ai/scripts/check-features.sh --no-write`; `bash .ai/scripts/check-feature-freshness.sh --worktree --strict`.
- Next : aucune action immédiate.
