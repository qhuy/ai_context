---
id: knowledge-source-contract
scope: core
title: Contrat knowledge source
status: done
type: contract
description: "Contrat core pour valider des fiches de connaissance partagee Git/Markdown et generer un index deterministic."
depends_on:
  - core/template-engine
touches:
  - .docs/features/core/knowledge-source-contract.md
  - .docs/features/core/knowledge-source-contract.worklog.md
  - .ai/schema/knowledge.schema.json
  - template/.ai/schema/knowledge.schema.json
  - .ai/scripts/_knowledge.sh
  - template/.ai/scripts/_knowledge.sh.jinja
  - .ai/scripts/check-knowledge.sh
  - template/.ai/scripts/check-knowledge.sh.jinja
  - .ai/scripts/build-knowledge-index.sh
  - template/.ai/scripts/build-knowledge-index.sh.jinja
  - tests/unit/test-knowledge-source-contract.sh
touches_shared: []
product:
  initiative: product/knowledge-federation
  contribution: "Transforme la decision produit du hub Git/Markdown en schema maintenu, validation locale et index derive."
  evidence: "test-knowledge-source-contract PASS, check-knowledge hub vide PASS, build index vide PASS, check-dogfood-drift PASS."
external_refs: {}
doc:
  level: full
  requires:
    auth: false
    data: true
    ux: false
    api_contract: true
    rollout: true
    observability: true
progress:
  phase: done
  step: "schema, validation frontmatter, index knowledge et miroir template livres"
  blockers: []
  resume_hint: "aucune action core immediate ; prochain scope attendu : workflow/knowledge-publish-search-link pour publish/search/link/import"
  updated: 2026-07-03
---

# Contrat knowledge source

## Résumé

Cette feature transforme la decision produit `product/knowledge-federation` en
contrat core executable : un hub Git/Markdown contient des fiches de connaissance
partagee sous `knowledge/<source_project>/<id>.md`, un check valide leur
frontmatter minimal et un builder genere un `index.json` derive pour la recherche
ou les futurs flux workflow.

## Objectif

Donner un socle stable avant les commandes `publish/search/link/import` : le
workflow pourra manipuler des connaissances partagees sans inventer son propre
format, et sans demarrer par une API centrale, une base de donnees ou une app web.

## Périmètre

### Inclus

- Schema JSON du frontmatter knowledge.
- Convention de stockage `knowledge/<source_project>/<id>.md`.
- Validation locale des champs obligatoires, enums et coherence path/frontmatter.
- Generation d'un index JSON deterministic depuis les fiches valides.
- Miroir runtime/template pour le scaffolding Copier.
- Test unitaire couvrant cas valide, index et cas invalides.

### Hors périmètre

- Commandes utilisateur `aic knowledge publish/search/link/import`.
- Publication non-tech, UI, API, MCP ou stockage base de donnees.
- Gestion avancee des droits entreprise.
- Verification de fraicheur semantique ou dereferencement de tous les `source_refs`.

### Granularité / nommage

Cette fiche couvre le contrat core et les checks bas niveau. Le flux agent reste
dans `workflow/knowledge-publish-search-link` et ne doit pas etre melange ici.

## Invariants

- Le Markdown avec frontmatter reste la source canonique ; `index.json` est derive.
- Une fiche publiee doit exposer provenance, owner, confiance, fraicheur,
  sensibilite et perimetre d'usage.
- Le path et le frontmatter doivent se recouper : parent = `source_project`,
  nom de fichier = `id`.
- Le build d'index ne doit pas reordonner aleatoirement les entrees.
- Le contrat doit fonctionner dans le repo source et dans un projet rendu par Copier.

## Décisions

- Utiliser Bash + `jq`, comme les autres scripts core, sans validateur JSON Schema
  externe obligatoire.
- Garder `knowledge.schema.json` comme reference formelle, et appliquer les regles
  bloquantes dans `check-knowledge.sh`.
- Scanner un hub racine qui contient `knowledge/` et ecrire `index.json` a la racine
  du hub en mode `--write`.
- Traiter l'absence de dossier `knowledge/` comme un hub vide valide.

## Comportement attendu

Un mainteneur ou un futur workflow fournit un chemin de hub. Le check liste les
fiches de connaissance, refuse celles dont le frontmatter est incomplet ou
incoherent avec le path, et sort non-zero en cas d'erreur. Le builder produit sur
stdout un JSON stable ; avec `--write`, il ecrit l'index derive sans modifier une
copie deja equivalente hors `generated_at`.

## Contrats

Fichier knowledge canonique :

```text
knowledge/legacy-erp/legacy-billing-invoice-rules.md
```

Frontmatter minimal :

```yaml
---
id: legacy-billing-invoice-rules
type: domain_knowledge
title: "Regles de facturation legacy"
summary: "Regles de generation des factures dans le legacy ERP."
source_project: legacy-erp
owner: finance
confidence: high
freshness:
  checked_at: 2026-06-29
sensitivity: internal
source_refs:
  - legacy-erp:/src/billing/InvoiceService.cs
usable_by:
  - migration-project
status: published
---
```

Enums MVP :

- `confidence`: `low`, `medium`, `high`.
- `sensitivity`: `public`, `internal`, `restricted`.
- `status`: `draft`, `published`, `deprecated`, `retracted`.

Sortie index :

```json
{
  "schema_version": "1",
  "generated_at": "2026-07-03T00:00:00Z",
  "knowledge": []
}
```

## Validation

- `check-knowledge.sh` passe sur un hub vide et sur une fiche valide.
- `check-knowledge.sh` echoue sur champ obligatoire manquant, enum invalide ou
  incoherence path/frontmatter.
- `build-knowledge-index.sh` produit un JSON valide et stable hors `generated_at`.
- Le miroir template est aligne par `check-dogfood-drift`.

## Droits / accès

- Aucun droit runtime n'est applique par ce contrat core.
- `sensitivity` et `usable_by` sont des metadonnees obligatoires que les futurs
  workflows devront respecter avant publication ou import.
- Un hub absent ou vide reste autorise ; il signifie simplement qu'aucune
  connaissance partagee n'est disponible localement.

## Données

- Entree : fichiers Markdown sous `knowledge/<source_project>/<id>.md`.
- Donnees derivees : `index.json`, reconstruit depuis les frontmatters.
- Confidentialite : la classification `sensitivity` est obligatoire mais ne remplace
  pas une politique d'acces ; les workflows devront respecter ce champ avant publish.
- Compatibilite : un consommateur peut ignorer l'index et relire les Markdown.

## UX

- Pas d'interface utilisateur dans cette feature core.
- Les scripts exposent une sortie CLI courte : check avec PASS/FAIL et build sur
  stdout ou `index.json`.
- Les messages d'erreur nomment le fichier et le champ fautif pour rendre le fix
  actionnable par un agent ou un mainteneur.

## Observabilité

- Les scripts affichent le nombre de fiches scannees et les erreurs par fichier.
- Les erreurs de contrat sont deterministes et nomment le path fautif.
- Aucun log de contenu sensible n'est requis : les messages se limitent aux champs
  manquants, enums et incoherences de path.

## Déploiement / rollback

- Deploiement : runtime source + template Copier dans le meme commit.
- Rollback : retirer les scripts/schema et revenir aux fiches Markdown non validees ;
  aucun format existant n'est migre automatiquement.
- Compatibilite : l'absence de `knowledge/` reste valide pour les projets sans hub.

## Risques

- Parser YAML maison trop ambitieux : le MVP accepte un frontmatter simple et documente.
- Survalidation prematuree : les champs metier extensibles restent libres hors enums
  strictement necessaires.
- Confusion avec le futur workflow : cette feature ne publie rien automatiquement.

## Cross-refs

- `product/knowledge-federation` decide le MVP Git/Markdown et delegue ce contrat core.
- `core/template-engine` porte le miroir `template/` attendu par Copier.

## Historique / décisions

- 2026-07-03 : creation depuis le HANDOFF `product -> core` de
  `product/knowledge-federation`.
- 2026-07-03 : contrat livre — schema `knowledge.schema.json`, helpers
  `_knowledge.sh`, validation `check-knowledge.sh`, index
  `build-knowledge-index.sh`, miroir template et test unitaire cible.
