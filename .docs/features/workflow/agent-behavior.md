---
id: agent-behavior
scope: workflow
title: Couche comportementale agent légère
status: active
depends_on:
  - workflow/claude-skills
touches:
  - .ai/agent/**
  - .claude/skills/aic-diagnose/**
  - .claude/output-styles/**
  - template/.ai/agent/**
  - template/.claude/skills/aic-diagnose/**
  - template/.claude/output-styles/**
touches_shared:
  - .ai/index.md
  - template/.ai/index.md.jinja
  - AGENTS.md
  - template/AGENTS.md.jinja
  - .ai/reminder.md
  - template/.ai/reminder.md.jinja
  - copier.yml
  - README.md
progress:
  phase: in_progress
  step: "chantier A restitution — lot 1 : contrat condensé canonique + output style + chargement clôture"
  blockers: []
  resume_hint: "registre .docs/pilots/2026-08-07-retour-ux-restitution.md ; lot 1 scope workflow en cours, lot 2 (core : AGENTS.md, reminder, settings outputStyle, copier.yml) après HANDOFF"
  updated: 2026-08-07
type: feature
---

# Couche comportementale agent légère

## Résumé

Une couche de qualité comportementale (posture, contrat d'initiative, style de réponse) vit sous `.ai/agent/`. Depuis la révision 2026-08-07 (chantier restitution), le **contrat de restitution** existe en deux niveaux : un **condensé canonique** (~10 lignes, défini dans `response-style.md` entre marqueurs) rendu au niveau session pour tous les agents (output style Claude, bloc AGENTS.md côté shim) et ancré à chaque tour par une ligne du reminder ; et le **contrat complet** chargé on-demand (diagnostic, style) et systématiquement près de la clôture (`aic-ship`, `aic-review`). `posture.md` et `initiative-contract.md` restent purement on-demand.

## Objectif

Améliorer proactivité, écoute, diagnostic, prise de position et **qualité de restitution** (synthèse, précision technique sourcée, clôture nette) sans transformer `ai_context` en prompt monolithique : le condensé coûte ~0 par tour (canaux session cachés), l'ancre par tour reste ≤ 1 ligne, la profondeur reste on-demand.

Origine de la révision : retour UX utilisateur multi-projets (registre `.docs/pilots/2026-08-07-retour-ux-restitution.md`) — réponses confuses, sans synthèse, données imprécises, divergence Claude/Codex. Cause prouvée : la démotion de la couche hors Pack A (`ea1adac`, 2026-05-04) avait rendu le contrat de style inopérant en flux normal.

## Périmètre

### Inclus

- Les fichiers comportementaux sous `template/.ai/agent/` : `posture.md.jinja`, `initiative-contract.md.jinja`, `response-style.md.jinja`, et leur rendu dogfoodé `.ai/agent/*`.
- Le **condensé canonique de restitution** : section balisée de `response-style.md` (source unique), et son rendu output style `.claude/output-styles/` (+ miroir template).
- Le skill Claude `/aic-diagnose` (`SKILL.md.jinja` + `workflow.md.jinja`) et son rendu `.claude/skills/aic-diagnose/*`.
- La déclaration de la couche dans `.ai/index.md` : condensé au niveau session, complet on-demand.

### Hors périmètre

- Les **rendus consommateurs** du condensé portés par d'autres fiches : bloc AGENTS.md (`core/agents-md-shim-canonical`), ancre reminder (`core/dogfood-runtime-sync`), clé `outputStyle` de `.claude/settings.json` et défaut `enable_codex_hooks` (`core/template-engine`) — suivis en `touches_shared`, livrés au lot core du chantier.
- La logique procédurale des intentions `frame/status/diagnose/review/ship` (`.ai/workflows/`, feature `workflow/claude-skills`) ; le chargement du contrat complet par `aic-ship`/`aic-review` appartient à `workflow/intentional-skills`.

## Invariants

- Les règles comportementales **complètes** vivent dans `.ai/agent/` ; les shims racine et le reminder ne portent jamais que le **condensé canonique** (ou son ancre 1 ligne), jamais le contrat complet ni posture/initiative.
- Le condensé a une **source unique** : la section balisée `AIC-RESTITUTION-CONDENSE` de `response-style.md`. Tout rendu (output style, AGENTS.md, ancre) dérive de cette section ; un écart de fond entre rendus est un bug de parité.
- Budget assumé (révision 2026-08-07) : condensé ≈ 120 tokens par canal session (caché), ancre ≤ 30 tokens par tour. `measure-context-size.sh` mesure ce budget ; il ne doit pas croître au-delà sans décision actée.
- `posture.md` et `initiative-contract.md` restent hors Pack A, hors shims, hors reminder — on-demand strict.
- Parité Claude/Codex : même condensé au niveau session des deux côtés (output style / AGENTS.md), même ancre par tour (hook partagé), même contrat complet à la clôture (skills `.claude` et `.agents`).

## Comportement attendu

- Toute session (Claude comme Codex) démarre avec le condensé de restitution en contexte session : TL;DR d'abord, synthèse quand le volume monte, données techniques sourcées, clôture fait/vérifié/risques/suite.
- Chaque tour porte une ancre d'une ligne rappelant le contrat (anti-dérive en session longue).
- Près de la clôture d'une tâche significative, l'agent charge le contrat complet (`response-style.md`), qui contient un exemple avant/après.
- Le diagnostic (`/aic-diagnose` ou lecture naturelle Codex) continue de charger posture + initiative + style à la demande.

## Contrats

- Fichiers agent :
  - `template/.ai/agent/posture.md.jinja`
  - `template/.ai/agent/initiative-contract.md.jinja`
  - `template/.ai/agent/response-style.md.jinja` — porte la section balisée `<!-- BEGIN AIC-RESTITUTION-CONDENSE -->` … `<!-- END AIC-RESTITUTION-CONDENSE -->`, le volet précision technique et l'exemple avant/après.
- Output style Claude :
  - `template/.claude/output-styles/aic-restitution.md.jinja` (rendu `.claude/output-styles/aic-restitution.md`) — frontmatter `name`, `description`, `keep-coding-instructions: true` ; corps = condensé canonique. Activation via `outputStyle` dans `.claude/settings.json` (lot core, fiche `core/template-engine`).
- Skill Claude : `template/.claude/skills/aic-diagnose/SKILL.md.jinja` + `workflow.md.jinja`.
- Compatibilité Codex : condensé rendu dans AGENTS.md (fiche `core/agents-md-shim-canonical`) ; ancre par tour via `pre-turn-reminder.sh` (hook UserPromptSubmit Claude et Codex).
- Mesure contexte : `measure-context-size.sh` compte désormais le condensé et l'ancre — budget acté ci-dessus.

## Décisions

- Couche éclatée en trois fichiers séparés (posture / initiative / style), inchangé.
- **2026-08-07 — Révision des décisions de mai** : la démotion totale hors Pack A (`ea1adac`) avait éteint le contrat de restitution (aucun chargement en flux normal, styles natifs divergents Claude/Codex, retour UX négatif). Nouveau modèle : **condensé session + ancre par tour + complet on-demand**, au lieu de « tout on-demand » (mai) ou « tout en Pack A » (avant mai). Le coût est borné et mesuré ; la profondeur reste juste-à-temps.
- Pas de skill côté Codex : lecture naturelle de `.ai/agent/*`, inchangé.
- Surface Claude/Codex orientée intentions (`frame/status/diagnose/review/ship`), inchangé.

## Validation

- `check-dogfood-drift.sh` : rendus runtime (`.ai/agent/*`, `.claude/output-styles/*`) alignés sur le template.
- `check-skills-parity.sh` : surfaces `.claude/skills` / `.agents/skills` alignées (chargement clôture inclus).
- `measure-context-size.sh` : budget condensé + ancre dans les bornes actées (~120 tokens/canal session, ≤ 30 tokens/tour).
- `check-feature-docs.sh --strict workflow/agent-behavior` : fiche cohérente.
- `smoke-test.sh` / `copier copy` : rendu Jinja sans erreur, output style généré quand `claude` est sélectionné.
- Preuve de bout en bout (registre pilot) : même prompt dans Claude et Codex, structure de réponse comparable (TL;DR, synthèse, sources, clôture) — consignée au registre avant clôture du chantier.

## Cross-refs

- `workflow/claude-skills` : conventions `SKILL.md.jinja` + `workflow.md.jinja`.
- `workflow/intentional-skills` : chargement du contrat complet par `aic-ship`/`aic-review` à la clôture.
- `workflow/codex-hooks-parity` : ancre par tour côté Codex (hook UserPromptSubmit, généré par défaut depuis la révision R5).
- `core/agents-md-shim-canonical`, `core/dogfood-runtime-sync`, `core/template-engine` : rendus consommateurs du condensé (lot core).
- Registre de pilotage : `.docs/pilots/2026-08-07-retour-ux-restitution.md`.

## Historique / décisions

- 2026-05-03 — Création de la couche comportementale en trois fichiers séparés et d'un skill `/aic-diagnose`. Décision : Pack A référence la couche, le reminder ne l'injecte pas.
- 2026-05-03 — Compatibilité Claude/Codex explicitée (skill vs lecture naturelle) ; dogfooding synchronisé ; `README.md` en `touches_shared` ; surface orientée intentions ; logique procédurale déplacée sous `.ai/workflows/`.
- 2026-05-03 — `response-style.md` : contrat de clôture de tâche adaptatif compact/structuré.
- 2026-05-04 — Lean Codex : `.ai/agent/*` sort du Pack A (`ea1adac`), couche disponible on-demand uniquement.
- 2026-07-03 — DONE. Couche confirmée on-demand ; aucune charge Pack A ni reminder.
- 2026-08-07 — **Réouverture (chantier restitution, pilot `2026-08-07-retour-ux-restitution`)** : le retour UX multi-projets prouve que le contrat on-demand n'est jamais chargé en flux normal (réponses confuses, divergence Claude/Codex, imprécision technique). Révision actée : condensé canonique session (output style Claude + bloc AGENTS.md) + ancre 1 ligne par tour + contrat complet chargé à la clôture par `aic-ship`/`aic-review`. Invariants, périmètre, budget contexte et validation réécrits en conséquence ; `touches` += `.claude/output-styles/**` (×2). Les invariants de mai (« jamais dans les shims », « reminder inchangé ») sont remplacés par la distinction condensé/complet.
