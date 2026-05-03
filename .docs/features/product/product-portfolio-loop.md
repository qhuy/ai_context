---
id: product-portfolio-loop
scope: product
title: Product Portfolio Loop
status: active
depends_on:
  - workflow/agent-behavior
  - core/feature-mesh
touches:
  - copier.yml
  - .ai/rules/product.md
  - template/.ai/rules/product.md.jinja
  - .ai/schema/feature.schema.json
  - template/.ai/schema/feature.schema.json
  - .ai/scripts/check-product-links.sh
  - .ai/scripts/product-status.sh
  - .ai/scripts/product-portfolio.sh
  - .ai/scripts/product-review.sh
  - .ai/scripts/build-feature-index.sh
  - .ai/scripts/ai-context.sh
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/scripts/dogfood-update.sh
  - template/.ai/scripts/check-product-links.sh.jinja
  - template/.ai/scripts/product-status.sh.jinja
  - template/.ai/scripts/product-portfolio.sh.jinja
  - template/.ai/scripts/product-review.sh.jinja
  - template/.ai/scripts/build-feature-index.sh.jinja
  - template/.ai/scripts/ai-context.sh.jinja
  - .ai/index.md
  - template/.ai/index.md.jinja
  - .docs/FEATURE_TEMPLATE.md
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - tests/smoke-test.sh
touches_shared:
  - README.md
  - CHANGELOG.md
product:
  type: initiative
  bet: "Relier les arbitrages produit aux features dev améliore la qualité des décisions sans créer de roadmap parallèle."
  target_user: "Développeurs solo et équipes produit/tech qui utilisent ai_context"
  success_metric: "Une initiative product peut être suivie via status, portfolio et review en sortie CLI stable."
  leading_indicator: "Smoke-test couvre product-status, product-portfolio et product-review sur un scaffold Copier."
  decision_state: explore
  next_decision_date: 2026-05-17
  kill_criteria:
    - "Le product mesh impose une roadmap parallèle ou augmente le reminder."
    - "Les rapports ne permettent pas de relier initiative, dev et evidence."
  portfolio:
    appetite: medium
    confidence: high
    expected_impact: high
    urgency: medium
    strategic_fit: high
progress:
  phase: implement
  step: "V1 product scope + scripts read-only en cours"
  blockers: []
  resume_hint: "valider smoke-test, check-product-links, dogfood drift et freshness"
  updated: 2026-05-03
---

# Product Portfolio Loop

## Objectif

Ajouter un pilotage COO/CEO au feature mesh sans créer une roadmap séparée ni injecter de contexte produit à chaque tour.

Le modèle cible :

```text
initiative product -> features dev liées -> evidence -> décision suivante
```

## Comportement attendu

- `scope: product` représente une initiative produit.
- Les features dev se relient à une initiative via `product.initiative`.
- `depends_on` reste réservé aux dépendances techniques ou de contexte.
- `check-product-links.sh` signale les initiatives floues, non exécutables ou liées à tort.
- `product-status.sh` donne une vue COO des initiatives et dev linked.
- `product-portfolio.sh` compare impact, confiance, coût et evidence.
- `product-review.sh product/<id>` recommande une décision `continue / cut / pivot / scale`.

## Contrats

- Read-only : aucun script produit ne modifie les fichiers.
- Pas de reminder : la couche produit est lue juste-à-temps.
- Pas de roadmap parallèle : la roadmap est une vue calculée depuis `.docs/features/product/*.md`.
- Compatible Claude/Codex : la surface commune passe par `ai-context.sh product-*`.

## Cross-refs

- `workflow/agent-behavior` : posture de recommandation et clôture orientée prochaine action.
- `core/feature-mesh` : source du frontmatter, de l'index et des dépendances.

## Historique / décisions

- 2026-05-03 : décision de ne pas copier BOS tel quel. Le besoin retenu est un Product Portfolio Loop adapté au logiciel : initiatives product, lien typé vers features dev, evidence et décision suivante.
