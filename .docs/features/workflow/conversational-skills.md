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
  - copier.yml
  - tests/smoke-test.sh
# NB : `template/.claude/skills/aic/**` et `template/.claude/skills/aic-resume/**`
# seront ajoutés à `touches` dès la phase=implement (validateur refuse les
# globs ne résolvant aucun chemin existant). Friction tracée.
progress:
  phase: spec
  step: "re-spec v3 — auto-progression invisible, /aic en override"
  blockers: []
  resume_hint: "rédiger SKILL.md /aic + hook Stop d'auto-progression + assertion smoke-test ; rouvrir workflow/claude-skills pour acter sa réduction de périmètre"
  updated: 2026-04-24
---

# Auto-progression invisible (+ skill `/aic` en override)

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
| Bascule `status: draft → active`, `active → done` | **Applique + rapporte** explicitement |
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

### Skills granulaires actuels

Les 5 skills `/aic-feature-{new,update,handoff,done,resume}` et `/aic-quality-gate` :
- **Disparaissent de l'UX** (plus mentionnés dans `_message_after_copy`, `AGENTS.md`).
- **Restent comme fonctions internes** (renommés ou conservés sous `template/.claude/skills/aic/internals/`).
- Invoqués par le hook `Stop` ou par `/aic` selon le routage.
- `/aic-quality-gate` reste accessible directement (utile en CI/scripts).

## Cross-refs

- **`workflow/claude-skills`** : périmètre **réduit radicalement** (de 6 skills exposés à 0 + 2 optionnels). Sera rouverte au moment de l'implem effective pour acter ce changement.
- **`workflow/auto-worklog`** : brique fondatrice — l'auto-progression s'appuie sur ses logs PostToolUse + Stop pour détecter les transitions.
- **`core/feature-index-cache`** : source pour la résolution fuzzy de cible (mode override `/aic`).

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
- Modèle final inspiré de la philosophie déjà présente dans le projet : *« le rituel doit être invisible »* (cf. `auto-worklog`).
