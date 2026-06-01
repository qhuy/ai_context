---
frame_id: "2026-05-14-ai-context-stability-migration"
status: "done"
scope_probable: "product"
route: "feature"
level: "high"
evidence: "Deux passes d'audit par subagents ont convergé sur les contrats read-only, l'index feature, la rationalisation workflow, les tests/CI et la migration downstream."
next_hint: "Créer/reprendre product/ai-context-stability-migration, puis cadrer le premier chantier quality/read-only-checks-contract + core/index-contract-v2 avant toute modification runtime."
created_at: "2026-05-14"
updated_at: "2026-05-14"
---

# Frame 2026-05-14-ai-context-stability-migration — Stabilisation et migration ai_context

## Intention

Officialiser le programme de stabilisation de `ai_context` après les audits exhaustifs et décisionnels : chaque évolution doit améliorer pertinence, fiabilité et maintenabilité sans casser les projets déjà scaffoldés.

Le problème réel n'est pas seulement une liste de bugs. Le framework a accumulé des contrats runtime, docs, hooks et features qui restent utiles, mais certains contrats sont trop ambitieux, redondants ou ambigus pour les utilisateurs downstream.

## Niveau de cadrage

Niveau : `high`

Justification :

- La demande touche les contrats agents, scripts, hooks, template Copier, CI, docs de migration et compatibilité downstream.
- Les changements peuvent modifier le comportement perçu de commandes existantes.
- Les projets déjà générés avec `ai_context` doivent disposer d'un chemin de migration explicite.

## Objectif

- Stabiliser les contrats centraux de `ai_context`.
- Décider ce qui est gardé, amélioré, fusionné, simplifié ou déclassé en doc.
- Définir une stratégie de migration compatible pour les projets existants.
- Organiser les travaux en features séparées avec preuves et validations ciblées.

## Non-objectifs

- Réécrire tout le framework en une seule feature.
- Supprimer brutalement des commandes ou fichiers générés sans période de compatibilité.
- Transformer `.docs/features/product/` en roadmap parallèle.
- Dupliquer BMAD, Spec Kit, Linear, Jira ou GitHub : ils restent sources propriétaires, `ai_context` ne fait que relier et gouverner localement.

## Scope et route

Scope primaire probable : `product`

Route : `feature`

Justification :

- Le besoin est une initiative produit chapeau qui pilote plusieurs chantiers techniques.
- Les scopes `core`, `quality` et `workflow` seront traités par des features dédiées liées à cette initiative via `product.initiative`.
- Le cadrage global doit rester durable et référençable sans mélanger les responsabilités techniques.

## Challenge IA

- Le problème déclaré est-il le vrai problème ? Oui : le sujet principal est la confiance dans les contrats, pas seulement la correction de warnings documentaires.
- Faut-il reprendre une feature existante ? Non pour le chapeau. `product/product-portfolio-loop` est liée, mais couvre la boucle produit elle-même, pas le programme de stabilisation du framework.
- Faut-il découper ? Oui. Le programme doit être découpé en features techniques : index, read-only, mesh, workflow rationalization, CI/tests, product loop hardening.
- Une doc, ADR ou diagnostic suffit-il ? Non. Le cadrage doit créer une initiative produit, puis des features exécutables avec validations.

## Analyse technique

Surfaces probables :

- `core` : `build-feature-index.sh`, `.ai/.feature-index.json`, `check-features.sh`, schema feature, Copier, templates.
- `quality` : `doctor.sh`, `review-delta.sh`, `check-feature-freshness.sh`, CI, smoke, tests unitaires.
- `workflow` : skills `aic-*`, hooks Claude/Git, `feature-audit`, `auto-worklog`, `auto-progress`, policies MCP/subagents.
- `product` : règles product, scripts `product-*`, docs de migration, changelog.

Contrats touchés :

- Commandes de diagnostic et leur caractère non mutant.
- Contrat d'index feature : format, déterminisme, cache, timestamp, fallback sans `yq`.
- Contrat feature mesh : schema JSON, validation shell, `touches`, `touches_shared`, `external_refs`, `product`.
- Contrat workflow : surface publique `aic`, primitives internes, hooks, fail-open/fail-closed.
- Contrat downstream : `copier update`, hooks existants, CI existante, fichiers générés et shims.

Compatibilité Claude/Codex/templates/downstream :

- Claude garde les hooks les plus automatisés, mais ceux-ci doivent rester bornés, testables et non surprenants.
- Codex reste aligné via `.ai/index.md`, skills locaux, Git hooks et `aic.sh`, sans dépendre d'une injection équivalente à Claude.
- Les templates Copier doivent supporter les anciens projets au moins pendant une release de transition.
- Les projets existants doivent avoir un guide d'upgrade clair et des checks de migration locaux.

## Scénario nominal

1. Une initiative produit `product/ai-context-stability-migration` pilote le programme.
2. Les changements runtime sont découpés en features ciblées par scope.
3. Les commandes actuellement ambiguës gagnent un mode explicite : diagnostic non mutant par défaut, mutation seulement via `--write`, `--repair`, `--apply` ou commande dédiée.
4. Les doublons workflow sont fusionnés ou déclassés en docs.
5. La migration est documentée dans `docs/upgrading.md`, `CHANGELOG.md` et le README si l'expérience utilisateur change.
6. Les projets downstream peuvent faire `copier update`, puis lancer des checks de migration sans écriture implicite.

## Cas limites

- Projet downstream sans `yq` : les fonctions critiques doivent soit rester fiables avec fallback borné, soit déclarer `yq` requis pour les analytics avancées.
- Projet downstream avec `.ai/.feature-index.json` déjà versionné par erreur : la migration doit expliquer quoi faire sans perdre les fiches.
- Projet ayant customisé `.ai/project/**` : `copier update` ne doit pas écraser l'overlay projet.
- Projet ayant activé `.githooks` : les hooks doivent rester compatibles ou afficher une dépréciation claire avant changement.
- Projet CI strict : les nouveaux checks ne doivent pas rendre rouge sans chemin d'action documenté.

## Incertitudes

| Catégorie | Point | Décision |
|---|---|---|
| Bloquant maintenant | Faut-il traiter read-only et index dans une seule feature ou deux ? | Cadrer ensemble, implémenter en deux features coordonnées si les touches divergent. |
| Hypothèse de travail | Le défaut futur doit être non mutant pour les diagnostics. | Accepté ; les mutations deviennent explicites. |
| Risque accepté | Maintenir une compat temporaire augmente le coût court terme. | Accepté pour protéger les projets existants. |
| À valider plus tard | Besoin d'un flag legacy type `AI_CONTEXT_LEGACY_INDEX_WRITE=1`. | À décider pendant `read-only-checks-contract`. |

## Critères d'acceptation

- Une commande de diagnostic ne modifie jamais le repo sans option explicite.
- Le contrat `.feature-index.json` est stable, documenté et testé.
- Les anciens usages disposent d'une migration documentée.
- Les tests critiques sont branchés dans CI ou une suite unitaire unique.
- Les features fusionnées/déclassées sont reflétées dans le feature mesh.
- `copier update` reste viable pour les profils existants.

## Validation prévue

- Checks ciblés par feature : `check-shims`, `check-agent-config`, `check-ai-references`, `check-features`, `check-feature-docs`, `check-feature-freshness`.
- Tests unitaires : matcher, review-delta, context relevance, dogfood drift, project overlay, index determinism.
- Smoke Copier minimal et CI.
- Validation documentaire : `docs/upgrading.md`, `CHANGELOG.md`, fiches feature et worklogs.

## Préconisations

1. Créer l'initiative produit chapeau `product/ai-context-stability-migration`.
2. Lier les futures features techniques à cette initiative via `product.initiative`.
3. Commencer par le couple `quality/read-only-checks-contract` et `core/index-contract-v2`.
4. Reporter les nettoyages documentaires généraux après les contrats runtime.
5. Éviter toute suppression sans période de dépréciation.

## Evidence

Deux audits ont été réalisés par scope :

- Audit exhaustif : fonctionnalités, écarts doc/code, risques et plans d'audit.
- Revue décisionnelle : `KEEP`, `IMPROVE`, `SIMPLIFY`, `MERGE`, `DOWNGRADE_TO_DOC`, `REMOVE`.

Les convergences principales sont : read-only/cache, index déterministe, feature mesh cohérent, rationalisation workflow, tests/CI, migration downstream.

## Next hint

Reprendre avec `product/ai-context-stability-migration`, puis créer/cadrer les features techniques liées. Ne pas modifier runtime avant d'avoir cadré la compatibilité downstream et la stratégie de migration.
