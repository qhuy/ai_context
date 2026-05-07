---
id: context-relevance-tracker
scope: quality
title: Tracker minimal de pertinence du contexte injecté (sans MCP)
status: draft
depends_on: []
touches:
  - .ai/.gitignore
  - .claude/settings.json
  - .ai/scripts/features-for-path.sh
  - .ai/scripts/auto-worklog-log.sh
  - template/.ai/scripts/features-for-path.sh.jinja
  - template/.ai/scripts/auto-worklog-log.sh.jinja
  - template/.claude/settings.json.jinja
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
  phase: implement
  step: "5 choix tranchés post cross-check Codex, prêt à coder"
  blockers: []
  resume_hint: "créer context-relevance-log.sh + context-relevance-report.sh, brancher 3 hooks (PreToolUse via features-for-path, PostToolUse via auto-worklog-log, Stop séparé pour summary), B3 fenêtre last-summary, rotation taille 10MB"
  updated: 2026-05-07
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

Tranchées post cross-check Codex 2026-05-07 :

### 1. Branchement hooks (A1 partiel + Stop dédié)

- `features-for-path.sh` (PreToolUse Write|Edit|MultiEdit) appelle `context-relevance-log.sh inject ...` à la fin de son traitement.
- `auto-worklog-log.sh` (PostToolUse Write|Edit|MultiEdit) appelle `context-relevance-log.sh touch ...` en plus de son écriture session-edits.
- **Nouveau Stop hook séparé** : `bash .ai/scripts/context-relevance-log.sh summary`, ajouté dans `.claude/settings.json` après `auto-worklog-flush.sh` et `auto-progress.sh`. **Pas dans `auto-worklog-flush.sh`** : ce dernier exit early si aucun edit, ce qui raterait le cas critique « inject sans touch » (faux positif à mesurer).

### 2. Tour : fenêtre last-summary (B3)

- Le summary agrège les events depuis le dernier `event=summary` (fenêtre temporelle implicite, pas de UUID).
- Champs : `window_start_ts` (timestamp du dernier summary, ou epoch 0 au premier run), `window_end_ts` (now).
- **Si aucun inject/touch dans la fenêtre** : **no-op silencieux**. Pas de summary vide écrit.

### 3. Rotation par taille (C1)

- `.ai/.context-relevance.jsonl` rotation à 10 MB : `mv .context-relevance.jsonl .context-relevance.jsonl.old` quand seuil atteint.
- **Pas de promesse atomicité PIPE_BUF** (confusion pipes/FIFOs, pas applicable au fichier régulier). Contrat correct : best-effort, une écriture = un `printf '%s\n' >> file`, payload < 1 KB. Race append/rotation acceptée comme non bloquante.
- `.ai/.gitignore` : ajout de `.context-relevance.jsonl*` (jsonl + .old).

### 4. Reporter standalone

- `.ai/scripts/context-relevance-report.sh [--last N] [--feature scope/id] [--format markdown|json]`.
- Pas d'intégration `aic.sh` dans ce scope. Wrapper futur si besoin.

### 5. Tests E3 (unit + E2E)

Cas obligatoires :
- Unit logger : 3 événements (inject/touch/summary) écrits, JSONL parsable via jq.
- Unit reporter : 10 summaries synthétiques en input, ratios précision/rappel calculés correctement.
- E2E inject sans touch : PreToolUse + Stop sans PostToolUse → summary avec `injected_not_touched` non vide, `touched_not_injected` vide.
- E2E touch sans inject : PostToolUse + Stop sans PreToolUse → summary inverse.
- Rotation : taille seuil basse (1 KB pour test) → vérifier `.old` produit.
- Best-effort : simuler erreur d'écriture (permissions read-only) → hook continue, exit 0.

### Q1 résolu — pas de tour_id explicite

B3 fenêtre temporelle suffisante. UUID pas nécessaire. Si multi-Stop par prompt apparaît, traiter au moment où ça pose un vrai problème.

### Q2 résolu — logger même si unsupported

Champs structurés (pas parsing stderr) :
- `matcher_policy` : `silent|warn|strict`
- `unsupported_patterns` : `["foo**bar", ...]`
- `direct_features`, `dependency_features`, `injected_features`
- `omitted_count`, `top_k`

Si unsupported sans matches : log `inject` quand même avec ensembles vides + `unsupported_patterns` populated.

### Q3 résolu — pas de promesse atomicité

Cf. décision 3.

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
- ~~Matcher contaminé bash 3.2~~ : **résolu** par Phase 2 #2 (livrée commit `de6f86b` + fixes `6bf2b1b` `b5b1be7`). Le matcher est maintenant path-aware POSIX, no-overmatch garantis. Le tracker peut donc considérer `injected_features` comme fiable.
- Hooks PostToolUse Claude existent (cf. `.claude/settings.json:37-48` : Write|Edit|MultiEdit → `auto-worklog-log.sh`). On modifie ce dernier pour appeler aussi `context-relevance-log.sh touch`.
- Race append/rotation : best-effort, accepté comme non bloquant. Si problème futur, ajouter un lock `mkdir` dédié.

## Cross-refs

- `quality/features-for-path-ranking-and-matcher-correctness` : Phase 2 #2, source des `injected_features`. Le tracker devient pertinent après ce fix.
- `quality/review-delta-uncommitted-coverage` : Phase 2 #1, indépendant.
- `workflow/auto-worklog` : worklog automatique, pattern voisin (logger silencieux côté hook). Référence pour l'implémentation.
- `workflow/intentional-skills` : ordre Phase 2 décidé après cross-check Claude/Codex (round 4).

## Historique / décisions

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds). Format à 3 événements et ensembles complets (pas seulement intersection) précisé par Codex round 2-3 : sans `injected_not_touched` et `touched_not_injected`, on ne mesure pas les faux positifs/faux négatifs. Précision et rappel sont des proxies, pas des métriques sémantiques.
