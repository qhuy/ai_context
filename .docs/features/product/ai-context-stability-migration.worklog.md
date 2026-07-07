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
