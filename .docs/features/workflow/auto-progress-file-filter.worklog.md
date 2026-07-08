# Worklog — workflow/auto-progress-file-filter

## 2026-05-06 23:25 — création
- Feature créée en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`.
- Scope : workflow.
- Intent initial : restaurer la sémantique de `progress.phase` en filtrant la transition `spec→implement` par type de fichier édité.
- Bug identifié : aujourd'hui, n'importe quelle édition (README, test, commentaire, fiche feature) bumpe la phase. Conséquence : `phase: implement` ne signifie plus « code en cours », juste « activité dans le périmètre ».
- Décision Phase 2 : positionnée en #4. Indépendant des fiches #1–#3 mais devient calibré après matcher correct (`#2`).
- Approche par défaut envisagée : filtre déterministe combinant matche `touches:` direct (pas `touches_shared:`) ET extension ∈ liste « structurelle » (par défaut exclure `.md`, `.txt`, `.lock`).
- Question ouverte : comportement sur fichiers de tests. Préférence par défaut : structurel (TDD valide la phase implement).
- Next : à reprendre dans un turn dédié pour passer en `status: active`, lire `auto-progress.sh`, définir précisément la liste d'extensions exclues, implémenter, ajouter tests reproductibles 1-4 décrits dans la fiche.

## 2026-05-07 11:51 — auto-progress
- Bascule phase : spec → implement (édits réels détectés sur 1 fichier(s))
- Annulable via /aic undo (snapshot dans .ai/.progress-history.jsonl)

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .claude/settings.json

## 2026-05-07 17:33 — auto
- Fichiers modifiés :
  - .ai/scripts/auto-progress.sh

## 2026-05-07 18:04 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - .ai/scripts/auto-progress.sh
  - template/.ai/scripts/_lib.sh.jinja
  - template/.ai/scripts/auto-progress.sh.jinja
  - tests/unit/test-auto-progress-filter.sh
## 2026-05-12 — impact partagé contrat lock index

- Fichiers/surfaces : `.ai/scripts/_lib.sh`, `template/.ai/scripts/_lib.sh.jinja`.
- Contexte : `quality/index-lock-contract` modifie un helper commun de `_lib.sh`.
- Impact : aucun changement du filtre d'auto-progression ; le lock d'index devient strict en cas de timeout.
- Validation portée par `quality/index-lock-contract`.

## 2026-06-01 22:47 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-07-03 — HANDOFF depuis core/vcs-provider-abstraction
- Surface partagée touchée : `_lib.sh` source le provider VCS avec fallback Git. Aucun changement du filtre auto-progress.
- Validation portée par `core/vcs-provider-abstraction`.

## 2026-06-01 — _lib.sh touché (perf matcher, sans impact sur ce périmètre)

- `_lib.sh` (+ `.jinja`) modifié pour le fast-path no-glob de `path_matches_touch` (perf : saute `_glob_pattern_supported`). `is_structural_feature_edit` (le périmètre de cette feature) est inchangé. Entrée de traçabilité freshness.

## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja

## 2026-06-26 11:17 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-07-03 — done
- Intent : clôturer `workflow/auto-progress-file-filter` après audit du runtime livré.
- Fichiers/surfaces : `.docs/features/workflow/auto-progress-file-filter.md`, `.docs/features/workflow/auto-progress-file-filter.worklog.md`, `.ai/scripts/_lib.sh`, `.ai/scripts/auto-progress.sh`, `template/.ai/scripts/_lib.sh.jinja`, `template/.ai/scripts/auto-progress.sh.jinja`, `tests/unit/test-auto-progress-filter.sh`.
- Décision : statut `done`. Pas de nouveau delta runtime : le helper structurel, la revalidation `touches:` direct et le test dédié étaient déjà présents ; ce commit aligne la fiche sur l'état réel.
- Validation : `bash tests/unit/test-auto-progress-filter.sh` PASS (26 cas) ; `bash .ai/scripts/check-feature-docs.sh --strict workflow/auto-progress-file-filter` PASS ; `bash .ai/scripts/check-feature-freshness.sh --worktree --strict` OK ; `bash .ai/scripts/check-dogfood-drift.sh` PASS.
- Next : aucune action immédiate ; `workflow/stop-hook-idempotence` peut consommer le helper dans un tour dédié.

## 2026-07-07 — audit 2026-07-07
- Intent : fermer SCR-5 et tracer les changements partagés `_lib.sh`.
- Changement : `auto-progress.sh` lit les champs jq TSV avec `IFS=$'\t'`, afin de préserver les chemins/ids contenant des espaces ; test E2E ajouté dans `test-auto-progress-filter`.
- Validation ciblée : `bash tests/unit/test-auto-progress-filter.sh` PASS.
