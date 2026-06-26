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
