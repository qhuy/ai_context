# Worklog — quality/review-delta-uncommitted-coverage

## 2026-05-06 22:55 — création
- Feature créée en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`.
- Scope : quality.
- Intent initial : sécuriser la review pre-commit en couvrant le delta uncommitted (working tree + staged).
- Bug confirmé en local : `bash .ai/scripts/review-delta.sh` retourne 1 fichier en comparant `HEAD~1..HEAD` alors que `git status --short` montre 30+ fichiers uncommitted. Conséquence : `aic.sh review` peut bénir un commit dont le delta réel n'a pas été analysé.
- Blast radius : `aic.sh review` (CLI consommatrice). Aucun hook ne dépend du script. Le fixer ne casse rien d'autre.
- Décision Phase 2 : positionnée en #1 selon convergence Claude/Codex round 2 (egress > injection sur faux feu vert), avant `quality/features-for-path-ranking-and-matcher-correctness`.
- Approche par défaut envisagée : étendre `review-delta.sh` pour couvrir `HEAD..working tree` avec sections committed/uncommitted séparées dans la sortie.
- Next : à reprendre dans un turn dédié pour passer en `status: active`, lire le code complet de `review-delta.sh`, arbitrer A vs B, implémenter, ajouter test reproductible.

## 2026-05-07 — cross-check Codex pre-implémentation
- Avant de coder, Codex challengé sur 5 choix d'implémentation. 4 corrections actées :
  1. **Approche A confirmée** + compat parsabilité stricte (section uncommitted s'ajoute en suffixe, format committed inchangé, `--committed-only` restaure l'ancien comportement).
  2. **Source de vérité uncommitted** = `git status --short --untracked-files=all`. Pas `git diff HEAD` qui rate les untracked.
  3. **Libellé section** : « Delta committed reference », pas « Delta committed (HEAD~1..HEAD) ». Ne pas figer la base comme contrat.
  4. **Features impactées** : garder `features_matching_path` direct (déjà utilisé). Pas de migration vers `features-for-path.sh` dans ce scope (évite mélange Phase 2 #1 + #2). Mode best-effort, warning sans fail hard.
  5. **Tests** : unit-test dédié `tests/unit/test-review-delta-uncommitted.sh`, 5 cas (tracked modifié, staged, untracked, deletion, `--committed-only`).
- Fiche mise à jour : phase=implement, step et resume_hint alignés. Décisions tranchées remplacent les questions ouvertes. Comportement attendu, Contrats, Validation, Risques reformulés.
- Next : implémenter dans un turn dédié (ce turn ou le suivant), avec code dans `review-delta.sh` et test dans `tests/unit/`.

## 2026-05-07 — implémentation livrée
- Fonction `collect_uncommitted_paths` extraite dans `.ai/scripts/_lib.sh` (réutilisable + testable, parité template).
- `review-delta.sh` étendu :
  - Flag `--committed-only` (compat ascendante stricte).
  - Variable `include_uncommitted` qui contrôle la section ajoutée.
  - Section « Delta committed reference » regroupe l'ancien rapport sous des sous-titres `####`.
  - Nouvelle section « Delta uncommitted (working tree + index + untracked) » avec source `git status --short --untracked-files=all`, fichiers uncommitted, features directes (best-effort), features liées (best-effort).
  - Pas de fail hard sur matcher dans ce scope (best-effort confirmé).
- Parité template appliquée : `_lib.sh.jinja` et `review-delta.sh.jinja`. `check-dogfood-drift` PASS.
- Test unit `tests/unit/test-review-delta-uncommitted.sh` créé. 6 cas testés :
  1. tracked modifié non commité visible
  2. fichier staged visible
  3. fichier untracked visible
  4. fichier supprimé visible avec son chemin
  5. rename → chemin nouveau retourné
  6. `--committed-only` n'affiche pas la section uncommitted
- Validation : check-shims, check-features, check-dogfood-drift, smoke-test, test-unit ALL PASS.
- Cross-touch : freshness ajoutées sur core/dogfood-runtime-sync, core/feature-index-cache, core/template-engine, quality/pr-report.
- Phase bumpée implement → review. Prêt à commit `feat(quality): couvrir le delta uncommitted dans review-delta.sh`.
