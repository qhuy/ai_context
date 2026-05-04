---
id: claude-skills
scope: workflow
title: Skills /aic* publics + procédures internes
status: active
depends_on:
  - core/feature-mesh
  - workflow/auto-worklog
touches:
  - template/.claude/skills/**
  - template/.ai/workflows/**
progress:
  phase: implement
  step: "skills Claude maintenus hors contexte Codex obligatoire"
  blockers: []
  resume_hint: "valider que les workflows internes restent accessibles sans être chargés par défaut"
  updated: 2026-05-04
---

# Claude skills /aic*

## Objectif

Exposer côté Claude uniquement les intentions lisibles, et déplacer les étapes internes du mesh dans `.ai/workflows/` pour qu'elles soient partagées par Claude et Codex.

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

### Procédures internes (`.ai/workflows/`, non exposées comme skills Claude)

| Procédure | Rôle | Invocateur |
|---|---|---|
| `feature-new` | Créer fiche + worklog | `/aic-frame` après confirmation ou `/aic` sur intent explicite |
| `feature-resume` | Buckets EN COURS / BLOQUÉES / STALE / À FAIRE | Backend de `/aic-status` |
| `feature-update` | Bump `progress` (phase/step/blockers/resume_hint) | `/aic` sur intent « blocked / pause / j'attends » |
| `feature-handoff` | Passation inter-scope | `/aic handoff vers X` ou détection auto cross-scope |
| `feature-audit` | Rétro-doc / re-sync d'une fiche vs code réel | Backend ponctuel de `/aic-review` ou maintenance mesh |
| `quality-gate` | Check go/no-go déterministe | Backend de `/aic-ship` |
| `feature-done` | Clôture (evidence + status done) | `/aic force done` ou auto-progression V2 (pas encore implémentée) |
| `project-guardrails` | Non-goals + glossaire métier | `/aic-frame` quand un cadrage projet est nécessaire |

## Contrats

- Chaque skill public Claude : `SKILL.md` (description courte) + `workflow.md` (procédure d'orchestration).
- Les procédures internes vivent sous `.ai/workflows/` et ne sont pas invocables comme commandes Claude.
- Aucun skill ne contourne `auto-worklog` : ils déclenchent des éditions, le hook s'en charge.
- `quality-gate` invoque `check-shims` + `check-features` + `check-feature-coverage` + `measure-context-size`.

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
- **2026-05-03** — Migration : suppression des skills procéduraux de `.claude/skills/` et déplacement des workflows sous `.ai/workflows/`. Objectif : ne plus exposer les primitives tout en conservant une procédure partagée Claude/Codex.
- **2026-05-04** — Lean Codex : `.claude/skills/**` et `.ai/workflows/**` restent disponibles mais explicitement hors Pack A. `context-ignore.md` documente cette exclusion pour les agents non-Claude.
- **2026-05-04** — Les workflows internes référencent désormais `check-feature-docs.sh` et son strict ciblé. La surface skill publique ne change pas : l'usage reste intentionnel via `/aic-frame`, `/aic-review` et `/aic-ship`.
