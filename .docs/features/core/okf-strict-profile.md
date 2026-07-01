---
id: okf-strict-profile
scope: core
title: Profil strict OKF (Open Knowledge Format) des fiches feature
status: draft
depends_on:
  - core/feature-mesh
  - core/index-contract-v2
  - core/feature-index-cache
  - core/template-engine
  - core/graph-aware-injection
touches:
  - .ai/schema/feature.schema.json
  - template/.ai/schema/feature.schema.json
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
  - .ai/scripts/migrate-okf-type.sh
  - template/.ai/scripts/migrate-okf-type.sh.jinja
  - .docs/FEATURE_TEMPLATE.md
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja
  - MIGRATION.md
  - docs/upgrading.md
touches_shared:
  - CHANGELOG.md
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - .ai/scripts/check-features.sh
  - template/.ai/scripts/check-features.sh.jinja
  - copier.yml
  - tests/smoke-test.sh
  - tests/unit/test-okf-type.sh
product: {}
external_refs:
  okf_spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
  okf_annotated: https://okf.md/spec/
doc:
  level: full
  requires:
    auth: false
    data: true
    ux: false
    api_contract: true
    rollout: true
    observability: false
type: feature
progress:
  phase: review
  step: "Phase 0 implémentée et validée (smoke-test + 19 tests unitaires dont test-okf-type + dogfood-drift) en régime warn-only"
  blockers: []
  resume_hint: "Phase 0 livrée. Reste : confirmer HANDOFF quality/product/workflow, puis planifier le release d'enforce vN+1 (type dans required[] + check exit 1 ; si bump schema_version un jour, mettre à jour l'assertion == \"1\" du smoke-test)"
  updated: 2026-06-26
---

# Profil strict OKF des fiches feature

## Résumé

Faire de chaque fiche `.docs/features/<scope>/<id>.md` un **concept OKF valide** (Open Knowledge Format, Google Cloud v0.1, juin 2026) sans rien perdre du modèle riche : OKF devient le **plancher d'interop** (markdown + frontmatter lisible par tout agent LLM), les règles maison restent le **plafond de gouvernance** (MUST appliqués par les checks bloquants). Le changement de contrat est livré aux projets consommateurs via `copier update` en régime `warn → fail`, identiquement sous Claude et Codex.

## Objectif

Ne pas diverger d'un standard de format de connaissance émergent tant que l'écart de conformité est faible. Bénéfices visés : portabilité multi-LLM (Claude, Codex, autres readers OKF), interop future (visualizer de graphe, catalogue) sans dette, et neutralisation d'une migration douloureuse à 6-12 mois. La feature livre la **convergence de format** (Phase 0), pas une intégration produit : aucun consommateur OKF n'est ciblé aujourd'hui.

Insight fondateur : la permissivité d'OKF (« un consommateur MUST NOT rejeter ») est une obligation du **consommateur**, pas une limite du **producteur**. Rester strict côté producteur est donc 100 % OKF-compatible — c'est la façon prévue de profiler OKF.

## Périmètre

### Inclus

- **Phase 0 — convergence non-cassante** (cette livraison) :
  - Champ `type` ajouté au schema (optionnel en vN, requis en vN+1), **enum fermé maison** : `feature | contract | workflow | reference`.
  - Champ `description` (1 phrase) en frontmatter, en gardant `## Résumé` comme forme longue en corps.
  - `okf_version: "0.1"` déclaré à la racine de bundle.
  - Headings conventionnels OKF `# Examples` / `# Citations` autorisés (non bloquants).
  - Plan de migration consumers `warn → fail` sur 2 releases + commande `aic migrate okf-type` (backfill `type` seul).

### Hors périmètre

- **Phase 1 (déférée)** — conformité bundle complète : frontmatter `type: worklog` sur les `*.worklog.md`, `index.md` régénéré par scope, liens markdown bundle-relative en corps.
- **Phase 2 (déférée, sur trigger réel)** — consommateurs OKF : visualizer du graphe `depends_on`, catalogue pour agents tiers.
- **Option C (export OKF lossy)** : non retenue ; un export n'a de valeur que si un consommateur est ciblé.
- **Option D (migration native vers OKF comme format de stockage)** : **rejetée définitivement** (cf. Décisions).
- Backfill de `description` : optionnel, hors défaut de Phase 0.

### Granularité / nommage

- Une fiche = la convergence de format + son rollout consumers. Les phases déférées seront des fiches distinctes si/quand déclenchées (`core/okf-bundle-conformance`, `core/okf-consumer-export`).

## Invariants

- La fiche markdown reste l'**unique source de vérité** ; aucun artefact OKF dérivé ne devient autoritatif.
- Toute fiche valide reste un **concept OKF valide** (frontmatter parsable + `type` non vide une fois la convergence terminée).
- Les MUST maison ne sont jamais dégradés vers la permissivité OKF : `depends_on` reste **typé, validé, acyclique, sans lien cassé** ; les checks restent **bloquants** (`exit 1`).
- `type` reste dans son **enum fermé** ; pas de taxonomie ouverte (évite le drift qu'OKF reconnaît comme sa faiblesse).
- Comportement **identique sous Claude et Codex** : la logique vit dans des scripts bash partagés, pas dupliquée par runtime.
- Aucune régression de l'injection de contexte (`graph-aware-injection`, `features-for-path`) ni côté Claude ni côté Codex.

## Décisions

- **Profil strict, pas migration** : ai_context est un sur-ensemble de gouvernance ; OKF en est un sous-ensemble d'interop descriptif. On expose une vue OKF d'un modèle qu'on possède déjà à ~80 %.
- **Option D rejetée** : OKF impose la permissivité best-effort là où le mesh repose sur des gates bloquants ; reconstruire les gates par-dessus un format permissif coûte XL, est one-way, et la richesse n'est pas préservable hors-spec, pour un bénéfice d'interop identique à un simple export.
- **`type` enum fermé** `feature | contract | workflow | reference` : comble un trou d'axe réel (la nature de l'asset, absente de `scope`=ownership et `status`=cycle de vie) tout en évitant le drift de taxonomie.
- **Rollout `warn → fail` sur 2 releases** : `type` introduit optionnel + warning en vN, rendu requis (`exit 1`) en vN+1. Jamais `optional → required` dans le même release.
- **Backfill Phase 0 = `type` seul** ; `description` reste une option du même script, pas le défaut.
- **`aic migrate okf-type` runtime-agnostique** (bash pur), exposé via le dispatch existant `aic.sh migrate` (pattern `migrate-features.sh`).

## Comportement attendu

Du point de vue d'un mainteneur de projet consommateur, à la réception de la version vN via `copier update` :

1. `copier update` récupère le schema, les checks, les scripts et la commande de migration ; aucune fiche project-owned n'est touchée.
2. La bannière `_message_after_update` invite à lancer `bash .ai/scripts/aic.sh migrate okf-type --apply`.
3. `aic migrate okf-type` (dry-run par défaut) liste les fiches sans `type` ; `--apply` injecte `type: feature` de façon idempotente.
4. `check-features.sh` émet un **warning** (pas d'échec) tant que `type` manque : CI verte.
5. À la version vN+1, `type` devient requis : une fiche sans `type` fait échouer le check, dont le message cite la commande de backfill.

Du point de vue de ce repo (dogfood) : les ~40 fiches existantes reçoivent `type: feature` via la même commande, validées avant tout tag.

## Contrats

- **Frontmatter feature** (`.ai/schema/feature.schema.json`) : ajout `type` (string, enum `feature|contract|workflow|reference`) et `description` (string). En vN : optionnels. En vN+1 : `type` ajouté à `required[]`. `additionalProperties` reste `true` (préservation des extensions, conforme OKF).
- **Index dérivé** (`.ai/.feature-index.json` via `build-feature-index.sh`) : ajout **additif** du champ `type` par feature (défaut `feature` à la lecture quand absent). **Pas de bump `schema_version`** — l'ajout est rétro-compatible (contrat de l'index) et un bump casserait l'assertion `schema_version == "1"` du smoke-test. `description` n'est **pas** exposé dans l'index (frontmatter + schema seulement). Pas de `migrations_pending` : le rappel de backfill passe par le warn per-fiche de `check-features` + la bannière `_message_after_update`.
- **Validation** (`check-features.sh`) : `type` absent ou hors-enum ⇒ `warn` en vN, `ko`/`exit 1` en vN+1. Les autres invariants (clés requises, anti-path-traversal, cycles) inchangés.
- **Commande** : `aic migrate okf-type [--apply] [--type=<valeur>]` — dry-run par défaut, idempotente, **bash pur (awk, aucune dépendance `yq` ni `sed`)**, n'écrase jamais un `type` existant.
- **OKF côté producteur** : chaque fiche conforme = concept OKF valide ; `okf_version: "0.1"` au root de bundle ; champs maison (`scope`, `depends_on`, `progress`, etc.) = extension keys ignorés par un consommateur OKF, préservés en round-trip.

## Validation

- **Acceptance** :
  - (a) Une fiche sans `type` ⇒ `check-features.sh` `warn` et `exit 0` en vN.
  - (b) `aic migrate okf-type --apply` rend toutes les fiches conformes et est **idempotent** (re-run = aucun changement).
  - (c) `build-feature-index.sh` produit un index bien formé exposant `type` par feature, déterministe (idempotent hors `generated_at`, `schema_version` inchangé à `"1"`) ; l'injection Claude (hooks `.claude/settings.json`) et le chemin git-hook Codex restent inchangés.
  - (d) Le message d'échec d'enforce (vN+1) cite explicitement `aic migrate okf-type --apply`.
  - (e) `yq` absent : la migration fonctionne quand même (fallback).
- **Checks** : `bash .ai/scripts/dogfood-update.sh` (dry-run), `bash .ai/scripts/check-features.sh --no-write`, `bash .ai/scripts/check-feature-docs.sh core/okf-strict-profile`, `bash .ai/scripts/check-shims.sh`, `bash tests/smoke-test.sh`, quality gate avant DONE.
- **Cas limites couverts** : consumer Codex-only ; saut direct vN-1 → vN+1 (rate la grâce) ; `yq` absent ; fiche avec `type` déjà présent ou hors-enum ; consommateur de l'index faisant une égalité stricte sur `schema_version`.

## Droits / accès

Aucun contrôle d'accès applicatif : la feature ne touche ni authentification ni autorisation runtime. La seule surface de sécurité concernée est l'**anti-path-traversal** déjà appliqué par `check-features.sh` sur `id`/`scope` (ils servent à construire des chemins de worklog) ; ce contrôle reste **inchangé** et n'est pas relâché par l'ajout de `type`/`description`. La commande `aic migrate okf-type` n'écrit que dans `.docs/features/**` du repo courant et ne modifie jamais de fichier hors repo.

## Données

- **Donnée concernée** : le frontmatter des fiches feature (le champ `type` ajouté, `description` optionnel). C'est une donnée éditoriale versionnée en git, pas une base.
- **Migration / backfill** : `aic migrate okf-type --apply` insère `type: feature` dans les fiches existantes du consommateur. Idempotent, n'écrase pas un `type` présent, ne réordonne pas les clés.
- **Compatibilité** : pendant la fenêtre de grâce (vN → vN+1), `build-feature-index.sh` applique un défaut `type: feature` à la lecture pour qu'aucun consommateur de l'index ne voie de valeur nulle. Ajout **additif**, donc `schema_version` reste `"1"` (pas de bump).
- **Rétention / confidentialité** : sans objet (donnée de structure documentaire, pas de PII).

## UX

Pas d'interface graphique. La surface « utilisateur » se limite à :

- La **CLI** `aic migrate okf-type` : sortie de type dry-run (compte fiches à migrer / déjà conformes), drapeau `--apply`, messages d'erreur actionnables.
- La **bannière** `_message_after_update` de copier, affichée après update, qui pointe vers la commande de backfill.
- Le **message d'échec** de `check-features.sh` en vN+1, qui doit citer la commande de remédiation.

Les copies de ces trois points sont des livrables (claires, en français, actionnables).

## Observabilité

- **Signaux de migration** : le warn per-fiche de `check-features` (`champ 'type' absent`), qui s'efface dès le backfill, plus la bannière `_message_after_update`, tiennent lieu de rappel. (`migrations_pending` écarté : redondant avec le warn, et coûteux en état inter-boucle dans `build-feature-index`.)
- **Sortie des checks** : `check-features.sh` distingue `warn` (vN) et `ko` (vN+1) ; le compte de fiches non conformes est visible dans la sortie.
- **Dogfood drift** : `dogfood-update.sh` / `check-dogfood-drift.sh` détectent une dérive entre le template source et le runtime appliqué avant livraison.
- Pas de métrique runtime ni d'alerte externe : l'observabilité reste au niveau des sorties CLI/CI.

## Déploiement / rollback

- **Cadence** : 2 releases. **vN (introduce)** — `type`/`description` optionnels, `check-features` en `warn`, `type` additif dans l'index (sans bump `schema_version`), commande `aic migrate okf-type`, bannière `_message_after_update`, docs (`MIGRATION.md`, `docs/upgrading.md`, `CHANGELOG.md`). **vN+1 (enforce)** — `type` dans `required[]`, `check-features` en `exit 1`.
- **Migration progressive** : la fenêtre de grâce est le temps passé par un consommateur sur vN avant d'adopter vN+1. Backfill un-coup via `aic migrate okf-type --apply`.
- **Plan de rollback** : les fiches sont project-owned et la migration est git-trackée ⇒ `git revert` du commit de backfill suffit ; `.copier-answers.yml` permet d'épingler la ref de template précédente si besoin de redescendre sous vN.
- **Vérifications post-déploiement** : sur ce repo, dogfood complet (`dogfood-update.sh` → `aic migrate okf-type --apply` → `check-features.sh --no-write` → `tests/smoke-test.sh`) avant tag. Côté consommateur : CI verte en vN, message d'erreur actionnable en vN+1.
- **Compatibilité Claude / Codex** : la bascule warn→fail vit dans `check-features.sh` (source unique appelée par les hooks Claude `.claude/settings.json` ET les git hooks Codex `codex-hooks-parity`/`git-hooks`) ; `aic migrate` est bash pur. Les shims `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` restent cohérents (générés depuis les règles, pas depuis le schema fiche).

## Risques

- **Risques connus** :
  - **(Résolu)** `tests/smoke-test.sh` asserte `schema_version == "1"` → décision de **ne pas bumper** en Phase 0 (ajout additif). Tout futur bump devra mettre à jour cette assertion (surface quality).
  - **(Résolu, appris au smoke)** `check-features.sh` tourne sous `set -euo pipefail` : extraire un champ optionnel via `$(… | grep …)` abort le script quand le champ manque. Corrigé par un guard `grep -q` en condition `if`. Tout futur check d'un champ optionnel doit suivre ce motif.
  - Drift de taxonomie `type` si l'enum n'est pas tenu fermé → mitigé par enum documenté + warn hors-enum.
  - Doublon sémantique potentiel `touches[]` (binding code, bloquant) vs un futur `resource` OKF → clarifier avant d'introduire `resource` (hors Phase 0).
  - Parité `template/**` jumelle : tout ajout doit être répliqué dans `template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja` et le schema template, sous peine de dérive.
- **Décisions ouvertes** : reclassement éventuel des fiches non-`feature` (contrats/workflows backfillés en `feature` par défaut) si l'axe `type` doit être affiné — sans impact fonctionnel (enum tolérant en warn).
- **Points à revalider** : déclencheurs de Phase 1 / Phase 2 (apparition d'un consommateur OKF réel ou passage d'OKF en ≥ 1.0).

## Cross-refs

- `core/feature-mesh` : définit le contrat de frontmatter et le graphe `depends_on` que cette feature étend (ajout de `type`/`description`).
- `core/index-contract-v2` : contrat de l'index JSON ; le champ `type` y est ajouté de façon **additive** (sans bump `schema_version`).
- `core/feature-index-cache` : cache dérivé ; tolère le nouveau champ `type` (ajout additif, déterminisme préservé).
- `core/template-engine` : cycle copier install/update et parité `template/**` ; porte la bannière `_message_after_update` et la livraison aux consumers.
- `core/graph-aware-injection` : consommateur de l'index ; doit rester insensible à l'ajout de `type` (injection inchangée sous Claude et Codex).
- **HANDOFF émis** (cross-scope, à confirmer par les scopes cibles) :
  - `quality` — `ci-guard`, `smoke-test`, `check-feature-freshness` ne doivent pas durcir `type` avant vN+1 (grâce CI).
  - `product` — cadence des releases vN/vN+1 (modèle « pas de bump auto ») + claim « OKF-compatible » dans `readme-positioning`.
  - `workflow` — `codex-hooks-parity` (parité de la bascule warn→fail côté git hooks Codex) ; `auto-worklog` si la Phase 1 touche le format worklog ; `subagent-contract`.
- Détail externe non dupliqué : spec OKF référencée via `external_refs.okf_spec` / `external_refs.okf_annotated`.

## Historique / décisions

- 2026-06-25 — Cadrage validé (`aic-frame`, niveau high). Décision de routage : feature. Thèse « profil strict d'OKF » retenue ; options C (export) déférée et D (migration native) rejetée. Arbitrages confirmés par l'utilisateur : enum `type` = `feature|contract|workflow|reference` ; cadence 2 releases ; backfill `type` seul. Compatibilité Claude **et** Codex posée en exigence de premier ordre.
