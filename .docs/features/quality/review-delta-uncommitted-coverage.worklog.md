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
