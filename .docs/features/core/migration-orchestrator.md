---
id: migration-orchestrator
scope: core
title: Orchestrateur de migrations post-Copier
status: done
type: feature
description: "Une commande aic unique inventorie, prévalide et applique dans l'ordre les migrations project-owned après une mise à jour Copier."
depends_on:
  - core/aic-surface-canonical
  - core/okf-strict-profile
  - core/feature-mesh-progressive-indexes
  - core/template-engine
touches:
  - .ai/scripts/migrate-all.sh
  - template/.ai/scripts/migrate-all.sh.jinja
  - tests/unit/test-migration-orchestrator.sh
touches_shared:
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - copier.yml
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - MIGRATION.md
  - docs/upgrading.md
  - CHANGELOG.md
  - tests/smoke-test.sh
product: {}
external_refs: {}
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: done
  step: ""
  blockers: []
  resume_hint: "feature clôturée le 2026-07-17"
  updated: 2026-07-17
---

# Orchestrateur de migrations post-Copier

## Résumé

Après `copier update`, plusieurs migrations project-owned peuvent être nécessaires
mais restent aujourd'hui exposées comme commandes indépendantes. Cette feature
ajoute un cockpit unique qui inventorie les actions, exécute un préflight sans
écriture, applique les migrations automatisables dans un ordre stable et signale
séparément les étapes qui exigent une décision humaine.

## Objectif

Réduire le risque d'oublier une migration après une mise à jour du template, sans
donner à Copier le droit de réécrire silencieusement les fiches ou l'overlay du
projet destination. Un mainteneur doit pouvoir comprendre le plan complet avec une
commande, puis déclencher explicitement les seules écritures automatisables.

## Périmètre

### Inclus

- Une commande `aic migrate plan` strictement read-only.
- Une commande `aic migrate all`, read-only par défaut, et son mode `--apply`.
- Le préflight ordonné des migrations actives OKF `type` et index Markdown.
- Le blocage avant écriture sur conflit connu, notamment fichier `.rej` ou index
  Markdown manuel incompatible.
- Le signalement de l'état de `.copier-answers.yml` et de l'étape humaine
  `aic-onboard`.
- Les validations post-application et les conseils de rollback VCS.
- La parité entre runtime dogfood et template Copier.

### Hors périmètre

- Lancer `copier update` depuis `aic` ou arbitrer ses conflits à la place de
  l'utilisateur.
- Lancer automatiquement `aic-onboard`, qui conserve son contrat interactif et
  son approbation avant écriture.
- Inclure implicitement la migration historique des frontmatters dans le batch :
  elle reste accessible via `aic migrate` pour les projets réellement legacy.
- Garantir une transaction globale entre des migrateurs historiques qui écrivent
  plusieurs fichiers.
- Introduire un service central, une base de données ou un nouveau format de
  manifeste de migration dans cette première version.
- Rendre immédiatement obligatoires les index Markdown dans tous les projets.

### Granularité / nommage

`migration-orchestrator` couvre uniquement l'orchestration post-Copier. La logique
de chaque migration reste portée par sa feature d'origine et par son script dédié.

## Invariants

- Toute commande de migration reste dry-run par défaut ; seule l'option explicite
  `--apply` autorise les écritures automatisables.
- Le plan complet est exécuté avant la première écriture.
- Les commandes existantes `aic migrate`, `aic migrate okf-type` et
  `aic migrate okf-indexes` restent compatibles.
- L'overlay `.ai/project/**` n'est jamais modifié par l'orchestrateur.
- Le runtime et le miroir `.jinja` restent identiques hors syntaxe Jinja requise.
- Le script reste compatible Bash 3.2 et ne dépend pas de `yq` pour orchestrer.

## Décisions

- Utiliser un script séparé `migrate-all.sh` plutôt que d'ajouter la logique dans
  le dispatcher `aic.sh` déjà volumineux.
- Exécuter les migrations actives dans l'ordre : champ OKF `type`, puis index
  Markdown progressifs.
- Conserver `aic migrate` comme migration legacy opt-in hors batch : le dogfood
  prouve qu'elle ajouterait sinon `schema_version` aux 65 fiches canoniques alors
  que le template courant n'émet pas ce champ.
- Faire de `migrate all` un alias de preview complet tant que `--apply` n'est pas
  présent ; `migrate plan` rend l'intention read-only plus explicite.
- Prévalider tous les migrateurs avant `--apply` pour éviter les applications
  partielles causées par un conflit détectable à l'avance.
- Signaler `aic-onboard` comme action manuelle séparée, jamais comme quatrième
  migrateur automatique.
- Ne pas masquer les sorties détaillées des migrateurs : le cockpit ajoute un
  résumé, mais conserve les preuves produites par chaque script.

## Comportement attendu

Après une mise à jour Copier, le mainteneur lance :

```bash
bash .ai/scripts/aic.sh migrate plan
```

Il obtient l'état des prérequis, les migrations nécessaires, les éventuels
blocages, l'étape overlay et les commandes de validation. Aucun fichier n'est
modifié. Il peut relancer la même preview via `migrate all`, puis appliquer :

```bash
bash .ai/scripts/aic.sh migrate all --apply
```

Le mode apply refait le préflight, s'arrête avant écriture si un blocage est
détecté, applique les deux migrations actives dans l'ordre et lance les validations
post-application.

## Contrats

- `aic migrate plan` : preview complète, refuse `--apply`, exit `0` si le plan est
  exécutable et exit non nul si un blocage doit être résolu.
- `aic migrate all` : même preview sans écriture.
- `aic migrate all --apply` : préflight puis application ordonnée.
- Un argument inconnu est refusé avec usage et exit non nul.
- Un fichier `*.rej` hors `.git/` bloque le mode apply et est visible dans le plan.
- Une `.copier-answers.yml` absente produit une recommandation
  `repair-copier-metadata`, sans bloquer les migrations project-owned.
- Un overlay absent, config-only, legacy ou déjà stampé produit respectivement une
  suggestion `init`, un quasi no-op, `migrate` ou `sync`, sans aucune écriture sous
  `.ai/project/**`.
- Les erreurs et sorties des migrateurs sont propagées ; aucun échec n'est converti
  silencieusement en succès.

## Validation

- Preview sur un mesh legacy : les deux migrations actives sont détectées sans
  mutation et la migration historique reste signalée hors batch.
- `all` sans option : aucune mutation.
- `all --apply` : type et index générés dans l'ordre, puis second
  passage idempotent.
- `.rej` présent : blocage avant mutation.
- Index manuel en conflit : le préflight bloque avant que les migrations
  précédentes écrivent.
- Overlay absent, config-only, legacy et stampé : message adapté, aucune mutation.
- Argument inconnu ou `plan --apply` : refus explicite.
- Tests ciblés, dogfood drift, smoke Copier et quality gate verts.

## Droits / accès

Non requis : la commande agit uniquement dans le dépôt courant avec les droits du
processus local.

## Données

Non requis : les seules données modifiées sont les fichiers Markdown
project-owned déjà couverts par les migrateurs existants.

## UX

Non requis au sens interface graphique. La sortie CLI doit toutefois distinguer
clairement `prêt`, `à appliquer`, `bloqué` et `action humaine`.

## Observabilité

Non requise : sortie déterministe sur stdout/stderr, codes de retour et diff VCS
constituent les preuves d'exécution.

## Déploiement / rollback

- Livraison additive : les commandes historiques restent disponibles.
- Première version non cassante ; elle orchestre les migrations déjà livrées.
- Recommandation downstream : branche ou commit de migration dédié.
- Rollback Git : `git revert` du commit contenant les changements project-owned ;
  avec un autre VCS, utiliser l'opération de revert équivalente.
- Une panne imprévisible pendant apply peut laisser une application partielle ; le
  préflight réduit ce risque mais ne promet pas une transaction globale.

## Risques

- Parsing trop couplé au texte humain des migrateurs : les statuts doivent être
  couverts par tests et rester secondaires par rapport aux codes de retour.
- Faux sentiment de transaction globale : la sortie et la documentation doivent
  rester explicites sur la limite.
- Dérive runtime/template : couverte par dogfood drift.
- Ajout futur d'une migration oublié dans l'orchestrateur : l'ordre central doit
  être visible dans un seul tableau du script et dans les tests.

## Cross-refs

- `core/aic-surface-canonical` porte le dispatcher public `aic` et conserve la
  commande legacy `aic migrate` hors batch.
- `core/okf-strict-profile` porte le backfill `type`.
- `core/feature-mesh-progressive-indexes` porte les index Markdown project-owned.
- `core/template-engine` porte le cycle `copier update` et son message de sortie.

## Historique / décisions

- 2026-07-17 : proposition issue de la revue post-livraison des index progressifs ;
  priorité donnée à l'expérience d'upgrade plutôt qu'à un nouveau concept OKF.
- 2026-07-17 : cadrage high validé par l'utilisateur ; orchestration séparée de
  Copier et de `aic-onboard`, dry-run par défaut, préflight avant apply.
- 2026-07-17 : le premier plan dogfood a détecté 65 ajouts artificiels de
  `schema_version` via le migrateur historique. Décision : le garder opt-in via
  `aic migrate` et limiter `migrate all` aux migrations de version actives.
