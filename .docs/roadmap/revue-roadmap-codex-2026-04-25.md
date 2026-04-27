# Revue de roadmap — Codex (`ai-context`)

_Date : 2026-04-25_

## Verdict global

La roadmap est **solide, réaliste et bien priorisée**. Elle met correctement l'accent sur la vérité documentaire (P0) avant les ambitions produit (CLI/MCP/graph).

## Points forts

- Priorisation cohérente : P0 corrige la dette de crédibilité avant d'ajouter des couches.
- Critères d'acceptation actionnables (grep, smoke-test, alignement docs/runtime).
- Découpage en PR thématiques pertinent pour réduire le risque de régression.
- Vision long terme claire (doctor, audit agent-agnostique, modes d'adoption, puis MCP).

## Points de vigilance

1. **Taille du périmètre P1** : config + schema + migration + CI peut vite déborder si fusionné trop tôt.
2. **Risque de duplication des sources de vérité** : schema JSON + checks Bash + docs doivent rester strictement synchronisés.
3. **Charge de maintenance CI** : matrice multi-OS + shellcheck sur scripts rendus demandera une stratégie de fixtures stable.

## Recommandations concrètes

### 1) Exécuter P0 en premier, sans mélange

Traiter P0.1 → P0.5 en une série de PR docs/tests courtes. L'objectif est de restaurer une base de confiance (docs = runtime).

### 2) Ajouter une "policy de vérité"

Documenter explicitement dans le repo :

- source de vérité des skills exposés ;
- source de vérité des transitions auto-progress ;
- source de vérité de l'index feature.

Une règle simple : **tout message public doit être dérivable d'un script ou d'un fichier unique versionné**.

### 3) Isoler les fondations P1 en deux étapes

- **P1-A** : `config.yml` + lecture d'un seul script + fallback defaults.
- **P1-B** : schema + migration dry-run/apply + documentation migration.

Cela limite l'effet domino et facilite les retours arrière.

### 4) Cadencer l'UX adoption avant MCP

Traiter d'abord `doctor` + audit agent-agnostique + modes `lite/standard/strict`.

Bénéfice attendu : meilleure adoption immédiate, sans dépendre d'une pile MCP.

### 5) Définir des métriques d'impact dès maintenant

Avant P2/P3, fixer des indicateurs minimaux (ex. temps de reprise, orphelins détectés, faux positifs audit) pour objectiver la valeur.

## Plan d'exécution recommandé (court terme)

1. PR1 — Sync docs/skills/auto-progress + nettoyage `PROJECT_STATE`.
2. PR2 — Renfort smoke-test sur set de skills réel.
3. PR3 — Fondation config (`.ai/config.yml`) avec fallback.
4. PR4 — Fondation schema + validation alignée.
5. PR5 — `doctor` MVP (non destructif).

## Conclusion

Mon avis : la stratégie est très bonne. Le principal facteur de succès sera la **discipline de synchronisation docs/runtime** et la **limitation du scope par PR**. Tant que P0 est traité strictement avant P2/P3, la roadmap maximise la crédibilité du projet.
