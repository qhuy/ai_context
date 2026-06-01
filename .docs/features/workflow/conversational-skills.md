---
id: conversational-skills
scope: workflow
title: Auto-progression invisible (+ skill /aic en override)
status: draft
depends_on:
  - workflow/claude-skills
  - workflow/auto-worklog
  - core/feature-index-cache
touches:
  - template/AGENTS.md.jinja
  - template/.claude/skills/aic/**
  - .claude/skills/aic/**
  - .agents/skills/aic/**
  - template/.agents/skills/aic/**
touches_shared:
  - copier.yml
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "/aic marqué non-auto-invocable sur les 4 surfaces (Claude: disable-model-invocation ; agents: garde prose)"
  blockers: []
  resume_hint: "check-shims + check-dogfood-drift + smoke verts, puis commit FR conventional"
  updated: 2026-06-02
---

# Auto-progression invisible (+ skill `/aic` en override)

## Résumé

L'agent auto-progresse silencieusement les transitions d'état des fiches (`progress.phase`, `status`, worklog) et ne les rapporte que dans la réponse finale, ramenant l'UX à zéro skill au quotidien. Le skill `/aic` n'est qu'un mode override pour corriger ou forcer une bascule quand l'inférence se trompe.

## Objectif

Réduire la surface utilisateur du système à **zéro skill par défaut**. L'humain travaille en langage naturel ; l'agent code, teste, et **auto-progresse** les transitions d'état (`progress.phase`, `status`, scellage worklog) **silencieusement mais visiblement** (rapportées dans la réponse finale).

L'humain n'intervient que **2 fois par feature** :
1. Au début : décrire l'intent (« développe X »)
2. À la fin : valider le commit suggéré (« go »)

## Problème résolu

Le design initial exigeait 6 skills `/aic-*`, chacun à invoquer manuellement avec 5-6 champs structurés (`id`, `phase`, `step`, `resume_hint`, `blockers`…). Asymétrie absurde : 1 phrase de pensée humaine, 6 champs YAML à fournir.

Constats du dog-fooding :
- Le créateur lui-même ne maîtrisait pas la syntaxe d'invocation.
- 5 skills sur 6 ne font que des **mises à jour d'état suite à des actions** — comptabilité, pas travail.
- L'agent dispose déjà des informations nécessaires pour inférer ces transitions (auto-worklog sait quels fichiers ont été touchés ; tests/build savent si l'evidence est OK).

→ Faire de la comptabilité un service du système, pas une charge utilisateur.

## Périmètre

### Inclus

- L'auto-progression de bout en bout : détection d'intent, création/mise à jour de fiche, et bascules `progress.phase` / `progress.step` / `status` rapportées dans la ligne d'état finale.
- Les deux canaux de convergence partageant `auto-progress.sh` : hook Claude `Stop` (immédiat) et hook git `pre-commit` (universel, tous agents).
- Le skill `/aic` (override conversationnel + `/aic undo`) et son snapshot d'état dans `.ai/.progress-history.jsonl`.
- La réécriture des docs de surface (`copier.yml` `_message_after_copy`, `template/AGENTS.md.jinja`) pour exposer l'UX zéro skill.

### Hors périmètre

- La mécanique d'append worklog et de trace d'édition, portée par `workflow/auto-worklog`.
- L'hébergement du hook `pre-commit` lui-même, porté par `workflow/git-hooks`.
- La bascule `active → done`, déléguée à `.ai/workflows/feature-done.md` (quality gate, build/tests, docs strictes).
- La résolution fuzzy de cible, consommée depuis `core/feature-index-cache`.

## Comportement attendu

### Mode normal (par défaut, 95 % du temps)

L'humain prompt librement, sans préfixe. L'agent :

1. **Détecte l'intent** depuis la phrase (création, reprise, clôture, handoff…).
2. **Crée/met à jour la fiche** silencieusement si l'intent est clair (sinon 1 question de clarif).
3. **Code, teste, build** comme demandé.
4. **Hook `Stop`** observe la fin de tour et applique les transitions :
   - 1 fichier édité couvert par une feature → `progress.updated = today`, append worklog (existant)
   - tests passent + cohérence détectée → propose `phase: implement → review`
   - evidence complète + section `Contrats` à jour → propose `status: done`
5. **Réponse finale** inclut une **ligne d'état** transparente :

```
[code, diffs, etc.]

────────
📋 État : workflow/X
   phase  : implement → review (tests ✅ 24/24, check-features ✅ 12/12)
   touché : 5 fichiers (cf. worklog)
   commit prêt :
     feat(workflow): X — implem + tests
   → tape "go" pour commiter, ou décris la suite
```

### Mode override : `/aic <phrase>`

Reprend la main quand l'auto-progression se trompe ou pour des cas exceptionnels :
- `/aic non, repasse en spec` (annule transition mal inférée)
- `/aic marque ça en blocked, j'attends la spec backend`
- `/aic je rouvre feature-mesh pour ajouter status stable`

Affiche un plan, demande confirmation avant d'agir.

### Mode lecture : `/aic-resume`

Zero-arg, dump des buckets EN COURS / BLOQUÉES / STALE. Conservé tel quel (zéro friction d'invocation).

## Contrats

### Garde-fous asymétriques

| Type d'action | Règle |
|---|---|
| Bump `progress.updated`, append worklog | **Applique silencieusement** (déjà le cas via auto-worklog) |
| Bump `progress.phase`, `progress.step` | **Applique + rapporte** dans la ligne d'état |
| Bascule `status: draft → active` | **Applique + rapporte** explicitement |
| Bascule `active → done` | **Passe par `feature-done`** : quality gate, build/tests et docs strictes obligatoires |
| Édition de fichiers code | **Applique** (mode normal Claude Code) |
| Création d'une fiche feature | **Annonce avant** (« je crée `workflow/X` »), pas de question si intent clair |
| `git commit` | **Propose + attend "go"** (irréversible) |
| `git push`, `reset --hard`, suppression | **Toujours demande explicitement** |

Principe : invisible quand c'est sûr, visible quand ça mord.

### Règles d'inférence d'intent

| Vocabulaire / signal détecté | Transition appliquée |
|---|---|
| Phrase initiale décrivant un nouveau besoin sans match d'id | création de fiche, `phase: spec` |
| Édits de code sur `touches:` d'une feature en `phase: spec` | bascule en `phase: implement` |
| Tests + check-features verts juste après édits | propose `phase: review` |
| Evidence complète + section `Contrats` à jour | propose `status: done` |
| Phrase « pause / blocker / je continue plus tard » | `progress.blockers` mis à jour, pas de bascule |
| Phrase « je passe la main au scope X » | propose handoff explicite |

### Annulation

- `/aic undo` : revient à l'état `progress` précédent (snapshot pris à chaque transition par le hook `Stop`).
- Snapshot stocké en JSON dans `.ai/.progress-history.jsonl` (gitignore, append-only, garde 50 derniers).

### Procédures granulaires actuelles

Les primitives procédurales :
- **Disparaissent de l'UX** (plus mentionnés dans `_message_after_copy`, `AGENTS.md`).
- **Restent comme procédures internes** sous `.ai/workflows/`.
- Sont consommables par Claude et Codex sans être exposées comme skills Claude.
- La surface recommandée est `/aic-frame`, `/aic-status`, `/aic-diagnose`, `/aic-review`, `/aic-ship`.
- Ne sont pas chargées par défaut dans Pack A ; elles sont appelées juste-à-temps.

## Invariants

- Une transition est **invisible quand elle est sûre** (bump `updated`, append worklog) et **visible quand elle mord** (phase, step, `status`) : rapportée dans la ligne d'état finale.
- `active → done` ne se patche jamais directement : elle passe toujours par `feature-done` avec evidence obligatoire.
- `git commit` propose et attend « go » ; `git push`, `reset --hard` et suppressions demandent toujours explicitement.
- Idempotence des deux canaux : si Claude a déjà auto-progressé dans le tour, le `pre-commit` ne refait rien (`current_phase != "spec"`), aucun double-bump.
- Les deux canaux partagent le même script (`auto-progress.sh`) et le même format de trace (`.session-edits.flushed`).
- Chaque transition prend un snapshot `progress` dans `.ai/.progress-history.jsonl` (append-only, gitignore, 50 derniers) pour rendre `/aic undo` possible.

## Décisions

- **Zéro skill par défaut** : la comptabilité d'état devient un service du système (hooks + agent), pas une charge utilisateur — 2 interventions humaines par feature (intent + « go »).
- **Préfixe forcé `/aic`** sur tous les prompts : envisagé puis **rejeté** (friction massive sans gain ; hard rules + reminders couvrent déjà la discipline).
- **Renommage `→ workflow/auto-progress`** : **rejeté** pour stabilité d'`id` (cohérent avec l'heuristique extension/création du projet).
- **Convergence universelle via `pre-commit`** : retenue car le hook `Stop` est Claude-only ; le commit est le point commun à tous les agents (`claude, codex, cursor, gemini, copilot`, humain CLI).
- **`/aic` reste Claude-only** : acceptable car c'est un mode exceptionnel ; les autres agents éditent directement la fiche pour un override.
- **`/aic` non-auto-invocable (2026-06-02)** : l'override ne doit jamais se déclencher sur du matching lexical implicite. Mécanisme par harness — Claude : `disable-model-invocation: true` (champ natif) ; agents non-Claude (Codex/cursor/gemini/copilot) : garde prose dans la description (« invocation explicite uniquement »), comme les primitives `aic-feature-*`. La doctrine « commands vs skills » (mattpocock/skills) est ainsi satisfaite par le modèle 3-tiers déjà en place (intentions exposées / `/aic` override / procédures internes `.ai/workflows/`), sans nouvelle surface.
- **Codex `/aic` conservé fonctionnel (option ii)** : le fichier `.agents/skills/aic/` garde sa logique d'override mais devient explicitement non-auto-déclenchable ; précise — sans la contredire — la décision « Claude-only » (le flag natif n'existe que côté Claude, la parité d'intention passe par la prose côté agents).

## Cross-refs

- **`workflow/claude-skills`** : périmètre **réduit radicalement** (de 6 skills exposés à 0 + 2 optionnels). Sera rouverte au moment de l'implem effective pour acter ce changement.
- **`workflow/auto-worklog`** : brique fondatrice — l'auto-progression s'appuie sur ses logs PostToolUse + Stop pour détecter les transitions.
- **`workflow/git-hooks`** : héberge le hook `pre-commit` qui porte l'auto-progression pour tous les agents non-Claude (voir section Compatibilité ci-dessous).
- **`core/feature-index-cache`** : source pour la résolution fuzzy de cible (mode override `/aic`).

## Compatibilité multi-agents

L'auto-progression doit être **universelle** : le multiselect `agents` de `copier.yml` liste `claude, codex, cursor, gemini, copilot` — promettre un automatisme qui ne marche que pour Claude romprait le contrat.

Double convergence retenue :

| Canal | Déclenché par | Utilisateurs bénéficiaires | Latence |
|---|---|---|---|
| Hook Claude `Stop` (`auto-progress.sh`) | fin de tour Claude Code | Claude uniquement | immédiat (avant même le commit) |
| Hook git `pre-commit` (`.githooks/pre-commit`) | `git commit` | **tous** (Claude, Codex, Cursor, Gemini, Copilot, humain CLI) | au commit |

Les deux canaux partagent le **même script** (`.ai/scripts/auto-progress.sh`) et le même format de trace (`.session-edits.flushed`). Le hook `pre-commit` matérialise la trace à partir des fichiers stagés ; le hook Claude `Stop` la reçoit déjà construite par `auto-worklog-flush.sh`.

Idempotence : si Claude a déjà auto-progressé dans le tour (phase passée de `spec` à `implement`), le `pre-commit` ne refait rien (`current_phase != "spec"` → continue). Aucun double-bump.

Le skill `/aic` (mode override) reste Claude-only — acceptable : c'est un mode exceptionnel. Les autres agents peuvent éditer directement la fiche si besoin d'override (accessible, documenté dans `AGENTS.md`).

## Validation

- Assertion smoke-test (cross-scope `quality/smoke-test`) : vérifie la bascule `spec → implement` au commit, le snapshot dans `.progress-history.jsonl`, l'append worklog et l'idempotence.
- Régression dog-foodée : `auto-progress.sh` crée le worklog s'il est absent (cas des agents non-Claude via `pre-commit`) — bug révélé puis fixé, correctif propagé dans `.ai/scripts/` et `template/.ai/scripts/`.
- Override du seuil STALE testé via `progress.stale_after_days: 0` (le bucket STALE inclut alors `back/inprog`).
- `template/AGENTS.md.jinja` reste un shim mince : vérifié par `check-shims` (les détails runtime vivent dans `.ai/index.md` et les docs, pas dans le shim).

## Cross-scope anticipé (à l'implem)

- **quality** (`tests/smoke-test.sh`) : ajouter assertion « auto-progression bump phase après tests verts »
- Reste workflow ; pas de touch sur `core/`.

## Historique / décisions

- **2026-04-24** — 3 itérations de spec dans la même séance dog-fooding :
  - **v1** : wrapper additif `/aic` au-dessus des 6 skills (commit 18f4c91)
  - **v2** : remplacement des 6 skills par 1 conversationnel `/aic` (rejeté par l'utilisateur — toujours trop manuel)
  - **v3** (actuelle) : auto-progression invisible par hook `Stop` ; `/aic` rétrogradé en override
- **Préfixe forcé `/aic` sur tous les prompts** : envisagé puis **rejeté** (friction massive sans gain réel ; les hard rules + pre-turn-reminder couvrent déjà la discipline ; cas hors-skills inévitables).
- **Renommage `→ workflow/auto-progress`** : envisagé puis **rejeté** pour stabilité d'`id` (cohérent avec notre propre heuristique extension/création).
- **2026-05-03** — Le smoke-test commun lance désormais les tests unitaires de régression `check-feature-freshness` multi-feature et drift dogfood destination-only. Pas de changement sur `/aic`, mais cette feature touche `tests/smoke-test.sh` et reste documentée pour conformité freshness.
- **2026-05-03** — `tests/smoke-test.sh` passe en `touches_shared` : il reste visible dans les rapports mais ne rend plus chaque évolution du smoke-test bloquante pour la fiche `/aic`.
- **2026-05-03** — `_message_after_copy` ne présente plus les primitives procédurales comme gestes utilisateur. Les commandes exposées deviennent intentionnelles : `/aic-frame`, `/aic-status`, `/aic-diagnose`, `/aic-review`, `/aic-ship`.
- **2026-05-03** — Les primitives procédurales quittent `.claude/skills/` et sont déplacées sous `.ai/workflows/` pour conserver la logique interne sans exposer de commandes utilisateur procédurales.
- **2026-05-03** — `_message_after_copy` conserve l'UX zéro skill au quotidien ; la boucle product passe par la CLI commune `ai-context.sh product-*`, utilisable par Claude et Codex sans préfixe obligatoire.
- Modèle final inspiré de la philosophie déjà présente dans le projet : *« le rituel doit être invisible »* (cf. `auto-worklog`).
- **2026-04-24** — Ajout section `Compatibilité multi-agents` après prise de conscience du gap Codex : le hook Stop est Claude-only. Option B (git pre-commit comme point de convergence universel) retenue et implémentée dans `workflow/git-hooks` (mini-chantier 1.5, avant le skill `/aic` lui-même).
- **2026-04-24** — Chantier 2 : skill `/aic` écrit (`template/.claude/skills/aic/` + dog-food `.claude/skills/aic/`). 2 modes : `/aic undo` (consomme `.progress-history.jsonl`) et `/aic <phrase>` (override conversationnel avec résolution fuzzy + plan + confirmation). Zéro script Bash dédié — la procédure est entièrement dans `workflow.md`, exécutée par l'agent Claude via ses tools standards (Read/Edit/Bash). Pas de rupture de compatibilité : `/aic` reste Claude-only, les autres agents éditent directement les fiches pour les overrides exceptionnels (documenté comme acceptable).
- **2026-04-24** — Chantier 3 : docs de surface. `copier.yml` (`_message_after_copy`) et `template/AGENTS.md.jinja` réécrits pour exposer l'UX « 0 skill par défaut » aux utilisateurs des nouveaux projets. Les 4 skills internes (`/aic-feature-{new,update,handoff,done}`) disparaissent de la liste visible (conservés comme fonctions invoquées par `/aic` et les hooks). Édition cross-scope assumée vers `core/template-engine` (HANDOFF émis et clos dans son Historique).
- **2026-04-24** — Chantier 4 : assertion smoke-test [18/27] ajoutée (cross-scope `quality/smoke-test`, HANDOFF émis et clos). Vérifie la bascule spec→implement au commit + snapshot history + worklog + idempotence. A révélé un bug fixé : `auto-progress.sh` ne créait pas le worklog si absent (cas des agents non-Claude via pre-commit). Correctif propagé dans `.ai/scripts/` et `template/.ai/scripts/`. Reste pour passer en `phase: review` : chantier 5 (réouvrir `workflow/claude-skills` pour acter réduction 6→2 skills exposés).
- **2026-04-27** — Intégration incrémentale de `.ai/config.yml` dans `resume-features.sh` : le seuil STALE devient configurable via `progress.stale_after_days` (fallback 14j). Smoke-test enrichi pour valider l'override (`stale_after_days: 0` ⇒ bucket STALE inclut `back/inprog`).
- **2026-04-28** — `_message_after_copy` étendu pour exposer `/aic-project-guardrails` comme étape recommandée post-scaffold (étape 4 dans la liste numérotée + entrée dans la table « Commandes exposées »). N'invalide pas la philosophie « 0 skill par défaut au quotidien » : ce nouveau skill est explicitement positionné comme **1-2 fois dans la vie d'un projet** (bootstrap + révisions ponctuelles), pas un geste récurrent. Voir `workflow/project-guardrails`.
- **2026-05-03** — Audit post-commits : `template/AGENTS.md.jinja` redevient un shim mince. Les détails runtime multi-agents sont conservés dans `.ai/index.md` et les docs, pour préserver l'UX zéro skill sans casser `check-shims`.
- **2026-05-06** — Resserage `/aic done` : l'override ne patche plus directement `status: done`. Il délègue à `.ai/workflows/feature-done.md` et conserve l'evidence obligatoire (quality gate, build/tests, docs strictes).
- **2026-06-02** — `/aic` rendu non-auto-invocable sur les 4 surfaces (runtime + template, Claude + agents). Claude : ajout de `disable-model-invocation: true`. Agents : clause « invocation explicite uniquement — ne pas déclencher par matching lexical implicite » dans la description (parité avec les primitives `aic-feature-*`). Origine : analyse comparée du repo `mattpocock/skills` (doctrine commands-vs-skills) — constat que ai_context implémente déjà un modèle 3-tiers plus riche, le seul gain additif propre étant ce marquage. `touches` étendu aux 4 surfaces `/aic`.
