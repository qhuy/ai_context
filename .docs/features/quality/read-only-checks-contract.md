---
id: read-only-checks-contract
scope: quality
title: Contrat read-only des checks et diagnostics
status: active
depends_on:
  - core/index-contract-v2
  - quality/doctor
  - quality/doc-freshness
  - quality/review-delta-uncommitted-coverage
touches:
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - .ai/scripts/doctor.sh
  - template/.ai/scripts/doctor.sh.jinja
  - .ai/scripts/check-features.sh
  - template/.ai/scripts/check-features.sh.jinja
  - .ai/scripts/check-feature-freshness.sh
  - template/.ai/scripts/check-feature-freshness.sh.jinja
  - .ai/scripts/check-feature-coverage.sh
  - template/.ai/scripts/check-feature-coverage.sh.jinja
  - .ai/scripts/review-delta.sh
  - template/.ai/scripts/review-delta.sh.jinja
  - .ai/scripts/pr-report.sh
  - template/.ai/scripts/pr-report.sh.jinja
  - .github/workflows/ai-context-check.yml
  - template/.github/workflows/ai-context-check.yml.jinja
  - .ai/workflows/quality-gate.md
  - template/.ai/workflows/quality-gate.md.jinja
  - docs/upgrading.md
  - MIGRATION.md
  - CHANGELOG.md
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - tests/unit/**
  - .docs/features/quality/read-only-checks-contract.md
  - .docs/features/quality/read-only-checks-contract.worklog.md
touches_shared:
  - tests/smoke-test.sh
product:
  initiative: product/ai-context-stability-migration
  contribution: "Rend les checks et diagnostics fiables pour les projets existants en supprimant les écritures implicites."
  evidence: "Tests no-write, CI --no-write, docs migration/downstream et rapports product alignés."
external_refs:
  frame: ".docs/frames/2026-05-14-ai-context-stability-migration.md"
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: review
  step: "checks, rapports, surface aic, CI et docs migration alignés read-only"
  blockers: []
  resume_hint: "relire le delta puis décider si le comportement legacy de check-features sans flag doit être déprécié en release N+1"
  updated: 2026-06-25
type: feature
---

# Contrat read-only des checks et diagnostics

## Résumé

Définir et appliquer un contrat clair pour les commandes de diagnostic, review et checks : par défaut, elles ne doivent pas modifier le repo. Les écritures, réparations ou rebuilds de cache doivent être explicites.

## Objectif

Restaurer la confiance dans les outils qualité de `ai_context`. Un humain ou un agent doit pouvoir lancer un diagnostic ou une review sans créer ou modifier `.ai/.feature-index.json`, ni retoucher des artefacts repo-local par surprise.

## Périmètre

### Inclus

- Cartographier les scripts qui écrivent ou reconstruisent l'index implicitement.
- Définir quels scripts sont read-only par contrat : `doctor`, `review-delta`, `pr-report`, `check-feature-freshness`, quality gate et scripts product si consommés côté quality.
- Définir les modes explicites : `--write`, `--repair`, `--rebuild-index`, `--apply` ou commandes dédiées.
- Ajouter des tests de non-écriture.
- Documenter les warnings/deprecations pour les projets downstream.

### Hors périmètre

- Redéfinir le format de l'index : couvert par `core/index-contract-v2`.
- Fusionner `review-delta` et `pr-report` : chantier à cadrer séparément, même si les tests read-only doivent préparer la fusion.
- Refaire l'ensemble de la CI : couvert par une future feature `quality/test-suite-reorg`.

### Granularité / nommage

Cette feature couvre le contrat d'effet de bord des commandes qualité. Elle ne doit pas absorber les refactors de logique métier des rapports.

## Invariants

- Un check ou diagnostic ne modifie pas le repo sans option explicitement mutante.
- Les modes mutants doivent être nommés, documentés et testés.
- Les commandes qualité doivent rester utilisables par Claude, Codex, autres agents et humains.
- Les erreurs doivent être actionnables : si un index manque, la commande explique quoi lancer plutôt que l'écrire silencieusement.
- Les hooks Git et CI restent la garantie stable, pas les prompts agent.

## Décisions

- Le défaut futur doit être non mutant pour les diagnostics.
- Les commandes qui réparent ou écrivent doivent être séparées ou porter un flag explicite.
- Toute transition cassante doit passer par une phase warning/compat.
- Les tests doivent vérifier l'état Git ou les mtimes des artefacts sensibles avant/après exécution.
- Les rapports quality ciblés utilisent un index temporaire généré via stdout de `build-feature-index.sh`.
- `check-features.sh --no-write` est le mode de validation mesh à utiliser par `doctor`, le quality gate et la CI.
- Le comportement historique de `check-features.sh` sans option reste mutable pour préserver les usages existants pendant la transition.

## Comportement attendu

- `doctor.sh` diagnostique sans reconstruire l'index.
- `review-delta.sh` produit un rapport sans écrire l'index.
- `check-feature-freshness.sh --warn` et `--staged --strict` ne modifient pas le repo.
- `check-feature-coverage.sh` ne modifie pas le repo.
- `pr-report.sh` ne modifie pas le repo.
- `aic.sh status`, `aic.sh ship`, `aic.sh frame` et `aic.sh diagnose` ne reconstruisent pas l'index implicitement.
- Le quality gate peut lire l'état, mais ne doit pas corriger ou régénérer silencieusement.
- Si un cache est absent ou stale, les commandes affichent une action explicite.

## Contrats

- Contrat read-only : aucune écriture hors fichiers temporaires système nettoyés.
- Contrat mutable : toute écriture repo-local passe par un flag ou une commande nommée.
- Contrat downstream : les anciens comportements implicites ont un warning avant changement de défaut.
- Contrat CI : les checks lancés en CI ne doivent pas modifier le workspace sauf étape explicitement dédiée.

## Validation

- Test no-write sur `doctor.sh`.
- Test no-write sur `review-delta.sh`.
- Test no-write sur `check-feature-freshness.sh --warn`.
- Test no-write sur `check-feature-freshness.sh --staged --strict`.
- Test no-write sur `check-feature-coverage.sh`.
- Test no-write sur `pr-report.sh`.
- Test no-write sur la surface publique `aic.sh status`, `aic.sh ship`, `aic.sh frame` et `aic.sh diagnose`.
- Test CI dédié aux commandes read-only et au contrat d'index.
- Test absence d'index : message actionnable, pas écriture silencieuse.
- Test présence d'index stale : warning ou action explicite selon le contrat retenu.
- Documentation migration mise à jour si un comportement par défaut change.

## Droits / accès

Non requis.

Les scripts concernés ne doivent pas nécessiter de réseau, secret ou accès externe. Ils ne doivent pas modifier les hooks Git ou configs locales sans demande explicite.

## Données

- Données lues : Git status/diff/log, fiches feature, index feature, config `.ai/config.yml`, workflows et scripts.
- Données sensibles : aucune attendue.
- Données écrites : aucune en mode read-only ; uniquement cache ou réparations explicites en mode mutable.

## UX

Les messages doivent éviter l'ambiguïté :

- `OK` signifie que la commande a lu et diagnostiqué, pas qu'elle a réparé.
- Si une action est nécessaire, afficher la commande exacte.
- Si un comportement legacy est utilisé, afficher une dépréciation claire pendant la phase de transition.

## Observabilité

Non requis comme observabilité runtime.

Les preuves attendues sont les tests no-write, les sorties de checks et les entrées de migration/changelog.

## Déploiement / rollback

- Release N : ajouter warnings et modes explicites tout en conservant le comportement legacy si nécessaire.
- Release N+1 : basculer les diagnostics en read-only par défaut.
- Release N+2 : retirer les écritures implicites legacy.
- Rollback : flag legacy temporaire ou commande de rebuild explicite documentée.

## Risques

- Les projets downstream peuvent dépendre d'un rebuild implicite de l'index.
- Un mode read-only strict peut rendre certains diagnostics moins pratiques si l'index manque.
- Les tests no-write peuvent être fragiles si des scripts écrivent dans des traces ignorées.
- Le chantier touche plusieurs scripts qualité et doit rester séparé des refactors de rapport.

## Cross-refs

- `core/index-contract-v2` : définit le contrat de lecture/écriture de l'index.
- `quality/doctor` : diagnostic local à rendre réellement non destructif.
- `quality/doc-freshness` : check clé qui doit rester fiable avant commit.
- `quality/review-delta-uncommitted-coverage` : report review qui doit analyser sans muter.
- `product/ai-context-stability-migration` : initiative de stabilisation et migration.

## Historique / décisions

- 2026-05-14 : création suite à l'initiative `product/ai-context-stability-migration`.
- 2026-05-14 : décision de bloquer l'implémentation sur un contrat d'index v2 clair.
- 2026-05-14 : première implémentation. `check-feature-freshness`, `check-feature-coverage`, `review-delta` et `pr-report` lisent un index temporaire non repo-local ; `doctor`, `quality-gate` et la CI utilisent `check-features.sh --no-write`. Ajout de `tests/unit/test-read-only-checks-contract.sh`.
- 2026-05-14 : arbitrage AI Debate `0016` : la correction `aic.sh` est ajoutée au plan. `aic.sh status`, `ship`, `frame` et `diagnose` utilisent un index temporaire et `check-features.sh --no-write`; la surface publique ne reconstruit plus `.ai/.feature-index.json` implicitement.
