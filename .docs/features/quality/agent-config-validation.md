---
id: agent-config-validation
scope: quality
title: Validation non destructive des configs agents
status: active
depends_on:
  - workflow/codex-hooks-parity
touches:
  - .ai/scripts/check-agent-config.sh
  - template/.ai/scripts/check-agent-config.sh.jinja
  - tests/unit/test-check-agent-config.sh
  - .ai/scripts/doctor.sh
  - template/.ai/scripts/doctor.sh.jinja
  - .ai/workflows/quality-gate.md
  - template/.ai/workflows/quality-gate.md.jinja
  - .github/workflows/ai-context-check.yml
  - template/.github/workflows/ai-context-check.yml.jinja
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
touches_shared:
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
  step: "check-agent-config livré et smoke-test PASS"
  blockers: []
  resume_hint: "prêt à review ; shellcheck non lancé car absent localement"
  updated: 2026-05-12
---

# Validation non destructive des configs agents

## Résumé

Ajouter un check déterministe qui valide les configurations agent connues, notamment `.claude/settings.json` et les futures configs Codex, sans modifier le dépôt.

## Objectif

Les hooks et configs agents sont une surface critique du workflow. Un script manquant, un timeout absent ou une config invalide peut désactiver silencieusement les garde-fous. Cette feature rend ces erreurs visibles dans la quality gate.

## Périmètre

### Inclus

- Valider la syntaxe et les commandes de `.claude/settings.json`.
- Valider les références de scripts dans une future configuration `.codex/` si elle existe.
- Brancher le check dans la quality gate, doctor et CI.
- Ajouter un test unitaire ciblé.

### Hors périmètre

- Installer ou activer des hooks Codex par défaut.
- Parser tous les formats TOML possibles avec une dépendance nouvelle.
- Remplacer les hooks Git ou les checks existants.
- Bloquer un projet qui n'utilise ni Claude ni Codex.

### Granularité / nommage

Cette fiche couvre uniquement la validation des configs agent. Les règles de fond des hooks Codex vivent dans `workflow/codex-hooks-parity`.

## Invariants

- Le check est lecture seule.
- L'absence de config agent est acceptée.
- Une config présente doit référencer des scripts versionnés existants.
- Les timeouts des hooks commandés doivent être explicites quand le format les expose.

## Décisions

- `jq` est requis pour valider JSON Claude, comme les autres scripts du mesh.
- Les configs Codex futures sont validées de façon prudente : scripts référencés, signaux de risque, absence de mutation.
- Les warnings ne remplacent pas les fails structuraux.

## Comportement attendu

`bash .ai/scripts/check-agent-config.sh` passe si aucune config agent n'existe, ou si les configs présentes sont lisibles et référencent des scripts existants. Il échoue sur JSON Claude invalide, hook Claude manquant, timeout invalide ou script référencé absent.

## Contrats

- Entrée : fichiers `.claude/settings.json` et `.codex/*` si présents.
- Sortie : rapport PASS/FAIL avec chemins précis.
- Code retour : `0` si aucun fail, `1` si au moins une erreur bloquante.
- Effet de bord : aucun fichier modifié.

## Validation

- `bash tests/unit/test-check-agent-config.sh`
- `bash .ai/scripts/check-agent-config.sh`
- `bash .ai/scripts/check-feature-docs.sh --strict quality/agent-config-validation`
- `bash .ai/scripts/check-features.sh`

## Risques

- Sur-valider un format Codex encore mouvant.
- Oublier le miroir template et créer un drift dogfood.
- Confondre warning de prudence et garantie de non-régression.

## Cross-refs

`workflow/codex-hooks-parity` définit ce que les hooks Codex peuvent faire. Cette feature vérifie seulement que les configs présentes ne sont pas cassées.

## Historique / décisions

- 2026-05-12 : création après HANDOFF `workflow -> quality` inclus dans le plan validé.
