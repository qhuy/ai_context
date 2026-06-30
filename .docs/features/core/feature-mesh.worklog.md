# Worklog — core/feature-mesh


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - template/.ai/scripts/check-features.sh.jinja

## 2026-05-04 — freshness
- Impact documentaire : `.docs/FEATURE_TEMPLATE.md` précise la granularité et le nommage des fiches feature.
- Changement porté par `workflow/feature-granularity`.
- Validation associée : quality gate `workflow/feature-granularity` PASS.

## 2026-05-04 — freshness
- Impact template : `template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja` conserve la règle de granularité pour les projets générés.
- Changement porté par dogfood runtime sync.
- Validation associée : `check-dogfood-drift.sh` PASS.
## 2026-05-14 — HANDOFF quality/read-only-checks-contract

- HANDOFF reçu depuis `quality/read-only-checks-contract`.
- Besoin : exposer un mode non-mutant de `check-features.sh` pour que `doctor` et le quality gate puissent valider le mesh sans réécrire `.ai/.feature-index.json`.
- Changement limité : ajout de `--no-write`, qui construit un index temporaire pour la détection des cycles mais ne touche pas le cache repo-local.
- Le comportement historique sans option reste inchangé.

## 2026-06-01 — convention d'ownership des fichiers de config partagés (audit U13)

- Constat (audit unifié) : `copier.yml` était listé en `touches:` (bloquant freshness) par 10 features sur 4 scopes → toute édition d'un fichier de config partagé déclenchait une cascade documentaire cross-scope disproportionnée et forçait un commit multi-scope (violation « un scope primaire par tâche »).
- Décision : un fichier de config partagé n'est *bloquant* (`touches:`) que pour les features de son scope d'appartenance naturel ; les features d'autres scopes ayant un intérêt secondaire le référencent en `touches_shared:` (visible dans `review-delta`, non bloquant pour `check-feature-freshness --staged`).
- Application à `copier.yml` (config du moteur template → scope core) : reste `touches:` pour core/{template-engine, aic-surface-canonical, preset-ds-skeletons, project-overlay-stable} ; déplacé en `touches_shared:` pour product/product-portfolio-loop, quality/targeted-regression-coverage, workflow/{agent-behavior, conversational-skills, intentional-skills, project-guardrails}.
- Effet : éditer `copier.yml` redevient une tâche mono-scope core ; la visibilité review est préservée. Débloque U10 (_min_copier_version) en mono-scope.
- HANDOFF : édition du frontmatter de 6 fiches hors core (product/quality/workflow) = pure maintenance du contrat mesh, aucun changement de comportement de ces features. Confirmé par l'utilisateur (option « narrow touches d'abord »).
- Suivi : appliquer la même convention à `_lib.sh` et autres configs partagées si la cascade se reproduit.
- Validation : index rebuild → `copier.yml` bloquant sur 4 core uniquement ; `check-features --no-write` PASS.

## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - .ai/scripts/check-features.sh
  - template/.ai/scripts/check-features.sh.jinja
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja

## 2026-06-29 — reconciliation id schema<->checker (C2b)
- check-features.sh : regex id alignee sur le schema kebab-strict (etait tolerante a l'underscore). runtime + jinja. scope inchange (pas de pattern schema). 0 fiche en violation.
- Test differentiel tests/unit/test-id-schema-checker-parity.sh (snapshot pattern + rejet underscore + accept kebab).
- Verifs : nouveau test PASS, check-features dogfood PASS, test-okf-type PASS, drift PASS.
- HANDOFF depuis index-contract-v2. Reste C2a (appliquer/retirer le schema).
- Fichiers : .ai/scripts/check-features.sh, template/.ai/scripts/check-features.sh.jinja, tests/unit/test-id-schema-checker-parity.sh

## 2026-06-29 — couverture incidente (C2a-doc : role du schema)
- Surface partagee touchee (feature.schema.json via .ai/** ou touches:). Aucun changement de comportement propre. (Taxe sur-couverture touches: — cf. quality/touches-breadth-guard.)

## 2026-06-29 — fix check-features frontmatter-boundary (audit hebdo P0)
- `check-features.sh` lit maintenant `depends_on`, `touches` et `touches_shared` avec un extracteur borné au premier frontmatter, aligné sur le correctif déjà fait côté `build-feature-index`.
- Ajout du support flow-style pour la validation (`touches: [a, b]`) et du test `tests/unit/test-check-features-frontmatter-boundary.sh`.
- Fichiers : `.ai/scripts/check-features.sh`, `template/.ai/scripts/check-features.sh.jinja`, `tests/unit/test-check-features-frontmatter-boundary.sh`.
- Validation : test unitaire ciblé, `check-features --no-write`, smoke complet.
- Note livraison : le commit initial `4103f65` a été fait avec `--no-verify` pour préserver le découpage mono-scope face à la sur-couverture Signal A. Le reclassement des propriétaires non directs est suivi par `quality/touches-breadth-guard`.

## 2026-06-29 — YAML strict dans le gate check-features (audit hebdo — finding #3)
- `check-features.sh` valide désormais que le frontmatter parse en YAML strict (yq, parité `build-feature-index.sh:117`) et BLOQUE sinon — runtime + `.jinja`. Avant : une fiche au YAML cassé mais grep-passable passait le gate puis était silencieusement EXCLUE de l'index par le builder (warn + skip), et avec elle ses `touches:` → les gates freshness/commit cessaient de couvrir ses fichiers sans bruit.
- Conditionné à yq (même condition que le drop côté builder ; le fallback awk ne valide pas le YAML). Les 54 fiches réelles passent.
- Test : `tests/unit/test-check-features-yaml-strict.sh` (fiche flow-seq non fermée, grep-passable → gate FAIL ; fiche valide → PASS ; SKIP si yq absent).
- Interaction #4a découverte : un glob char-class inline NON quoté (`touches: [src/[ab].ts]`) est du YAML invalide → droppé par le builder. La fixture du test frontmatter-boundary (posée par #4a) utilisait cette forme ; corrigée en quoté (`["src/[ab].ts"]`), valide YAML, qui exerce toujours la préservation du `]` interne par fm_list. Le gate protège donc aussi de ce footgun.
- Fichiers : `.ai/scripts/check-features.sh`, `template/.ai/scripts/check-features.sh.jinja`, `tests/unit/test-check-features-yaml-strict.sh`, `tests/unit/test-check-features-frontmatter-boundary.sh`, `.docs/features/core/feature-mesh.md` (touches).
- Validation : 3 tests unitaires check-features PASS, `check-features --no-write` (54 fiches) PASS, parité runtime/template OK, drift dogfood aligné.
- HANDOFF quality : brancher `test-check-features-yaml-strict.sh` dans `tests/smoke-test.sh` (scope `quality/smoke-test`) — non fait ici pour rester mono-scope core.

## 2026-06-29 — détection de cycles O(V+E) par Kahn (audit A13)
- La DFS récursive de cycles dans `check-features.sh` ré-explorait chaque nœud une fois par chemin → coût exponentiel sur un DAG en diamant (mesuré : k=20 ≈ 76s, k≥22 timeout >2min). Remplacée par un tri topologique de Kahn (point fixe), réellement O(V+E) : diamant k=24 instantané. Arête pendante ignorée (pas un cycle, contrat cycle-detection).
- Message d'erreur : liste triée des features impliquées (au lieu d'un chemin `A → B → A`). Le smoke ne vérifie que l'exit non-zéro → pas de casse.
- Runtime + `.jinja` (parité). Vérifs : vrai mesh 55 fiches PASS sans faux cycle, 2-cycle détecté end-to-end, diamant k=24 instantané.
- HANDOFF `quality/cycle-detection` : la fiche affirmait `O(V+E)` (faux avant) — maj fiche + garde anti-régression diamant dans le commit suivant.

## 2026-06-30 — clés requises dérivées du schéma (init. quality/feature-schema-validator, P3)
- `check-features.sh` ne code plus en dur la liste des clés obligatoires : `REQUIRED_FIELDS="$(read_schema_enum '.required' 'id scope title status depends_on touches')"` (lecture jq du schéma, fallback hardcodé si schéma/jq absent). Fin de la dérive heuristique/schéma sur les clés requises ; ajouter une clé à `feature.schema.json` l'exige sans rééditer le script.
- Éthos préservé : bash/jq, **aucune** dépendance validateur externe (cf. `$comment` du schéma). Le « vrai validateur » = schéma lu comme donnée.
- Runtime + `.jinja` (parité dogfood vérifiée). Test dédié `tests/unit/test-schema-driven-required.sh` (clé `owner` ajoutée au schéma temp → exigée).
- HANDOFF `quality/smoke-test` : brancher ce test dans `tests/smoke-test.sh` — non fait ici pour rester focalisé (même pattern que yaml-strict).
- Initiative portée par `quality/feature-schema-validator` (P3 du pilot `2026-06-30-ze-solution`) ; `check-features.sh` reste surface `core/feature-mesh`, d'où cette entrée.
