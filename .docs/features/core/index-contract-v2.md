---
id: index-contract-v2
scope: core
title: Contrat v2 de l'index feature
status: done
depends_on:
  - core/feature-index-cache
  - core/feature-mesh
  - quality/index-lock-contract
touches:
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
  - .ai/schema/feature.schema.json
  - template/.ai/schema/feature.schema.json
  - tests/unit/test-build-feature-index-contract.sh
  - .docs/features/core/index-contract-v2.md
  - .docs/features/core/index-contract-v2.worklog.md
touches_shared:
  - docs/upgrading.md
  - CHANGELOG.md
  - README_AI_CONTEXT.md
  - tests/smoke-test.sh
product:
  initiative: product/ai-context-stability-migration
  contribution: "Stabilise le contrat de l'index feature utilisé par hooks, checks, reports et product traceability."
  evidence: "Tests de contrat stdout/no-write, ordre stable, cache idempotent et index vide valide."
external_refs:
  frame: ".docs/frames/2026-05-14-ai-context-stability-migration.md"
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
  step: "contrat index v2 livré : stdout non-mutant, cache idempotent, schema_version opérationnalisé"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si le format .ai/.feature-index.json ou schema_version change"
  updated: 2026-07-03
type: feature
---

# Contrat v2 de l'index feature

## Résumé

Définir et fiabiliser le contrat v2 de `.ai/.feature-index.json`, utilisé par les hooks, checks, rapports, product traceability et workflows de reprise.

## Objectif

Rendre l'index feature explicite, déterministe et compatible downstream. Les consommateurs doivent savoir si l'index est un cache, une sortie contractuelle, ou une représentation interne régénérable.

## Périmètre

### Inclus

- Format JSON contractuel : racine, champs obligatoires, champs optionnels, version.
- Déterminisme : ordre stable, champs non déterministes, timestamp, comparaison de builds successifs.
- Modes d'exécution : sortie stdout, écriture `--write`, cache, lock, erreurs.
- Fallback sans `yq` : champs supportés, limites explicites, comportement si le fallback ne suffit pas.
- Migration downstream pour les scripts ou projets qui lisent directement l'index.
- Tests de contrat.

### Hors périmètre

- Rendre tous les checks read-only par défaut : couvert par `quality/read-only-checks-contract`.
- Revoir toute la sémantique du feature mesh : couvert par une future feature d'alignement schema/checker si nécessaire.
- Refaire le product scoring : couvert par `product/product-loop-hardening` si créé.

### Granularité / nommage

Cette feature couvre le contrat d'index. Les consommateurs seront adaptés dans leurs propres features si leurs comportements changent.

## Invariants

- L'index doit être régénérable à partir des fiches feature.
- La sortie stdout ne doit pas modifier le repo.
- L'écriture d'un cache doit être explicite, atomique et protégée par lock.
- Les champs consommés par les scripts doivent être documentés ou traités comme internes.
- La compatibilité avec Bash 3.2/macOS reste une contrainte runtime.

## Décisions

- Le contrat v2 doit distinguer clairement :
  - représentation contractuelle ;
  - cache écrit sur disque ;
  - métadonnées non déterministes.
- Les champs comme `generated_at` ne doivent pas casser les tests de déterminisme.
- `generated_at` reste une métadonnée non contractuelle : les comparaisons de contrat doivent l'exclure.
- `--write` ne doit pas réécrire le cache si la représentation contractuelle existante est identique.
- Le fallback sans `yq` doit être borné : soit il supporte les champs utilisés, soit il émet un warning/action explicite.
- Les changements de format doivent être documentés dans `docs/upgrading.md`.
- `schema_version` est **opérationnalisé** : un test de contrat snapshotte le jeu de clés émises (top-level + feature + progress) **couplé à la version** (`tests/unit/test-build-feature-index-contract.sh`). Tout changement de clés fait échouer le test tant que la version n'est pas bumpée et le snapshot mis à jour. Le smoke ne **pinne** plus la version (présence + type string seulement), pour ne pas décourager un bump légitime — le pin vit dans le test de contrat.

## Comportement attendu

- `bash .ai/scripts/build-feature-index.sh` produit une sortie JSON valide sur stdout ; sa représentation contractuelle hors `generated_at` est stable.
- `bash .ai/scripts/build-feature-index.sh --write` écrit explicitement le cache.
- `--write` ne touche pas le fichier cache existant si seul `generated_at` changerait.
- Deux builds successifs sur le même état repo produisent une représentation contractuelle équivalente.
- Les consommateurs peuvent vérifier `schema_version`.
- En cas d'erreur de parsing, le comportement est documenté : fail hard ou exclusion/warning selon le mode choisi.

## Contrats

- API script : `.ai/scripts/build-feature-index.sh`.
- Template correspondant : `template/.ai/scripts/build-feature-index.sh.jinja`.
- Le format v2 doit documenter :
  - `schema_version`
  - `project_id`
  - `features[]`
  - `features[].id`
  - `features[].scope`
  - `features[].status`
  - `features[].depends_on`
  - `features[].touches`
  - `features[].touches_shared`
  - `features[].product`
  - `features[].external_refs`
  - `features[].path`
- Les champs non contractuels doivent être nommés et exclus des assertions byte-identiques.

## Validation

- Test unitaire : deux builds successifs produisent une représentation contractuelle identique.
- Test unitaire : ordre stable des features, quel que soit l'ordre `find`.
- Test unitaire : stdout ne modifie pas le repo.
- Test unitaire : `--write` écrit via lock et sortie atomique.
- Test fallback sans `yq` ou décision explicite que certains champs avancés exigent `yq`.
- Validation Copier : template source et rendu restent synchronisés.

## Droits / accès

Non requis.

Le script ne doit pas demander d'accès externe, réseau ou secret. Les effets d'écriture se limitent au cache repo-local explicitement demandé.

## Données

- Entrée : frontmatter des fiches `.docs/features/**/*.md`.
- Sortie : JSON stdout et cache `.ai/.feature-index.json`.
- Données sensibles : aucune attendue.
- Compatibilité : les projets downstream peuvent avoir des fiches anciennes ou des champs inconnus ; le contrat doit rester tolérant aux propriétés additionnelles.

## UX

La developer experience attendue est une commande prévisible :

- sans option : inspection/sortie non mutante ;
- avec `--write` : cache écrit explicitement ;
- erreurs et warnings suffisamment précis pour corriger une fiche.

## Observabilité

Non requis comme observabilité runtime.

Les signaux utiles sont les tests, warnings explicites et messages d'erreur du script.

## Déploiement / rollback

- Release N : introduire le contrat v2, documenter les différences et garder compat si possible.
- Release N+1 : migrer les consommateurs internes vers le contrat v2.
- Release N+2 : retirer les chemins legacy si aucun consommateur interne ne les utilise.
- Rollback : conserver la possibilité de reconstruire l'ancien cache pendant la période de transition si le format change de façon visible.

## Risques

- Un consommateur downstream peut parser directement `.ai/.feature-index.json`.
- Le champ `generated_at` peut rendre les tests de déterminisme trompeurs.
- Un fallback incomplet sans `yq` peut produire des rapports product ou review faux.
- Les changements dans `_lib.sh` peuvent impacter plusieurs scopes.

## Cross-refs

- `core/feature-index-cache` : contrat historique à remplacer ou préciser.
- `core/feature-mesh` : source des données indexées.
- `quality/index-lock-contract` : mécanisme de lock atomique.
- `product/ai-context-stability-migration` : initiative de stabilisation et migration.

## Historique / décisions

- 2026-05-14 : création suite à l'initiative `product/ai-context-stability-migration`.
- 2026-05-14 : décision de traiter le contrat d'index avant la généralisation des commandes read-only.
- 2026-05-14 : première implémentation core. Tri stable des fiches avant agrégation, comparaison contractuelle via `del(.generated_at)` avant écriture du cache, et test `tests/unit/test-build-feature-index-contract.sh` couvrant stdout non mutant, ordre stable, contrat stable et `--write` idempotent.
- 2026-06-29 : **`schema_version` opérationnalisé** (item C2c du frame de remédiation `2026-06-28-audit-strategique-remediation`). Avant : version littérale `"1"` + smoke `== "1"` → la pression du test décourageait tout bump (audit : « version gérée par évitement »). Après : `test-build-feature-index-contract.sh` snapshotte les clés top-level/feature/progress **couplées à la version** ; un changement de clés échoue tant que version + snapshot ne sont pas mis à jour ensemble (incitation **inversée**). Smoke relâché en présence-seule. Vérifs : contract test ✅, smoke ✅. **Restent hors scope index-contract-v2** : C2a (appliquer le schéma JSON) + C2b (réconcilier la divergence `id`/`depends_on` schema↔checker — schéma kebab-strict vs checker tolérant underscore, 0 fiche en violation) — touchent `check-features.sh` (scope `feature-mesh`), à router en feature d'alignement schema/checker.
- 2026-06-29 : **C2a tranché — clarification du rôle, pas de validateur** (closing du frame de remédiation). C2b a été livré séparément (`core/feature-mesh`, commit `57c7691`). Pour C2a : décision de **ne pas** introduire de dépendance de validation JSON-Schema (ajv/check-jsonschema) — contraire à l'éthos bash/jq/yq, et non vérifiable dans l'env courant. Le schéma **n'est pas décoratif** : il dérive les enums + le pattern `id` (appliqués par `check-features.sh`). Fix honnête : ajout d'un `$comment` dans `feature.schema.json` (runtime + template, parité) précisant ce rôle réel, pour qu'il ne *promette* pas une validation full qu'il n'exécute pas. Les trois « contrats qui mentent » de l'audit sont clos : `id` aligné (C2b), `schema_version` opérationnel (C2c), rôle du schéma explicite (C2a-doc).
- 2026-07-03 : fiche clôturée en `done`. Le contrat v2 de l'index est stable : sortie stdout non mutante, cache `--write` idempotent, snapshot de clés couplé à `schema_version`, C2a clarifié et C2b traité dans `core/feature-mesh`. Doc Impact Decision : C — fiche feature et worklog mis à jour.
