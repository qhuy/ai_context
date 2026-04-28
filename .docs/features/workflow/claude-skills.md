---
id: claude-skills
scope: workflow
title: Skills /aic* (cycle de vie feature — 3 exposés + 4 internes)
status: active
depends_on:
  - core/feature-mesh
  - workflow/auto-worklog
touches:
  - template/.claude/skills/**
progress:
  phase: implement
  step: "réduction périmètre UX 6→3 skills exposés (v3 auto-progression invisible)"
  blockers: []
  resume_hint: "valider en usage réel que les 4 skills internes ne sont plus invoqués à la main ; après quoi passer en review"
  updated: 2026-04-28
---

# Claude skills /aic*

## Objectif

Fournir les primitives du cycle de vie feature côté agent Claude. Depuis la bascule v3 (voir `workflow/conversational-skills`), les primitives sont **cachées derrière l'auto-progression invisible** (hooks Stop + pre-commit) et le skill override `/aic`. L'utilisateur n'en invoque plus que 3 à la main ; les 4 autres restent comme fonctions internes.

## Comportement attendu

### Skills exposés (invocation utilisateur attendue)

| Skill | Rôle | Quand l'invoquer |
|---|---|---|
| `/aic` | Override conversationnel de l'auto-progression (`/aic <phrase>`, `/aic undo`) | Quand l'auto-progression se trompe ou pour cas exceptionnels |
| `/aic-feature-resume` | Lecture : buckets EN COURS / BLOQUÉES / STALE / À FAIRE | Reprise de session, audit de backlog |
| `/aic-feature-audit` | Rétro-doc (`discover <scope>`) ou re-sync (`refresh <scope>/<id>`) d'une fiche vs code réel | Découverte d'orphelins, alignement après gros refactor |
| `/aic-quality-gate` | Check go/no-go complet (shims, features, coverage, size) | Avant PR, en CI, ou doute sur l'état global |
| `/aic-project-guardrails` | Cadre les non-goals + glossaire métier dans `.ai/guardrails.md` | 1-2 fois par projet — bootstrap après scaffold + révisions ponctuelles (pivot produit, nouveau hors-scope) |

### Skills internes (invoqués par les hooks et par `/aic`)

| Skill | Rôle | Invocateur |
|---|---|---|
| `/aic-feature-new` | Créer fiche + worklog | `/aic` sur intent « crée / développe X » |
| `/aic-feature-update` | Bump `progress` (phase/step/blockers/resume_hint) | `/aic` sur intent « blocked / pause / j'attends » |
| `/aic-feature-handoff` | Passation inter-scope | `/aic handoff vers X` ou détection auto cross-scope |
| `/aic-feature-done` | Clôture (evidence + status done) | `/aic force done` ou auto-progression V2 (pas encore implémentée) |

## Contrats

- Chaque skill : `SKILL.md` (description courte) + `workflow.md` (procédure détaillée).
- Les skills internes **existent toujours** et restent **invocables à la main** pour cas de fallback (debug, contournement), mais ne sont plus documentés dans `_message_after_copy` ni `AGENTS.md` → `.ai/index.md`.
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
