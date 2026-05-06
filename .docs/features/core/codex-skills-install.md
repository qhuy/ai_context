---
id: codex-skills-install
scope: core
title: Installer les skills Codex avec ai_context
status: done
depends_on: []
touches:
  - .agents/skills/**
  - template/.agents/skills/**
  - .ai/scripts/dogfood-update.sh
  - .ai/scripts/check-dogfood-drift.sh
  - tests/smoke-test.sh
  - README.md
  - CHANGELOG.md
touches_shared: []
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
  phase: done
  step: ""
  blockers: []
  resume_hint: "feature clôturée le 2026-05-04"
  updated: 2026-05-06
---

# Installer les skills Codex avec ai_context

## Résumé

Ajouter les skills Codex au runtime installé par défaut afin que les applications utilisant `ai_context` exposent directement les gestes `/aic-*` côté Codex, sans dépendre uniquement des skills Claude.

## Objectif

Réduire la friction d'usage dans Codex : les workflows `.ai/workflows/*` restent la source agent-agnostique, mais l'installation doit aussi fournir des wrappers `SKILL.md` consommables par Codex.

## Périmètre

### Inclus

- Ajouter une arborescence template `.agents/skills/`.
- Couvrir les gestes Codex équivalents aux workflows existants.
- Étiqueter les primitives procédurales comme internes/fallback pour préserver l'UX intentionnelle.
- Adapter les tests smoke pour vérifier leur présence.
- Documenter le comportement attendu.

### Hors périmètre

- Modifier les workflows métier eux-mêmes.
- Supprimer les skills Claude.
- Changer la mécanique des hooks ou du feature mesh.

## Invariants

- `.ai/workflows/*` reste la source procédurale partagée.
- Les skills Codex doivent être des wrappers minces et alignés avec les workflows existants.
- Les wrappers `aic-feature-*` et `aic-quality-gate` restent disponibles uniquement comme fallback explicite ; l'usage recommandé passe par `aic-frame`, `aic-status`, `aic-review`, `aic-ship`, `aic-document-feature` ou le langage naturel.
- L'installation Claude existante sous `.claude/skills` doit rester intacte.

## Décisions

- Installer les skills Codex dans `.agents/skills/`, chemin reconnu par Codex pour des skills locaux au projet.
- Garder `workflow.md` dans chaque skill Codex pour rendre le comportement self-contained.

## Comportement attendu

Après installation du template dans un projet cible, Codex voit les skills `aic-*` locaux et peut les invoquer naturellement sans demander à l'utilisateur de citer manuellement `.ai/workflows/...`.

## Contrats

- Fichiers générés : `.agents/skills/{nom-du-skill}/SKILL.md` et `.agents/skills/{nom-du-skill}/workflow.md`.
- Les workflows internes restent disponibles sous `.ai/workflows/*.md`.

## Validation

- `bash .ai/scripts/build-feature-index.sh --write`
- `bash .ai/scripts/check-features.sh`
- Smoke-test : présence des skills Codex publics et workflows internes.

## Droits / accès

Non applicable : aucune règle d'autorisation runtime n'est modifiée.

## Données

Non applicable : aucune donnée applicative ni migration n'est introduite.

## UX

Impact limité à l'UX agent : Codex peut découvrir les skills locaux sans demander à l'utilisateur de citer manuellement les workflows.

## Observabilité

Non applicable : aucun log, métrique ou signal runtime n'est ajouté.

## Déploiement / rollback

Déploiement par release du template Copier. Rollback : retirer `codex` de `agents` ou supprimer `.agents/skills` dans le projet cible.

## Risques

- Divergence entre wrappers Claude, wrappers Codex et workflows `.ai/workflows`.
- Surface de skills trop large si des procédures internes sont perçues comme UX principale.

## Cross-refs

Aucune dépendance déclarée.

## Historique / décisions

- 2026-05-04 : décision d'ajouter les skills Codex par défaut à l'installation.
- 2026-05-04 : ajout des wrappers `.agents/skills` conditionnés par l'agent `codex`.
- 2026-05-06 : alignement dogfood local : les skills Codex rendus sont synchronisés dans `.agents/skills/` et contrôlés par `check-dogfood-drift.sh`.
- 2026-05-06 : ajout du wrapper Codex `aic-document-feature`, aligné avec le workflow partagé `.ai/workflows/document-feature.md`.
- 2026-05-06 : les primitives Codex `aic-feature-*` et `aic-quality-gate` sont conservées mais marquées `Primitive interne/fallback` dans leurs descriptions.
