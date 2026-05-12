---
id: aic-frame-external-reference
scope: workflow
title: Rendre aic-frame exploitable comme cadrage durable référençable
status: done
depends_on:
  - workflow/intentional-skills
  - workflow/feature-new-approval-step
  - core/aic-surface-canonical
touches:
  - .agents/skills/aic-frame/**
  - .claude/skills/aic-frame/**
  - template/.agents/skills/aic-frame/**
  - template/.claude/skills/aic-frame/**
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - .docs/frames/**
  - template/{{docs_root}}/frames/**
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - README.md
touches_shared:
  - tests/smoke-test.sh
product: {}
external_refs:
  ai_debate: "/Users/huy/Documents/Perso/ai_debate/.ai-debate/discussions/0015-amelioration-cadrage-technique-aic-frame.md"
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: false
    observability: false
progress:
  phase: done
  step: "arbitrage AI Debate 0015 livré : niveaux low/standard/high, incertitudes, template frames, external_refs.frame et wrapper frame bootstrap"
  blockers: []
  resume_hint: "Feature clôturée ; reprendre seulement pour itération post-usage."
  updated: 2026-05-12
---

# Rendre aic-frame exploitable comme cadrage durable référençable

## Résumé

`aic-frame` doit devenir le cadrage complet d'une intention de feature, pas un simple plan conversationnel. Le résultat doit être structuré, durable, reprenable plusieurs jours plus tard et référençable par un orchestrateur externe via `execution_ref`.

L'arbitrage AI Debate 0015 valide une évolution adaptative : le niveau de cadrage est choisi automatiquement entre `low`, `standard` et `high`, avec justification visible et override humain explicite.

## Objectif

Permettre à un outil externe de décision ou planification, notamment AI Debate, de déléguer le cadrage au repo cible sans recopier le contenu du cadrage. L'outil externe doit pouvoir conserver uniquement un pointeur stable, un statut, une preuve et un `next_hint`, tandis que `ai_context` reste propriétaire du cadrage détaillé.

Le cadrage `aic-frame` doit faire tout ce qui est nécessaire avant de décider si l'intention devient une feature, une documentation, une ADR, une décision humaine, un diagnostic, ou rien.

## Périmètre

### Inclus

- Renforcer les workflows `aic-frame` runtime Claude/Codex.
- Propager le même contrat dans les templates Copier.
- Ajouter une sortie durable et stable exploitable comme `execution_ref`.
- Ajouter un template durable `.docs/frames/0000-template.md` et sa version Copier.
- Repositionner `aic.sh frame` comme bootstrap de contexte, pas comme moteur de cadrage critique.
- Formaliser les sections de cadrage :
  - analyse technique approfondie ;
  - impacts ;
  - aspects non couverts / à couvrir ;
  - préconisations ;
  - challenge IA ;
  - décision de routage.
- Définir les états de cadrage terminé et bloqué.
- Clarifier les décisions possibles après cadrage : `feature`, `doc`, `adr`, `manual`, `diagnose`, `dropped`.
- Préserver la confirmation humaine avant toute création de feature.

### Hors périmètre

- Modifier AI Debate.
- Importer des workflows AI Debate dans `ai_context`.
- Créer automatiquement une feature depuis `aic-frame`.
- Changer le schéma frontmatter des fiches feature sans décision séparée.
- Construire une API réseau ou un protocole inter-repo.

### Granularité / nommage

Cette fiche couvre le contrat de cadrage durable de `aic-frame`. Elle ne couvre pas une refonte générale de tous les skills `aic-*`.

## Invariants

- `aic-frame` cadre une intention de feature ou une intention proche ; il ne se limite pas à exécuter la demande initiale.
- L'IA doit challenger, questionner, proposer, découper, factoriser et signaler les angles morts.
- Le cadrage peut recommander de ne pas créer de feature.
- Si l'intention est vague, `aic-frame` doit poser toutes les questions nécessaires au cadrage, pas une seule question arbitraire.
- Aucune feature n'est créée sans confirmation humaine explicite.
- AI Debate reste externe : `ai_context` expose une sortie durable, il ne connaît pas ni n'importe les plans AI Debate.
- Le résultat durable doit être lisible par un humain sans contexte conversationnel complet.

## Décisions

- Le niveau de cadrage est automatique par défaut, avec override humain explicite possible :
  - `low` : demande locale, faible risque, sans contrat durable ni reprise externe ;
  - `standard` : défaut pour une feature ou une évolution de workflow non critique ;
  - `high` : contrat agentique, workflow, runtime/template, CI, migration, multi-agent, reprise externe, AI Debate ou `execution_ref`.
- La sortie de `aic-frame` doit déclarer le niveau choisi et sa justification.
- Les cadrages `standard` et `high` classent les incertitudes entre `Bloquant maintenant`, `Hypothèse de travail`, `Risque accepté` et `À valider plus tard`.
- `aic.sh frame` est un bootstrap de contexte. Son output ne doit pas laisser croire qu'il remplace le skill `aic-frame`.
- `external_refs.frame` est autorisé par `.ai/schema/feature.schema.json` via `additionalProperties`; aucune extension de schéma n'est nécessaire pour ce chantier.
- La décision de routage du cadrage utilise un enum fermé :
  - `feature` : créer une nouvelle feature ou confirmer une feature proposée ;
  - `doc` : produire ou mettre à jour une documentation hors feature active ;
  - `adr` : produire une décision d'architecture ;
  - `manual` : demander une décision humaine avant de continuer ;
  - `diagnose` : basculer vers `aic-diagnose` car le blocage réel n'est pas assez compris ;
  - `dropped` : abandonner explicitement l'intention.
- La sortie durable cible est un artefact Markdown versionné dans le repo, par exemple `.docs/frames/2026-05-12-cadrage-aic-frame.md`. Ce chemin est la valeur recommandée pour `execution_ref`.
- Le format exact de l'artefact doit rester repo-local, lisible, diffable et stable.

## Comportement attendu

Quand `aic-frame` est utilisé, l'agent produit un cadrage complet avec :

- niveau `low | standard | high` déclaré et justifié ;
- problème réel et besoin ;
- objectif, non-objectifs et critères de succès ;
- contexte métier / produit utile ;
- analyse technique approfondie ;
- impacts directs et indirects ;
- risques, inconnues, dépendances et arbitrages ;
- aspects non couverts / à couvrir ;
- préconisations priorisées et actionnables ;
- challenge IA ;
- décision de routage et prochaine action.

Le résultat doit pouvoir être repris plusieurs jours plus tard par un agent ou un humain qui ne dispose que de l'artefact durable.

### Niveaux de cadrage

`low` exige le noyau minimal : problème réel, non-objectifs, scope primaire, route unique et prochaine action minimale.

`standard` ajoute impacts probables, critères d'acceptation testables, validations prévues, risques et inconnues. Si la route est `feature`, il propose `scope/id`, `depends_on` et `touches`.

`high` ajoute surfaces probables, contrats touchés, compatibilité Claude/Codex/templates/downstream, scénario nominal, au moins deux cas limites, stratégie d'artefact durable, checks ciblés et décision explicite `done` vs `blocked`.

## Analyse technique approfondie

Le cadrage doit expliciter :

- les surfaces probables à modifier ;
- les contrats ou formats concernés ;
- les effets sur le feature mesh, les workflows, les skills runtime et les templates ;
- les validations nécessaires ;
- les risques de compatibilité avec Claude, Codex et les repos consommateurs ;
- les points qui demandent lecture ciblée avant implémentation.

Pour choisir le niveau, `aic-frame` inspecte les signaux suivants :

- déclaration utilisateur : cadrage durable, reprise externe, AI Debate, `execution_ref`, plan d'action, décision d'architecture, migration, compatibilité, refonte de workflow ou skill ;
- lexique : `skill`, `workflow`, `hook`, `quality gate`, `contrat`, `template`, `Claude`, `Codex`, `agent`, `orchestrateur`, `MCP`, `ADR`, `handoff`, `cross-scope`, `migration`, `schema`, `format`, `runtime` ;
- inspection ciblée d'au plus deux familles de chemins quand le scope ou le risque le justifie.

Une inconnue ne peut pas rester une hypothèse si elle peut changer le scope, la route, le DONE ou la validation, ou si son impact serait majeur même à faible probabilité.

## Impacts

Impacts probables de cette feature :

- `aic-frame` runtime Codex sous `.agents/skills/aic-frame/`.
- `aic-frame` runtime Claude sous `.claude/skills/aic-frame/`.
- Templates associés sous `template/.agents/skills/aic-frame/` et `template/.claude/skills/aic-frame/`.
- Smoke tests si le rendu Copier doit vérifier la présence du nouveau contrat.
- Documentation utilisateur si la notion d'artefact durable devient visible.
- Wrapper `.ai/scripts/aic.sh` et template Copier associé, pour clarifier que `frame` est un bootstrap.

## Aspects non couverts / à couvrir

À couvrir pendant l'implémentation :

- nommage exact et emplacement de l'artefact durable ;
- format minimal du frontmatter ou des métadonnées de cadrage ;
- stratégie si un cadrage concerne plusieurs features potentielles ;
- comportement si un artefact de cadrage existe déjà ;
- lien entre artefact de cadrage et fiche feature créée plus tard.

Non couvert par cette fiche :

- synchronisation automatique avec AI Debate ;
- mutation des plans externes ;
- décision produit globale hors cadrage de l'intention courante.

## Préconisations

1. Priorité haute : définir d'abord le contrat de sortie durable (`execution_ref`, statut, preuve, `next_hint`).
2. Priorité haute : rendre le niveau de cadrage visible, justifié et contestable.
3. Priorité haute : garder `aic-frame` lisible en conversation tout en ajoutant un mode artefact durable.
4. Priorité moyenne : ajouter un format de routage strict, avec enum fermé et justification courte.
5. Priorité moyenne : tester le dogfood runtime/template pour éviter la divergence Claude/Codex.
6. Priorité moyenne : clarifier `aic.sh frame` comme bootstrap de contexte.
7. Priorité basse : enrichir la documentation publique seulement après stabilisation du contrat.

## Challenge IA

`aic-frame` doit explicitement challenger la demande avant de proposer la suite :

- Le problème déclaré est-il le vrai problème ?
- L'intention est-elle trop grosse pour une seule feature ?
- Faut-il découper en plusieurs features ou étapes ?
- Une documentation, une ADR ou une décision humaine est-elle plus adaptée qu'une feature ?
- Existe-t-il une feature active à reprendre plutôt qu'une nouvelle à créer ?
- Quels angles morts, dépendances ou risques rendent le cadrage incomplet ?
- Quelle option réduit le plus le risque sans sur-spécifier trop tôt ?

Le challenge ne doit pas bloquer artificiellement l'exécution ; il doit produire une recommandation claire et actionnable.

## Décision de routage

Chaque cadrage durable doit terminer par une décision parmi :

- `feature`
- `doc`
- `adr`
- `manual`
- `diagnose`
- `dropped`

La décision doit inclure :

- une justification courte ;
- une prochaine action ;
- un `next_hint` utilisable par un orchestrateur externe ;
- une preuve minimale que le cadrage a été produit, typiquement le chemin `execution_ref`.

## Cadrage terminé

Un cadrage est terminé quand :

- le niveau est déclaré et justifié ;
- les sections obligatoires sont renseignées ;
- la décision de routage est explicite ;
- les impacts techniques sont listés ;
- les aspects non couverts sont listés ;
- les préconisations sont priorisées ;
- la prochaine action est claire ;
- l'artefact durable existe ou la conversation indique explicitement qu'il doit être créé avant reprise externe.

## Cadrage bloqué

Un cadrage est bloqué quand :

- une information nécessaire manque et ne peut pas être inférée raisonnablement ;
- plusieurs routes restent plausibles sans arbitrage humain ;
- le problème réel semble différent du problème déclaré ;
- le découpage en features dépend d'une décision produit ou architecture non prise ;
- le bon prochain geste est un diagnostic plutôt qu'une feature.

Un cadrage bloqué doit produire une raison, toutes les questions ou décisions nécessaires au cadrage, et un `next_hint`. Les questions doivent distinguer ce qui bloque maintenant de ce qui peut rester `À valider`.

## Checklist d'acceptation du cadrage

- Le niveau `low | standard | high` est déclaré et justifié.
- Le problème réel est distingué de la demande initiale.
- Les non-objectifs sont écrits.
- Le scope primaire est unique ou le blocage/HANDOFF est explicite.
- La route finale est unique.
- Les inconnues bloquantes ne sont pas déguisées en hypothèses.
- Les critères d'acceptation sont testables.
- Les validations prévues sont listées ou explicitement justifiées.
- La prochaine action minimale est claire.
- Pour `standard`, impacts, risques et validations sont présents.
- Pour `high`, surfaces, contrats, compatibilité, scénario nominal et deux cas limites sont présents.
- Pour une route `feature`, `scope/id`, `depends_on`, `touches` et validations attendues sont proposés.
- Pour un `execution_ref`, l'artefact durable contient `status`, `route`, `level`, `evidence` et `next_hint`.

## Contrats

- `aic-frame` ne modifie pas AI Debate.
- `aic-frame` ne lit pas les workflows AI Debate.
- `aic-frame` peut produire un artefact durable repo-local référençable par `execution_ref`.
- Un outil externe peut stocker :
  - `execution_ref` : chemin de l'artefact durable ;
  - `status` : état externe du plan ;
  - `evidence` : preuve courte, par exemple existence du fichier ou résumé de routage ;
  - `next_hint` : prochaine action proposée par le cadrage.
- Le contenu détaillé reste dans `ai_context`.
- La création de feature passe toujours par confirmation humaine et workflow `feature-new`.

## Validation

- `bash .ai/scripts/build-feature-index.sh --write`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh workflow/aic-frame-external-reference`
- `bash .ai/scripts/check-dogfood-drift.sh`
- `bash tests/smoke-test.sh`

## Droits / accès

Non requis : workflow documentaire et agentique uniquement.

## Données

Non requis : pas de données applicatives.

## UX

Non requis : pas d'interface applicative. L'UX concernée est celle du workflow agent.

## Observabilité

Non requis au runtime applicatif. La preuve attendue est le fichier durable et les checks locaux.

## Déploiement / rollback

Déploiement par mise à jour des workflows runtime et templates. Rollback par revert des fichiers `aic-frame` modifiés et suppression du format d'artefact durable si introduit.

## Risques

- Format trop lourd : `aic-frame` deviendrait pénible pour les petites demandes.
- Format trop vague : l'orchestrateur externe ne pourrait pas s'appuyer dessus.
- Sur-automatisation : risque de créer une feature sans confirmation humaine.
- Couplage externe : risque d'introduire des concepts AI Debate dans `ai_context`.
- Divergence runtime/template : Claude et Codex pourraient cadrer différemment.

## Cross-refs

- `workflow/intentional-skills` : `aic-frame` est la surface publique de cadrage.
- `workflow/feature-new-approval-step` : aucune fiche feature sans proposition validée.
- `core/aic-surface-canonical` : la surface `aic-*` reste canonique.

## Historique / décisions

- 2026-05-11 : création de la fiche pour rendre `aic-frame` durable, référençable et exploitable par un orchestrateur externe sans importer ses workflows.
- 2026-05-11 : implémentation rédactionnelle runtime/template. `aic-frame` formalise désormais challenge IA, analyse approfondie, impacts, non-couverts, préconisations, routage enum et sortie durable `execution_ref`.
- 2026-05-11 : clarification du comportement flou : `aic-frame` pose toutes les questions nécessaires au cadrage, groupées entre blocage immédiat et points à valider plus tard.
- 2026-05-12 : arbitrage AI Debate 0015 validé. Ajout du cadrage adaptatif `low|standard|high`, table d'incertitudes, template `.docs/frames`, `external_refs.frame` sans extension de schéma, et clarification de `aic.sh frame` comme bootstrap.
