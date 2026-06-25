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
