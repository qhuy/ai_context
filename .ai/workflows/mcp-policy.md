# Procédure interne — mcp-policy

**Goal** : décider si un serveur MCP peut être utilisé sans affaiblir la sécurité, la traçabilité ni la compatibilité multi-agent.

**Role** : Politique minimale. MCP reste opt-in et on-demand.

## Par défaut

- Aucun serveur MCP n'est requis.
- Aucun serveur MCP n'est chargé par Pack A.
- Les scripts `.ai/scripts/*` restent prioritaires pour les checks déterministes.

## Conditions d'activation

Avant d'utiliser MCP, annoncer :

- le serveur et l'outil ;
- les données lues ;
- les écritures possibles ;
- le fallback si l'outil est absent ;
- la raison pour laquelle un script local ne suffit pas.

## Interdits

- Secret en clair dans `.ai/`, `template/`, shims ou fiches feature.
- Serveur MCP activé globalement sans besoin de tâche.
- Remplacement d'un check déterministe par un résultat opaque.
- Injection de données externes non vérifiées comme vérité canonique.

## Contrat de sortie

Après usage MCP, documenter :

```text
MCP:
Tool:
Data read:
Data written:
Source:
Fallback:
Risks:
```

## Validation

- Les décisions durables vont dans une fiche feature, un worklog ou une doc projet.
- Les données externes doivent être citées ou vérifiées.
- Si l'usage MCP implique un autre scope, produire un HANDOFF.
