---
id: claude-skills
scope: workflow
title: Skills /aic* (surface intentionnelle + primitives internes)
status: active
depends_on:
  - core/feature-mesh
  - workflow/auto-worklog
touches:
  - template/.claude/skills/**
progress:
  phase: implement
  step: "surface UX intentionnelle : frame/status/diagnose/review/ship"
  blockers: []
  resume_hint: "valider en usage réel que les 4 skills internes ne sont plus invoqués à la main ; après quoi passer en review"
  updated: 2026-04-28
---

# Claude skills /aic*

## Objectif

Fournir les primitives du cycle de vie feature côté agent Claude, mais exposer à l'utilisateur des intentions lisibles plutôt que des étapes internes du mesh.

## Comportement attendu

### Skills exposés (invocation utilisateur attendue)

| Skill | Rôle | Quand l'invoquer |
|---|---|---|
| `/aic` | Override conversationnel de l'auto-progression (`/aic <phrase>`, `/aic undo`) | Quand l'auto-progression se trompe ou pour cas exceptionnels |
| `/aic-frame` | Cadrage : objectif, position, métier, technique, plan, validation | Avant une feature ou une décision insuffisamment cadrée |
| `/aic-status` | État actionnable : en cours, blockers, stale, delta, prochaine reprise | Début de session ou reprise après interruption |
| `/aic-diagnose` | Diagnostic du bottleneck principal | Quand ça bloque, quand la demande est floue ou contradictoire |
| `/aic-review` | Review du delta courant : risques, features, doc, checks | Avant review humaine, PR ou correction de findings |
| `/aic-ship` | Gate de sortie : freshness, quality gate, evidence, commit proposé | Avant commit, PR ou push |

### Skills internes (invoqués par les hooks et par `/aic`)

| Skill | Rôle | Invocateur |
|---|---|---|
| `/aic-feature-new` | Créer fiche + worklog | `/aic` sur intent « crée / développe X » |
| `/aic-feature-resume` | Buckets EN COURS / BLOQUÉES / STALE / À FAIRE | Backend de `/aic-status` |
| `/aic-feature-update` | Bump `progress` (phase/step/blockers/resume_hint) | `/aic` sur intent « blocked / pause / j'attends » |
| `/aic-feature-handoff` | Passation inter-scope | `/aic handoff vers X` ou détection auto cross-scope |
| `/aic-feature-audit` | Rétro-doc / re-sync d'une fiche vs code réel | Backend ponctuel de `/aic-review` ou maintenance mesh |
| `/aic-quality-gate` | Check go/no-go déterministe | Backend de `/aic-ship` |
| `/aic-feature-done` | Clôture (evidence + status done) | `/aic force done` ou auto-progression V2 (pas encore implémentée) |

## Contrats

- Chaque skill : `SKILL.md` (description courte) + `workflow.md` (procédure détaillée).
- Les skills internes **existent toujours** et restent **invocables à la main** pour cas de fallback (debug, contournement), mais ne sont plus documentés comme UX recommandée.
- Aucun skill ne contourne `auto-worklog` : ils déclenchent des éditions, le hook s'en charge.
- `aic-quality-gate` invoque `check-shims` + `check-features` + `check-feature-coverage` + `measure-context-size`.

## Cross-refs

- **`workflow/conversational-skills`** : fiche pilote de la bascule v3. Définit le contrat d'UX « 0 skill par défaut » dont cette fiche est la réalisation côté catalogue Claude.
- **`workflow/auto-worklog`** : brique hook invisible — les skills déclenchent des éditions, lui se charge de les logger.
- **`workflow/pre-turn-reminder`** : l'autre part visible du système (mais côté contexte injecté, pas invocation explicite).

## Historique / décisions

- v0.5 : 6 skills figés. Renoncement à un skill `/aic-feature-archive` (couvert par `/aic-feature-done` + édition manuelle status).
- v0.8 : reminders côté pre-turn i18n FR/EN. Skills restent en anglais (dette tracée).
- **2026-04-24** — Réouverture (phase=implement). Catalogue refondu : passage de 6 skills exposés à **3 exposés + 4 internes**. Origine : `workflow/conversational-skills` v3 (auto-progression invisible via hook Stop + pre-commit). Les skills internes ne disparaissent pas — ils restent au même emplacement, juste cachés de la surface utilisateur (`_message_after_copy`, `AGENTS.md → .ai/index.md`). Le nouveau skill `/aic` (override) rejoint le catalogue comme point d'entrée conversationnel unique quand l'auto-progression doit être corrigée. Aucune suppression de fichier ; uniquement redéclaration du rôle.
- **2026-04-28** — Catalogue passe à **9 skills** (5 exposés + 4 internes). Ajout de `/aic-project-guardrails` (voir `workflow/project-guardrails`) qui cadre les non-goals + glossaire métier dans `.ai/guardrails.md` — comble le trou « contexte général projet » que ne couvraient ni les rules ni le feature mesh. Resynchronisation de la table avec la réalité : `/aic-feature-audit` était déjà exposé dans `README.md` (`_message_after_copy`) mais absent de cette fiche — ajouté pour cohérence.
- **2026-05-03** — Refonte UX : ajout de `/aic-frame`, `/aic-status`, `/aic-review`, `/aic-ship` et repositionnement des skills `aic-feature-*` + `aic-quality-gate` comme primitives internes/fallback. Motivation : éviter une surface procédurale qui force l'utilisateur à connaître les étapes du mesh.
