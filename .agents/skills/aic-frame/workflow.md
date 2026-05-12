# Workflow — aic-frame

**Goal** : cadrer complètement une intention avant implémentation, puis recommander la bonne suite sans écrire de code.

**Role** : Cadreur critique. L'agent clarifie, challenge, factorise, découpe si nécessaire, prend position et produit une sortie exploitable. Il peut créer ou mettre à jour une fiche feature seulement après confirmation explicite.

## INPUT

- Intention libre : "je veux ajouter X", "améliorer Y", "prépare la feature Z".
- Optionnel : scope, feature existante, contrainte métier/technique, deadline, besoin de sortie durable, niveau demandé `low|standard|high`.
- Si l'intention est trop vague : poser toutes les questions nécessaires au cadrage, limitées aux décisions bloquantes. Les grouper par thème, séparer `Bloquant maintenant` de `À valider plus tard`, et ne pas produire de plan tant que les bloquantes ne sont pas résolues.

## CONTEXT LOADING

Mandatory :

1. `.ai/index.md`
2. `.ai/rules/<scope>.md` si le scope est identifiable et utile
3. `.docs/features/<scope>/<id>.md` si la feature existe

On-demand seulement :

- `.ai/quality/QUALITY_GATE.md` si `progress.phase` ∈ {review, done}, ou intention nommée ship/done/review/quality-gate, ou changement contrat/sécurité/CI/doc canonique.
- `.ai/agent/posture.md`, `.ai/agent/initiative-contract.md`, `.ai/agent/response-style.md` seulement si la demande porte explicitement sur posture, diagnostic ou style.

Ne pas précharger le reste.

## NIVEAU DE CADRAGE

Choisir automatiquement un niveau `low | standard | high`, sauf override humain explicite. Le niveau doit être visible et justifié dans la sortie.

Déclencheurs :

- `low` : demande locale, faible risque, sans contrat durable ni reprise externe.
- `standard` : défaut pour une feature ou une évolution de workflow non critique.
- `high` : contrat agentique, workflow, runtime/template, CI, migration, multi-agent, reprise externe, AI Debate ou `execution_ref`.

Signaux à inspecter :

- Signal A — déclaration utilisateur : cadrage durable, reprise externe, AI Debate, `execution_ref`, plan d'action, décision d'architecture, migration, compatibilité, refonte de workflow ou skill.
- Signal B — détection lexicale : `skill`, `workflow`, `hook`, `quality gate`, `contrat`, `template`, `Claude`, `Codex`, `agent`, `orchestrateur`, `MCP`, `ADR`, `handoff`, `cross-scope`, `migration`, `schema`, `format`, `runtime`.
- Signal C — inspection ciblée : au plus deux familles de chemins parmi `.agents/skills/<nom>/`, `.claude/skills/<nom>/`, `.ai/workflows/<nom>.md`, `.ai/scripts/<nom>.sh`, `.docs/features/<scope>/<id>.md`, `template/.agents/skills/<nom>/`, `template/.claude/skills/<nom>/`.

Si le signal lexical est seul, confirmer par une justification d'une ligne pour éviter les faux positifs.
Si l'inspection révèle un contrat agentique, un format durable, un script partagé ou une surface template/runtime, passer `high`.

## PHASES

### 1. Intention réelle

Identifier le problème réel, l'objectif, l'utilisateur/système concerné, les non-objectifs, la décision manquante et le résultat vérifiable attendu.

### 2. Challenge IA

Challenger avant de planifier :

- Le problème déclaré est-il le vrai problème ?
- Faut-il reprendre une feature existante ?
- L'intention doit-elle être découpée en plusieurs features ou étapes ?
- Une doc, une ADR, une décision humaine ou `aic-diagnose` est-elle plus adaptée ?
- Quels angles morts, risques ou dépendances changent la route ?

### 3. Analyse

Séparer explicitement :

- **Métier / produit** : règles, vocabulaire, acteurs, cas limites, invariants.
- **Technique** : surfaces probables, contrats, données, dépendances, migrations, tests.
- **Impacts** : fichiers, workflows, templates, docs, CI, compatibilité downstream.
- **Non couverts / à couvrir** : ce qui reste volontairement hors décision ou demande un arbitrage.

Marquer `À valider` toute inconnue bloquante. Ne pas l'enterrer en hypothèse.

Pour `standard` et `high`, classer les incertitudes :

| Catégorie | Règle |
|---|---|
| Bloquant maintenant | empêche `done`, exige question, diagnostic ou décision |
| Hypothèse de travail | autorisée si elle ne change probablement pas scope/route/DONE/validation |
| Risque accepté | conséquence écrite + validation prévue |
| À valider plus tard | attaché à une étape ou un check précis |

Une inconnue ne peut pas rester une hypothèse si elle a une probabilité crédible de changer le scope, la route, le DONE ou la validation, ou si son impact serait majeur même à faible probabilité.

### 4. Préconisations et routage

Fournir des préconisations priorisées et une décision unique :

- `feature` : créer/reprendre une feature après confirmation humaine ;
- `doc` : produire ou mettre à jour une doc ;
- `adr` : formaliser une décision d'architecture ;
- `manual` : décision humaine requise ;
- `diagnose` : basculer vers `aic-diagnose` ;
- `dropped` : abandon recommandé.

### 5. Plan et validation

Si la suite est actionnable, produire 3 à 7 étapes vérifiables, les critères d'acceptance, les checks prévus et l'impact documentaire.

Compléments obligatoires par niveau :

- `low` : problème réel, non-objectifs, scope primaire, route unique, prochaine action minimale.
- `standard` : impacts probables, critères d'acceptation testables, validations prévues, risques et inconnues, proposition `scope/id`, `depends_on`, `touches` si `route=feature`.
- `high` : surfaces probables, contrats touchés, compatibilité Claude/Codex/templates/downstream, scénario nominal, au moins deux cas limites, stratégie d'artefact durable, checks ciblés, décision explicite `done` vs `blocked`.

### 6. Sortie durable

Si l'utilisateur demande `execution_ref`, AI Debate, orchestrateur externe, reprise durable ou plan externe :

- créer ou mettre à jour un artefact Markdown repo-local sous `.docs/frames/<YYYY-MM-DD>-<slug>.md` ;
- y mettre le même cadrage, plus `frame_id`, `status`, `scope_probable`, `route`, `level`, `evidence`, `next_hint` ;
- retourner `execution_ref: .docs/frames/<...>.md`.

Sinon, répondre en conversation et indiquer `execution_ref: non créé`. Ne pas importer de workflow externe.

## CADRAGE TERMINÉ / BLOQUÉ

Terminé si : objectif clair, challenge fait, impacts listés, non-couverts listés, préconisations priorisées, route unique, prochaine action claire.

Bloqué si : information indispensable absente, routes concurrentes sans arbitrage, vrai problème incertain, découpage dépendant d'une décision, ou diagnostic nécessaire. Dans ce cas : expliquer le blocage, poser les questions ou décisions attendues, fournir `next_hint`.

## FORMAT DE SORTIE

```markdown
## Cadrage

Statut : done | blocked
Niveau de cadrage : low | standard | high
Justification du niveau :
- ...
execution_ref : <path | non créé>

Objectif :
- ...

Challenge IA :
- ...

Analyse technique approfondie :
- ...

Scénario nominal :
- ...

Cas limites :
- ...

Impacts :
- ...

Incertitudes :
| Catégorie | Point | Décision |
|---|---|---|
| Bloquant maintenant | ... | ... |
| Hypothèse de travail | ... | ... |
| Risque accepté | ... | ... |
| À valider plus tard | ... | ... |

Aspects non couverts / à couvrir :
- ...

Préconisations :
1. ...

Décision de routage : feature | doc | adr | manual | diagnose | dropped
Justification :
- ...

Plan :
1. ...

Validation :
- Acceptance :
- Checks :
- Doc impact :

Points à confirmer :
- ...

Questions de cadrage si bloqué :
- Bloquant maintenant :
- À valider plus tard :

Prochaine action minimale :
- ...
```

## NON-NEGOTIABLE RULES

- Pas de code dans ce skill.
- Pas de liste neutre : prendre position.
- Pas de création de fiche sans confirmation humaine explicite.
- Si `route=feature`, proposer `scope/id`, titre, `depends_on`, `touches`, puis attendre confirmation avant `.ai/workflows/feature-new.md`.
- Si le cadrage révèle un blocage de compréhension, choisir `route=diagnose` et basculer vers le format `aic-diagnose`.
- AI Debate ou tout orchestrateur externe ne stocke que `execution_ref`, `status`, `evidence`, `next_hint`; le détail reste dans `ai_context`.
