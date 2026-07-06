---
id: evidence-discipline
scope: workflow
title: Discipline de preuve — aucune affirmation sans source ni étiquette
status: active
type: contract
description: "Éliminer les suppositions des sorties d'agent : toute affirmation de fonctionnement est prouvée (code lu, commande exécutée, doc citée) ou explicitement étiquetée Hypothèse / À vérifier."
depends_on:
  - workflow/agent-behavior
  - workflow/pre-turn-reminder
touches:
  - .ai/workflows/evidence-discipline.md
  - template/.ai/workflows/evidence-discipline.md.jinja
  - .docs/features/workflow/evidence-discipline.md
  - .docs/features/workflow/evidence-discipline.worklog.md
touches_shared:
  - .ai/reminder.md
  - template/.ai/reminder.md.jinja
  - AGENTS.md
  - template/AGENTS.md.jinja
  - .claude/skills/aic-review/**
  - .claude/skills/aic-diagnose/**
  - .claude/skills/aic-pilot/**
  - .claude/skills/aic-frame/**
  - .agents/skills/aic-review/**
  - .agents/skills/aic-diagnose/**
  - .agents/skills/aic-pilot/**
  - .agents/skills/aic-frame/**
  - template/.claude/skills/aic-review/**
  - template/.claude/skills/aic-diagnose/**
  - template/.claude/skills/aic-pilot/**
  - template/.claude/skills/aic-frame/**
  - template/.agents/skills/aic-review/**
  - template/.agents/skills/aic-diagnose/**
  - template/.agents/skills/aic-pilot/**
  - template/.agents/skills/aic-frame/**
  - CHANGELOG.md
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: false
    observability: false
progress:
  phase: implement
  step: "contrat evidence-discipline créé ; reste hard rule (reminder + AGENTS.md) et wiring des 4 skills d'analyse"
  blockers: []
  resume_hint: "livrer la hard rule FR/EN dans reminder + AGENTS.md (15 lignes max), puis les NON-NEGOTIABLE des skills aic-review/diagnose/pilot/frame, puis clôturer avec preuve"
  updated: 2026-07-06
---

# Discipline de preuve — aucune affirmation sans source ni étiquette

## Résumé

Les agents ont tendance à « supposer » des fonctionnements pendant les analyses.
Cette feature introduit une exigence transverse : toute affirmation de
fonctionnement est **Prouvée** (fichier:ligne, commande exécutée, doc officielle,
mesure) ou explicitement étiquetée **Hypothèse** / **À vérifier**. L'affirmation
nue est interdite.

## Objectif

Rendre les analyses d'agent fiables par construction : l'utilisateur doit pouvoir
distinguer d'un coup d'œil le prouvé du supposé, et une supposition ne doit jamais
se déguiser en fait. La discipline existait par fragments (table des incertitudes
d'`aic-frame`, colonne `evidence` du registre natif, evidence build/tests avant
DONE) ; cette feature la généralise à toute sortie d'agent.

## Périmètre

### Inclus

- Le contrat transverse `.ai/workflows/evidence-discipline.md` : les trois étiquettes, leurs exigences, l'interdit de l'affirmation nue.
- Une hard rule dense injectée à chaque tour (`.ai/reminder.md`, FR + EN) et portée par `AGENTS.md` (tous agents, y compris lecture native Cursor/Copilot).
- Le wiring dans les règles non négociables des quatre skills d'analyse : `aic-review`, `aic-diagnose`, `aic-pilot`, `aic-frame` (Claude + Codex + miroirs template).

### Hors périmètre

- Tout gate mécanique de véracité : un script ne peut pas vérifier qu'une affirmation est vraie, et les hooks LLM-juges sont interdits (`workflow/codex-hooks-parity`).
- La couche posture on-demand (`.ai/agent/*`) : la règle est une hard rule, pas un conseil de style ; l'invariant de `workflow/agent-behavior` (rien de comportemental on-demand dans le Pack A) n'est pas remis en cause.
- L'extension à `QUALITY_GATE.md` (evidence des analyses avant review) : phase ultérieure éventuelle.

### Granularité / nommage

Une fiche pour le contrat de preuve transverse. Les formats de sortie détaillés
restent portés par les fiches des skills (`workflow/intentional-skills`,
`workflow/claude-skills`).

## Invariants

- Le Pack A reste lean : la hard rule tient en une ligne dans le reminder (~90 caractères) et `AGENTS.md` reste ≤ 15 lignes (limite `check-shims`).
- La règle est identique pour tous les agents ; seul le canal diffère (reminder par tour pour Claude/Codex, `AGENTS.md` pour tous).
- L'étiquette Hypothèse est une soupape, pas une échappatoire : une hypothèse qui peut changer la décision, la route ou le DONE devient bloquante (règle héritée d'`aic-frame`).
- Aucune promesse de garantie mécanique : l'enforcement est comportemental et structurel, et documenté comme tel.

## Décisions

- La règle vit dans les hard rules (reminder + AGENTS.md), pas dans `.ai/agent/posture.md` : une règle on-demand ne changerait pas le comportement par défaut, or c'est précisément le comportement par défaut qui est en cause.
- `AGENTS.md` reste à 15 lignes en condensant le paragraphe « Shim lean » (2 lignes → 1) plutôt qu'en montant la limite `MAX_LINES` de `check-shims` — le contrat lean est préservé.
- Trois étiquettes seulement (Prouvé / Hypothèse / À vérifier), calquées sur le précédent FAIT/INTERPRÉTATION/OPINION d'ANALYSE.md mais orientées action.
- Le wiring des skills passe par leurs sections NON-NEGOTIABLE (une ligne par skill, pointant le contrat), pas par une réécriture des formats de sortie.

## Comportement attendu

Un agent qui analyse, review, diagnostique ou cadre étiquette chaque affirmation
de fonctionnement : source citée si prouvée, « Hypothèse — à vérifier via X »
sinon. En exploration, les hypothèses étiquetées sont acceptables ; près d'une
décision ou d'un DONE, elles doivent être converties en preuves ou en blocages
explicites. Un agent sans injection par tour (Gemini) reçoit la règle via
`AGENTS.md` uniquement — fiabilité moindre, assumée.

## Contrats

- Contrat canonique : `.ai/workflows/evidence-discipline.md` (+ miroir template).
- Hard rule (reminder FR) : « Aucune supposition : tout fonctionnement affirmé est prouvé (code lu, commande exécutée, doc citée) ou marqué “Hypothèse — à vérifier”. »
- Hard rule (reminder EN) : « No assumptions: any claimed behavior is proven (code read, command run, doc cited) or flagged “Hypothesis — to verify”. »
- Skills d'analyse : une règle non négociable référençant le contrat.

## Validation

- `bash .ai/scripts/check-shims.sh` — AGENTS.md ≤ 15 lignes, auto-suffisant, Pack A lean.
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/evidence-discipline`.
- `bash tests/unit/test-agents-md-self-sufficient.sh` — hard rules inline préservées.
- `bash tests/smoke-test.sh` — étapes reminder ([3/28], i18n [23/28]) avec la nouvelle ligne FR/EN.
- `bash .ai/scripts/measure-context-size.sh` — coût par tour mesuré avant/après (impact attendu ≈ +90 caractères).
- `bash .ai/scripts/check-dogfood-drift.sh` — parité runtime/template.

## Risques

- Règle comportementale : efficacité réelle non garantie à 100 % — assumé, documenté dans le contrat (« discipline outillée, pas garantie machine »).
- Paralysie d'analyse si la règle est lue comme « tout prouver » : l'étiquette Hypothèse est la soupape explicite.
- Dérive de la ligne dense du reminder au fil des éditions : le contrat canonique reste la référence, la ligne ne fait que pointer la discipline.

## Cross-refs

- `workflow/agent-behavior` : la couche posture reste on-demand ; cette fiche place la règle au niveau hard rule sans violer l'invariant de non-gonflement du Pack A.
- `workflow/pre-turn-reminder` : canal d'injection par tour de la hard rule.
- `workflow/codex-hooks-parity` : le reminder atteint aussi Codex via `enable_codex_hooks` ; les gates LLM restent interdits.
- `workflow/intentional-skills` : possède les skills d'analyse dont les règles non négociables sont étendues.

## Historique / décisions

- 2026-07-06 : création après cadrage `aic-frame` (niveau high, demande utilisateur « primordiale » : éliminer les suppositions). Décisions clés : hard rule dans le Pack A plutôt que posture on-demand ; AGENTS.md condensé plutôt que limite montée ; trois étiquettes orientées action ; enforcement honnêtement décrit comme comportemental + structurel, jamais mécanique.
