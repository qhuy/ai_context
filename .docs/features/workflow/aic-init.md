---
id: aic-init
scope: workflow
title: Parcours guidé post-scaffold (aic init)
status: done
depends_on:
  - core/aic-surface-canonical
  - workflow/git-hooks
touches:
  - .ai/scripts/aic-init.sh
  - template/.ai/scripts/aic-init.sh.jinja
touches_shared:
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - tests/smoke-test.sh
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md
product: {}
external_refs: {}
doc:
  level: brief
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: done
  step: "aic init livré (doctor + hooks git + prochaine étape) ; runtime/template alignés, smoke-test étendu"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si le parcours post-scaffold doit gagner une étape supplémentaire"
  updated: 2026-07-24
type: feature
---

# Parcours guidé post-scaffold (aic init)

## Résumé

`aic init` est la première commande qu'un consommateur exécute juste après `copier copy`. Elle enchaîne un diagnostic non destructif (`doctor.sh`), l'activation idempotente des hooks git locaux, un état bref du feature mesh, et un pointeur clair vers la prochaine action (`aic frame` ou `aic-pilot`).

## Objectif

L'ancien `ai-context.sh first-run` a été retiré en v0.13 sans remplacement (dette relevée par l'audit fonctionnel général du 2026-07-23, item P12). Depuis, un scaffold frais ne propose aucun parcours guidé : l'utilisateur doit déjà connaître `doctor`, la config `core.hooksPath`, et la commande `frame` pour démarrer correctement. `aic init` comble ce trou avec une commande unique, sûre à relancer.

## Périmètre

### Inclus

- Commande `bash .ai/scripts/aic.sh init` (et `aic-init.sh` direct).
- Appel de `doctor.sh` en mode par défaut (informatif, jamais bloquant : cf. contrat exit-code documenté en tête de `doctor.sh`).
- Activation de `core.hooksPath=.githooks` si un provider `git` est détecté et que la config n'est pas déjà positionnée (idempotent, no-op si déjà fait).
- État bref du feature mesh (nombre de fiches déjà présentes, ou pointeur vers `FEATURE_TEMPLATE.md` si mesh vide).
- Message final condensé pointant vers `aic-frame` (tâche unique) et `aic-pilot` (backlog de constats).

### Hors périmètre

- Créer une fiche feature d'exemple non vide : `FEATURE_TEMPLATE.md` + le pointeur affiché par `aic init` suffisent ; une fiche d'exemple jetable ajouterait un artefact à nettoyer sans gain net.
- Réimplémenter ou dupliquer la logique de `doctor.sh` : `aic-init.sh` l'appelle telle quelle.
- Un mode interactif (prompts, choix multiples) : le scaffold Copier a déjà collecté les réponses ; `aic init` ne fait qu'diagnostiquer et orienter.

### Granularité / nommage

Cette fiche couvre uniquement la commande `init` et son script. Le diagnostic sous-jacent reste `core`/`doctor` (non dupliqué ici) ; l'activation git hooks détaillée reste `workflow/git-hooks`.

## Invariants

- `aic init` est idempotent : relancer plusieurs fois ne doit produire aucun effet de bord supplémentaire après le premier passage.
- `aic init` ne doit jamais échouer à cause de `doctor.sh` : ce dernier est appelé sans `--strict`, dont le contrat garantit un exit 0 hors blocage explicite.
- Aucune écriture hors `core.hooksPath` (pas de génération de fichiers, pas de mutation du mesh).

## Décisions

- `doctor.sh` est appelé en mode informatif (pas `--strict`) pour que `aic init` reste toujours un point d'entrée non bloquant, y compris sur un scaffold partiellement configuré.
- La fiche d'exemple non vide envisagée dans le cadrage initial de P12 est explicitement écartée (cf. Hors périmètre) : `FEATURE_TEMPLATE.md` déjà existant + pointeur affiché suffisent ; ajouter un artefact d'exemple créerait un fichier de plus à maintenir en cohérence avec le schema au fil du temps sans bénéfice proportionnel.
- Route unique `init` dans `aic.sh` (pas d'alias), cohérent avec la convention `core/aic-surface-canonical`.

## Comportement attendu

```
bash .ai/scripts/aic.sh init
```
affiche successivement : diagnostic `doctor.sh`, statut hooks git (déjà configuré ou nouvellement activé), compte de fiches du mesh (ou pointeur vers le template si vide), et un bloc texte fixe pointant vers `aic frame` / `aic-pilot` / `aic document-feature` / `aic status`.

## Contrats

- `init` : aucune entrée requise, aucun flag.
- Sortie : texte humain uniquement (pas de JSON, pas de machine-parsing attendu).
- Exit code : hérite de `doctor.sh` en mode informatif (0 sauf échec système type `jq`/`copier` absent), jamais un `--strict`.

## Validation

- `bash .ai/scripts/aic.sh init` sur le dogfood repo : sortie propre, hooks déjà configurés détectés correctement.
- `bash .ai/scripts/check-features.sh --no-write`
- `bash .ai/scripts/check-dogfood-drift.sh`
- `bash tests/smoke-test.sh` (assertion `aic init` ajoutée)

## Droits / accès

Non requis : commande locale, pas d'authentification.

## Données

Non requis : aucune donnée applicative, seule la config git locale (`core.hooksPath`) est lue/écrite.

## UX

Non requis formellement, mais l'UX CLI est le sujet même de la fiche : sortie lisible, sections numérotées, pointeur d'action unique en fin de commande.

## Observabilité

Non requis : sortie stdout humaine suffisante ; pas de logs structurés.

## Déploiement / rollback

Déploiement par `copier update` côté consommateurs (nouveau fichier `aic-init.sh` + route `init` dans `aic.sh`). Rollback par suppression du fichier et de la ligne de dispatch, sans effet sur l'existant (commande additive, aucune route retirée).

## Risques

- Confusion possible avec `doctor` seul si l'utilisateur ne comprend pas la valeur ajoutée : mitigé par les sections numérotées et le message final distinct.
- Activation git hooks silencieuse si l'utilisateur ne voulait pas de hooks globaux au niveau système (elle ne touche que ce repo, `core.hooksPath` est local).

## Cross-refs

- `core/aic-surface-canonical` : `init` rejoint la surface `aic-*` canonique.
- `workflow/git-hooks` : réutilise la logique d'activation `core.hooksPath` sans la dupliquer.
- `workflow/aic-pilot` : pilotage P12 de l'audit fonctionnel général du 2026-07-23.

## Historique / décisions

- 2026-07-24 : création + implémentation. `aic init` livré (runtime + template), route ajoutée à `aic.sh`, smoke-test étendu. Fiche d'exemple non vide explicitement écartée du périmètre (cf. Décisions).
