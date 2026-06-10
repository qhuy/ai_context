# Module review techno — C#

Charger pour `.cs`, `.cshtml`, `.razor` ou surfaces .NET.

## ASP.NET / API

- Les endpoints valident les entrées, droits, codes d'erreur et contrats de
  sérialisation.
- Les actions ne mélangent pas orchestration HTTP, métier et accès données au
  point de rendre les règles impossibles à tester.
- Les annulations (`CancellationToken`) sont propagées sur I/O et requêtes
  longues quand disponible.

## Async et concurrence

- Pas de blocage sync sur async (`.Result`, `.Wait()`) dans un chemin serveur.
- Les opérations concurrentes protègent les invariants métier : idempotence,
  verrou, transaction ou contrainte unique selon le cas.

## Données / EF Core

- Surveiller N+1, `Include` excessifs, projections manquantes et requêtes non
  bornées.
- Les migrations préservent les données et prévoient rollback ou compatibilité
  si nécessaire.
- Les transactions couvrent les changements qui doivent rester atomiques.

## Tests

- Tester les règles métier hors infrastructure quand possible.
- Ajouter intégration API/DB quand le contrat HTTP, EF ou migration change.
