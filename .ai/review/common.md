# Module review — socle commun

Charger pour toute revue applicative.

## Exactitude et contrats

- Vérifier que le delta respecte les préconditions, postconditions, erreurs et
  cas refusés décrits par la feature ou l'API.
- Signaler un finding seulement si le comportement observé contredit un contrat
  explicite ou crée un risque concret.
- Identifier les changements de compatibilité : signature publique, format,
  schéma, route, événement, configuration ou migration.

## Erreurs et robustesse

- Les erreurs attendues doivent être représentées explicitement : retour typé,
  exception contrôlée, code HTTP, message utilisateur ou log support.
- Les erreurs ne doivent pas être avalées sans trace exploitable.
- Les chemins partiels, timeouts, données absentes, doublons et états concurrents
  doivent rester cohérents avec les invariants.

## Sécurité légère

- Vérifier les droits avant action ou exposition de données.
- Refuser les entrées non fiables avant usage sensible : requête, commande,
  chemin fichier, template, SQL, URL, sérialisation.
- Ne pas introduire de secret, token, donnée personnelle inutile ou log sensible.
- Escalader vers une revue sécurité dédiée si auth, chiffrement, permissions
  complexes ou données sensibles changent substantiellement.

## Performance pragmatique

- Chercher les risques visibles dans le delta : N+1, boucle non bornée, requête
  large, rendu répété, I/O synchrone bloquante, cache incohérent.
- Demander une mesure seulement si le risque est crédible ou si le changement
  touche un chemin chaud.
- Ne pas bloquer sur une optimisation spéculative.

## Tests

- Le niveau de test doit suivre le risque : nominal, limites, erreurs, droits,
  régression métier et intégration externe si concernée.
- Une absence de test est un finding seulement si le delta modifie un contrat, un
  invariant ou une surface à risque.
