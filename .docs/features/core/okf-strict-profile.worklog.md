# Worklog — core/okf-strict-profile

## 2026-06-25 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : Profil strict OKF (Open Knowledge Format) des fiches feature
- Cadrage source : `aic-frame` niveau high — thèse « profil strict d'OKF » (OKF = plancher d'interop, règles maison = plafond de gouvernance MUST), non-lossy, livré aux consumers via `copier update` en `warn → fail`, compatible Claude et Codex.
- Arbitrages confirmés utilisateur : enum `type` = `feature|contract|workflow|reference` ; cadence 2 releases (warn vN → fail vN+1) ; backfill `type` seul (`description` en option).
- Phasage : Phase 0 = convergence non-cassante (cette fiche) ; Phase 1 (bundle) et Phase 2 (consommateurs) déférées ; option C déférée, option D rejetée.

## 2026-06-25 — HANDOFF quality/ci-guard, quality/smoke-test, quality/doc-freshness
- Besoin : pendant la fenêtre de grâce (vN → vN+1), les checks CI ne doivent PAS durcir le champ `type` (régime `--warn`), sinon les consumers cassent au premier `copier update`.
- Changement limité : `type` absent ⇒ warning, jamais `exit 1`, jusqu'au release d'enforce vN+1.
- Confirmation : à valider par le scope quality avant implémentation.

## 2026-06-25 — HANDOFF product/readme-positioning, product/product-portfolio-loop
- Besoin : cadence des releases vN (introduce) / vN+1 (enforce) sous le modèle « pas de bump auto » ; claim « OKF-compatible » à positionner au README.
- Changement limité : décision de cadence + formulation marketing ; aucun code.
- Confirmation : à valider par le scope product.

## 2026-06-25 — HANDOFF workflow/codex-hooks-parity, workflow/auto-worklog
- Besoin : garantir que la bascule `warn → fail` se comporte identiquement côté git hooks Codex (pas de logique dupliquée hors `check-features.sh`) ; `auto-worklog` impacté seulement si la Phase 1 touche le format worklog (déférée).
- Changement limité : vérification de parité ; pas de modification de format worklog en Phase 0.
- Confirmation : à valider par le scope workflow.

## 2026-06-25 — implémentation Phase 0 (auto-pilot)
- Sources template éditées (vérité = `template/**`), runtime rendu via `dogfood-update.sh --apply` puis frames restaurés :
  - schema (+ jumeau template) : champs optionnels `type` (enum `feature|contract|workflow|reference`) + `description`.
  - `_lib.sh.jinja` : `TYPE_ENUM` (via `read_schema_enum`) + `is_valid_type`.
  - `check-features.sh.jinja` : warn (jamais `exit 1`) si `type` absent/hors-enum.
  - `build-feature-index.sh.jinja` : `type` exposé par feature (défaut `feature`). **Pas de bump `schema_version`** (additif) ni `migrations_pending` (redondant).
  - `migrate-okf-type.sh.jinja` (neuf, bash pur) + dispatch `aic migrate okf-type` (rétro-compat `migrate` nu).
  - `FEATURE_TEMPLATE.md.jinja` : nouvelles fiches en `type: feature`. Bannière `_message_after_update`. Docs MIGRATION/upgrading/CHANGELOG.
- Backfill dogfood : `aic migrate okf-type --apply` → `type: feature` sur 48 fiches du repo (idempotent).
- **Bug attrapé par le smoke [11/28] et corrigé** : `check-features.sh` sous `set -euo pipefail` ; extraire `type` via `$(… | grep …)` abort le script quand le champ manque (le warn devenait un abort sur exactement le scénario consumer en grâce). Corrigé par guard `grep -q` en condition `if`. Fix appliqué source `.jinja` + rendu `.sh` (drift propre).
- Décision assumée (déviation du plan) : pas de bump `schema_version` (smoke asserte `== "1"`, ajout additif) ; pas de `migrations_pending` (warn per-fiche + bannière suffisent) ; `description` hors index.
- Evidence : `check-features --no-write` exit 0 / 0 warn ; `check-feature-docs core/okf-strict-profile` PASS ; `check-dogfood-drift` aligné ; `smoke-test` PASS ; 18/18 tests unitaires PASS.
- Compatibilité Claude/Codex : bascule warn→fail dans `check-features.sh` (source unique appelée par hooks Claude ET git hooks Codex) ; `aic migrate` bash pur ; shims régénérés cohérents par le rendu dogfood.
- Co-impact même scope core (documenté ici ; fiches co-détentrices inchangées car couvertes par les `touches` de cette feature et `check-feature-freshness --staged` est OK) : `index-contract-v2` (index gagne `type`, additif), `feature-mesh` (frontmatter gagne `type` + warn check-features), `feature-index-cache` (cache tolère `type`), `template-engine` (nouveau `.jinja` + bannière copier).
- Note staging : 4 fichiers étaient modifiés avant la session (bumps `progress.updated` + entrées worklog auto de `aic-surface-canonical`/`template-engine`) ; drift bénin de hooks, inclus dans ce commit faute de séparation propre.
