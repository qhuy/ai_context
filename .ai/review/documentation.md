# Module review — documentation

Charger si le delta change une règle durable, une surface publique ou une
exploitation.

## Seuils de documentation

Exiger une mise à jour documentaire quand le delta modifie :

- un contrat API, événement, schéma, format ou configuration ;
- une règle métier ou un invariant ;
- une migration, un rollout, un rollback ou une compatibilité downstream ;
- une permission, un rôle ou une exposition de données ;
- une procédure d'exploitation, debug, observabilité ou support.

Ne pas exiger de doc pour un changement interne étroit sans contrat durable.

## Fiche feature

- `Objectif`, `Périmètre`, `Comportement attendu`, `Contrats` et `Validation`
  doivent permettre de vérifier le delta.
- Les modules conditionnels doivent être remplis quand `doc.requires.*` vaut
  `true`.
- Le worklog doit garder les décisions ou changements d'intention utiles à la
  reprise.

## ADR / README / migration

- Proposer une ADR si le delta introduit un choix structurant ou difficile à
  inverser.
- Proposer README ou docs utilisateur si l'usage change.
- Proposer une note de migration si un utilisateur downstream doit agir.
