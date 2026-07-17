---
id: feature-mesh-progressive-indexes
scope: core
title: Index Markdown progressifs du feature mesh
status: done
type: feature
description: "Générer des index Markdown racine et par scope pour naviguer progressivement dans le feature mesh sans remplacer son index JSON."
depends_on:
  - core/okf-strict-profile
  - core/feature-index-cache
  - core/index-contract-v2
  - core/template-engine
touches:
  - .ai/scripts/migrate-features.sh
  - template/.ai/scripts/migrate-features.sh.jinja
  - .ai/scripts/migrate-okf-indexes.sh
  - template/.ai/scripts/migrate-okf-indexes.sh.jinja
  - .ai/scripts/check-feature-indexes.sh
  - template/.ai/scripts/check-feature-indexes.sh.jinja
  - tests/unit/test-feature-markdown-indexes.sh
touches_shared:
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
  - .ai/scripts/check-features.sh
  - template/.ai/scripts/check-features.sh.jinja
  - .ai/scripts/check-feature-docs.sh
  - template/.ai/scripts/check-feature-docs.sh.jinja
  - .ai/scripts/migrate-okf-type.sh
  - template/.ai/scripts/migrate-okf-type.sh.jinja
  - .ai/scripts/features-for-path.sh
  - template/.ai/scripts/features-for-path.sh.jinja
  - .ai/scripts/pre-turn-reminder.sh
  - template/.ai/scripts/pre-turn-reminder.sh.jinja
  - .ai/scripts/auto-worklog-log.sh
  - template/.ai/scripts/auto-worklog-log.sh.jinja
  - .ai/scripts/fiche-consolidation-nudge.sh
  - template/.ai/scripts/fiche-consolidation-nudge.sh.jinja
  - .ai/scripts/check-commit-features.sh
  - template/.ai/scripts/check-commit-features.sh.jinja
  - copier.yml
  - tests/**
  - MIGRATION.md
  - docs/upgrading.md
  - CHANGELOG.md
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
  - .docs/features/index.md
  - .docs/features/*/index.md
product: {}
external_refs:
  okf_spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
  okf_overview: https://medium.com/@tahirbalarabe2/what-is-open-knowledge-format-okf-270b20791802
doc:
  level: full
  requires:
    auth: false
    data: true
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: done
  step: "résidus du re-audit Claude remédiés et quality gate vert"
  blockers: []
  resume_hint: "feature clôturée le 2026-07-17 après re-audit ; rouvrir seulement pour l'enforcement vN+1"
  updated: 2026-07-17
---

# Index Markdown progressifs du feature mesh

## Résumé

Ajouter une navigation Markdown progressive au feature mesh : un `index.md` à la racine des features route vers des index par scope, puis chaque index de scope route vers les fiches canoniques. Ces fichiers sont générés, déterministes et versionnés pour être lisibles directement par GitHub et les agents, sans remplacer le cache machine `.ai/.feature-index.json`. Les projets consommateurs reçoivent le comportement via Copier selon une migration explicite et non cassante.

## Objectif

Permettre à un humain ou un agent de découvrir le feature mesh sans charger ni parcourir toutes les fiches. L'organisation reprend le principe OKF d'index récursifs et de liens relatifs, tout en conservant les contrats locaux de gouvernance, de validation et de reprise.

Le résultat attendu est une navigation à coût progressif : racine du mesh, choix d'un scope, puis ouverture d'une fiche précise.

## Périmètre

### Inclus

- Réserver et classifier centralement `index.md`, `log.md` et `*.worklog.md` afin qu'aucun scanner ne les traite comme des fiches feature.
- Générer `<docs_root>/features/index.md` et `<docs_root>/features/<scope>/index.md` à partir des fiches canoniques.
- Produire des liens Markdown relatifs, un ordre stable et un contenu sans timestamp.
- Versionner les index Markdown générés ; `.ai/.feature-index.json` reste le cache machine dérivé.
- Exposer `aic migrate okf-indexes` en dry-run par défaut et `--apply` explicite.
- Détecter les index absents ou périmés, en warning à l'introduction puis en échec dans une version ultérieure.
- Livrer le runtime, son miroir `template/**`, le message `_message_after_update`, la documentation de migration et les tests Copier.

### Hors périmètre

- Remplacer `.ai/.feature-index.json` ou changer son `schema_version`.
- Générer ou standardiser un `log.md` ; le nom est seulement réservé pour éviter une collision future.
- Ajouter `type: worklog` aux journaux existants.
- Construire un visualiseur de graphe, un catalogue externe ou un consommateur OKF dédié.
- Autoriser du contenu éditorial manuel dans les index générés.
- Migrer nativement toutes les fiches vers un format OKF plus permissif.

### Granularité / nommage

Cette fiche porte un livrable unique : la navigation Markdown progressive et son contrat de génération/migration. Un futur visualiseur, un changement de format des worklogs ou un consommateur OKF constituent des features distinctes, avec leurs propres DONE et validations.

## Invariants

- Les fiches `.docs/features/<scope>/<id>.md` restent la source canonique de connaissance.
- L'index JSON reste la surface machine ; les index Markdown sont une projection de navigation humaine et agentique.
- `copier update` ne modifie jamais automatiquement les fiches ou index appartenant au projet consommateur.
- Toute écriture project-owned exige `--apply` ; le dry-run est le comportement par défaut.
- Un `index.md` existant sans marqueur de génération n'est jamais écrasé.
- Deux générations successives sur un mesh inchangé produisent zéro diff.
- Les chemins utilisent `docs_root` et les liens restent relatifs au bundle.
- Le runtime dogfoodé et `template/**` restent synchronisés.
- Aucun durcissement `warn -> fail` n'a lieu dans la même version que l'introduction.

## Décisions

- Les index Markdown sont générés et commités afin d'être consultables sans exécuter le runtime.
- Le contenu généré porte un marqueur explicite interdisant l'édition manuelle et permettant de distinguer un fichier géré d'un fichier utilisateur.
- La classification des documents réservés est centralisée dans `_lib.sh`, puis consommée par tous les scanners et migrateurs concernés.
- L'index racine existe même si le mesh est vide et affiche un état vide déterministe ; seuls les scopes non vides obtiennent un index de scope et un lien depuis la racine.
- Un index de scope liste au minimum le titre lié à la fiche, l'identifiant, le statut et le type. Les relations détaillées restent dans la fiche et l'index JSON.
- La migration suit deux versions : vN introduit la génération et avertit ; vN+1 impose la présence et la fraîcheur.
- Copier livre l'outillage et le message de migration, mais aucune `_task` ne lance `--apply` silencieusement.

## Comportement attendu

### Nouveau projet

Après le scaffold et la création de ses premières fiches, le mainteneur lance la commande d'écriture. Le générateur crée l'index racine et un index pour chaque scope non vide. Une seconde exécution n'apporte aucun changement.

### Projet existant mis à jour par Copier

1. `copier update` apporte les classificateurs, générateurs, checks et commandes sans toucher à `<docs_root>/features/**`.
2. `_message_after_update` recommande d'abord le dry-run `bash .ai/scripts/aic.sh migrate okf-indexes`.
3. Le dry-run liste les créations, mises à jour, suppressions, états inchangés ou conflits, sans écrire.
4. `bash .ai/scripts/aic.sh migrate okf-indexes --apply` génère uniquement les index gérés.
5. En vN, un index absent ou périmé produit un warning et conserve une CI verte.
6. En vN+1, le même état fait échouer le check avec la commande de remédiation dans le message.

### Entretien courant

Après l'ajout, le renommage ou le changement de métadonnées d'une fiche, le check détecte un index périmé. La même commande idempotente le régénère. Les index ne sont pas reconstruits implicitement par un check read-only.

## Contrats

- **Documents canoniques** : seuls les fichiers de profondeur `<scope>/<id>.md` qui ne sont ni `index.md`, ni `log.md`, ni `*.worklog.md` sont des fiches feature.
- **Layout généré** :
  - `<docs_root>/features/index.md` route vers les scopes non vides ;
  - `<docs_root>/features/<scope>/index.md` route vers les fiches du scope.
- **Marqueur de propriété** : tout index géré contient un marqueur stable du type `<!-- generated by ai_context; do not edit -->`. Un fichier sans marqueur est project-owned manuel et provoque un refus d'écriture.
- **Déterminisme** : tri lexical stable, liens bundle-relative, aucun timestamp ni donnée volatile.
- **CLI** : `aic migrate okf-indexes [--apply]` ; dry-run et succès sans écriture par défaut, écriture explicite avec `--apply`, échec non nul sur collision avec un index manuel ou génération invalide.
- **Check de fraîcheur** : compare le contenu attendu au contenu présent sans modifier le repo. Le niveau est warning en vN puis bloquant en vN+1.
- **Compatibilité** : le générateur tolère une fiche sans `type` pendant la fenêtre de migration OKF, comme l'index JSON actuel ; la migration `okf-type` peut être exécutée avant `okf-indexes`, mais les deux restent découplées.
- **Copier** : le runtime et ses miroirs Jinja sont livrés ensemble ; le message post-update expose la migration, sans tâche d'écriture automatique.

## Validation

- **Acceptance** :
  - un mesh contenant plusieurs scopes produit un index racine et un index par scope non vide avec des liens relatifs valides ;
  - `index.md`, `log.md` et `*.worklog.md` sont ignorés par l'indexeur JSON, les validators et les migrateurs de fiches ;
  - un second `--apply` sur un mesh inchangé produit zéro diff ;
  - un `index.md` manuel sans marqueur n'est pas écrasé et provoque une erreur actionnable ;
  - `docs_root` personnalisé, mesh vide, scope vide et nom de fiche avec espaces supportés par les scanners existants restent couverts ;
  - un projet ancien reçoit Copier sans mutation de ses features et sans CI rouge en vN ;
  - en vN+1, un projet ayant sauté vN obtient un échec citant la commande de migration ;
  - `.ai/.feature-index.json` reste inchangé contractuellement.
- **Tests ciblés** : classification des fichiers réservés, génération multi-scope, état vide, `docs_root`, collision manuelle, idempotence, fraîcheur et sortie CLI.
- **Tests d'intégration Copier** : scaffold d'une ancienne version dans un dossier temporaire, ajout de fiches project-owned, `copier update`, vérification de non-mutation avant `--apply`, génération, second passage sans diff et rollback Git.
- **Checks repo** : `check-dogfood-drift.sh`, `check-features.sh --no-write`, `check-feature-docs.sh core/feature-mesh-progressive-indexes`, `check-ai-references.sh`, `tests/smoke-test.sh`, puis quality gate avant DONE.

### Evidence d'implémentation vN

- Le classificateur partagé réserve `index.md`, `log.md` et `*.worklog.md` dans le runtime et son miroir Copier ; les indexeurs, validateurs, migrateurs et hooks concernés l'utilisent.
- `aic migrate okf-indexes` fournit le dry-run, `--apply`, le contrôle warn-only par défaut et `--check --strict` pour préparer vN+1.
- Les index racine et par scope du dépôt dogfood sont générés, déterministes et validés strictement.
- Les 45 tests unitaires passent, dont les cas multi-scope, vide, `docs_root`, collision transactionnelle, idempotence, noms avec espaces et hooks.
- `tests/smoke-test.sh` passe avec un scénario d'upgrade Copier qui prouve la non-mutation avant `--apply`, l'avertissement non bloquant et la migration explicite.
- `check-dogfood-drift.sh` confirme l'alignement du runtime avec les profils Copier rendus.
- La revue croisée Claude/Codex a confirmé puis fait couvrir les régressions suivantes : propriété du marqueur ancrée en première ligne, gate `feat:` insensible aux index réservés, fraîcheur discriminée, mode `0644`, symlinks et `docs_root` hors repo refusés, TSV robuste et clé auto-worklog normalisée.
- Le smoke d'upgrade couvre désormais un second `--apply` sans diff et un rollback par `git revert` qui préserve la fiche project-owned.
- Le re-audit Claude du 2026-07-17 est soldé : les assertions des sous-shells sont explicitement discriminantes, la fraîcheur conserve la précision sub-seconde sur Bash 3.2, le comptage traite les antislashs littéralement, et les statuts `unchanged`/`conflict` ainsi que les scopes symlinkés sont couverts.

## Droits / accès

Aucun contrôle d'accès applicatif. La commande reste bornée au repo courant et au `docs_root` résolu par la configuration. Toute construction de chemin réutilise les validations existantes de scope/id et interdit d'écrire hors de la racine du feature mesh.

## Données

- **Données concernées** : fichiers Markdown versionnés sous `<docs_root>/features/**`.
- **Source de vérité** : frontmatter et titre des fiches canoniques ; les index sont entièrement dérivés.
- **Migration** : création ou mise à jour opt-in des seuls index portant le marqueur géré.
- **Backfill** : aucune réécriture des fiches n'est nécessaire pour générer les index.
- **Compatibilité** : absence temporaire de `type` tolérée ; valeur de lecture par défaut identique au contrat courant de l'index JSON.
- **Rétention/confidentialité** : aucune donnée nouvelle ; les index republient uniquement des métadonnées déjà versionnées.

## UX

- Le dry-run distingue clairement `create`, `update`, `delete`, `unchanged` et `conflict`.
- La sortie `--apply` liste uniquement les fichiers écrits.
- Le message de collision explique qu'un index manuel doit être déplacé, fusionné ou explicitement repris avant relance.
- Le message de fraîcheur cite `bash .ai/scripts/aic.sh migrate okf-indexes --apply`.

## Observabilité

- Signaux locaux uniquement : nombre d'index à créer, mettre à jour, supprimer, inchangés ou en conflit.
- Le check indique les chemins absents ou périmés et son niveau `warn` ou `fail`.
- Aucun état de migration séparé, métrique distante ou télémétrie n'est introduit.

## Déploiement / rollback

- **vN — introduction** : classification réservée, générateur, commande, marqueur, check warn-only, message Copier et documentation. `copier update` reste non mutatif pour les index project-owned.
- **Migration opt-in** : dry-run, puis `--apply`, review et commit des index générés dans chaque projet consommateur.
- **vN+1 — enforcement** : index absents ou périmés bloquants ; le message d'échec donne la commande de remédiation.
- **Saut de version** : un projet passant directement d'avant vN à vN+1 peut exécuter la même commande ; aucune étape intermédiaire n'est nécessaire.
- **Rollback** : `git revert` du commit des index générés, puis épinglage éventuel de la référence Copier précédente dans `.copier-answers.yml` ou avec `--vcs-ref`.
- **Post-déploiement** : vérifier l'absence de `.rej`, lancer la migration en dry-run, appliquer, contrôler le diff puis exécuter les checks locaux.

## Risques

- **Collision avec un index manuel** : mitigée par le marqueur de propriété et le refus d'écrasement.
- **Dérive entre scanners** : mitigée par un classificateur partagé et des tests paramétrés sur chaque consommateur.
- **Dérive runtime/template** : mitigée par le dogfood drift et le smoke Copier.
- **Duplication index JSON/Markdown** : acceptée car les usages diffèrent ; les deux projections dérivent des mêmes fiches et ont des checks distincts.
- **Taxe de commit après chaque changement de fiche** : acceptée en échange de la navigation disponible directement sur GitHub ; le générateur idempotent réduit cette taxe.
- **Décision à revalider avant vN+1** : confirmer qu'au moins un cycle de release a laissé une fenêtre de migration réelle aux consommateurs.

## Cross-refs

- `core/okf-strict-profile` : fournit le plancher OKF et déferre explicitement les index Markdown par scope à une phase ultérieure.
- `core/feature-index-cache` : conserve le cache JSON machine et son contrat de déterminisme.
- `core/index-contract-v2` : garantit que la nouvelle projection Markdown n'impose pas de changement au schema JSON.
- `core/template-engine` : livre scripts, checks, documentation et message de migration aux projets consommateurs via Copier.
- **HANDOFF `core -> quality` confirmé** : ajouter la couverture unitaire, le scénario d'upgrade Copier, le contrôle de fraîcheur et la validation du passage warn-only vers fail.
- **HANDOFF `core -> workflow` confirmé** : vérifier que les hooks auto-worklog, auto-progress et freshness ignorent les documents réservés et ne reconstruisent pas les index pendant un check read-only.
- **HANDOFF `core -> quality/touches-breadth-guard` confirmé et clôturé** : les consommateurs non canoniques sont reclassés en `touches_shared:`, les propriétaires directs sont documentés et les gates worktree/staged stricts passent.

## Historique / décisions

- 2026-07-16 — Cadrage `aic-frame` niveau high après analyse du dépôt Google `knowledge-catalog` et de la présentation OKF. Décision : reprendre l'organisation récursive par `index.md`, sans adopter `log.md` ni remplacer le modèle local.
- 2026-07-16 — Validation utilisateur de la création. Migration Copier retenue en deux versions, écriture project-owned opt-in, idempotente et réversible.
- 2026-07-16 — Implémentation vN terminée : génération et migration explicites, check warn-only, mode strict testable, documentation d'upgrade et couverture Copier. L'activation bloquante par défaut reste explicitement différée à vN+1 après un cycle de migration réel.
- 2026-07-16 — Revue adversariale Claude vérifiée par Codex : les défauts runtime et trous de tests confirmés sont remédiés. La clôture reste bloquée uniquement par le Signal A historique de sur-couverture `touches:` ; son nettoyage transverse doit être confirmé et livré séparément sous `quality/touches-breadth-guard`.
- 2026-07-16 — HANDOFF transverse confirmé puis clôturé : 4ᵉ vague `quality/touches-breadth-guard`, propriétaires structurels explicites, staged strict simulé et gate `feat:` verts. Blocker levé.
- 2026-07-16 — DONE vN : index Markdown progressifs, migration Copier opt-in, warn-only par défaut, mode strict explicite et rollback validés. L'activation stricte par défaut reste une décision vN+1 distincte.
