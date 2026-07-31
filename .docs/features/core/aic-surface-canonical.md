---
id: aic-surface-canonical
scope: core
title: Surface utilisateur canonique aic
status: done
depends_on: []
touches:
  - README_AI_CONTEXT.md
  - PROJECT_STATE.md
  - MIGRATION.md
  - CONTRIBUTING.md
  - docs/archive/AUDIT_2026-05-06.md
  - template/README_AI_CONTEXT.md.jinja
  - template/.ai/scripts/aic.sh.jinja
  - .ai/scripts/aic.sh
  - .ai/scripts/product-status.sh
  - .ai/scripts/product-portfolio.sh
  - template/.ai/scripts/product-status.sh.jinja
  - template/.ai/scripts/product-portfolio.sh.jinja
  - template/.claude/skills/aic-*/**
  - template/.agents/skills/aic-*/**
touches_shared:
  - CHANGELOG.md
  - docs/upgrading.md
  - docs/getting-started.md
  - README.md
  - copier.yml
  - tests/smoke-test.sh
  - tests/unit/test-surface-manifest.sh
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: done
  step: "surface aic canonique complète : 10/10 intentions ont une route aic.sh (onboard + dev-plan ajoutées, additive-only)"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir si une nouvelle commande publique aic ou un alias legacy est ajouté"
  updated: 2026-07-24
type: feature
---

# Surface utilisateur canonique aic

## Résumé

Cette feature unifie la surface publique autour de `aic` et des skills `aic-*`.
Les anciens verbes publics exposes via `ai-context` ne doivent plus apparaitre
comme interface utilisateur recommandee.

## Objectif

Reduire l'ambiguite entre Claude, Codex et les agents non-hookes. Un utilisateur
doit voir une seule taxonomie : `aic`, `aic-onboard`, `aic-frame`, `aic-status`,
`aic-diagnose`, `aic-document-feature`, `aic-review`, `aic-ship`.

## Périmètre

### Inclus

- Supprimer la presentation publique des anciens verbes `ai-context` quand ils
  doublonnent la surface `aic`.
- Aligner README, etat projet, changelog, migration, messages Copier et aide
  runtime/template.
- Ajouter une verification smoke qui detecte la reintroduction d'anciens noms
  publics.
- Garder les scripts internes uniquement comme implementation, pas comme UX
  utilisateur.

### Hors périmètre

- Refonte BOS-like de `aic-frame`.
- Ajout du champ `verification:` au frontmatter feature.
- MCP local, plugin Claude Code, site docs ou benchmark public.

### Granularité / nommage

Cette fiche couvre la migration de surface utilisateur, pas tous les chantiers
P0/P1 de la roadmap.

## Invariants

- `.ai/` reste la source unique.
- Le langage utilisateur canonique est `aic`, pas `ai-context`.
- Aucun alias legacy public ne doit etre conserve pour les anciens verbes.
- Les commits restent en francais.

## Décisions

- Migration breaking propre : suppression nette des anciens noms publics au lieu
  d'aliases de compatibilite.
- `aic-document-feature` fait partie du noyau officiel.
- Le wrapper runtime/template est renomme de `ai-context.sh` vers `aic.sh`.
  Aucun alias legacy n'est rendu dans le scaffold.
- Les anciens noms ne sont conserves que comme references historiques ou table de
  migration explicite, pas comme surface active.

## Comportement attendu

Un utilisateur qui lit le README, le message post-copy ou l'aide runtime voit la
surface `aic` comme entree principale. Les commandes historiques de cadrage,
brief, document-delta et ship-report ne sont plus presentees comme chemins
utilisateur.

## Contrats

- **Classification en 4 niveaux (contrat v1.0)**, matérialisée dans `aic.sh --help` :
  - `stable` (10 routes) : `init`, `onboard`, `frame`, `pilot`, `dev-plan`, `status`, `diagnose`, `document-feature`, `review`, `ship` — retrait/renommage = MAJOR ;
  - `stable-maintenance` (17 routes) : `doctor`, `migrate`, `repair`, `repair-copier-metadata`, `template-diff`, `resume`, `audit`, `check`, `check-docs`, `coverage`, `shims`, `index`, `pr-report`, `measure`, `product-status`, `product-portfolio`, `product-review` — publiques et documentées (`_message_after_update` pour `migrate`, RELEASE.md §7 pour `doctor`, README_AI_CONTEXT pour `repair-copier-metadata`/`template-diff`) : nom, rôle et code de retour gelés, la forme exacte de la sortie texte ne l'est pas ;
  - `deprecated` (3 routes) : `frame-bootstrap`, `frame-context` (alias historiques de `frame`), `knowledge` (initiative `cut`, code conservé) — fonctionnent, retrait possible en v2 ;
  - `interne` (1 route) : `reminder` — plomberie hooks, non contractuelle, peut changer en MINOR.
- Surface publique canonique (10 intentions) :
  - `aic`
  - `aic-onboard`
  - `aic-frame`
  - `aic-pilot`
  - `aic-dev-plan`
  - `aic-status`
  - `aic-diagnose`
  - `aic-document-feature`
  - `aic-review`
  - `aic-ship`
- Route CLI `aic.sh <verbe>` = nom du skill sans le prefixe `aic-`, pour toute
  intention scriptable. Pour les intentions purement conversationnelles
  (`pilot`, `dev-plan`, `onboard`), la route existe mais pointe vers un message
  d'orientation vers le skill, jamais vers une logique dupliquee.
- Les workflows internes `.ai/workflows/*` restent la source procedurale
  partagee.

## Validation

- `bash .ai/scripts/check-shims.sh`
- `bash .ai/scripts/check-features.sh`
- `bash .ai/scripts/check-feature-docs.sh core/aic-surface-canonical`
- `bash tests/smoke-test.sh`
- `bash .ai/scripts/check-ai-references.sh`
- `bash .ai/scripts/check-feature-coverage.sh`
- `bash .ai/scripts/measure-context-size.sh`
- Assertion smoke : les anciens noms publics ne reapparaissent pas dans les
  surfaces utilisateur.

## Risques

- Des references historiques peuvent rester dans `CHANGELOG.md` par nature.
  Elles doivent rester cantonnees a l'historique, pas a la documentation active.
- Supprimer des commandes runtime existantes peut casser des utilisateurs
  downstream ; la migration doit etre documentee dans `MIGRATION.md`.

## Cross-refs

Aucune dependance frontmatter.

## Historique / décisions

- 2026-07-24 (v1.0, chantiers C12+C13 du gel P16) : **manifeste de surface livré et gaté en CI.** `tests/unit/test-surface-manifest.sh` snapshote les 8 éléments du contrat public (routes par niveau, questions Copier avec `multiselect`/`when`/validateurs/choix, cycle d'update `_skip_if_exists`/`_migrations`/`_answers_file`, requis + 11 enums + 5 patterns du schéma, enveloppe et clés TYPÉES de l'index avec vérification qu'aucune clé n'est émise à `null`, clés `config.yml` réellement lues extraites du code, modèle de shims dont les agents dépréciés, prédicats de la matrice de capacités). Parsing par `yq`/`jq` uniquement, dans `tests/` — aucune logique ajoutée au moteur bash, donc hors moratoire. Deux invariants forts encodés au-delà du snapshot : aucune migration native ne contient `--apply` (Copier ne doit jamais écrire dans le mesh) et aucune route du dispatch n'est absente de l'aide. **Vérifié discriminant sur 4 dérives réelles** : ajout d'une valeur de choix, migration native passée en écriture, retrait d'un champ requis du schéma, renommage d'une route stable — chacune fait échouer le manifeste. Câblé dans la CI (`ai-context-check.yml`) et le smoke (`[0q4/28]`). C13 : section CONTRIBUTING « Moratoire de surface (v1.0+) » — contrairement au moratoire bash, celui-ci EST gaté automatiquement (les surfaces sont énumérables) ; table SemVer explicite, et le piège de la valeur de choix Copier documenté (retirer une valeur réinitialise la réponse entière — d'où le niveau `deprecated`).
- 2026-07-24 (v1.0, pilotage P16 Bloc A) : **classification de la surface CLI en 4 niveaux** validée par l'utilisateur et matérialisée dans `aic.sh --help` (+ miroir template). Motif : la review Codex #4 a montré que « 10 intentions » ne décrivait pas le contrat CLI réel — l'aide exposait 13 entrées sous « Commandes utilisateur » (dont `init`, livré le même jour mais absent du contrat proposé, et `knowledge` alors que P1 venait de l'acter en `cut`), et rangeait `migrate`/`doctor`/`repair-copier-metadata`/`template-diff` en « maintenance » non contractuelle alors qu'elles sont données au consommateur par `_message_after_update`, RELEASE.md §7 et README_AI_CONTEXT. D'où le niveau intermédiaire `stable-maintenance`. Vérifié par script que les 31 routes du dispatch sont toutes listées et classées, sans route orpheline ni entrée d'aide sans route. Assertion smoke réécrite : elle exige les 4 en-têtes de niveau et vérifie le classement de deux routes témoins (`init` en stable, `knowledge` en deprecated) au lieu de l'ancien en-tête « Commandes utilisateur : ».
- 2026-05-06 : decision de faire une migration breaking sans alias legacy, avec
  un commit dedie au sous-chantier.
- 2026-06-19 : ajout de `aic-onboard` a la taxonomie canonique (init/sync/migrate
  de l'overlay projet). Voir `workflow/project-overlay-onboarding`.
- 2026-07-03 : fiche clôturée en `done`. La surface publique canonique reste `aic`/`aic-*`, `aic-pilot` et `aic-onboard` sont intégrés, et les adaptations VCS n'ont pas changé l'UX commande. Doc Impact Decision : C — fiche feature et worklog mis à jour.
- 2026-07-07 (P6, hygiène repo) : `AUDIT.md` et `AUDIT_2026-05-06.md` déplacés vers `docs/archive/` (0 et 1 référence mesh respectivement, vérifié par `rg` avant déplacement). `PROJECT_STATE.md` lie désormais vers `docs/archive/`. Les 60 fiches `status: done` restent en place : `build-feature-index.sh` scanne `-mindepth 2 -maxdepth 2` sous `.docs/features/` (non récursif) — les archiver casserait silencieusement `depends_on`/`touches` sans bénéfice fonctionnel (déjà masquées du reminder par défaut). Décision confirmée avec l'utilisateur plutôt que suivie à la lettre depuis ANALYSE.md.
- 2026-07-24 (release v0.14.0) : `README_AI_CONTEXT.md` (+ miroir `template/README_AI_CONTEXT.md.jinja`) et `PROJECT_STATE.md` bascule la reco `copier update` de `--vcs-ref=HEAD` par défaut vers le comportement par défaut de Copier (dernier tag), suite à la reprise d'une cadence de tags (voir `RELEASE.md`). `--vcs-ref=HEAD` reste documenté comme option avancée. Aucun changement de la surface `aic` elle-même.
- 2026-07-24 (pilotage P15, additive-only) : écart trouvé et corrigé — `aic-onboard` et `aic-dev-plan` faisaient déjà partie de la taxonomie canonique (skills existants, mentionnés dans l'Objectif depuis 2026-06-19) mais n'avaient **aucune route `aic.sh`** correspondante. Ajout de `onboard` et `dev-plan` au dispatch (message d'orientation vers le skill, même style que `pilot`, aucune logique dupliquée). Contrat § mis à jour : 10/10 intentions listées explicitement, plus la règle de dérivation `aic.sh <verbe>` = nom du skill sans le préfixe `aic-`. Tout renommage des routes existantes (`frame-bootstrap`/`frame-context` → retrait, `plan` vs `dev-plan`) reste hors périmètre et reporté au chantier v1.0 (`P16`) : additive-only, zéro breaking avant cette version.
