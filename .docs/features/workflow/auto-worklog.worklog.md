# Worklog — workflow/auto-worklog


## 2026-04-24 11:42 — auto
- Fichiers modifiés :
  - template/.ai/scripts/auto-worklog-flush.sh.jinja

## 2026-05-07 — freshness
- Impact direct : `auto-worklog-log.sh` étendu pour appeler aussi `context-relevance-log.sh touch` (livraison Phase 2 #3). Aucune modif sur la sémantique du logger session-edits.
- Validation associée : 8 cas test-context-relevance PASS.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - .ai/scripts/auto-worklog-log.sh
  - template/.ai/scripts/auto-worklog-log.sh.jinja

## 2026-05-07 — freshness
- Impact direct : `auto-worklog-log.sh` filtre désormais via `is_structural_feature_edit` (livraison Phase 2 #5). Le logger context-relevance touch reste agnostique. Aucune modif sur auto-worklog-flush ni le contrat append-only.
- Validation : 9/9 cas test-stop-hook-idempotence PASS.

## 2026-06-26 — fix churn date (option 2, cadrage aic-frame)
- `auto-worklog-flush.sh` (+ jinja) : suppression du bump `progress.updated` dans le frontmatter (retrait du bloc awk + variables `today`/`feature_md` devenues inutiles). Le flush n'append plus que le worklog ; le frontmatter des fiches n'est plus touché à chaque tour.
- Motif : constat consumer (63 fiches modifiées juste pour la date). `progress.updated` n'est désormais stampé que sur transition de phase (`auto-progress.sh`, qui stampe déjà `updated` sur `spec → implement`) ou édit manuel (`feature-update.md`).
- Fiche `workflow/auto-worklog` mise à jour (Périmètre, Invariants, Comportement, Décisions, Validation, Historique).
- Test : `tests/unit/test-auto-worklog-flush.sh` (worklog appendé + `updated:` inchangé + log consommé) ; enregistré dans `tests/smoke-test.sh` [0j].
- Validation : test PASS, `bash -n`, dogfood-drift + smoke-test (voir commit).

## 2026-06-26 16:56 — auto
- Fichiers modifiés :
  - .ai/scripts/auto-worklog-flush.sh

## 2026-06-28 — anti-churn bloc auto (A9)
- `auto-worklog-log.sh` marque dans `.ai/.session-docs.log` toute feature dont la fiche/worklog est éditée manuellement ; `auto-worklog-flush.sh` saute le bloc auto pour ces features puis nettoie le marqueur. Filet de sécurité préservé (feature code-only → bloc auto).
- Parité jinja + gitignore (runtime+template). Test : cas 4-7 de test-auto-worklog-flush.sh. drift ✅, check-features ✅.
- Fichiers : auto-worklog-log.sh(+jinja), auto-worklog-flush.sh(+jinja), .ai/.gitignore(+template), tests/unit/test-auto-worklog-flush.sh

## 2026-06-29 — docstring corrigée (finding #6 audit hebdo)
- En-tête de `auto-worklog-flush.sh` (+ jinja) corrigé : il prétendait encore « bump progress.updated dans le frontmatter », alors que le code ne le fait plus depuis le fix anti-churn (A9 / audit U4). La docstring décrit désormais le réel : append worklog uniquement ; `updated` géré par `auto-progress.sh` (transition) ou `.ai/workflows/feature-update.md`.
- Commentaire seul, aucun changement de comportement. Parité runtime↔jinja vérifiée.

## 2026-07-03 — done
- Intent : clôturer `workflow/auto-worklog` après validation des incréments no-churn et anti-doublon.
- Fichiers/surfaces : `.docs/features/workflow/auto-worklog.md`, `.docs/features/workflow/auto-worklog.worklog.md`, `.ai/scripts/auto-worklog-log.sh`, `.ai/scripts/auto-worklog-flush.sh`, templates Jinja associés, `tests/unit/test-auto-worklog-flush.sh`.
- Décision : statut `done`. Le suivi “dériver updated au build-index” n'est pas un blocker de cette feature ; il devra être cadré séparément si la sémantique de staleness change.
- Validation : `bash tests/unit/test-auto-worklog-flush.sh` PASS ; `bash tests/unit/test-stop-hook-idempotence.sh` PASS ; `bash -n` runtime/template PASS ; `bash .ai/scripts/check-dogfood-drift.sh` PASS ; `bash .ai/scripts/check-feature-docs.sh --strict workflow/auto-worklog` PASS.
- Next : aucune action immédiate.
