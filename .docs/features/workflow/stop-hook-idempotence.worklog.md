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

## 2026-05-07 — fix mesh touches (re-review Codex)
- Codex re-review du commit `fc5eeeb` : `touches:` ne couvrait pas le fichier principal de l'implémentation recommandée (option a = `auto-worklog-log.sh`).
- Correction : `touches:` couvre maintenant `auto-worklog-log.sh` (option a, préférée) et `auto-worklog-flush.sh` (option b, alternative). `tests/smoke-test.sh` conservé.
- `.claude/settings.json` déplacé de `touches:` vers `touches_shared:` car la fiche y fait référence (cite ligne 43) mais ne le modifie pas.
- Titre `stop-hook-idempotence` conservé : l'objectif final reste l'idempotence du Stop, même si l'implémentation préférée vit en amont dans le PostToolUse logger. Renommage évité pour ne pas casser l'id.

## 2026-05-07 — micro-fix Granularité (re-review Codex)
- Codex re-review du commit `e63efca` : section "Granularité / nommage" disait encore « cette fiche couvre uniquement le hook Stop / auto-worklog-flush », inexact après l'ajout de `auto-worklog-log.sh` en `touches:`.
- Correction : reformulation explicite — la fiche couvre l'idempotence côté Stop avec implémentation préférée dans le logger PostToolUse (option a) et alternative dans le flush Stop (option b). Titre conservé pour préserver l'id.

## 2026-05-07 11:51 — auto-progress
- Bascule phase : spec → implement (édits réels détectés sur 1 fichier(s))
- Annulable via /aic undo (snapshot dans .ai/.progress-history.jsonl)

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .ai/scripts/auto-worklog-log.sh

## 2026-06-18 — DONE

### Contexte clôture
- Implémentation déjà livrée et live depuis `2b66ae6` (`is_structural_feature_edit` dans `_lib.sh:105`, branché dans `auto-worklog-log.sh:76` et `auto-progress.sh:103`). Fiche restée `draft` par oubli de clôture — métadonnée périmée (« prêt à commit » alors que déjà committé).
- Clôture déclenchée après vérification factuelle : le code tourne, le test E2E passe.

### Evidence
- Tests : `bash tests/unit/test-stop-hook-idempotence.sh` ✅ (9/9 PASS)

### Résumé livré
- Le hook Stop n'ajoute plus d'entrée auto-worklog ni ne bump `progress.updated` quand les seuls édits sont non-structurels (fiche `.md`, `*.worklog.md`, `*.lock`, caches `.ai/.*`).
- Filtre `is_structural_feature_edit` appliqué dans le logger PostToolUse (option a) après `features_matching_path` — matcher et contrat append-only intacts.
- `progress.updated` retrouve sa sémantique « date du dernier change structurel » ; worklogs allégés.

### Commit suggéré
docs(workflow): clôture stop-hook-idempotence (impl. déjà live)

## 2026-06-28 — couverture incidente (A9 : anti-churn auto-worklog)
- Surface partagée touchée (auto-worklog-log/flush, .ai/.gitignore ou tests/unit/**) via glob/touches:. Aucun changement de comportement propre à cette feature. (Taxe sur-couverture — cf. quality/touches-breadth-guard.)
