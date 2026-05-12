# Worklog — workflow/intentional-skills

## 2026-05-04 — freshness
- Impact direct : la surface intentionnelle `aic-frame/status/diagnose/review/ship` est aussi générée sous `.agents/skills/` pour Codex.
- Les workflows canoniques restent sous `.ai/workflows/`.
- Validation associée : smoke-test complet PASS.

## 2026-05-04 — freshness
- Impact documentaire : `.ai/workflows/feature-new.md` reçoit un check anti fourre-tout sans changer la mécanique des skills intentionnels.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact documentaire : `feature-new` devient explicitement validable avant écriture, sans changer les autres skills intentionnels.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-features.sh` et `check-feature-docs.sh workflow/feature-new-approval-step` PASS.

## 2026-05-04 — freshness
- Impact template : `template/.ai/workflows/feature-new.md.jinja` propage la validation explicite avant écriture aux projets générés.
- Changement porté par `workflow/feature-new-approval-step`.
- Validation associée : `check-dogfood-drift.sh` PASS.
## 2026-05-05 — freshness
- Impact transversal : les messages de démarrage orientent les règles locales vers `.ai/project/index.md`.
- Validation associée : smoke-test PASS.

## 2026-05-06 — update
- Intent : ajouter `/aic-document-feature` comme intention explicite de documentation feature.
- Fichiers/surfaces : `.claude/skills/aic-document-feature/**`, `.agents/skills/aic-document-feature/**`, `.ai/workflows/document-feature.md`, README et smoke-test.
- Décision : `legacy` reste un scope custom documenté dans le workflow, non scaffoldé par défaut.
- Validation : dogfood + checks ciblés prévus.

## 2026-05-06 — freshness commit
- Impact couvert : wrappers runtime/template, workflow canonique, README, `copier.yml` et smoke-test.
- Aucun changement sur les autres skills intentionnels.
- Validation associée : `check-dogfood-drift.sh`, `check-shims.sh`, `check-ai-references.sh`, smoke-test PASS.
## 2026-05-06 — freshness
- Intent : documenter l'ajout de `aic-document-feature` dans la surface intentionnelle et le remplacement des anciens verbes CLI.
- Validation : couvert par `check-features` et `tests/smoke-test.sh`.

## 2026-05-06 21:57 — resserrage post-audit
- Intent : appliquer les préconisations validées après relecture des skills.
- Fichiers/surfaces : `aic`, `aic-frame`, wrappers Codex procéduraux, templates associés, fiche `workflow/intentional-skills`.
- Décisions : `/aic done` délègue à `feature-done`; `aic-frame` charge `.ai/agent/*` et `QUALITY_GATE` seulement on-demand; `aic-feature-*` et `aic-quality-gate` sont marqués internes/fallback.
- Validation : `check-shims`, `check-dogfood-drift`, `check-feature-docs --strict workflow/intentional-skills`, smoke-test à lancer.
- Next : vérifier dogfood et freshness sur le delta complet.

## 2026-05-06 22:30 — round 4 application (cross-check Claude/Codex)
- Intent : appliquer le plan consolidé après 4 rounds de cross-check Claude Opus 4.7 / Codex.
- Modifications :
  - 6 SKILL.md primitives Codex (runtime + template = 12 fichiers) : descriptions reformulées, préfixe "Primitive interne/fallback" déplacé en milieu pour préserver le matching de la phrase discriminante.
  - 6 workflow.md primitives Codex (runtime + template = 12 fichiers) : ajout d'une section "Invocation guard" en tête avec règle STOP+redirect sur sélection implicite (matching lexical), exécution autorisée seulement sur invocation explicite (nom littéral, chemin workflow canonique, ou instruction "utilise la primitive X").
  - 4 SKILL.md `aic-ship` (Claude + Codex + 2 templates) : descriptions enrichies avec "Couvre done / clôture / livraison ; s'appuie sur .ai/workflows/feature-done.md" — formulation stricte sans rappel primitive.
  - 4 SKILL.md `aic-status` (Claude + Codex + 2 templates) : descriptions enrichies avec "Couvre status / reprise / phase / état".
  - 4 workflow.md `aic-frame` (Claude + Codex + 2 templates) : trigger on-demand `QUALITY_GATE.md` rendu déterministe (`progress.phase` ∈ {review, done} OU intention nommée OU change touchant contrat/sécurité/CI/doc canonique). `.ai/agent/*` strictement on-demand sur demande explicite.
- Décisions consolidées :
  - Garde-fou comportemental dans body, pas seulement wording de description (apport Codex round 1).
  - Trigger déterministe sur phase + intention + type-change, pas `scope ∈ {core, quality}` (apport Codex round 2).
  - Chemin propre intention publique → workflow canonique, sans retour primitive (apport Codex round 2).
  - Formulation stricte « s'appuie sur » pour aic-ship, pas « appelle aic-feature-done » (précision utilisateur).
- Bash 3.2 confirmé en local (`/bin/bash 3.2.57 arm64-darwin25`) : critère P1 pour fiche Phase 2 `quality/features-for-path-ranking-and-matcher-correctness` (acceptance bloque livraison sur matcher correct multi-niveaux).
- Validation : check-shims, check-dogfood-drift, check-feature-docs --strict workflow/intentional-skills, smoke-test à exécuter immédiatement après cette entrée.
- Next : si PASS → bump phase → review et commit FR conventional. Si FAIL → diagnostiquer le check rouge.

## 2026-05-06 22:35 — validation round 4 PASS
- check-shims : PASS (shims OK, Pack A lean 87 mots, .ai/agent/* optionnel)
- check-dogfood-drift : PASS (runtime aligné avec rendu Copier minimal)
- check-feature-docs --strict workflow/intentional-skills : PASS
- check-features : PASS (toutes les fiches du mesh OK)
- tests/smoke-test.sh : PASS (pre-turn reminder 2264 chars ≤ 30000, AI_CONTEXT_FOCUS réduit, max_tokens_warn déclenché)
- Phase bumpée implement → review. Prêt à commit FR conventional.

## 2026-05-06 22:46 — auto
- Fichiers modifiés :
  - .agents/skills/aic-feature-done/SKILL.md
  - .agents/skills/aic-feature-done/workflow.md
  - .agents/skills/aic-feature-handoff/SKILL.md
  - .agents/skills/aic-feature-handoff/workflow.md
  - .agents/skills/aic-feature-new/SKILL.md
  - .agents/skills/aic-feature-new/workflow.md
  - .agents/skills/aic-feature-resume/SKILL.md
  - .agents/skills/aic-feature-resume/workflow.md
  - .agents/skills/aic-feature-update/SKILL.md
  - .agents/skills/aic-feature-update/workflow.md
  - .agents/skills/aic-frame/workflow.md
  - .agents/skills/aic-quality-gate/SKILL.md
  - .agents/skills/aic-quality-gate/workflow.md
  - .claude/skills/aic-frame/workflow.md
  - .claude/skills/aic-ship/SKILL.md
  - .claude/skills/aic-status/SKILL.md
  - template/.agents/skills/aic-feature-done/SKILL.md.jinja
  - template/.agents/skills/aic-feature-done/workflow.md.jinja
  - template/.agents/skills/aic-feature-handoff/SKILL.md.jinja
  - template/.agents/skills/aic-feature-handoff/workflow.md.jinja
  - template/.agents/skills/aic-feature-new/SKILL.md.jinja
  - template/.agents/skills/aic-feature-new/workflow.md.jinja
  - template/.agents/skills/aic-feature-resume/SKILL.md.jinja
  - template/.agents/skills/aic-feature-resume/workflow.md.jinja
  - template/.agents/skills/aic-feature-update/SKILL.md.jinja
  - template/.agents/skills/aic-feature-update/workflow.md.jinja
  - template/.agents/skills/aic-frame/workflow.md.jinja
  - template/.agents/skills/aic-quality-gate/SKILL.md.jinja
  - template/.agents/skills/aic-quality-gate/workflow.md.jinja
  - template/.claude/skills/aic-frame/workflow.md.jinja
  - template/.claude/skills/aic-ship/SKILL.md.jinja
  - template/.claude/skills/aic-status/SKILL.md.jinja

## 2026-05-08 — freshness
- Impact indirect : nettoyage drift README runtime/template + note mainteneur PROJECT_STATE (driver core/dogfood-runtime-sync).
- Aucun changement de contrat propre a cette feature.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : ajout de workflows on-demand `subagent-contract`, `codex-hooks-parity` et `mcp-policy` sans modifier les wrappers de skills intentionnels.
- Clarification README/runtime : ces contrats restent activables explicitement et compatibles multi-agent.
- Validation : `check-shims`, `check-features`, strict docs des nouvelles fiches et smoke-test PASS.
