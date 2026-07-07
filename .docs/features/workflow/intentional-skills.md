---
id: intentional-skills
scope: workflow
title: Skills intentionnels pour cadrage, documentation, status, review et ship
status: done
depends_on:
  - workflow/claude-skills
  - workflow/agent-behavior
touches:
  - .ai/workflows/**
  - template/.ai/workflows/**
  - .claude/skills/aic-status/**
  - .claude/skills/aic/**
  - .claude/skills/aic-document-feature/**
  - .claude/skills/aic-review/**
  - .claude/skills/aic-ship/**
  - template/.claude/skills/aic-status/**
  - template/.claude/skills/aic/**
  - template/.claude/skills/aic-document-feature/**
  - template/.claude/skills/aic-review/**
  - template/.claude/skills/aic-ship/**
  - .agents/skills/aic/**
  - .agents/skills/aic-document-feature/**
  - .agents/skills/aic-ship/**
  - template/.agents/skills/aic/**
  - template/.agents/skills/aic-document-feature/**
  - template/.agents/skills/aic-ship/**
  - .ai/index.md
  - template/.ai/index.md.jinja
touches_shared:
  - .claude/skills/aic-frame/**
  - template/.claude/skills/aic-frame/**
  - .agents/skills/aic-frame/**
  - template/.agents/skills/aic-frame/**
  - template/README_AI_CONTEXT.md.jinja
  - README_AI_CONTEXT.md
  - copier.yml
  - README.md
  - PROJECT_STATE.md
  - CHANGELOG.md
  - tests/smoke-test.sh
progress:
  phase: done
  step: "surface intentionnelle réduite et clôturée avec preuve : 6 wrappers retirés (P3), parité stricte Claude/Codex, CHANGELOG tracé"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si la surface publique ou le trigger aic-frame changent"
  updated: 2026-07-07
type: feature
---

# Skills intentionnels

## Résumé

La surface utilisateur recommandée expose des intentions lisibles (`frame`, `status`, `diagnose`, `document-feature`, `review`, `ship`) et garde les primitives du feature mesh comme procédures internes ou fallback explicite.

## Objectif

Réduire la friction des skills Claude en exposant des intentions utilisateur plutôt que les primitives internes du feature mesh.

Le vocabulaire utilisateur devient :

- cadrer ;
- documenter une feature ;
- voir le status ;
- diagnostiquer ;
- review ;
- ship.

Les primitives procédurales vivent sous `.ai/workflows/`. Elles restent disponibles pour Claude et Codex, mais ne sont plus exposées comme skills Claude invocables par l'utilisateur.

## Périmètre

### Inclus

- Skills publics intentionnels Claude/Codex, surface identique entre les deux agents.
- Procédures internes `.ai/workflows/*` consommées juste-à-temps par ces skills (pas de wrapper séparé à invoquer).
- Surface CLI `aic.sh` pour les agents non hookés.

### Hors périmètre

- Modifier les hooks d'auto-progression.
- Changer le modèle de frontmatter feature.
- Ajouter un nouveau scope métier.

## Comportement attendu

- `/aic-frame` cadre une tâche/feature : objectif, position, spécificités métier, spécificités techniques, plan, validation, points à confirmer.
- `/aic-status` reprend le contexte : features en cours, blockers, stale, delta courant, prochaine action.
- `/aic-document-feature` documente une fiche du mesh : init/update/audit/handoff/done-check, sans logique projet spécifique.
- `/aic-review` analyse le delta : risques, features directes/liées, doc/freshness, checks.
- `/aic-ship` prépare la sortie : quality gate, freshness staged, evidence, risques, commit proposé.
- `.ai/workflows/*` porte les procédures internes : création/reprise/update/handoff/audit/gate/done/guardrails.

## Invariants

- Pack A reste lean : aucun skill, workflow ou fichier `.ai/agent/*` n'est chargé par défaut.
- Les workflows canoniques restent sous `.ai/workflows/`, consommés en interne par les skills — jamais exposés comme skills séparés.
- `/aic done` ne peut pas contourner la quality gate ni l'evidence build/tests/docs.
- Claude et Codex exposent exactement la même surface de skills (parité stricte, plus de wrapper Codex-only).

## Contrats

- Aucun de ces skills ne doit élargir Pack A ; les procédures et skills restent on-demand.
- `/aic-frame` ne code pas et ne crée pas de fiche sans confirmation.
- `/aic-ship` ne commit/push jamais sans confirmation explicite.
- Les équivalents Codex restent en langage naturel : "cadre cette feature", "montre le status", "review le delta", "prépare le ship".
- Claude et Codex s'appuient sur les mêmes procédures internes `.ai/workflows/`, sans dupliquer de logique dans les shims.

## Décisions

- **2026-07-07 (P3)** : retirer les 6 wrappers Codex procéduraux (`aic-feature-new`, `aic-feature-done`, `aic-feature-handoff`, `aic-feature-resume`, `aic-feature-update`, `aic-quality-gate`). Ils ne faisaient que citer leur workflow canonique et rediriger (garde-fou STOP+redirect) — aucun canal ne les invoquait en dehors d'eux-mêmes, et les 14 workflows de `.ai/workflows/` restent la source de vérité, déjà consommés en interne par les skills intentionnels. Zéro perte de capacité : les procédures restent disponibles pour Claude et Codex via lecture directe des workflows.
- Aligner `/aic done` sur `.ai/workflows/feature-done.md` au lieu de patcher `status: done` directement.
- Rendre les lectures de `aic-frame` juste-à-temps : `.ai/agent/*` et `QUALITY_GATE` ne sont chargés que si le risque ou l'intention le justifie.
- Utiliser `aic-document-feature` comme point d'entrée documentaire générique, sans logique projet spécifique.
- Trigger déterministe pour `aic-frame` : `QUALITY_GATE.md` chargé seulement si `progress.phase` ∈ {review, done}, ou intention nommée (ship / done / review / quality-gate), ou change touchant contrat (API, schema), sécurité, CI, doc canonique.
- Descriptions publiques (`aic-ship`, `aic-status`) enrichies avec les mots-clés d'intention associés. Pour `aic-ship` : la description référence `.ai/workflows/quality-gate.md` (backend réel, gate avant `feature-done`).

## Validation

- `bash .ai/scripts/check-shims.sh`
- `bash .ai/scripts/check-dogfood-drift.sh`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/intentional-skills`
- `bash tests/smoke-test.sh`

Preuve de clôture 2026-07-03 :

- Dépendances `workflow/claude-skills` et `workflow/agent-behavior` clôturées.
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/intentional-skills` PASS.
- `bash .ai/scripts/check-shims.sh` PASS.
- `bash .ai/scripts/check-dogfood-drift.sh` PASS.
- `bash .ai/scripts/check-features.sh --no-write` PASS.
- `bash tests/smoke-test.sh` PASS.

Preuve de clôture 2026-07-07 (P3, retrait des 6 wrappers) :

- Recherche de complétude (`rg` ciblé, hors smoke-test/CHANGELOG/docs historiques datées) : zéro référence résiduelle aux 6 wrappers retirés.
- `bash .ai/scripts/check-shims.sh` PASS.
- `bash .ai/scripts/check-features.sh --no-write` PASS (2 fiches voisines corrigées : `feature-new-approval-step`, `feature-granularity`).
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/intentional-skills` PASS.
- `bash .ai/scripts/check-dogfood-drift.sh` PASS.
- `shellcheck -S error tests/smoke-test.sh` silencieux (0 erreur).
- `bash tests/smoke-test.sh` PASS ×2 (un par commit).

## Cross-refs

- `workflow/claude-skills` : catalogue public vs interne.
- `workflow/agent-behavior` : posture attendue, prise de position, prochaine action.

## Historique / décisions

- 2026-05-03 : création des skills intentionnels `/aic-frame`, `/aic-status`, `/aic-review`, `/aic-ship`. Décision initiale : ne plus présenter les primitives procédurales comme UX recommandée.
- 2026-05-03 : retrait des primitives procédurales de `.claude/skills/` et déplacement sous `.ai/workflows/` pour préserver la logique interne tout en gardant la parité Claude/Codex.
- 2026-05-03 : `README_AI_CONTEXT.md` et son template ajoutent un workflow quotidien orienté intention : `status`, chargement du contexte pour un chemin, `review`, `doctor/check`. Objectif : rendre l'UX Codex explicite sans ajouter de skill procédural.
- 2026-05-03 : workflow quotidien étendu avec `mission`, `document-delta`, `repair` et `ship-report`. Objectif : proposer une surface naturelle Claude/Codex sans réintroduire les skills procéduraux.
- 2026-05-03 : `ai-context.sh` ajoute les commandes intentionnelles `product-status`, `product-portfolio` et `product-review` pour piloter les initiatives sans nouveau skill obligatoire.
- 2026-05-04 : ajout de l'intention `first-run` pour guider le premier usage après scaffold sans obliger Claude/Codex à invoquer un skill procédural.
- 2026-05-04 : ajout des intentions CLI `repair-copier-metadata` et `template-diff` pour rendre le cycle update Copier pilotable en langage naturel, sans nouveau skill utilisateur.
- 2026-05-04 : lean Codex confirmé : `.ai/index.md` garde les intentions comme vocabulaire d'usage, mais ne charge plus quality gate, `.ai/agent/*` ni workflows au démarrage.
- 2026-05-04 : `ai-context.sh check-docs` devient l'intention CLI pour vérifier la fiche "bible feature". Les workflows `feature-new`, `quality-gate` et `feature-done` documentent le strict ciblé avant DONE.
- 2026-05-06 : ajout de `/aic-document-feature` côté Claude et Codex. Le skill reste générique `ai_context`, documente le mesh feature et laisse `legacy` comme scope custom activable par les repos consommateurs.
- 2026-05-06 : resserrage post-audit skills. `/aic done` délègue désormais à `feature-done`, `aic-frame` charge `.ai/agent/*` et `QUALITY_GATE` seulement on-demand, et les primitives Codex `aic-feature-*` / `aic-quality-gate` sont explicitement marquées internes/fallback.
- 2026-05-06 (round 4) : cross-check Claude/Codex sur 4 rounds, application du plan consolidé. Garde-fous comportementaux ajoutés dans les 6 wrappers Codex (runtime + template) avec règle STOP+redirect sur matching lexical implicite. Trigger `aic-frame` rendu déterministe (phase + intention + type-change). Descriptions `aic-ship` (couvre done/clôture/livraison) et `aic-status` (couvre status/reprise/phase/état) enrichies sans rompre la chaîne intention publique → workflow canonique.
- 2026-06-02 : correction du wording `aic-ship` — la description référence désormais `.ai/workflows/quality-gate.md` (backend réel, gate avant `feature-done`) au lieu de `feature-done.md`. Appliqué aux 4 surfaces (runtime + template, Claude + Codex) ; `touches` étendu à `.agents/skills/aic-ship/**` (+ template). Cross-scope `core` (dogfood-runtime-sync, codex-skills-install, aic-surface-canonical, template-engine) → freshness propagée.
- 2026-07-03 : DONE. Surface intentionnelle livrée ; les primitives restent internes/fallback et Pack A reste lean.
- 2026-07-07 (P3, réouverture) : les 6 wrappers Codex `aic-feature-*`/`aic-quality-gate` sont retirés (racine + template). Ils étaient déjà catalogués « internes/fallback » sans aucune référence externe hors smoke-test et docs historiques — surface pure, zéro capacité perdue. `.ai/workflows/*` (14 procédures) reste la source canonique, consommée en interne par les skills intentionnels ; `copier.yml` (`_message_after_copy`) et `tests/smoke-test.sh` alignés. Parité Claude/Codex désormais stricte (même liste de skills).
