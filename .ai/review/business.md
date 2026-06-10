# Module review — métier et fonctionnel

Charger quand une feature, une règle métier, un parcours utilisateur ou une API
fonctionnelle est touché.

## Source de vérité

Comparer le delta avec les sections suivantes des fiches feature concernées :

- `Objectif`
- `Périmètre`
- `Invariants`
- `Comportement attendu`
- `Contrats`
- `Validation`
- modules conditionnels `Droits / accès`, `Données`, `UX`, `Observabilité` si
  activés.

## Critères vérifiables

- Le code implémente le comportement nominal décrit, sans élargir le périmètre.
- Les cas refusés sont traités explicitement.
- Les transitions d'état respectent les invariants.
- Les droits et données visibles correspondent aux acteurs prévus.
- Les messages utilisateur ou erreurs API restent compréhensibles et stables.
- Les cas limites documentés ont une validation associée.

## Incertitudes

Marquer `non vérifiable depuis la doc feature` quand :

- la fiche ne décrit pas le comportement modifié ;
- une règle métier semble implicite ;
- le delta ajoute un cas sans critère de validation ;
- une décision produit changerait la route de correction.

Une incertitude devient `blocker` si elle concerne le comportement central livré
par la feature.
