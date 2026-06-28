---
id: project-overlay-scope-registry
scope: core
title: Overlay projet comme registre de scopes
status: active
depends_on:
  - core/project-overlay-stable
touches:
  - ".ai/index.md"
  - "template/.ai/index.md.jinja"
  - ".ai/OWNERSHIP.md"
  - "template/.ai/OWNERSHIP.md.jinja"
  - ".ai/templates/project-overlay/README.md"
  - "template/.ai/templates/project-overlay/README.md.jinja"
  - "tests/unit/test-project-overlay.sh"
touches_shared:
  - ".ai/scripts/check-dogfood-drift.sh"
  - ".ai/scripts/check-ai-references.sh"
  - "docs/upgrading.md"
  - ".docs/frames/2026-06-19-project-overlay-scope-registry.md"
product:
  initiative: product/ai-context-stability-migration
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: false
    observability: false
progress:
  phase: done
  step: "contrat livré, tests verts, quality gate passée"
  blockers: []
  resume_hint: "DONE. Prochain : workflow/project-overlay-onboarding (skill aic-onboard). HANDOFF core → workflow à ouvrir."
  updated: 2026-06-19
---

# Overlay projet comme registre de scopes

> Cadrage source : [.docs/frames/2026-06-19-project-overlay-scope-registry.md](../../frames/2026-06-19-project-overlay-scope-registry.md)

## Résumé

Faire de l'overlay projet `.ai/project/**` un **registre de scopes** structuré et versionné : chaque scope du projet consommateur (app, couche, préoccupation — `bo-front`, `bo-back`, `sql`, `infra`…) possède son propre dossier `.ai/project/<scope>/` et un `index.md` privé jouant le rôle de routeur + manifeste. Cette feature livre **le contrat de forme**, pas l'outil qui le remplit.

## Objectif

Donner un foyer durable, project-owned et divergence-safe aux spécificités de chaque scope d'un projet consommateur, là où elles survivent à `copier update`. Aujourd'hui `.ai/project/**` existe et est stable ([core/project-overlay-stable](project-overlay-stable.md)) mais n'a aucune forme interne définie : impossible de router, valider ou maintenir de manière déterministe. Cette feature pose le contrat qui rend possible un outillage (skill `aic-onboard`, feature `workflow/project-overlay-onboarding`) et une migration sûre.

## Périmètre

### Inclus

- **Contrat de forme** de `.ai/project/<scope>/index.md` : front-matter (`scope`, `paths`, `meta`) + sections fixes (`conventions` durables, `derived` pointeurs volatils).
- **`overlay_contract_version`** : stamp de version du contrat, vivant **une seule fois** dans le front-matter de `.ai/project/index.md` (racine) — versionne l'overlay entier, pas chaque scope ; socle d'idempotence des migrations futures.
- **Extension du contrat de chargement** : `.ai/project/index.md` route `path → scope` ; `.ai/project/<scope>/index.md` route `path → feuille`. Descente **d'un niveau, bornée, par pointeur explicite** — pas une récursion aveugle.
- **Tolérance des checks vérifiée** : `check-dogfood-drift.sh` (le motif `case` `project/*` matche déjà la profondeur) et `check-ai-references.sh` acceptent `.ai/project/<scope>/**` sans la signaler — couvert par test, **aucune modification de script nécessaire**.
- **Doc d'exemple** : `.ai/templates/project-overlay/README.md` illustre la forme `<scope>/index.md`.

### Hors périmètre

- La détection des scopes, l'interview et le scaffolding → skill `aic-onboard` (feature `workflow/project-overlay-onboarding`).
- La procédure `migrate` et son mode opératoire → documentés dans `product/ai-context-stability-migration` (`docs/upgrading.md`).
- La génération de contenu métier des conventions (le contrat définit la forme, pas le fond).
- Tout changement des meta-scopes du template (`core/quality/workflow/product`) ou de `.ai/rules/**`.

### Granularité / nommage

- Fiche = un livrable cohérent (le contrat overlay), pas un domaine extensible. Le skill est une fiche distincte car flux, validation et risques diffèrent.

## Invariants

- `.ai/project/**` reste **project-owned** ; aucun fichier upstream-managed n'est écrit par l'usage de l'overlay.
- Un repo **sans** overlay garde le comportement actuel (zéro régression).
- Le contrat est **forward-tolérant** : un overlay à l'ancienne forme (plat) ou absent reste chargeable ; la nouvelle forme est additive.
- **Durable vs volatile** strictement séparés : l'état volatile (ex. sprint courant) n'est jamais figé en prose, il est dérivé ou porté par `.ai/project/config.yml`.
- Le chargement reste **lean** : la descente dans un scope est on-demand (match de path), jamais un préchargement récursif.

## Décisions

- **Un dossier + un `index.md` privé par scope** (pattern fractal du système), plutôt qu'un fichier plat par scope : structure machine-maintenue, évolution zéro-migration. Le lean punit le *load*, pas l'*existence* sur disque.
- **`.ai/project/<scope>/` = pendant project-owned de `.ai/rules/<scope>.md`** (upstream-managed, intouchable sans drift).
- Le `index.md` de scope doit être **routeur + manifeste**, jamais une redirection vide → justifie un contrat de forme (discipline `feature.schema.json`).
- **Nouvelle feature** plutôt qu'extension de `core/project-overlay-stable` : celle-ci a livré « overlay stable et optionnel » et exclut explicitement migration et obligation d'index ; le registre structuré est un livrable distinct, en dépendance.

## Comportement attendu

Quand un overlay conforme existe, un agent qui touche un path donné est routé : `.ai/index.md` → `.ai/project/index.md` (résout le scope) → `.ai/project/<scope>/index.md` (résout les feuilles utiles : conventions durables, pointeurs dérivés, méta) → feuilles chargées à la demande. En l'absence d'overlay ou face à une forme ancienne, le comportement actuel est préservé sans erreur.

## Contrats

- **Entrée** : `.ai/project/index.md` (route `path → scope`), inchangée comme point d'entrée unique.
- **Nouveau** : `.ai/project/<scope>/index.md` — front-matter `scope`, `paths`, `meta` ; sections `conventions`, `derived`. Pas de `overlay_contract_version` ici (global, racine).
- **Stamp global** : `overlay_contract_version` dans le front-matter de `.ai/project/index.md`.
- **Schéma** : contrat **documentaire** (prose dans `.ai/templates/project-overlay/README.md`), décision tranchée en `aic-dev-plan`. Pas de JSON Schema exécutable v1 ; il s'ajoutera si le skill `aic-onboard` doit valider sa sortie.
- **Ownership** inchangé : tout `.ai/project/**` est projet ; `.ai/index.md`, `.ai/rules/**`, `.ai/schema/**`, `.ai/templates/**` restent template.
- **Compatibilité** : forward-tolérant (ancien overlay et absence d'overlay restent valides) ; agent-agnostique (Claude/Codex consomment le même markdown routé).

## Validation

- `check-dogfood-drift.sh` reste vert avec une arborescence `.ai/project/<scope>/**` présente.
- `check-ai-references.sh` accepte les liens vers `.ai/project/<scope>/**`.
- Un overlay conforme valide contre `.ai/schema/overlay-scope.schema.json` (si schéma exécutable retenu).
- Un repo sans overlay et un overlay plat existant : aucun échec de chargement, aucun bruit de check.
- Quality gate + smoke-test verts.
- Preuve attendue : démonstration sur ce repo (état overlay config-only) que la présence du contrat ne déclenche ni drift ni régression.

## Risques

- **Étend un invariant de [core/project-overlay-stable](project-overlay-stable.md)** (« pas de chargement récursif de `.ai/project/**` »). Mitigation : descente bornée d'un niveau par pointeur explicite, documentée dans le contrat de chargement ; HANDOFF cross-scope tracé.
- Surface template + dogfood (drift) : un contrat mal borné peut faire diverger le rendu Copier du repo source. Mitigation : checks adaptés et testés avant DONE.
- Sur-spécification du contrat : un format trop riche redeviendrait un catalogue. Mitigation : sections minimales, le fond reste à la charge du projet.
- Décision ouverte : schéma exécutable vs documentaire (impacte les checks et l'effort).

## Cross-refs

- **`depends_on: core/project-overlay-stable`** — fournit l'overlay project-owned, le `_skip_if_exists` Copier et l'exclusion de drift sur lesquels ce registre s'appuie. Cette feature **étend** son contrat de chargement (descente d'un niveau).
- **`product.initiative: product/ai-context-stability-migration`** — le registre et sa migration servent l'initiative de stabilisation ; la procédure `migrate` se documentera dans `docs/upgrading.md` (possédé par cette initiative).
- **Aval** : `workflow/project-overlay-onboarding` (skill `aic-onboard`) consommera ce contrat pour `init` / `sync` / `migrate`.

## Historique / décisions

- 2026-06-19 — Feature créée à partir du cadrage `aic-frame` ([frame](../../frames/2026-06-19-project-overlay-scope-registry.md)), après 4 tours de design convergés et HANDOFF `workflow → core` confirmé par l'utilisateur. Découpage retenu : contrat core (cette fiche) → skill workflow → rattachement doc produit.
- 2026-06-19 — Implémentation du contrat : `aic-dev-plan` lancé, arbitrages tranchés (schéma documentaire, matching prose agent-driven). Contrat de forme livré dans `.ai/templates/project-overlay/README.md(.jinja)`, contrat de chargement étendu dans `.ai/index.md(.jinja)` et `.ai/OWNERSHIP.md(.jinja)`, `check-dogfood-drift.sh` adapté pour `project/*/*` et `project/*/*/*`. Checks verts : dogfood-drift, ai-references, check-shims, check-features, smoke-test.
