# Règles Product

Le scope `product` sert à piloter les initiatives, paris, métriques et arbitrages de portefeuille. Il ne remplace pas les scopes dev ; il explique pourquoi ils existent.

## Contrats

- Une feature `scope: product` représente une initiative produit.
- Une initiative produit doit formuler un pari testable, une métrique de succès et une prochaine décision.
- Les features dev se relient à une initiative via `product.initiative`, pas via `depends_on`, sauf vraie dépendance technique/contexte.
- Les scripts produit sont read-only : ils recommandent, ils ne changent pas les priorités automatiquement.

## Frontmatter recommandé pour une initiative

```yaml
product:
  type: initiative
  bet: ""
  target_user: ""
  success_metric: ""
  leading_indicator: ""
  decision_state: explore
  next_decision_date: ""
  kill_criteria: []
  portfolio:
    appetite: small
    confidence: medium
    expected_impact: medium
    urgency: medium
    strategic_fit: high
```

## Frontmatter recommandé pour une feature dev liée

```yaml
product:
  initiative: product/<id>
  contribution: ""
  evidence: ""
```

## Interdits

- Ne pas créer une roadmap séparée si une initiative `product/*` suffit.
- Ne pas garder plus de trois initiatives produit `active` sans justification explicite.
- Ne pas marquer une initiative `done` sans evidence produit ou décision de cut documentée.
