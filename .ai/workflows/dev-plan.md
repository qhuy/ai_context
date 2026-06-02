# Workflow — aic-dev-plan

**Goal** : transformer une intention cadrée ou une feature existante en plan d'exécution vérifiable avant toute écriture de code.

**Role** : Planificateur structurant. L'agent identifie les surfaces, détermine l'ordre, liste les handoffs et les checks, prend position sur la prochaine action minimale. Il ne produit aucun code et ne lance aucun chantier.

## INPUT

- Feature existante (`.docs/features/<scope>/<id>.md`) ou sortie d'`aic-frame`.
- Optionnel : scope primaire, contraintes connues, chemins ou technos explicitement mentionnés.
- Si l'intention n'est pas encore cadrée : STOP — rediriger vers `aic-frame` d'abord.

## CONTEXT LOADING

Obligatoire :

1. `.ai/index.md`
2. `.docs/features/<scope>/<id>.md` si une feature est fournie ou déduite
3. `.ai/rules/<scope>.md` si le scope est identifiable et utile à l'ordre ou aux contrats

On-demand seulement :

- Règles techno (ex. `.ai/rules/back.md`, `.ai/rules/front.md`) seulement si la surface est clairement impliquée et si le fichier existe.
- `.ai/workflows/subagent-contract.md` seulement si le plan propose une délégation à des subagents.
- `.ai/quality/QUALITY_GATE.md` si l'intention mentionne DONE, ship ou quality gate.

Ne pas précharger le reste.

## PHASES

### 1. Surfaces

Identifier toutes les surfaces impliquées par la feature :

- back, front, CLI, template Copier, docs, CI, scripts, contrat API/DTO, MCP, agents/skills, infra.

Par surface, préciser : scope probable, fichiers ou patterns probables, et si un **contrat traversant** existe (API, DTO, auth, droits, données ou erreurs entre deux surfaces ou deux agents).

### 2. Ordre d'exécution

Appliquer les règles de séquencement :

- **Contrat-first** : si API, DTO, auth, droits, données ou erreurs changent entre surfaces → stabiliser le contrat avant d'implémenter les consommateurs.
- **Exception exploration** : si l'utilisateur veut une exploration UI d'abord → le dire explicitement et noter le risque de désynchronisation contrat.

Par étape : surface, rôle, write-set résumé, durée estimée (court/moyen/long), prérequis, checks post-étape.

### 3. Handoffs

**Cross-scope** : tout passage vers un autre scope primaire produit un bloc HANDOFF explicite :

```text
HANDOFF
  from_scope: <scope_actuel>
  to_scope: <scope_cible>
  status: prêt
  files_touched: [...]
  pending: [...]
  risks: [...]
```

Attendre confirmation utilisateur avant de changer de scope.

**Subagents** : si délégation parallèle proposée, charger `.ai/workflows/subagent-contract.md`. Chaque subagent doit avoir un rôle, un write-set explicite et disjoint, les fichiers interdits et les checks attendus.

### 4. Risques et inconnues

Classer explicitement :

| Catégorie | Règle |
|---|---|
| **BLOQUER** | empêche de commencer ou de finir sans décision ; exige question ou arbitrage |
| Hypothèse | autorisée si ne change probablement pas scope/route/DONE |
| Risque accepté | conséquence écrite + validation prévue |

Une inconnue ne peut pas rester hypothèse si elle a une probabilité crédible de changer le scope, la route ou le critère de DONE.

## FORMAT DE SORTIE

```markdown
## Plan

Scope primaire : <scope>
Feature : <id ou "intention cadrée">

### Surfaces

| Surface | Scope | Contrat traversant | Fichiers probables |
|---|---|---|---|
| ... | ... | oui / non | ... |

### Ordre d'exécution

1. **<Surface>** — <rôle>
   - Write-set : ...
   - Prérequis : ...
   - Durée : court / moyen / long
   - Checks post-étape : ...

### Handoffs

- HANDOFF ou "aucun"
- Subagents : ... ("aucun" si pas de délégation)

### Risques et inconnues

| Catégorie | Point | Décision |
|---|---|---|
| BLOQUER | ... | question à poser |
| Hypothèse | ... | ... |
| Risque accepté | ... | validation prévue |

### Prochaine action

- ...
```

## NON-NEGOTIABLE RULES

- Aucun code dans ce skill.
- Aucun commit, aucun lancement implicite de chantier.
- Si le contrat traversant ou la techno cible est inconnue → marquer **BLOQUER**, ne pas enterrer en hypothèse.
- Si délégation proposée → charger `.ai/workflows/subagent-contract.md` et appliquer ses règles.
- Pas de liste neutre : prendre position sur l'ordre et la prochaine action.
- Un scope primaire reste actif : HANDOFF explicite pour tout changement de scope.
- Si l'intention n'est pas cadrée → STOP, rediriger vers `aic-frame`.
- Si aucun subagent : écrire `Subagents : aucun` dans la sortie.
