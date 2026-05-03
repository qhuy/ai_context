# Workflow — aic-diagnose

**Goal** : identifier le bottleneck principal d'une tâche ou d'une feature et produire une prochaine action minimale.

**Role** : Diagnosticien. Écoute, lit le contexte juste nécessaire, prend position. Ne code pas dans ce skill.

## INPUT ATTENDU

- Une tâche, un symptôme, ou un `scope/id` de feature.
- Si absent : diagnostiquer la situation courante à partir du dernier prompt et du mesh chargé.

## MANDATORY READS

- `.ai/index.md`
- `.ai/agent/posture.md`, `.ai/agent/initiative-contract.md`, `.ai/agent/response-style.md`
- `.ai/quality/QUALITY_GATE.md`
- `.ai/rules/<scope>.md` si le scope est identifiable
- `.docs/features/<scope>/<id>.md` + worklog si une feature est ciblée

Ne pas charger d'autres docs sans signal concret.

## PHASES

### Phase 1 — Cadrage minimal

1. Reformuler en une ligne le résultat attendu.
2. Identifier le scope primaire si possible.
3. Classer le blocage probable parmi :
   - `spec`
   - `contexte`
   - `scope`
   - `architecture`
   - `implémentation`
   - `tests`
   - `doc`
   - `qualité`
   - `décision produit`

Si deux catégories semblent plausibles, choisir la plus bloquante pour la prochaine action.

### Phase 2 — Evidence courte

Collecter uniquement les preuves nécessaires :

- `spec` : objectif, contrat attendu, critères d'acceptance.
- `contexte` : docs/features manquantes ou contradictoires.
- `scope` : cross-scope, dépendance non chargée, handoff nécessaire.
- `architecture` : frontière, dépendance, layering, contrat public.
- `implémentation` : fichier, code path, erreur reproductible.
- `tests` : commande, échec, couverture ou fixture manquante.
- `doc` : fiche feature/worklog/contrat obsolète.
- `qualité` : quality gate, shims, references, feature mesh, contexte trop gros.
- `décision produit` : choix métier nécessaire avant d'écrire.

### Phase 3 — Recommandation

Produire une recommandation unique. Si une alternative existe, la mentionner seulement si elle change réellement la décision.

## FORMAT DE SORTIE

Répondre exactement avec cette structure :

```markdown
## Diagnostic

Bottleneck principal :
<spec / contexte / scope / architecture / implémentation / tests / doc / qualité / décision produit>

Pourquoi :
- ...

Ce que je recommande :
1. ...

Ce que je ne recommande pas :
- ...

Prochaine action minimale :
- ...
```

## NON-NEGOTIABLE RULES

- Un seul bottleneck principal.
- Pas de liste neutre sans recommandation.
- Pas de diagnostic sans prochaine action minimale.
- Si le blocage est un manque d'information, demander une seule information, pas un questionnaire.
- Si le blocage est actionnable localement, recommander l'action locale plutôt qu'une discussion.
- Ne pas modifier de fichiers dans ce skill ; sortir du skill pour implémenter après diagnostic.
