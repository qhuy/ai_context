---
id: knowledge-publish-search-link
scope: workflow
title: Flux knowledge publish/search/link/import
status: done
type: workflow
description: "Commandes workflow pour publier, chercher, lier et importer des connaissances partagees depuis un hub Git/Markdown."
depends_on:
  - core/knowledge-source-contract
touches:
  - .docs/features/workflow/knowledge-publish-search-link.md
  - .docs/features/workflow/knowledge-publish-search-link.worklog.md
  - .ai/scripts/knowledge.sh
  - template/.ai/scripts/knowledge.sh.jinja
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - tests/unit/test-knowledge-workflow.sh
touches_shared: []
product:
  initiative: product/knowledge-federation
  contribution: "Expose le MVP Git/Markdown au flux utilisateur aic : publish explicite, search, link et import sans backend central."
  evidence: "test-knowledge-workflow PASS, dogfood drift PASS, freshness worktree strict PASS."
external_refs: {}
doc:
  level: full
  requires:
    auth: false
    data: true
    ux: true
    api_contract: true
    rollout: true
    observability: true
progress:
  phase: done
  step: "commandes aic knowledge publish/search/link/import/freshness livrees"
  blockers: []
  resume_hint: "aucune action workflow immediate ; prochaine suite possible : quality/knowledge-freshness-checks ou vue non-tech dediee"
  updated: 2026-07-03
---

# Flux knowledge publish/search/link/import

## Résumé

Cette feature ajoute la surface workflow `aic knowledge` au-dessus du contrat core
`knowledge-source-contract`. Elle permet a un agent ou mainteneur de publier
explicitement une fiche knowledge dans un hub Git/Markdown, de chercher une
connaissance, de produire un lien `external_refs.knowledge` et d'importer une
synthese locale sans masquer la provenance.

## Objectif

Rendre le MVP `product/knowledge-federation` utilisable sans backend central :
un projet source peut proposer une connaissance versionnee, et un projet
consommateur peut la retrouver puis la citer dans son contexte local.

## Périmètre

### Inclus

- Commande `bash .ai/scripts/aic.sh knowledge ...`.
- Sous-commandes `publish`, `search`, `link`, `import`, `freshness`.
- Publication explicite via `publish --apply` uniquement.
- Recherche locale depuis l'index derive ou les frontmatters du hub.
- Sorties texte et JSON pour les usages agentiques.
- Miroir runtime/template et test unitaire cible.

### Hors périmètre

- UI non-tech, portail, API, MCP ou synchronisation distante.
- Edition automatique d'une fiche feature locale par `link`.
- Validation de droits entreprise au-delà des metadonnees `sensitivity` et
  `usable_by`.
- Verification semantique de la fraicheur des connaissances.

### Granularité / nommage

Cette fiche couvre le flux CLI workflow. Le schema et l'index restent dans
`core/knowledge-source-contract`; les controles de fraicheur avances relevent
d'une future feature `quality/knowledge-freshness-checks`.

## Invariants

- Publication humaine explicite : pas de creation de fiche knowledge sans
  `publish --apply`.
- Le hub Git/Markdown reste canonique ; les commandes workflow ne creent pas de
  backend alternatif.
- `link` et `import` ne doivent pas cacher la provenance `knowledge://...`.
- Une connaissance `restricted` reste visible seulement selon les droits du hub ;
  la CLI ne doit pas inventer ou declasser son contenu.
- Le repo local reste livrable si le hub est absent.

## Décisions

- Ajouter un script dedie `knowledge.sh` plutot que grossir `aic.sh`; `aic.sh`
  route seulement la commande.
- `publish` fonctionne en dry-run par defaut et exige `--apply` pour ecrire.
- `link` produit un snippet `external_refs.knowledge` au lieu de modifier une
  fiche feature automatiquement dans ce MVP.
- `import` produit une synthese Markdown avec provenance, source refs et limites
  d'usage ; il n'ecrit pas dans le repo consommateur.

## Comportement attendu

Un mainteneur lance `aic knowledge publish ...` pour previsualiser une fiche.
Avec `--apply`, la fiche est ecrite dans `knowledge/SOURCE_PROJECT/KNOWLEDGE_ID.md`,
le hub est valide par `check-knowledge.sh` et `index.json` est regenere.
Un consommateur lance `search`, puis `link` pour obtenir le snippet a coller dans
une fiche locale, ou `import` pour obtenir une synthese citee.

## Contrats

Commande publique :

```text
bash .ai/scripts/aic.sh knowledge COMMAND [options]
```

Hub par defaut :

- `--hub PATH` si fourni.
- Sinon `AI_CONTEXT_KNOWLEDGE_HUB`.
- Sinon le repo courant.

Reference knowledge acceptee :

- `knowledge://SOURCE_PROJECT/KNOWLEDGE_ID`
- `SOURCE_PROJECT/KNOWLEDGE_ID`
- `KNOWLEDGE_ID` si non ambigu dans le hub.

## Validation

- `publish` dry-run ne modifie pas le hub.
- `publish --apply` cree une fiche valide et regenere `index.json`.
- `search` retrouve une connaissance par texte.
- `link` produit un snippet `external_refs.knowledge` avec URI canonique.
- `import` conserve titre, summary, provenance, source refs et limites d'usage.
- `freshness` liste les dates de verification.
- `aic.sh knowledge` route vers `knowledge.sh`.

## Droits / accès

- La CLI ne gere pas l'authentification ; elle lit/ecrit seulement dans le hub
  local accessible au processus.
- Les champs `sensitivity` et `usable_by` sont affiches dans `import` pour que le
  consommateur decide s'il peut reutiliser la connaissance.
- Une publication `restricted` n'est pas bloquee par la CLI si l'humain choisit
  explicitement `--apply`, mais elle reste tracee dans le frontmatter.

## Données

- Entree publish : options CLI transformees en fiche Markdown knowledge.
- Entree search/link/import/freshness : `index.json` derive ou frontmatters si
  l'index n'est pas encore present.
- Sortie publish : fiche Markdown + `index.json` en mode `--apply`.
- Sortie link/import : texte ou JSON, sans mutation du repo consommateur.

## UX

- Les commandes sont decouvrables via `aic.sh --help`.
- Les erreurs nomment le champ manquant, l'option invalide ou la reference
  ambiguë.
- Les commandes lecture privilegient une sortie courte et copiables dans une
  fiche feature.
- Le dry-run de `publish` montre le path et le contenu qui seraient ecrits.

## Observabilité

- `publish --apply` affiche le fichier cree et laisse `check-knowledge.sh` /
  `build-knowledge-index.sh` produire leurs sorties.
- `search` indique quand aucun resultat n'est trouve.
- `freshness` expose `status`, `checked_at`, `owner`, `confidence` et
  `sensitivity`.

## Déploiement / rollback

- Deploiement : script runtime + template + routage `aic.sh`.
- Rollback : supprimer la commande workflow ; les fiches knowledge deja ecrites
  restent lisibles par le contrat core.
- Compatibilite : projets sans hub `knowledge/` continuent a fonctionner.

## Risques

- Surpromesse de `link` si l'utilisateur attend une edition automatique ; le MVP
  documente que `link` produit un snippet.
- Publication de contenu sensible si l'humain choisit `--apply` sans relire la
  sensibilite ; le champ est obligatoire et visible.
- Recherche simple par texte non classee ; suffisante pour MVP local.

## Cross-refs

- `core/knowledge-source-contract` fournit schema, validation et index.
- `product/knowledge-federation` porte l'initiative produit.

## Historique / décisions

- 2026-07-03 : creation depuis le HANDOFF `product -> workflow` de
  `product/knowledge-federation`, apres livraison du contrat core.
- 2026-07-03 : livraison — `knowledge.sh`, routage `aic.sh knowledge`, miroir
  template et test unitaire cible. Cross-scope core trace dans les worklogs
  `core/aic-surface-canonical` et `core/vcs-provider-abstraction` pour le routage
  public `aic.sh`.
