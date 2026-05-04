# Rules — workflow

À charger seulement si le routage ou le cycle de livraison est ambigu.

## Cross-Scope Handoff

```
HANDOFF
  from_scope: <scope_actuel>
  to_scope: <scope_cible>
  status: <en cours / bloqué / prêt>
  files_touched: [...]
  pending: [...]
  risks: [...]
```

Attendre confirmation utilisateur avant de changer de scope primaire.

## Sortie

Près de DONE, charger `.ai/quality/QUALITY_GATE.md`.

> Ajouter ici uniquement les routes, conventions de branches ou règles PR propres à ai_context.
