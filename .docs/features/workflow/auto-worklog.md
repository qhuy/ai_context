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
---

# Auto-worklog

## Objectif

Capturer sans friction les modifications d'une session Claude vers les worklog des features touchées. L'utilisateur n'a rien à faire : les hooks `PostToolUse` (Write/Edit) loguent en JSONL volatile, le hook `Stop` regroupe par feature et append au markdown.

## Comportement attendu

- `PostToolUse` Write/Edit → ligne JSONL dans `.ai/.session-edits.log` (path + tool + timestamp).
- `Stop` (fin de tour) → groupe par feature via `touches`, append à `<id>.worklog.md`, bump `progress.updated`, vide le JSONL.
- Atomique : si flush échoue, le JSONL n'est pas tronqué (lock `mkdir`).
- Silencieux : aucune sortie utilisateur sauf `AI_CONTEXT_DEBUG=1`.

## Contrats

- Worklog : append-only, jamais édité ailleurs (skill `/aic-feature-update` passe par ce mécanisme).
- Path d'édition non rattachable à une feature → ignoré (pas d'orphan log).
- Échappement JSON sûr (paths avec quotes).

## Cross-refs

Trigger amont : `claude-skills` (les skills déclenchent des éditions). Source de vérité aval : worklog markdown commitable.

## Historique / décisions

- v0.6 : introduction.
- v0.7.2 : escaping JSON corrigé.
