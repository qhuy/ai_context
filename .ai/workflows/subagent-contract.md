# Procédure interne — subagent-contract

**Goal** : encadrer toute délégation à des subagents Claude, Codex ou équivalents sans casser le scope primaire, la traçabilité feature et la compatibilité multi-agent.

**Role** : Contrat de délégation. Ne remplace ni le feature mesh, ni les checks, ni les handoffs.

**Procedure chain** : cadrage → **`.ai/workflows/subagent-contract.md`** → délégation bornée → intégration → docs/checks.

## Quand déléguer

Déléguer seulement si la tâche parallèle est autonome, bornée et utile sans bloquer la prochaine décision de l'agent principal.

Ne pas déléguer :

- la décision de scope primaire ;
- la création du HANDOFF ;
- une écriture dans un scope non confirmé ;
- une correction urgente dont le résultat bloque l'action suivante.

## Rôles

### Explorer

- Lecture seule.
- Question précise.
- Sortie : réponse, fichiers consultés, incertitudes.
- Interdit : modification, suggestion de patch non demandée, exploration large.

### Worker

- Write-set explicite et disjoint.
- Contexte minimal : objectif, paths autorisés, fichiers interdits, checks attendus.
- Sortie : fichiers modifiés, décision prise, risques, checks lancés ou non lancés.
- Interdit : revert de changements tiers, édition hors assignation, changement de scope sans HANDOFF.

## Limites de fanout

- Par défaut : 0 ou 1 subagent.
- Plusieurs subagents seulement si les write-sets sont disjoints ou si tous sont lecture seule.
- Ne pas dupliquer le même travail entre agent principal et subagent.
- Fermer les subagents inutiles dès que leurs résultats sont intégrés.

## Contrat de sortie

Chaque subagent doit produire :

```text
RESULT: DONE | BLOCKED | PARTIAL
Scope:
Files read:
Files changed:
Decisions:
Risks:
Checks:
Next:
```

## Cross-scope

Si un subagent découvre un besoin hors scope :

1. Il stoppe les écritures hors scope.
2. Il remonte le besoin à l'agent principal.
3. L'agent principal produit un HANDOFF explicite.
4. La session cible reprend seulement après confirmation.

## Validation

- Vérifier que Pack A ne charge pas ce fichier par défaut.
- Vérifier que les features impactées documentent les décisions.
- Lancer les checks ciblés avant ship.
