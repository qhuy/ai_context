---
id: feature-consolidation-nudge
scope: workflow
title: Nudge de consolidation à l'édition d'une fiche
status: active
type: feature
description: "Hook PreToolUse advisory qui, à l'édition d'une fiche, réinterroge sa raison d'être et liste les fiches sœurs (anti-prolifération edit-time)."
depends_on:
  - workflow/feature-granularity
  - workflow/feature-new-approval-step
  - workflow/pre-turn-reminder
  - core/feature-mesh
touches:
  - .ai/scripts/fiche-consolidation-nudge.sh
  - template/.ai/scripts/fiche-consolidation-nudge.sh.jinja
  - .claude/settings.json
  - template/.claude/settings.json.jinja
  - tests/unit/test-fiche-consolidation-nudge.sh
touches_shared:
  - .ai/workflows/feature-update.md
  - template/.ai/workflows/feature-update.md.jinja
  - tests/smoke-test.sh
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: review
  step: "hook + test + wiring + doc livrés"
  blockers: []
  resume_hint: "MVP livré (nudge seul). Suivi possible : détecteur d'overlap touches: (mode consolidate de feature-audit)."
  updated: 2026-06-26
---

# Nudge de consolidation à l'édition d'une fiche

## Résumé

Quand un agent **édite une fiche feature existante**, un hook `PreToolUse` réinjecte en contexte une **question de raison d'être** (« cette fiche doit-elle encore exister, ou être consolidée/fusionnée/supprimée ? ») accompagnée de la liste des **fiches sœurs** du même scope (familles d'id en tête). Forcing function **advisory** (jamais bloquante) pour enrayer la prolifération de fiches au fil de l'eau, sans nettoyage de masse.

## Objectif

Le contrôle anti-prolifération (`workflow/feature-granularity`) ne joue qu'à la **création** (`feature-new`). Rien ne réinterroge une fiche **après**. Résultat observé : sur-découpage qui s'accumule (ex. `ticketing-sales-reports` + `ticketing-sales-reports-rights` + …). Cette feature ajoute le pendant **edit-time** : à chaque touche d'une fiche, reposer la question, pour reconsolider progressivement.

## Périmètre

### Inclus

- `fiche-consolidation-nudge.sh` : hook `PreToolUse(Write|Edit|MultiEdit)` qui détecte l'édition d'une fiche existante et émet un `additionalContext` (question + fiches sœurs). Early-exit (coût ~nul) hors fiche.
- Wiring comme **2ᵉ hook** sous le matcher `Write|Edit|MultiEdit` de `.claude/settings.json` (+ jinja).
- Signal sœurs : **même scope** (même dossier) + **famille d'id** (`<base>-<suffixe>`, ancré sur séparateur) mise en avant. Liste cappée (12) avec note de troncature.
- Rappel de la discipline dans `.ai/workflows/feature-update.md` (paire split/consolidate).

### Hors périmètre

- **Blocage** : décision actée par `workflow/feature-granularity` (« pas de contrôle fragile/bloquant dans les scripts »). Le nudge est advisory.
- **Détecteur d'overlap** de `touches:` (Jaccard, hors boilerplate) pour classer les candidats de fusion → suivi possible comme « mode consolidate » de `workflow/feature-audit`.
- La création de fiche (couverte par `feature-new` / `feature-new-approval-step`).
- Toute fusion/suppression automatique (jugement humain/agent, jamais le hook).

### Granularité / nommage

Surface = un hook de contexte + une discipline edit-time. Distinct de `feature-new-approval-step` (création) et de `feature-audit` (drift code↔fiche). Couvre uniquement la réinterrogation à l'édition.

## Invariants

- **Advisory, exit 0 toujours.** Jamais de `decision:block` / `permissionDecision`. Aucune écriture (read-only, best-effort).
- **Ne se déclenche que sur édition d'une fiche existante** : tool ∈ {Write,Edit,MultiEdit}, chemin `…/features/<scope>/<id>.md`, fichier présent (création ⇒ skip), worklog exclu.
- **Coût négligeable hors fiche** : early-exit après lecture stdin + test de chemin, avant tout travail.
- Indépendant de `repo_root` : raisonne sur `file_path` absolu (robuste aux symlinks `/tmp`↔`/private/tmp`).

## Décisions

- **MVP = nudge seul** (question + liste sœurs même-scope/famille-d'id). Le détecteur d'overlap est un suivi distinct (cadrage `aic-frame` option 2).
- **Signal = même scope + famille d'id**, pas overlap de `touches:` (réservé au futur détecteur). Famille ancrée sur `<base>-` pour éviter les faux positifs (`feature-mesh` ↔ `feature-mesh-contract-alignment` = famille ; `feature-mesh` ↔ `feature-index-cache` ≠ famille).
- **2ᵉ hook dédié** plutôt que greffe sur `features-for-path.sh` : reste workflow-contained (pas de cross-scope vers `quality/features-for-path-ranking`), n'altère pas le chemin ranké, et early-exit ⇒ pas de surcoût sur les éditions de code.
- **Filesystem glob** du dossier de scope plutôt que l'index (pas de dépendance index/jq pour les sœurs ; jq seulement pour parser le payload + émettre le JSON).

## Comportement attendu

1. `PreToolUse(Write|Edit|MultiEdit)` → lit `{tool_name, tool_input.file_path}` sur stdin.
2. Early-exit si : pas Write/Edit/MultiEdit, chemin worklog, chemin hors `…/features/<scope>/<id>.md`, ou fichier absent (création).
3. Sinon : scope/id dérivés du chemin ; sœurs = autres `*.md` (hors worklog) du dossier de scope ; familles d'id en tête, autres cappées.
4. Émet `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":<question + sœurs>}}`, exit 0.

## Contrats

- Entrée : payload PreToolUse JSON sur stdin.
- Sortie : `additionalContext` (texte advisory), exit 0. Jamais de blocage.
- Cap sœurs : 12 « autres » + familles non cappées ; note `(+N autres)` si dépassement.
- Best-effort : jq/chemin absents ou anormaux ⇒ exit 0 silencieux.

## Validation

`tests/unit/test-fiche-consolidation-nudge.sh` (enregistré `tests/smoke-test.sh` [0k]) :
1. Édition d'une fiche existante → nudge avec question + sœur + famille d'id, sans le worklog.
2. Édition d'un worklog → rien.
3. Édition de code → rien.
4. Création d'une nouvelle fiche (fichier absent) → rien.

Preuve : `bash tests/smoke-test.sh` PASS + `check-dogfood-drift.sh` aligné.

## Risques

- **Bruit** : se déclenche à chaque édition de fiche. Atténué par le ton advisory court + cap. Suivi possible : rate-limit par fiche/session si jugé bavard.
- **Faux positifs famille d'id** : limités par l'ancrage `<base>-`. Le signal fort reste « même scope ».
- **Parité Codex** : le hook est Claude-only (`.claude/settings.json`). La discipline reste documentée dans `feature-update.md` (agent-agnostique) ; un équivalent Codex relèverait de `workflow/codex-hooks-parity` (non requis pour le MVP, advisory).

## Cross-refs

- `workflow/feature-granularity` (done) : règle anti-fourre-tout à la création ; ce nudge en est le pendant edit-time (même critère : objectif/DONE/validations identiques ⇒ consolider).
- `workflow/feature-new-approval-step` : contrôle à la création ; complémentaire, non redondant.
- `workflow/pre-turn-reminder` / `features-for-path.sh` : famille des hooks d'injection ; même envelope `additionalContext`.
- `workflow/feature-audit` : hôte naturel d'un futur détecteur d'overlap (mode consolidate).
- `workflow/codex-hooks-parity` : parité Codex éventuelle (hors MVP).

## Historique / décisions

- 2026-06-26 : création. Cadrage `aic-frame` (high), décisions : MVP nudge seul + signal même-scope/famille-d'id (advisory, honore la décision no-blocking de feature-granularity). Détecteur d'overlap laissé en suivi.
