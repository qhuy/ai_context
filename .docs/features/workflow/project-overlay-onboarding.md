---
id: project-overlay-onboarding
scope: workflow
title: Skill aic-onboard — init/sync/migrate de l'overlay projet
status: draft
depends_on:
  - core/project-overlay-scope-registry
  - workflow/intentional-skills
  - workflow/claude-skills
touches:
  - "template/.claude/skills/aic-onboard/**"
  - "template/.agents/skills/aic-onboard/**"
  - "template/.ai/workflows/project-overlay-sync.md.jinja"
  - ".claude/skills/aic-onboard/**"
  - ".agents/skills/aic-onboard/**"
  - ".ai/workflows/project-overlay-sync.md"
touches_shared:
  - "tests/smoke-test.sh"
  - ".docs/frames/2026-06-19-project-overlay-scope-registry.md"
product:
  initiative: product/ai-context-stability-migration
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
  phase: done
  step: "skill aic-onboard livré (Claude + Codex), procédure canonique, smoke-test étendu, drift vert"
  blockers: []
  resume_hint: "DONE côté implémentation. Validation end-to-end naturelle : exercer aic-onboard sur un vrai consumer multi-app. Décision migrate-legacy déjà couverte par la procédure."
  updated: 2026-06-19
---

# Skill aic-onboard — init/sync/migrate de l'overlay projet

> Cadrage source : [.docs/frames/2026-06-19-project-overlay-scope-registry.md](../../frames/2026-06-19-project-overlay-scope-registry.md)

## Résumé

Livrer le skill conversationnel `aic-onboard` qui peuple, maintient et migre l'overlay projet `.ai/project/**` en tant que registre de scopes. Il **détecte** ce qui est inférable du code, **interviewe** le savoir tribal non inférable, puis **scaffolde** une arborescence conforme au contrat de [core/project-overlay-scope-registry](../core/project-overlay-scope-registry.md). C'est le cœur opérationnel ; le contrat de forme, lui, est déjà livré.

## Objectif

Supprimer la falaise d'onboarding : aujourd'hui rien ne peuple `.ai/project/` sur un consumer fraîchement installé (`skip_if_exists`, jamais scaffoldé), et le `.ai/config.yml` par défaut scanne 0 fichier hors stack C#/React. Le skill rend l'overlay réellement exploitable, scope par scope, et offre un chemin de migration sûr pour les overlays existants.

## Périmètre

### Inclus

- Skill `aic-onboard` (entrée mince `SKILL.md` → `workflow.md`), parité Claude + Codex.
- Procédure canonique sous `.ai/workflows/` (source agent-agnostique).
- Trois modes auto-détectés selon l'état de `.ai/project/` :
  - `init` : pas d'overlay → détecter scopes, interviewer, scaffolder.
  - `sync` : overlay existant → enrichir/affûter par scope, sans écraser le curé.
  - `migrate` : overlay ancien (plat / config-only / règles legacy) → relocaliser vers le registre de scopes.
- Détection inférable (apps, couches, roots via `coverage.roots`, stack, commandes test/build).
- Interview du non-inférable (conventions tribales, ex. « tout SQL → script du sprint courant »).
- Garde-fous `migrate` : préserver (pas régénérer), proposer (diff + confirmation), idempotent (lecture du stamp `overlay_contract_version`).

### Hors périmètre

- Le **contrat de forme** de `.ai/project/<scope>/index.md` → livré par `core/project-overlay-scope-registry`.
- La documentation de la procédure de migration deux-temps → `product/ai-context-stability-migration` (`docs/upgrading.md`).
- Toute écriture hors `.ai/project/**`.
- La génération du contenu métier des conventions (le skill scaffolde le squelette + interviewe ; il ne devine pas les règles métier).

### Granularité / nommage

- Fiche distincte du contrat core : flux, validation et risques diffèrent (un skill interactif qui écrit du project-owned vs un contrat documentaire).

## Invariants

- Le skill n'écrit **que** sous `.ai/project/**` (project-owned) ; jamais dans l'upstream-managed.
- `migrate` est non destructif : relocation pure, réversible par git, jamais d'auto-apply sans confirmation.
- `migrate` est idempotent : no-op si le stamp `overlay_contract_version` est déjà à jour.
- `sync` n'écrase pas le contenu curé à la main : enrichissement additif.
- Le skill propose, l'humain valide (cohérent avec `aic-frame` : « pas de création sans confirmation »).

## Décisions

- **Skill backé par workflow** (pas script pur) : classer du code en scopes et relocaliser du contenu curé = inférence + interaction + écriture project-owned avec confirmation.
- **Un seul skill, trois modes** (pas trois skills) : mode auto-détecté selon l'état de `.ai/project/`, comme `aic-document-feature` (create/update/audit/close).
- **Migrate ≠ détection** : la migration relocalise, elle ne re-détecte pas ; sinon elle écraserait le savoir curé par des devinettes auto-détectées. L'enrichissement est la passe `sync`, séparée et explicite.

## Comportement attendu

L'utilisateur invoque `aic-onboard`. Le skill inspecte `.ai/project/`, choisit le mode, détecte les scopes inférables, pose les questions sur le non-inférable, présente une proposition d'arborescence conforme au contrat, et — après confirmation — écrit sous `.ai/project/**`. En `migrate`, il montre un diff de relocation avant d'appliquer.

## Contrats

- **Consomme** le contrat de forme de `core/project-overlay-scope-registry` (front-matter `scope`/`paths`/`meta`, sections `conventions`/`derived`, stamp global `overlay_contract_version` dans `.ai/project/index.md`).
- **Surfaces prévues** (à figer en `aic-dev-plan`) :
  - `.claude/skills/aic-onboard/{SKILL.md,workflow.md}` + jinjas template.
  - `.agents/skills/aic-onboard/{SKILL.md,workflow.md}` + jinjas template (parité Codex).
  - `.ai/workflows/project-overlay-sync.md` (+ jinja) — procédure canonique.
  - `tests/**` — couverture des trois modes.
- **Modes** : `init` | `sync` | `migrate`, auto-détectés ; override explicite possible.

## Validation

- `init` sur un repo sans overlay → arborescence conforme au contrat, écrite seulement sous `.ai/project/**`, après confirmation.
- `migrate` sur un overlay plat → relocation sans perte ; idempotent (no-op si stamp à jour).
- `migrate` sur ce repo (overlay config-only) → quasi no-op (fixture dogfood).
- Aucun fichier upstream-managed écrit ; `check-dogfood-drift` reste vert.
- Smoke-test + quality gate verts.

## Risques

- **Écriture project-owned depuis l'upstream** : le skill est livré par le template mais écrit dans le territoire du projet. Mitigation : invariant « seulement `.ai/project/**` » + confirmation systématique.
- **Détection faillible** : la classification en scopes est de l'inférence. Mitigation : proposition + validation humaine, jamais d'auto-apply.
- **Parité Claude/Codex** : risque de divergence des deux surfaces. Mitigation : procédure canonique unique sous `.ai/workflows/`, skills minces qui la pointent.
- Décision ouverte : le mode `migrate` v1 couvre-t-il la relocation des règles legacy `.ai/rules/<scope>.md`, ou seulement les overlays plats ? À trancher en `aic-dev-plan`.

## Cross-refs

- **`depends_on: core/project-overlay-scope-registry`** — fournit le contrat de forme que le skill produit et migre. Sans lui, le skill n'a pas de cible déterministe.
- **`depends_on: workflow/intentional-skills`** — le skill respecte la surface intentionnelle (verbe utilisateur clair, invocation explicite).
- **`depends_on: workflow/claude-skills`** — convention de structure des skills (SKILL.md mince → workflow.md) et parité Codex.
- **`product.initiative: product/ai-context-stability-migration`** — la procédure `migrate` deux-temps se documente dans `docs/upgrading.md`, possédé par l'initiative.

## Historique / décisions

- 2026-06-19 — Feature créée après HANDOFF `core → workflow` confirmé, une fois le contrat `core/project-overlay-scope-registry` livré et committé (0b6e685). Issue du cadrage `aic-frame` du 2026-06-19. Prochaine étape : `aic-dev-plan`.
