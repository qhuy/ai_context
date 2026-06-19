---
id: product-portfolio-loop
scope: product
title: Product Traceability Loop
status: active
depends_on:
  - workflow/agent-behavior
  - core/feature-mesh
touches:
  - .ai/rules/product.md
  - template/.ai/rules/product.md.jinja
  - .ai/schema/feature.schema.json
  - template/.ai/schema/feature.schema.json
  - .ai/scripts/check-product-links.sh
  - .ai/scripts/product-status.sh
  - .ai/scripts/product-portfolio.sh
  - .ai/scripts/product-review.sh
  - .ai/scripts/build-feature-index.sh
  - .ai/scripts/aic.sh
  - .ai/scripts/check-dogfood-drift.sh
  - .ai/scripts/dogfood-update.sh
  - template/.ai/scripts/check-product-links.sh.jinja
  - template/.ai/scripts/product-status.sh.jinja
  - template/.ai/scripts/product-portfolio.sh.jinja
  - template/.ai/scripts/product-review.sh.jinja
  - template/.ai/scripts/build-feature-index.sh.jinja
  - template/.ai/scripts/aic.sh.jinja
  - tests/unit/test-product-reports-read-only.sh
  - .ai/index.md
  - template/.ai/index.md.jinja
  - .docs/FEATURE_TEMPLATE.md
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - tests/smoke-test.sh
touches_shared:
  - copier.yml
  - README.md
  - CHANGELOG.md
product:
  type: initiative
  bet: "Relier les décisions produit, les artefacts externes et les features dev améliore la qualité des décisions sans créer de roadmap parallèle."
  target_user: "Développeurs solo et équipes produit/tech qui utilisent ai_context"
  success_metric: "Une initiative product peut être suivie via status, portfolio/review et external_refs en sortie CLI/index stable."
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
  phase: review
  step: "rapports product alignés et testés read-only"
  blockers: []
  resume_hint: "relire le delta product et décider si le scoring portfolio doit être durci dans une feature dédiée"
  updated: 2026-06-19
---

# Product Traceability Loop

## Résumé

Ajoute une couche de traceability produit au feature mesh : `scope: product` représente une initiative, les features dev s'y relient via `product.initiative` et les artefacts externes via `external_refs`. Des scripts read-only (`product-status`, `product-portfolio`, `product-review`) donnent une vue de suivi et une recommandation de décision sans créer de roadmap parallèle ni augmenter le reminder.

## Objectif

Ajouter une couche de traceability produit au feature mesh sans créer une roadmap séparée ni injecter de contexte produit à chaque tour.

Le modèle cible :

```text
initiative product -> refs externes -> features dev liées -> evidence -> décision suivante
```

## Périmètre

### Inclus

- Le frontmatter produit : `scope: product`, bloc `product` (bet, target_user, success_metric, decision_state, kill_criteria, portfolio), `product.initiative` côté features dev et `external_refs`.
- Les scripts read-only `check-product-links.sh`, `product-status.sh`, `product-portfolio.sh`, `product-review.sh` et leur exposition via `aic.sh product-*`, côté source et template (`.jinja`).
- La validation par `feature.schema.json`, le rendu dans `build-feature-index.sh` et la couverture smoke-test.

### Hors périmètre

- Toute roadmap autonome : `.docs/features/product/*.md` reste un index d'initiatives et de décisions, pas un backlog parallèle.
- La propriété des artefacts externes (specs, stories, tickets BMAD, Spec Kit, Linear, Jira, GitHub) : `external_refs` ne fait que les relier, sans les dupliquer.
- Le durcissement du scoring portfolio (appetite/confidence/impact/urgency), candidat à une feature dédiée — cf. `resume_hint`.

## Invariants

- Aucun script produit ne modifie de fichier : la couche reste strictement read-only.
- La couche produit est lue juste-à-temps : aucun chargement produit imposé au démarrage, le Pack A / reminder n'augmente pas.
- `depends_on` reste réservé aux dépendances techniques ou de contexte ; le lien initiative ↔ dev passe par `product.initiative`, jamais par `depends_on`.
- Les rapports consomment un index temporaire ou un cache existant et ne reconstruisent jamais `.ai/.feature-index.json` implicitement.
- La surface est identique côté Claude et Codex via `aic.sh product-*`.

## Comportement attendu

- `scope: product` représente une initiative produit.
- Les features dev se relient à une initiative via `product.initiative`.
- Les specs, stories, tickets et docs externes se relient via `external_refs`.
- `depends_on` reste réservé aux dépendances techniques ou de contexte.
- `check-product-links.sh` signale les initiatives floues, non exécutables ou liées à tort.
- `product-status.sh` donne une vue de traceability des initiatives et dev linked.
- `product-portfolio.sh` compare impact, confiance, coût et evidence.
- `product-review.sh product/<id>` recommande une décision `continue / cut / pivot / scale`.

## Contrats

- Read-only : aucun script produit ne modifie les fichiers.
- Pas de reminder : la couche produit est lue juste-à-temps.
- Pas de roadmap parallèle : `.docs/features/product/*.md` reste un index d'initiatives et de décisions.
- Interop : BMAD, Spec Kit, Linear, Jira, GitHub et autres sources restent propriétaires de leurs artefacts ; `external_refs` ne fait que les relier.
- Compatible Claude/Codex : la surface commune passe par `aic.sh product-*`.

## Décisions

- **Pas de copie de BOS** : on retient une boucle product adaptée au logiciel (initiatives, lien typé vers dev, evidence, décision suivante) plutôt qu'un cadre importé tel quel.
- **Traceability/governance, pas roadmap** : le scope product est une couche compatible BMAD, Spec Kit et tickets externes via `external_refs`, jamais une roadmap autonome.
- **Lean by design** : la traceability reste on-demand pour ne pas augmenter le Pack A ; le smoke vérifie le rendu product sans imposer de chargement au démarrage.
- **Recommandation, pas décision** : `product-review.sh` propose `continue / cut / pivot / scale`, l'humain tranche (posture héritée de `workflow/agent-behavior`).
- **Read-only assumé** : les rapports n'écrivent jamais l'index, choix verrouillé le 2026-05-14 pour éviter les reconstructions implicites.

## Validation

- `tests/unit/test-product-reports-read-only.sh` garantit que `check-product-links`, `product-status`, `product-portfolio` et `product-review` ne reconstruisent pas `.ai/.feature-index.json`.
- `tests/smoke-test.sh` couvre `product-status`, `product-portfolio` et `product-review` sur un scaffold Copier (leading indicator de la feature).
- `check-product-links.sh` signale les initiatives floues, non exécutables ou liées à tort.
- Le frontmatter produit valide contre `.ai/schema/feature.schema.json` (et son pendant template).

## Cross-refs

- `workflow/agent-behavior` : posture de recommandation et clôture orientée prochaine action.
- `core/feature-mesh` : source du frontmatter, de l'index et des dépendances.

## Historique / décisions

- 2026-05-03 : décision de ne pas copier BOS tel quel. Le besoin retenu est une boucle product adaptée au logiciel : initiatives product, lien typé vers features dev, evidence et décision suivante.
- 2026-05-04 : passe first user experience. Ajout d'un parcours read-only `ai-context.sh first-run`, documentation dans README/README_AI_CONTEXT et smoke test dédié pour réduire la friction après scaffold.
- 2026-05-04 : recadrage marché. Le scope product devient une couche de traceability/governance compatible BMAD, Spec Kit et tickets externes via `external_refs`, pas une roadmap autonome.
- 2026-05-04 : lean Codex confirmé : la traceability product reste on-demand et n'augmente pas le Pack A ; le smoke continue de couvrir le rendu product sans imposer de chargement produit au démarrage.
- 2026-05-04 : le nouveau template feature documente explicitement les décisions produit/fonctionnelles dans `Décisions`, `Périmètre`, `Validation` et les modules conditionnels. `external_refs` et les initiatives product restent des liens de traceability, pas des duplications de specs externes.
- 2026-05-14 : alignement effectif du contrat read-only. `check-product-links`, `product-status`, `product-portfolio` et `product-review` consomment un index temporaire ou un cache existant, mais ne reconstruisent plus `.ai/.feature-index.json` implicitement.
