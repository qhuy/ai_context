---
id: agents-md-shim-canonical
scope: core
title: Shims dérivés d'AGENTS.md (base canonique + imports)
status: active
type: feature
description: "AGENTS.md devient la base de shim unique ; les shims spécifiques d'agent (CLAUDE.md, GEMINI.md, copilot) deviennent des imports @AGENTS.md + lignes agent, avec fallback tailored si l'import n'est pas supporté."
depends_on:
  - core/aic-surface-canonical
  - core/template-engine
  - product/readme-positioning
touches:
  - AGENTS.md
  - CLAUDE.md
  - template/AGENTS.md.jinja
  - template/CLAUDE.md.jinja
  - template/GEMINI.md.jinja
  - template/.github/copilot-instructions.md.jinja
  - .ai/scripts/check-shims.sh
  - template/.ai/scripts/check-shims.sh.jinja
touches_shared:
  - copier.yml
  - MIGRATION.md
  - docs/upgrading.md
  - CHANGELOG.md
external_refs:
  frame: ".docs/frames/2026-06-28-audit-strategique-remediation.md"
  github: "https://github.com/anthropics/claude-code/issues/34235"
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: implement
  step: "gate @import PASSÉ ; modèle par agent déterminé ; prêt à convertir AGENTS.md (base neutre) + shims"
  blockers: []
  resume_hint: "Implémenter : (1) rendre AGENTS.md neutre (pas 'Codex') = base ; (2) CLAUDE.md=@AGENTS.md+ligne Claude, GEMINI.md=@AGENTS.md+ligne Gemini (imports confirmés) ; (3) Cursor/Copilot = pas de shim requis (lisent AGENTS.md nativement) ou tailored minimal ; (4) étendre check-shims aux agents activés. À confirmer : Claude lit-il vraiment AGENTS.md nativement (#34235) ?"
  updated: 2026-06-29
---

# Shims dérivés d'AGENTS.md (base canonique + imports)

## Résumé

Faire d'`AGENTS.md` la **base de shim unique** (contenu réel, déjà toujours rendue par Copier). Les shims spécifiques d'agent (`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`) cessent d'être des copies parallèles tailored et deviennent des **imports** (`@AGENTS.md` + 1-2 lignes agent-spécifiques), avec un **fallback tailored** quand un agent ne supporte pas l'import. Objectif : supprimer la dérive multi-shims et aligner ai_context sur le standard `AGENTS.md` (couche de gouvernance au-dessus, pas Nième format).

## Objectif

L'écosystème mi-2026 a convergé sur `AGENTS.md` (standard Linux Foundation, 30+ agents) + `import`/`symlink`, contre la duplication. ai_context maintient des shims parallèles taillés par agent qui pointent tous vers `.ai/index.md` — dérive à l'édition et dette nette si Claude Code finit par lire `AGENTS.md` nativement. Cette feature réduit le coût de maintenance à un seul fichier de contenu de shim et acte le positionnement « au-dessus d'AGENTS.md ».

## Périmètre

### Inclus

- `AGENTS.md` comme base de contenu de shim (déjà toujours rendue ; jamais exclue dans `copier.yml`).
- Conversion de `CLAUDE.md` (et des agents dont l'import est confirmé) en `@AGENTS.md` + lignes agent-spécifiques minimales (ex. pointeur `.claude/settings.json` pour Claude).
- Extension de `check-shims.sh` : valider la base + le modèle d'import pour **tous les agents activés** (lire la liste depuis `.copier-answers.yml`), pas seulement `AGENTS.md`+`CLAUDE.md` en dur.
- Veille avec **kill_criterion** : « si Claude Code lit `AGENTS.md` nativement (issue #34235), retirer le double-shim ».
- Migration downstream documentée (`copier update` change la forme des shims édités).

### Hors périmètre

- L'indirection `.ai/index.md` elle-même (grief audit « source non-native ») — chantier séparé ; `.ai/` reste la source de contenu (invariant `aic-surface-canonical`).
- Le **pitch** « couche au-dessus d'AGENTS.md » — porté par `product/readme-positioning` (HANDOFF).
- La génération conditionnelle par agent dans `copier.yml` — co-porté par `core/template-engine` (HANDOFF).
- L'extension de `check-dogfood-drift` aux profils non-défaut (cursor/gemini/copilot) — recoupe l'item A12 du frame.

### Granularité / nommage

Une fiche pour le **modèle de shim multi-agent**, distincte de `aic-surface-canonical` (taxonomie `aic-*`) et de `template-engine` (moteur Copier).

## Invariants

- `AGENTS.md` reste **toujours** présent (base universelle, jamais exclue).
- `.ai/index.md` reste la source de **contenu** ; les shims sont des **entrées**, pas du contenu dupliqué.
- Aucun shim livré ne doit être **non fonctionnel** : si un agent ne supporte pas l'import, fallback tailored minimal.
- Les shims restent **lean** (`check-shims` : `MAX_LINES`, `MAX_PACK_A_WORDS`).
- Parité runtime/template tenue (dogfood drift).

## Décisions

- **Import, pas symlink** (tranché 2026-06-28). Le symlink aplatirait le sur-mesure par agent (CLAUDE.md perd son pointeur `.claude/settings.json`) et est fragile sur Windows / au rendu Copier. L'import (`@AGENTS.md` + lignes agent) préserve le sur-mesure et reste un fichier normal portable.
- **Fallback tailored** pour tout agent sans support `@import` confirmé : ne jamais livrer un shim cassé.
- **Nouvelle fiche** plutôt qu'extension de `aic-surface-canonical` (tranché 2026-06-28) : contrat durable distinct.
- `AGENTS.md` comme base (et non `.ai/index.md` directement comme shim) : conserve l'invariant `.ai/` source de contenu tout en donnant une entrée que les 30+ agents lisent nativement.

## Comportement attendu

- `copier copy agents=[claude,codex]` → `AGENTS.md` (contenu réel) + `CLAUDE.md` (`@AGENTS.md` + pointeur Claude). Éditer le shim = éditer `AGENTS.md` seul.
- `check-shims.sh` valide : base présente, imports bien formés pour les agents activés, contraintes lean respectées.
- Codex : `AGENTS.md` est déjà sa surface — gain direct.
- Agent sans `@import` : shim tailored minimal, validé comme tel.

## Contrats

- **Entrée de shim canonique** : `AGENTS.md` (toujours rendue).
- **Shims dérivés** : `CLAUDE.md`/`GEMINI.md`/`copilot-instructions.md` = `@AGENTS.md` + lignes agent, OU tailored minimal en fallback.
- **`check-shims`** : valide base + dérivés pour tous les agents de `.copier-answers.yml` ; échoue si un shim activé est absent ou non lean.
- **Downstream** : transition par phase — warning/migration documentée avant changement de défaut.

## Validation

- `bash .ai/scripts/check-shims.sh` (base + imports pour agents activés).
- `bash .ai/scripts/check-dogfood-drift.sh` (parité ; AGENTS.md+CLAUDE.md dogfoodés).
- `bash tests/smoke-test.sh` (rendu multi-agents).
- `bash .ai/scripts/measure-context-size.sh` (shims lean).
- Cas limites : agent sans `@import` → fallback tailored validé ; `copier update` downstream → conflit documenté ; Windows/CI → import = fichier normal (pas de symlink).
- **Gate amont (bloquant) avant tout code** : vérifier empiriquement le support `@import` par agent (Claude d'abord).

## Droits / accès

Non requis (`doc.requires.auth: false`). Aucun accès réseau/secret ; édition de fichiers repo-local uniquement.

## Données

Non requis (`doc.requires.data: false`). Données concernées : fichiers shim repo-local et `.copier-answers.yml` (lecture de la liste d'agents).

## UX

Non requis comme interface applicative (`doc.requires.ux: false`). L'« UX » concernée est l'expérience agent/mainteneur : un seul fichier de shim à éditer, shims fonctionnels par agent.

## Observabilité

Non requis (`doc.requires.observability: false`). Preuves attendues : sorties de `check-shims`, `check-dogfood-drift` et smoke multi-agents.

## Déploiement / rollback

- Release N : introduire `AGENTS.md` base + imports pour les agents confirmés, garder le tailored pour les non-confirmés ; documenter dans `MIGRATION.md` / `docs/upgrading.md`.
- Release N+1 : généraliser l'import aux agents dont le support s'est confirmé.
- Rollback : revenir au shim tailored (les deux formes restent valides pour `check-shims`).
- Vérifs post-déploiement : `check-shims`, `check-dogfood-drift`, smoke multi-agents verts.

## Risques

- Support `@import` **non garanti** hors Claude (Cursor/Gemini/Copilot) → fallback obligatoire.
- `copier update` casse les `CLAUDE.md` downstream édités → migration documentée.
- Si Claude Code lit `AGENTS.md` nativement (issue #34235), même le double-shim Claude devient inutile → kill_criterion à surveiller.

## Cross-refs

- `core/aic-surface-canonical` : surface canonique `aic` + invariant « `.ai/` source unique » ; cette feature en dérive la stratégie de shim.
- `core/template-engine` : génération Copier conditionnelle des shims (HANDOFF).
- `product/readme-positioning` : pitch « couche au-dessus d'AGENTS.md » (HANDOFF, déjà rattaché A10/C1).
- `external_refs.github` : issue #34235 (support natif AGENTS.md dans Claude Code) = déclencheur du kill_criterion.

## Historique / décisions

- 2026-06-28 : création via `aic-frame` (item C1 du frame de remédiation `2026-06-28-audit-strategique-remediation`). Arbitrages tranchés : (a) nouvelle fiche dédiée ; (b) import `@AGENTS.md` + fallback tailored (symlink rejeté : aplatit le sur-mesure + fragile Windows). Gate d'implémentation : vérifier le support `@import` par agent AVANT tout code.
- 2026-06-29 : **gate `@import` PASSÉ** (vérification 4 plateformes, sources docs officielles). Verdict par agent : **Claude Code** = `@path` import OK (récursif ≤5 hops) **et lirait AGENTS.md nativement** (#34235 rapportée résolue printemps 2026) ; **Gemini CLI** = `@path` import OK (Memory Import Processor) ; **Cursor** = `@file` en `.mdc` non fiable MAIS lit AGENTS.md nativement (racine+nested) ; **Copilot** = pas d'import inline (lien Markdown only) MAIS lit AGENTS.md nativement (depuis 2025-08). Modèle retenu : AGENTS.md = **base neutre** ; `CLAUDE.md`/`GEMINI.md` = `@AGENTS.md` + lignes agent ; Cursor/Copilot = **pas de shim requis** (lecture native) ou tailored minimal. **À confirmer** : la lecture native d'AGENTS.md par Claude Code (un seul agent l'affirme, contredit l'audit initial #34235-ouverte) — n'impacte pas l'import, mais si vrai, renforce le kill_criterion (CLAUDE.md devient optionnel, conservé pour les overrides Claude).
