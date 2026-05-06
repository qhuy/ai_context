---
id: context-relevance-tracker
scope: quality
title: Tracker minimal de pertinence du contexte injecté (sans MCP)
status: draft
depends_on: []
touches:
  - .ai/.gitignore
  - .claude/settings.json
  - tests/smoke-test.sh
touches_shared:
  - .ai/scripts/features-for-path.sh
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
  phase: spec
  step: "draft cadré, à reprendre pour implémentation"
  blockers: []
  resume_hint: "implémenter context-relevance-log.sh (3 événements) + report.sh, brancher hooks Claude, vérifier que la métrique reste un proxy non-bloquant"
  updated: 2026-05-06
---

# Tracker minimal de pertinence du contexte injecté

## Résumé

Aujourd'hui, le hook PreToolUse Claude injecte des features matchées par `features-for-path.sh` sans qu'on sache si elles sont effectivement utiles. Cette fiche cadre un tracker minimal qui logue les features injectées vs les features réellement touchées en fin de tour, pour produire un ratio précision/rappel approximé. Sans MCP. Best-effort, jamais bloquant.

## Objectif

Donner une boucle de calibration pour le ranking et le matcher de `features-for-path.sh` (Phase 2 #2). Sans cette boucle, les choix de top-K et de critère de spécificité sont aveugles.

Mesurer un proxy de pertinence, pas la pertinence sémantique : on regarde si une feature injectée a été touchée dans le tour, pas si l'agent a vraiment utilisé son contexte. C'est suffisant pour détecter le bruit structurel (feature toujours injectée, jamais touchée).

## Périmètre

### Inclus

- Script `context-relevance-log.sh` qui écrit en append dans `.ai/.context-relevance.jsonl`.
- Trois événements : `inject` (PreToolUse), `touch` (PostToolUse), `summary` (Stop).
- Script `context-relevance-report.sh --last N` qui agrège les N derniers tours et produit un rapport markdown.
- Branchement minimal côté Claude : hooks PostToolUse et Stop dans `.claude/settings.json`. Le PreToolUse log se greffe sur le hook existant.
- Ajout de `.ai/.context-relevance.jsonl` dans `.ai/.gitignore` (runtime local, non versionné).

### Hors périmètre

- Tracker côté Codex/Cursor/Gemini : tant qu'il n'y a pas de hook équivalent, le tracker reste Claude-only. Le format JSONL reste agent-agnostic pour qu'un futur consommateur Codex puisse écrire dedans.
- Calcul de pertinence sémantique (au-delà du proxy ensembliste).
- Boucle automatique de calibration du ranking (humain ou agent lit le report et ajuste).
- MCP server (Phase 3 différée).

### Granularité / nommage

Cette fiche couvre un seul outil de mesure (logger + reporter). Le ranking lui-même est dans `quality/features-for-path-ranking-and-matcher-correctness`. La calibration humaine n'est pas un livrable de cette fiche.

## Invariants

- **Best-effort** : le tracker ne doit jamais bloquer l'agent ni un hook. Toute erreur est silencieuse côté logger.
- **Pas d'extraits de docs** : seulement clés feature (`scope/id`) et paths. Pas de contenu de fiche dans le log.
- **Pas de gate** : le rapport est un signal d'audit, pas une condition de DONE.
- **Rotation/trim** : le fichier est borné en taille (rotation au-delà d'un seuil, par défaut 10 MB ou N entrées).
- Agent-agnostic en lecture (n'importe quel agent peut lire `.ai/.context-relevance.jsonl` et le report).

## Décisions

Ouvertes, à arbitrer en phase implement :

- Format de rotation : par taille (10 MB) ou par nombre de tours (1000) ? Préférence : par taille pour borner le coût disque.
- Granularité du `tour` pour le `summary` : un tour = un cycle UserPromptSubmit → Stop côté Claude. Côté Codex sans hooks, on pourrait grouper par session si un jour on logue depuis là.
- Format du report : markdown avec tableau précision/rappel par feature, ou JSON structuré pour piping ? Préférence : markdown avec section JSON appendée pour piping.

## Comportement attendu

### Événement `inject` (écrit par le hook PreToolUse)

```jsonl
{"ts":"2026-05-06T22:30:00Z","event":"inject","hook":"PreToolUse","tool_name":"Edit","file":".agents/skills/aic-feature-done/SKILL.md","direct_features":["workflow/intentional-skills"],"dependency_features":["workflow/claude-skills"],"injected_features":["workflow/intentional-skills","workflow/claude-skills"],"truncated":false,"budget_chars":10000,"feature_index_mtime":"2026-05-06T20:00:00Z"}
```

### Événement `touch` (écrit par le hook PostToolUse)

```jsonl
{"ts":"2026-05-06T22:30:05Z","event":"touch","hook":"PostToolUse","tool_name":"Edit","file":".agents/skills/aic-feature-done/SKILL.md","touched_features":["workflow/intentional-skills"]}
```

### Événement `summary` (écrit par le hook Stop)

```jsonl
{"ts":"2026-05-06T22:35:00Z","event":"summary","files":[".agents/skills/aic-feature-done/SKILL.md"],"injected_features":["workflow/intentional-skills","workflow/claude-skills"],"touched_features":["workflow/intentional-skills"],"intersection":["workflow/intentional-skills"],"injected_not_touched":["workflow/claude-skills"],"touched_not_injected":[],"precision_approx":0.5,"recall_approx":1.0}
```

### Rapport

`bash .ai/scripts/context-relevance-report.sh --last 50` agrège les 50 derniers `summary` et produit un tableau markdown avec, par feature :

- nombre d'injections
- nombre de touches
- ratio précision approximée
- ratio rappel approximé

Avec en bas : top features `injected_not_touched` (candidats à ranker plus bas), top features `touched_not_injected` (candidats à matcher mieux ou ajouter).

## Contrats

- Fichier JSONL : `.ai/.context-relevance.jsonl`, runtime local, ignoré en commit.
- Logger : `bash .ai/scripts/context-relevance-log.sh <event> <args...>`. Best-effort, code retour toujours 0.
- Reporter : `bash .ai/scripts/context-relevance-report.sh [--last N] [--feature <scope/id>] [--format markdown|json]`. Code retour 0 si lecture OK.
- Variables d'env : `AI_CONTEXT_RELEVANCE_DISABLED=1` désactive le logger (utile en CI).

## Validation

- Test de logger : appeler le script avec un événement valide, vérifier que la ligne JSONL est appendée et parsable.
- Test de reporter : générer 10 tours synthétiques, vérifier que les ratios précision/rappel sont calculés correctement.
- Test best-effort : simuler une erreur d'écriture (permissions, disque plein), vérifier que le hook continue sans bloquer.
- `bash tests/smoke-test.sh` PASS après intégration.

## Risques

- Sur bash 3.2, le calcul d'intersection ensembliste peut être verbeux. Peut nécessiter `comm` ou des boucles. À tester avant de committer.
- `injected_features` est calculé par `features-for-path.sh` qui a un matcher contaminé sur bash 3.2 (bug couvert par `quality/features-for-path-ranking-and-matcher-correctness`). Tant que ce bug n'est pas fixé, les ratios sont biaisés. Le tracker devient **calibré** seulement après le matcher correct. Ne pas livrer en se reposant sur les ratios : c'est un instrument, pas un verdict.
- Hooks PostToolUse Claude peuvent ne pas exister aujourd'hui (à vérifier dans `.claude/settings.json`). Si non, créer le hook et tracer l'ajout dans `core/dogfood-runtime-sync` ou `workflow/git-hooks`.

## Cross-refs

- `quality/features-for-path-ranking-and-matcher-correctness` : Phase 2 #2, source des `injected_features`. Le tracker devient pertinent après ce fix.
- `quality/review-delta-uncommitted-coverage` : Phase 2 #1, indépendant.
- `workflow/auto-worklog` : worklog automatique, pattern voisin (logger silencieux côté hook). Référence pour l'implémentation.
- `workflow/intentional-skills` : ordre Phase 2 décidé après cross-check Claude/Codex (round 4).

## Historique / décisions

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds). Format à 3 événements et ensembles complets (pas seulement intersection) précisé par Codex round 2-3 : sans `injected_not_touched` et `touched_not_injected`, on ne mesure pas les faux positifs/faux négatifs. Précision et rappel sont des proxies, pas des métriques sémantiques.
