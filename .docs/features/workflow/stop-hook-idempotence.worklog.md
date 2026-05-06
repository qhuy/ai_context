# Worklog — workflow/stop-hook-idempotence

## 2026-05-06 23:35 — création
- Feature créée en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`.
- Scope : workflow.
- Intent initial : rendre le hook Stop idempotent sur tour sans édit structurel. Aucune entrée worklog ni bump `progress.updated` si rien de structurel n'a été touché.
- Bug de signal : `auto-worklog-flush.sh` écrit en fin de chaque tour, même conversationnel ou lecture seule. Conséquence : worklogs bavards, `progress.updated` ne reflète plus la réalité.
- Décision Phase 2 : positionnée en #5 (dernière) selon ordre par impact agent (egress > injection > falsification d'état > hygiène signal). Indépendante des autres fiches mais bénéficie du matcher correct.
- Approche par défaut : critère « édit structurel » partagé avec `workflow/auto-progress-file-filter` (#4) via fonction commune dans `_lib.sh` pour éviter divergence.
- Pas de régression sur l'append-only : on n'efface jamais une entrée existante, on évite juste d'en créer une vide.
- Compatibilité historique : worklogs existants avec entrées « auto » bavardes restent (append-only).
- Next : à reprendre dans un turn dédié pour passer en `status: active`, lire `auto-worklog-flush.sh`, définir précisément le critère, implémenter, ajouter tests reproductibles 1-5.

## 2026-05-07 — correction post-review Codex
- Codex post-review du commit `2511d06` : diagnostic initial incorrect.
- Vérification factuelle :
  - [auto-worklog-flush.sh:23](.ai/scripts/auto-worklog-flush.sh:23) : early exit si `.ai/.session-edits.log` vide.
  - [auto-worklog-log.sh:36](.ai/scripts/auto-worklog-log.sh:36) : alimente le log uniquement sur PostToolUse Write/Edit/MultiEdit avec match `features_matching_path`.
  - [_lib.sh:130-141](.ai/scripts/_lib.sh:130) : `features_matching_path` regarde uniquement `touches:` direct, pas `touches_shared:`.
- Le hook est **déjà idempotent** sur tours conversationnels, lecture seule, et édits hors `touches:` direct.
- Le **vrai bruit** vient des édits non-structurels (extensions `.md`, `.txt`, `.lock`) qui passent `features_matching_path` car listées dans `touches:` direct (fiche feature elle-même, README, doc).
- Fiche reformulée : Résumé, Objectif, Périmètre, Comportement attendu, Validation, Historique. Périmètre maintenant clair : filtrage par extension après `features_matching_path`, dans `auto-worklog-log.sh` (option a) ou `auto-worklog-flush.sh` (option b). Préférence (a).
- Tests reformulés : 3 tests de non-régression (déjà passants) + 4 tests cibles du fix.
