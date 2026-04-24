---
id: claude-skills
scope: workflow
title: Skills /aic-* (cycle de vie feature côté Claude)
status: active
depends_on:
  - core/feature-mesh
  - workflow/auto-worklog
touches:
  - template/.claude/skills/**
---

# Claude skills /aic-*

## Objectif

Encadrer les gestes récurrents du cycle de vie d'une feature côté agent Claude via 6 skills explicites, invocables par l'utilisateur (`/aic-feature-new`, etc.).

## Comportement attendu

| Skill | Rôle |
|---|---|
| `/aic-feature-new` | Créer fiche + worklog depuis le template |
| `/aic-feature-resume` | Reprendre — buckets EN COURS / BLOQUÉES / STALE |
| `/aic-feature-update` | Sauver l'avancement (`progress` bumped) |
| `/aic-feature-handoff` | Passation inter-scope ou inter-session |
| `/aic-quality-gate` | Vérification go/no-go avant commit/PR |
| `/aic-feature-done` | Clôture (evidence + status `done`) |

## Contrats

- Chaque skill : `SKILL.md` (description courte) + `workflow.md` (procédure détaillée).
- Aucun skill ne contourne `auto-worklog` : ils déclenchent des éditions, le hook s'en charge.
- `aic-quality-gate` invoque les scripts `check-features` + `check-feature-coverage`.

## Cross-refs

Pendant côté hooks invisible : `auto-worklog` + `pre-turn-reminder`. Les skills sont la part visible utilisateur.

## Historique / décisions

- v0.5 : 6 skills figés. Renoncement à un skill `/aic-feature-archive` (couvert par `/aic-feature-done` + édition manuelle status).
- v0.8 : reminders côté pre-turn i18n FR/EN. Skills restent en anglais (dette tracée).
