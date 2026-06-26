---
id: auto-worklog
scope: workflow
title: Auto-logging silencieux des éditions vers worklog feature
status: active
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
touches:
  - template/.ai/scripts/auto-worklog-log.sh.jinja
  - template/.ai/scripts/auto-worklog-flush.sh.jinja
  - .ai/scripts/auto-worklog-log.sh
  - .ai/scripts/auto-worklog-flush.sh
progress:
  phase: review
  step: "fix churn date — le flush ne bumpe plus progress.updated"
  blockers: []
  resume_hint: "fix churn livré ; suivi possible = option 1 (dériver updated: au build-index)"
  updated: 2026-06-26
type: feature
---

# Auto-worklog

## Résumé

Logue silencieusement les éditions d'une session Claude (`PostToolUse` Write/Edit) puis, à la fin du tour (`Stop`), les regroupe par feature et les append au worklog markdown. Zéro friction utilisateur : le worklog reste à jour sans saisie manuelle.

## Objectif

Capturer sans friction les modifications d'une session Claude vers les worklog des features touchées. L'utilisateur n'a rien à faire : les hooks `PostToolUse` (Write/Edit) loguent en JSONL volatile, le hook `Stop` regroupe par feature et append au markdown.

## Périmètre

### Inclus

- Les deux scripts hooks : `auto-worklog-log.sh` (capture `PostToolUse`) et `auto-worklog-flush.sh` (regroupement `Stop`), plus leurs gabarits `.jinja` livrés au template.
- Capture des paths édités, rattachement à une feature via `touches:` (délégué à `_lib.sh`) et append au worklog. **Le flush ne bumpe pas `progress.updated`** (cf. Décisions — fix churn date).
- Gestion du JSONL volatile `.ai/.session-edits.log` et de sa bascule vers `.ai/.session-edits.flushed`.

### Hors périmètre

- La logique de matching `touches:` elle-même (portée par `core/feature-mesh` via `_lib.sh` / `features-for-path.sh`).
- L'auto-progression de phase consommant la trace post-flush (portée par son propre script `auto-progress.sh` chaîné sur `Stop`).
- Toute édition manuelle du worklog ou des fiches (le worklog reste append-only par ce mécanisme).

## Invariants

- Le flush est atomique : si le regroupement échoue, le JSONL n'est pas tronqué (lock `mkdir`).
- Aucune sortie utilisateur sauf `AI_CONTEXT_DEBUG=1` : le mécanisme reste silencieux.
- Un path non rattachable à une feature est ignoré (jamais d'orphan log dans un worklog).
- L'auto-update reste strictement factuel : une ligne `Fichiers modifiés` dans le worklog, jamais d'interprétation rédigée. Le flush ne touche **pas** le frontmatter de la fiche (`progress.updated` n'est pas bumpé).
- Les paths contenant des quotes sont échappés sûrement dans le JSONL.

## Comportement attendu

- `PostToolUse` Write/Edit → ligne JSONL dans `.ai/.session-edits.log` (path + tool + timestamp).
- `Stop` (fin de tour) → groupe par feature via `touches`, append à `<id>.worklog.md`, déplace le JSONL vers `.flushed`. **Ne bumpe pas `progress.updated`** : la date n'est stampée que sur événement significatif (transition de phase via `auto-progress.sh`, ou édit manuel via `feature-update.md`).
- Atomique : si flush échoue, le JSONL n'est pas tronqué (lock `mkdir`).
- Silencieux : aucune sortie utilisateur sauf `AI_CONTEXT_DEBUG=1`.

## Contrats

- Worklog : append-only, jamais édité ailleurs ; la procédure `.ai/workflows/feature-update.md` passe par ce mécanisme.
- Path d'édition non rattachable à une feature → ignoré (pas d'orphan log).
- Échappement JSON sûr (paths avec quotes).

## Décisions

- Deux hooks plutôt qu'un : `PostToolUse` capture au fil de l'eau (volatile, peu coûteux), `Stop` regroupe une seule fois par tour pour limiter le bruit dans le worklog.
- Le flush **déplace** `.session-edits.log` vers `.session-edits.flushed` au lieu de le vider : la trace post-flush reste consommable par `auto-progress.sh` (chaîné sur `Stop`) sans race condition.
- Le matching `touches:` est **délégué à `_lib.sh`** plutôt que réimplémenté, pour rester aligné avec `features-for-path.sh` et le hook git `pre-commit`.
- Auto-update **factuel uniquement** : on n'écrit que la ligne `Fichiers modifiés` dans le worklog, jamais de prose générée automatiquement.
- **Fix churn date (2026-06-26)** : le flush ne bumpe plus `progress.updated`. Bumper la date à chaque flush produisait des « commits juste pour changer la date » sur toutes les features couvrant un fichier touché (treadmill, cf. `quality/doc-freshness` audit U4). `progress.updated` devient un marqueur d'**événement significatif** (phase change, édit manuel), pas d'activité de code ; la staleness (`resume-features`) reflète l'attention documentaire.

## Validation

- `auto-worklog-log.sh` écrit bien une ligne JSONL par édition Write/Edit (path + tool + timestamp) dans `.ai/.session-edits.log`.
- `auto-worklog-flush.sh` regroupe par feature, append au worklog cible, puis bascule le JSONL vers `.session-edits.flushed` (vérifiable : le `.log` est absent/vidé et le `.flushed` présent après un tour). **Ne modifie pas `progress.updated`** (régression couverte par `tests/unit/test-auto-worklog-flush.sh`).
- Un path hors `touches:` ne crée aucune entrée de worklog (pas d'orphan).
- Un path contenant une quote produit du JSONL valide (échappement vérifié).
- Le lock `mkdir` empêche la troncature du JSONL si le flush échoue.

## Cross-refs

Trigger amont : `claude-skills` (les skills déclenchent des éditions). Source de vérité aval : worklog markdown commitable.

## Historique / décisions

- v0.6 : introduction.
- v0.7.2 : escaping JSON corrigé.
- 2026-04-24 : `auto-worklog-flush.sh` ne **vide** plus `.session-edits.log`, il le **déplace** vers `.session-edits.flushed`. Permet à `auto-progress.sh` (nouveau script Stop chaîné) de consommer la trace post-flush sans race condition. Comportement vis-à-vis du worklog inchangé (toujours auto-update factuel uniquement : `progress.updated` + ligne `Fichiers modifiés`).
- 2026-04-24 : `auto-worklog-log.sh` délègue le matching `touches:` à `_lib.sh` pour rester aligné avec `features-for-path.sh` et le hook git `pre-commit`.
- 2026-06-26 : **fix churn date** (réouverture, cadrage `aic-frame` option 2). `auto-worklog-flush.sh` ne bumpe plus `progress.updated` — constat consumer : 63 fiches modifiées juste pour la date. La date n'est désormais stampée que sur transition de phase (`auto-progress.sh`) ou édit manuel (`feature-update.md`). Régression : `tests/unit/test-auto-worklog-flush.sh`. HANDOFF léger `quality/doc-freshness` (sémantique staleness) ; option 1 (dériver `updated:` au build-index) laissée en suivi.
