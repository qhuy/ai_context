---
id: project-guardrails
scope: workflow
title: Skill /aic-project-guardrails — non-goals + glossaire métier pour orienter l'agent
status: active
depends_on:
  - workflow/claude-skills
  - core/feature-mesh
touches:
  - .claude/skills/aic-project-guardrails/**
  - .ai/index.md
  - README_AI_CONTEXT.md
  - template/.claude/skills/aic-project-guardrails/**
  - template/.ai/index.md.jinja
  - template/README_AI_CONTEXT.md.jinja
  - copier.yml
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "création skill + intégration Pack A + smoke-test"
  blockers: []
  resume_hint: "vérifier que le skill rendu apparaît dans /tmp/test-guardrails après copier copy ; valider qu'un dialogue /aic-project-guardrails produit bien .ai/guardrails.md conforme"
  updated: 2026-04-28
---

# Skill /aic-project-guardrails

## Objectif

Combler le trou identifié dans le contexte général projet : la `project_description` (copier) se réduit à 1 ligne en blockquote, et les 8 skills `/aic-*` existants sont 100 % feature-centric. Aucun mécanisme ne capture **les non-goals** (ce que l'agent ne doit *pas* proposer) ni le **glossaire métier** (acronymes, vocabulaire spécifique).

Le skill cible spécifiquement ce qui n'est *pas* déjà dans le README — pour orienter l'agent, pas pour décrire le produit. Vision et utilisateurs cibles restent intentionnellement délégués au README pour éviter la duplication.

## Comportement attendu

### Surface

| Skill | Statut | Quand l'invoquer |
|---|---|---|
| `/aic-project-guardrails` | exposé | 1-2 fois dans la vie d'un projet — bootstrap après scaffold + révisions ponctuelles quand les non-goals évoluent |

### Workflow

1. **Cadrage** : détecter `.ai/guardrails.md`. Si présent → proposer `update` / `replace` / `cancel`.
2. **Non-goals** : dialogue. 3-7 items typiques. Pour chacun, raison courte si non-évidente. **Minimum 1 item obligatoire** (sans ça le skill perd sa valeur).
3. **Glossaire** (optionnel) : « Y a-t-il du vocabulaire métier spécifique ? Acronymes ? » — si non, section omise.
4. **Récapitulatif** + confirmation utilisateur.
5. **Écriture** de `.ai/guardrails.md`.
6. **Auto-référence** : si `.ai/index.md` ne référence pas encore `guardrails.md`, proposer d'ajouter la ligne dans Pack A.

### Livrable utilisateur

`.ai/guardrails.md` (sous `.ai/`, pas `{{ docs_root }}/`, parce que c'est de l'orientation agent et non de la doc produit). Sections :

- **Non-goals (explicitement hors-scope)** — items que l'agent ne doit pas proposer/implémenter.
- **Glossaire métier** (optionnel) — vocabulaire à utiliser tel quel.

## Contrats

- Skill **exposé utilisateur** (pas interne). Catalogue passe de 4 à 5 surfaces utilisateur (`/aic`, `/aic-feature-resume`, `/aic-quality-gate`, `/aic-feature-audit`, `/aic-project-guardrails`).
- Référencé dans Pack A via `.ai/index.md` § *Séquence de chargement obligatoire* — étape « 3. `.ai/guardrails.md` *(si présent)* ».
- Pas d'injection runtime dans `pre-turn-reminder.sh` → coût tokens nul après lecture initiale.
- Idempotent : ré-invocation = mode update sans perte de contenu.
- Pas de `feat:` commit déclenché par ce skill (livrable doc).
- Vision / Users / Roadmap **explicitement absents** du fichier généré (délégué au README).

## Cross-refs

- **`workflow/claude-skills`** : catalogue parent. Cette fiche ajoute une 9ème entrée (5ème surface utilisateur). La table § *Surface* y est mise à jour.
- **`core/feature-mesh`** : intégration Pack A — `.ai/guardrails.md` rejoint la séquence canonique de lecture des agents.

## Historique / décisions

- **2026-04-28** — Création. Première itération envisageait un skill 4-sections (Vision + Users + Non-goals + Glossaire) sous le nom `/aic-project-bootstrap`. Audit honnête : Vision et Users sont redondants avec README et `project_description`. Resserrage aux **Non-goals + Glossaire** seuls (la valeur unique non couverte ailleurs), renommage en `/aic-project-guardrails` (intent : orienter l'agent, éviter la dérive — distinct d'un README marketing). Le fichier produit vit sous `.ai/` (orientation agent) et non sous `{{ docs_root }}/` (doc métier).
- **2026-05-03** — Dogfooding appliqué au repo source : le skill rendu `.claude/skills/aic-project-guardrails/*`, la référence Pack A dans `.ai/index.md` et l'étape recommandée dans `README_AI_CONTEXT.md` sont synchronisés.
