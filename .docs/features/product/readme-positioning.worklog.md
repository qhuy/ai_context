# Worklog — product/readme-positioning

## 2026-05-06 — création
- Feature créée via `.ai/workflows/document-feature.md`.
- Scope : product.
- Intent initial : rendre le README racine plus accessible, plus vendeur et toujours exact.

## 2026-05-06 — implementation
- Intent : remplacer le README exhaustif et dense par une page d'accueil orientée valeur, adoption et usage quotidien.
- Fichiers/surfaces : `README.md`.
- Décision : garder un seul README, mais séparer clairement promesse, quickstart, workflow `aic`, limites runtime, feature mesh et référence.
- Validation : `check-ai-references`, `check-product-links`, `check-features`, `check-feature-docs product/readme-positioning`.
- Next : relire le delta staged puis commit dédié si freshness OK.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : README enrichi avec les contrats subagents, hooks Codex et MCP pour clarifier l'adoption sans changer le positionnement produit.
- Aucun changement sur le quickstart ou la promesse principale.
- Validation : `check-ai-references`, `check-features` et smoke-test PASS.

## 2026-06-30 — README mentionne aic-pilot
- README racine enrichi avec `aic-pilot` dans la promesse multi-agent, le bootstrap post-install et le flux recommandé.
- Reclassification freshness `(a')` : `README.md` garde `product/readme-positioning` comme propriétaire exact unique ; les autres features le référencent en `touches_shared`.

## 2026-07-03 — A5/A10 + pitch C1
- Intent : fermer les points README restants du frame de remédiation 2026-06-28.
- Fichiers/surfaces : `README.md`, fiche `product/readme-positioning`.
- Décision : `README.md` est nommé comme porte d'entrée canonique du repo source ; `README_AI_CONTEXT.md` reste le guide rendu dans les projets consommateurs. La première promesse explicite l'asymétrie runtime : Claude Code est le plus automatisé, Codex est le pilote multi-agent le mieux outillé après Claude, les autres agents reposent surtout sur `AGENTS.md`, hooks et checks.
- Validation : `check-ai-references` PASS ; `check-product-links` OK en warn (signal connu : initiative docs sans dev slice) ; `check-feature-docs --strict product/readme-positioning` PASS ; `check-features` PASS avec warnings OKF préexistants ; `check-feature-freshness --worktree --strict` OK ; `git diff --check` OK.
- Next : relire le delta README puis décider si la fiche peut passer DONE ; traiter séparément le signal `product-review` sur les initiatives docs sans dev slice si nécessaire.
