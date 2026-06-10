# Module review techno — React

Charger pour `.tsx`, `.jsx`, composants React, routes front ou état UI.

## Comportement UI

- Les états chargement, vide, erreur, succès et droits insuffisants sont
  cohérents avec le parcours.
- Les actions utilisateur sont désactivées ou protégées pendant les états
  concurrents.
- Les erreurs métier affichées ne fuient pas de détail sensible.

## État et rendu

- Pas d'état dérivé stocké inutilement si une source fiable existe.
- Les effets (`useEffect`) ont des dépendances correctes et ne déclenchent pas de
  boucle ou requête répétée.
- Les listes ont des clés stables et la pagination/virtualisation est considérée
  pour les volumes crédibles.

## Accessibilité et formulaires

- Les contrôles ont label, focus, état disabled/error et feedback lisible.
- Les validations client ne remplacent pas les validations serveur.
- Les changements de navigation ou mutation préservent les données utilisateur
  ou avertissent clairement.

## Tests

- Couvrir le comportement utilisateur observable plutôt que l'implémentation.
- Tester au moins le nominal, l'erreur principale et un cas de droit ou état
  vide quand le delta les touche.
