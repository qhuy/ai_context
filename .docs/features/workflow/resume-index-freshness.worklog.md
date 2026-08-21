# Worklog — workflow/resume-index-freshness

## 2026-08-20 — diagnostic et implémentation

- Symptôme prouvé : `resume-features.sh` ne reconstruisait l'index que s'il était absent ; un cache présent conservait donc une phase périmée.
- Cause : contrairement à `pre-turn-reminder.sh`, `features-for-path.sh` et `features-search.sh`, le consommateur de reprise n'appelait pas `feature_docs_newer_than`.
- Correction : même condition de rebuild ajoutée au runtime et à son miroir Jinja, sans modifier le builder ni le format du cache.
- Régression : fixture avec cache en phase `implement`, source plus récente en phase `review`, puis assertions sur la sortie JSON et le cache reconstruit.

## 2026-08-20 — HANDOFF workflow → quality

- Surface partagée : `tests/smoke-test.sh`.
- Changement : ajout d'un appel au test ciblé `test-resume-features-index-freshness.sh`.
- Limite : aucun changement de numérotation globale ni de logique du smoke-test.
- Validation attendue : test ciblé, smoke complet et freshness des fiches concernées.

## 2026-08-20 — passage en review

- `bash tests/unit/test-resume-features-index-freshness.sh` : PASS.
- `bash .ai/scripts/check-dogfood-drift.sh` : PASS sur les trois profils rendus.
- `check-feature-docs --strict workflow/resume-index-freshness`, `check-features --no-write`, couverture stricte 118/118, freshness worktree strict et références Markdown : PASS.
- Prochaine preuve : smoke-test complet, puis clôture si la revue du delta ne révèle pas de régression.

## 2026-08-20 14:44 — DONE

### Evidence

- Build/lint : `bash -n .ai/scripts/resume-features.sh template/.ai/scripts/resume-features.sh.jinja tests/unit/test-resume-features-index-freshness.sh` — PASS.
- Test ciblé : `bash tests/unit/test-resume-features-index-freshness.sh` — PASS.
- Test global : `bash tests/smoke-test.sh` — PASS, dont la nouvelle étape `[0c2/28]`.
- Structure : shims, parité skills, config agents, références, feature mesh, docs strictes, couverture 118/118, freshness worktree et staged — PASS.
- Observabilité : `measure-context-size.sh` — 1 573 caractères, estimation 393–524 tokens pour le reminder par défaut.

### Risk ledger

- Breaking change : non ; options, buckets et formats text/JSON inchangés.
- Migration de données ou de schéma : non.
- Sécurité, authentification ou tenancy : non applicable.
- Compatibilité arrière : préservée ; Bash 3.2 et comportement best-effort conservés.
- Résiduel accepté : le détecteur canonique repose sur l'ordre des mtimes ; aucune nouvelle faiblesse propre à ce correctif.

### Doc Impact Decision

- **C — Fiche feature mise à jour** : la politique de fraîcheur du workflow de reprise change et son contrat est documenté dans cette fiche.

### Résumé livré

- `resume-features` reconstruit désormais un index présent mais antérieur à une fiche canonique.
- Runtime et template Copier restent byte-identiques.
- Une régression discriminante est intégrée au smoke-test.

### Commit suggéré

`fix(workflow): rafraîchir l'index avant la reprise`
