# Worklog — product/ai-context-stability-migration

## 2026-05-14 — création

- Feature créée via cadrage `aic-frame` officialisé.
- Scope : product.
- Intent initial : piloter la stabilisation et la migration de `ai_context` après audits exhaustifs et décisionnels.
- Frame durable : `.docs/frames/2026-05-14-ai-context-stability-migration.md`
- Première reprise recommandée : cadrer `quality/read-only-checks-contract` et `core/index-contract-v2` avec compatibilité downstream explicite.

## 2026-05-14 — suivi / P0 index + read-only

- `core/index-contract-v2` est en review : ordre stable, stdout non mutant, cache idempotent hors `generated_at`, index vide valide.
- `quality/read-only-checks-contract` est en review : diagnostics, rapports, quality gate et CI alignés sur `--no-write` ou index temporaire.
- `product/product-portfolio-loop` aligne les rapports product sur le contrat read-only.
- Migration downstream documentée dans `docs/upgrading.md`, `MIGRATION.md`, `CHANGELOG.md` et `README_AI_CONTEXT.md`.
- next : choisir la prochaine tranche entre alignement schema/checker/parser fallback et rationalisation des workflows/skills.

## 2026-05-14 — suivi / fallback feature mesh

- `core/feature-mesh-contract-alignment` est en review : le fallback sans `yq` conserve maintenant `product.portfolio.*`.
- Impact produit : les scores `product-portfolio` restent cohérents sur environnements minimalistes.
- CI source : test fallback ajouté au workflow check.
- next : poursuivre soit sur rationalisation workflow/skills, soit sur réorganisation des tests si l'objectif est de sécuriser la suite avant nouveaux changements.

## 2026-06-19 — rattachement migration overlay (registre de scopes)

- `docs/upgrading.md` : nouvelle section « Overlay projet : registre de scopes (`aic-onboard`) » documentant la migration deux-temps (copier update apporte le skill + contrat ; `aic-onboard` migre l'overlay project-owned).
- Garde-fous documentés : non bloquant, non destructif, idempotent (`overlay_contract_version`), durable vs volatile.
- Clôture le 3ᵉ maillon du chantier overlay : `core/project-overlay-scope-registry` (contrat) + `workflow/project-overlay-onboarding` (skill) + ce rattachement produit.

## 2026-06-19 15:14 — auto
## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - docs/upgrading.md

## 2026-06-26 15:48 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-06-26 — couverture incidente (CHANGELOG clôture session)
- `CHANGELOG.md` (entrées [Unreleased] des features de la session) couvert par le glob `touches:` de cette feature. Aucun changement de comportement propre. (CHANGELOG.md = candidat touches_shared, cf. quality/touches-breadth-guard.)

## 2026-06-28 21:09 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-07-03 — migration shims AGENTS.md
- `docs/upgrading.md` documente le passage aux shims agents moins dupliqués : `AGENTS.md` auto-suffisant, shims dérivés selon `agents` dans `.copier-answers.yml`, fallback anciens scaffolds, et conservation prudente de `CLAUDE.md`.
- `CHANGELOG.md` ajoute la note migration Unreleased correspondante.
- Rattachement produit : la page d'upgrade reste l'owner direct via cette initiative ; les features techniques concernées sont visibles en `touches_shared`.

## 2026-07-03 — migration kill criterion AGENTS.md natif
- `docs/upgrading.md` ajoute `check-agent-native-context.sh` au parcours post-update et documente le guard `--require-confirmed claude` avant toute optionnalité de `CLAUDE.md`.
- `CHANGELOG.md` ajoute la note Unreleased sur `.ai/native-context-support.tsv` comme matérialisation du kill criterion.
- Décision produit : statut prudent maintenu (`claude=pending`) tant que les issues Anthropic #34235/#6235 restent ouvertes.

## 2026-07-07 — couverture incidente (fix post-review, core/agents-md-shim-canonical)
- MIGRATION.md / docs/upgrading.md : sémantique `copier update` des shims élagués corrigée sur preuve empirique (copier update ne supprime jamais un chemin `_exclude`). Aucun changement du contrat propre de cette fiche. Validation portée par `core/agents-md-shim-canonical`.

## 2026-07-08 — couverture audit strict
- Surface couverte touchée dans le delta d'audit strict : `docs/upgrading.md`.
- Rattachement documentaire pour le gate `check-feature-freshness --staged --strict`; aucun nouveau changement du contrat propre de cette fiche.
- Validation : gate ship relancée avant commit.

## 2026-07-16 — HANDOFF upgrade index Markdown
- `docs/upgrading.md` ajoute la migration opt-in `okf-indexes`, sa fenêtre warn-only et la vérification stricte explicite.
- Le scénario Copier v0.11 → HEAD prouve la non-mutation, l'idempotence et le rollback.

## 2026-07-24 — couverture incidente (v1.0, retrait gemini)
- `docs/upgrading.md` : mentions `GEMINI.md` retirées des sections shims (le fichier n'est plus rendu ; le registre natif n'a pas de ligne `gemini`). Aucun changement du contrat de migration/stabilité.

## 2026-07-24 — v1.0 / B6 : chemin d'upgrade TFVC documenté
- `docs/upgrading.md` : nouvelle section « Mettre à jour un workspace TFVC (sans `.git`) ». Comble un trou réel du parcours de migration — `copier update` refuse un workspace non-git (vérifié), et aucun chemin alternatif n'était documenté pour le provider principal de l'organisation utilisatrice.
- Chemin documenté prouvé end-to-end (copie Git jetable hors workspace → update → `tf checkout` → application) : `_commit` avance, code métier préservé, 0 `.rej`, aucun `.git` dans le workspace, checks verts. Détail dans `core/vcs-provider-abstraction`.

## 2026-08-06 — couverture incidente
- `docs/upgrading.md` : nouvelle section « Tes propres skills Claude (namespace projet) ». Explique qu'un consommateur n'a ni à dupliquer ses skills vers `.agents/skills`, ni à maintenir une liste d'exclusion, et qu'un skill nommé `aic-*` entre dans le namespace réservé. Chemin de migration pour les repos ayant contourné le FAIL de v1.0.0.

## 2026-08-06 19:05 — auto
- Fichiers modifiés :
  - docs/upgrading.md
