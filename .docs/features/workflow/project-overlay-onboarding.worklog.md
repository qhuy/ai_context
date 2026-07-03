# Worklog — workflow/project-overlay-onboarding

## 2026-06-19 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : workflow
- Intent initial : Skill aic-onboard — init/sync/migrate de l'overlay projet
- HANDOFF `core → workflow` confirmé par l'utilisateur
- Prérequis livré : `core/project-overlay-scope-registry` (contrat de forme, committé 0b6e685)
- `touches: []` au départ (fichiers du skill pas encore créés) — à figer en `aic-dev-plan`
- Source : cadrage `aic-frame` → `.docs/frames/2026-06-19-project-overlay-scope-registry.md`

## 2026-06-19 — implémentation (autopilote)
- Procédure canonique `template/.ai/workflows/project-overlay-sync.md.jinja` : modes init/sync/migrate, détection inférable, interview du non-inférable, garde-fous migrate (préserver/proposer/idempotent), durable vs volatile.
- Skill `aic-onboard` (mince → pointe vers la procédure) en parité Claude (`template/.claude/skills/aic-onboard/`) + Codex (`template/.agents/skills/aic-onboard/`).
- Runtime régénéré via `dogfood-update.sh --apply` ; `.claude/skills/aic-onboard/`, `.agents/skills/aic-onboard/`, `.ai/workflows/project-overlay-sync.md` générés.
- Smoke-test étendu : `aic-onboard` ajouté à la liste des skills publics, `project-overlay-sync` à la liste des workflows internes.
- Catalogues mis à jour : `workflow/claude-skills`, `core/aic-surface-canonical`.
- Bug détecté hors scope : `dogfood-update.sh --apply` supprime les frames datés de `.docs/frames/` (restaurés via git) → tâche flaggée pour `core/dogfood-runtime-sync`.
- Checks verts : drift ✅, shims ✅, check-features ✅, smoke-test ✅.
- `touches` figés sur les paths réels ; phase → done.

## 2026-06-19 — correctif statut
- `status: draft → active` : oubli au commit 39c0fa2, la feature est implémentée et live (incohérent avec `phase: done`). Aligné sur `core/project-overlay-scope-registry`.

## 2026-07-03 — metadata OKF
- Intent : backfill metadata `type: feature` signalée par le profil OKF warn-only.
- Fichiers/surfaces : `.docs/features/workflow/project-overlay-onboarding.md`, `.docs/features/workflow/project-overlay-onboarding.worklog.md`.
- Décision : ajout metadata uniquement ; aucun changement du skill `aic-onboard` ni de la procédure `project-overlay-sync`.
- Validation : `bash .ai/scripts/aic.sh migrate okf-type` ne doit plus signaler cette fiche ; `bash .ai/scripts/check-features.sh --no-write` ne doit plus émettre de warning `type` absent.
- Next : aucune action immédiate.
