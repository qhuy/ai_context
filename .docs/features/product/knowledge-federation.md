---
id: knowledge-federation
scope: product
title: Federation de connaissances ai_context
status: active
type: feature
description: "Initiative produit pour publier, retrouver et reutiliser des connaissances ai_context entre projets sans remplacer le contexte local de chaque repo."
depends_on: []
touches:
  - .docs/features/product/knowledge-federation.md
  - .docs/features/product/knowledge-federation.worklog.md
touches_shared: []
product:
  type: initiative
  bet: "Une federation de connaissances permet de reutiliser les analyses deja produites entre projets, reduit les reanalyses inutiles et ouvre une lecture non-tech sans affaiblir la souverainete du contexte repo-local."
  target_user: "Mainteneurs de projets utilisant ai_context, equipes de migration, tech leads et non-techs qui doivent consulter ou valider des connaissances projet."
  success_metric: "Une connaissance produite dans un projet source peut etre retrouvee, referencee et reutilisee dans un projet consommateur avec provenance, fraicheur et sensibilite explicites."
  leading_indicator: "Un MVP de knowledge source permet publish/search/link sur deux projets reels sans duplication manuelle de l'analyse initiale."
  decision_state: commit
  next_decision_date: 2026-07-15
  kill_criteria:
    - "La solution remplace le .ai local au lieu de le completer."
    - "La publication devient implicite ou diffuse des informations sensibles sans validation humaine."
    - "Le hub devient un deuxieme feature mesh global qui force tous les projets a partager le meme cycle de livraison."
    - "L'acces non-tech impose Git/TFS comme interface principale."
  portfolio:
    appetite: medium
    confidence: medium
    expected_impact: high
    urgency: medium
    strategic_fit: high
external_refs: {}
doc:
  level: full
  requires:
    auth: true
    data: true
    ux: true
    api_contract: true
    rollout: true
    observability: true
progress:
  phase: review
  step: "contrat minimal et backend MVP Git/Markdown décidés"
  blockers: []
  resume_hint: "créer ensuite core/knowledge-source-contract puis workflow/knowledge-publish-search-link dans des tours dédiés ; ne pas mélanger avec R1"
  updated: 2026-07-03
---

# Federation de connaissances ai_context

## Résumé

Transformer `ai_context` d'un outil excellent en mono-repo vers un systeme capable de federer les connaissances utiles entre projets. Le contexte local reste souverain pour travailler et livrer dans chaque repo ; une couche de knowledge source partagee permet de publier, retrouver, citer et reutiliser les analyses deja produites.

## Objectif

Eviter que chaque projet doive reanalyser les memes modules, regles metier ou decisions techniques lorsqu'une connaissance fiable existe deja ailleurs. L'objectif est aussi de rendre certaines connaissances consultables ou validables par des non-techs sans leur imposer Git, TFS ou les contrats internes de `.ai/`.

## Périmètre

### Inclus

- Definition du modele produit d'une connaissance partagee.
- Separation entre feature locale, connaissance partagee et vue publiee non-tech.
- Flux cible `publish`, `search`, `link` et `import`.
- Garanties minimales : provenance, owner, fraicheur, confiance, sensibilite et droits d'usage.
- Premier choix de MVP pour un backend de knowledge source.
- Decoupage des futures features techniques `core` et `workflow`.

### Hors périmètre

- Remplacer les `.ai/` et `.docs/features/` locaux des repos consommateurs.
- Centraliser tous les worklogs, checks ou cycles DONE dans un hub global.
- Construire immediatement une application web complete.
- Publier automatiquement toutes les fiches locales.
- Resoudre tous les modeles de droits entreprise au premier MVP.

### Granularité / nommage

Cette fiche est une initiative produit. Elle ne doit pas devenir une feature technique fourre-tout. Les livrables executables devront etre separes, par exemple :

- `core/knowledge-source-contract` pour le schema et l'index.
- `workflow/knowledge-publish-search-link` pour les commandes ou skills.
- `workflow/knowledge-non-tech-publication` pour la vue publiee et les retours non-techs.
- `quality/knowledge-freshness-checks` pour les controles de provenance et de fraicheur.

## Invariants

- Le repo local reste la source de verite operationnelle pour ses features, checks, worklogs et livraisons.
- Une connaissance partagee complete le contexte local ; elle ne le remplace pas.
- Toute publication est explicite et reversible.
- Une connaissance partagee doit exposer sa provenance, sa fraicheur, son owner, son niveau de confiance et sa sensibilite.
- Un projet consommateur doit pouvoir lier une connaissance sans la copier silencieusement.
- Les non-techs consultent une vue publiee ou une interface dediee, pas les contrats bruts de `.ai/`.

## Décisions

- Demarrer par une federation de connaissances, pas par une centralisation du feature mesh.
- **MVP retenu 2026-07-03** : backend canonique Git/Markdown, avec fiches
  versionnées, index généré et publication explicite. Git sert de source de vérité
  maintainer ; il ne devient pas l'interface imposée aux non-techs.
- Distinguer trois couches :
  - contexte local du repo ;
  - knowledge source partagee ;
  - vue publiee lisible ou commentable.
- Ne pas embarquer le hub en submodule par defaut ; preferer une source configuree ou un cache local.
- Prevoir une evolution vers API ou MCP si les droits, la recherche ou les usages non-techs le justifient.
- Ne pas demarrer par une base de donnees, une API centrale ou une application web :
  ces options restent des evolutions si le MVP Git/Markdown prouve le besoin.

## Comportement attendu

Pour un projet source :

- Un agent peut transformer une analyse locale en connaissance partageable.
- L'humain valide explicitement la publication.
- Les metadonnees obligatoires sont verifiees avant ajout au hub.

Pour un projet consommateur :

- Un agent peut chercher des connaissances pertinentes.
- Une fiche locale peut referencer une connaissance partagee via `external_refs` ou un contrat equivalent.
- L'agent peut importer une synthese locale sans masquer la provenance.

Pour un non-tech :

- Les connaissances publiees sont lisibles hors Git/TFS.
- Les commentaires, validations ou signaux d'obsolescence peuvent etre remontes sans modifier directement les fichiers agentiques.

## Contrats

Contrat conceptuel d'une connaissance partagee :

```yaml
id: legacy-billing-invoice-rules
type: domain_knowledge
title: "Regles de facturation legacy"
source_project: legacy-erp
owner: finance
confidence: high
freshness:
  status: verified
  checked_at: 2026-06-29
sensitivity: internal
source_refs:
  - legacy-erp:/src/billing/InvoiceService.cs
  - legacy-erp:.docs/features/core/invoice-module.md
usable_by:
  - migration-project
```

Champs obligatoires du MVP :

- `id` : identifiant stable, unique dans le hub.
- `type` : nature de la connaissance (`domain_knowledge`, `technical_decision`,
  `migration_note`, etc.).
- `title` et `summary` : titre humain et synthese courte réutilisable.
- `source_project` et `source_refs` : provenance vérifiable.
- `owner` : responsable de validation ou de fraîcheur.
- `confidence` : niveau de confiance explicite.
- `freshness.checked_at` : date de dernière vérification.
- `sensitivity` : classification minimale (`public`, `internal`, `restricted`).
- `usable_by` : projets, équipes ou contextes autorisés.
- `status` : `draft`, `published`, `deprecated` ou `retracted`.

Structure MVP du hub :

```text
knowledge/
  legacy-erp/
    legacy-billing-invoice-rules.md
index.json
```

`index.json` est généré depuis les frontmatters pour la recherche locale ou un
futur connecteur ; le Markdown reste la source canonique relue et versionnée.

Contrat attendu cote repo consommateur :

```yaml
external_refs:
  knowledge:
    - company-hub://legacy-billing-invoice-rules
```

Commandes ou intents cibles :

- `aic knowledge publish`
- `aic knowledge search <query>`
- `aic knowledge link <knowledge-id>`
- `aic knowledge import <knowledge-id>`
- `aic knowledge freshness`

## Validation

- Un projet source peut publier une connaissance candidate avec metadonnees completes.
- Un projet consommateur peut retrouver cette connaissance sans reanalyser tout le projet source.
- Une fiche locale peut lier la connaissance partagee avec provenance visible.
- Une connaissance sensible ou sans owner est refusee ou reste locale.
- Une connaissance obsolete est signalee avant reutilisation.

## Droits / accès

- Acteurs / roles concernes : mainteneur projet source, mainteneur projet consommateur, owner metier ou technique, lecteur non-tech.
- Permissions requises : lecture du hub pour chercher, droit de proposition pour publier, validation explicite pour exposer hors repo source.
- Donnees visibles / modifiables : les non-techs voient une representation publiee ; les agents manipulent le contrat versionne.
- Cas refuses : publication automatique, publication sans sensibilite, publication sans provenance, publication sans owner.
- Reponse attendue en cas d'acces interdit : l'agent doit signaler que la connaissance existe peut-etre mais n'est pas consultable avec les droits courants, sans inventer son contenu.

## Données

- Modele principal : fiche de connaissance partagee en Markdown avec frontmatter structure.
- Index : catalogue genere pour recherche locale, API ou MCP.
- Provenance : references vers projets sources, chemins, fiches locales et eventuellement commits.
- Confidentialite : classification minimale `public`, `internal`, `restricted` ou equivalent a definir.
- Compatibilite : les repos consommateurs ne doivent pas dependre d'un clone complet du hub pour fonctionner hors ligne ; ils peuvent degrader vers une reference non resolue.

## UX

- Les developpeurs restent dans le flux `aic` : chercher, lier, importer.
- Les non-techs accedent a une vue publiee, par exemple site interne, Notion, Drive ou portail dedie.
- La vue non-tech doit montrer le statut, l'owner, la fraicheur, les projets sources et les limites d'usage.
- Les commentaires non-techs doivent devenir des signaux traitables, pas des modifications implicites du contrat canonique.

## Observabilité

- Nombre de connaissances publiees avec metadonnees completes.
- Nombre de reutilisations inter-projets.
- Taux de connaissances obsoletes ou sans owner.
- Recherches sans resultat sur des sujets frequents.
- Liens de connaissances references dans des fiches locales.

## Déploiement / rollback

- Phase 1 : definir le contrat et produire un hub Markdown/Git minimal.
- Phase 2 : ajouter recherche et liaison depuis un repo consommateur.
- Phase 3 : publier une vue non-tech en lecture.
- Phase 4 : ajouter validation, commentaires et signaux de fraicheur.
- Rollback : les fiches locales conservent leurs references ; si le hub est indisponible, le projet doit rester livrable avec un warning de reference non resolue.

## Risques

- Centralisation excessive qui affaiblit les garanties locales de `ai_context`.
- Confusion entre fiche feature et fiche connaissance.
- Publication de connaissances sensibles.
- Confiance excessive dans une connaissance ancienne ou specifique a un contexte.
- Cout d'interface non-tech trop eleve si le MVP demarre par une application complete.

## Cross-refs

Aucune dependance technique stricte n'est declaree pour l'instant. Les livrables
techniques suivants doivent être cadrés séparément :

- `core/knowledge-source-contract` : schema, conventions de stockage, génération
  d'index, validation du frontmatter.
- `workflow/knowledge-publish-search-link` : commandes ou skills `publish`,
  `search`, `link`, `import`.
- `quality/knowledge-freshness-checks` : contrôles de fraîcheur, owner,
  sensibilité et références cassées.

Cette initiative est conceptuellement reliee a `product/ai-context-stability-migration`, mais elle poursuit un palier produit distinct : partager les connaissances entre projets et avec des lecteurs non-techs.

## Historique / décisions

- 2026-06-29 : cadrage initial apres constat que `ai_context` couvre presque tous les usages repo-locaux mais ne mutualise pas encore les connaissances entre projets.
- 2026-06-29 : decision de privilegier une federation de connaissances plutot qu'un hub qui remplace le contexte local.
- 2026-07-03 : décision MVP — `decision_state=commit`, backend Git/Markdown,
  contrat minimal obligatoire et passations vers futures features `core`,
  `workflow` et `quality`.
