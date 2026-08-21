---
id: feature-intent-retrieval
scope: core
title: Récupération des fiches par intention
keywords:
  - retrouver une fiche
  - recherche par mots-clés
  - point d'entrée intent
  - fiche introuvable
  - capitalisation de connaissance
status: active
depends_on:
  - core/index-contract-v2
  - core/feature-index-cache
  - workflow/pre-turn-reminder
touches:
  - .ai/scripts/features-search.sh
  - template/.ai/scripts/features-search.sh.jinja
  - .docs/features/core/feature-intent-retrieval.md
  - .docs/features/core/feature-intent-retrieval.worklog.md
  - tests/unit/test-features-search.sh
touches_shared:
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
  - .ai/scripts/check-features.sh
  - template/.ai/scripts/check-features.sh.jinja
  - .ai/scripts/pre-turn-reminder.sh
  - template/.ai/scripts/pre-turn-reminder.sh.jinja
  - .ai/schema/feature.schema.json
  - template/.ai/schema/feature.schema.json
  - .ai/index.md
  - template/.ai/index.md.jinja
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - tests/unit/test-build-feature-index-contract.sh
  - tests/unit/test-surface-manifest.sh
  - tests/smoke-test.sh
  - docs/variables.md
  - CHANGELOG.md
  - .docs/FEATURE_TEMPLATE.md
  - template/{{docs_root}}/FEATURE_TEMPLATE.md.jinja
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: review
  step: "retour Claude challengé : nudge keywords et preuves de robustesse renforcés"
  blockers: []
  resume_hint: "vérifier la mesure de reprise côté dépôt consommateur après copier update"
  updated: 2026-08-21
type: feature
---

# Récupération des fiches par intention

## Résumé

`.ai/index.md` annonce deux déclencheurs de chargement des fiches feature — « l'intent ou les
paths ». Seul le déclencheur `paths` est outillé (`features-for-path.sh`). Cette feature outille le
déclencheur `intent` pour qu'une fiche existante soit retrouvée quand l'utilisateur formule sa
demande en vocabulaire métier, sans connaître ni le chemin ni l'id.

## Objectif

Supprimer le coût de ré-investigation d'un sujet déjà documenté. Une session neuve doit pouvoir
retrouver la fiche pertinente à partir des mots de l'utilisateur, par un mécanisme prescrit, pas par
une déduction d'agent sur la proximité lexicale d'un id.

## Périmètre

### Inclus

- Indexation de `title` (déjà requis par le schema, jusqu'ici jeté à l'indexation) et d'un champ
  optionnel `keywords` dans `.ai/.feature-index.json`.
- `features-search.sh` : recherche par mots sur id, title et keywords, pendant `intent` de
  `features-for-path.sh`.
- Affichage du titre dans l'inventaire injecté par `pre-turn-reminder.sh`.
- Prescription explicite du point d'entrée intent dans la section *On Demand* de `.ai/index.md`.
- Nudge de rédaction : le modèle crée `keywords: []` et `check-features.sh` avertit tant que
  l'auteur n'a pas renseigné le vocabulaire métier ou retiré explicitement la clé.
- Parité runtime/template et mise à jour du snapshot de clés du contrat d'index.

### Hors périmètre

- Recherche sémantique ou embeddings : le mécanisme reste lexical et déterministe.
- Extension du hook `PreToolUse` aux outils de lecture : ne résout pas le premier message, où aucun
  path n'est encore connu.
- Activation du knowledge hub : hors sujet pour la récupération de fiches feature.
- Rédaction rétroactive de `keywords` sur toutes les fiches existantes : le champ est optionnel et se
  remplit à la touche.

## Comportement attendu

- `bash .ai/scripts/features-search.sh <mots>` liste les fiches dont l'id, le titre, les
  `keywords` ou le scope contiennent les mots demandés, classées par nombre de termes couverts,
  avec un bonus pour les termes trouvés dans le vocabulaire humain (titre, keywords) plutôt que
  dans l'id seul.
- Tous les statuts sont cherchés par défaut, `done` compris. `--status active,draft` restreint.
- Les diacritiques latin-1 courants sont repliés : `telechargement` et `téléchargement` matchent
  le même haystack.
- Les termes de deux caractères ou moins matchent un mot entier : les acronymes `UI`, `UX`, `RH`,
  `IA`, `IT`, `BI` et `QA` ne matchent pas des fragments comme « guidé » ou « audit ».
- Avec `yq` + `jq`, une fiche dont `keywords` est mal typé est bloquée par `check-features.sh`.
  Le fallback sans `yq` bloque au moins les scalaires et types non-string inline évidents.
  L'indexeur normalise avec warning et le consommateur ignore défensivement toute valeur résiduelle
  fautive : les autres fiches restent cherchables.
- Un `keywords: []` explicite reste valide et produit un warning de décision ; l'absence de la clé
  reste silencieuse pour préserver les fiches existantes.
- L'inventaire injecté par `pre-turn-reminder.sh` affiche désormais le titre de chaque feature
  visible, et pointe vers la recherche par intention pour les fiches masquées.

## Invariants

- L'index reste la seule source : aucune lecture du corps markdown des fiches, aucun listing de
  dossiers, aucun `rg` à l'aveugle.
- L'index est reconstruit avant recherche si une fiche est plus récente que lui — même politique de
  fraîcheur que `pre-turn-reminder.sh`.
- `keywords` est optionnel : une fiche sans `keywords` reste valide, indexable et trouvable par son
  titre.
- Une violation de type sur `keywords` dégrade uniquement le rappel de la fiche fautive, jamais le
  service de recherche complet.
- La recherche est lexicale et déterministe : deux exécutions sur le même index donnent le même
  classement.

## Contrats

- Ajout de champs rétro-compatible dans `.ai/.feature-index.json` : MINOR, `schema_version` reste
  `"1"`, conformément à la politique documentée dans `build-feature-index.sh`. Le snapshot de clés
  de `tests/unit/test-build-feature-index-contract.sh` est mis à jour en conséquence.
- `features-search.sh` sort en code 0 si au moins une fiche matche, 1 sinon : utilisable en garde
  dans un script appelant.
- Pour les listes block-style supportées, le fallback sans `yq` doit produire les mêmes
  `title`/`keywords` que le chemin `yq`, apostrophes comprises — d'où
  `extract_text_scalar_awk` / `extract_text_list_awk`, qui ne strippent que les quotes englobantes,
  là où `extract_scalar_awk` reste réservé aux valeurs kebab-case.
- La route `aic search` reste classée `interne` et non contractuelle jusqu'à mesure du rappel sur un
  corpus consommateur. Le point d'entrée prescrit et stable pendant l'expérimentation est le script
  `bash .ai/scripts/features-search.sh <mots>`.

## Décisions

- **Enrichir l'index plutôt qu'étendre le hook `PreToolUse` aux outils de lecture.** Le hook ne se
  déclenche qu'avec un chemin déjà connu ; il ne peut donc pas servir de point d'entrée au premier
  message d'une session.
- **Ne pas passer par le knowledge hub.** `knowledge.sh search` fait un `contains` littéral et exige
  un hub qui n'existe pas dans les dépôts consommateurs ; il vise la connaissance publiée, pas les
  fiches feature.
- **Chercher tous les statuts par défaut.** La connaissance capitalisée vit dans les fiches `done`,
  que l'inventaire pre-turn masque ; les exclure reproduirait le trou que la feature comble.
- **Rester lexical, pas sémantique.** L'éthos du repo est bash/jq/yq sans dépendance ajoutée ; le
  rappel se paie en rédaction de `keywords`, pas en runtime.

## Validation

- `bash tests/unit/test-features-search.sh` — recherche métier sur fiche `done`, repli des
  diacritiques, code 1 sans résultat, `--status`/`--limit`/`--json`, `keywords` scalaire et
  `[123]`, index pré-corrompu, nudge `keywords: []`, acronymes courts exacts seuls ou dans une
  requête mixte, et parité du fallback sans `yq`.
- `bash .ai/scripts/check-features.sh --no-write` — type de `keywords` validé à l'écriture.
- `bash tests/unit/test-build-feature-index-contract.sh` — snapshot de clés mis à jour, MINOR sans
  bump de `schema_version`.
- `bash tests/unit/test-build-feature-index-fallback.sh`,
  `bash tests/unit/test-build-feature-index-fallback-frontmatter.sh`,
  `bash tests/unit/test-build-feature-index-robust.sh` — non-régression du parseur après
  l'extraction de `extract_list_awk_raw`.
- `bash .ai/scripts/check-dogfood-drift.sh` — parité runtime/template.

## Déploiement / rollback

- **Déploiement consommateur** : `copier update` puis reconstruction de l'index
  (`bash .ai/scripts/build-feature-index.sh --write`). Aucun champ obligatoire ajouté, donc aucune
  fiche existante à migrer.
- **Effet immédiat sans rédaction** : les titres deviennent cherchables dès la reconstruction de
  l'index, puisque `title` est déjà requis par le schema.
- **Rollback** : retirer la route interne, `features-search.sh` et les deux champs de l'index. Les fiches portant des
  `keywords:` restent valides — `additionalProperties: true` dans le schema — donc le rollback ne
  casse aucune fiche déjà rédigée.

## Risques

- Coût contexte de l'inventaire pre-turn, re-mesuré après les corrections dans le worktree isolé :
  69 fiches, dont 3 `active|draft`. Les titres ajoutent 148 octets en affichage par défaut et
  3713 octets avec tous les statuts ; la sortie pre-turn complète mesure respectivement 1473 et
  7278 octets. Commandes : `jq '[.features[] | select(.status == "active" or .status == "draft") | 5 + (.title | utf8bytelength)] | add' .ai/.feature-index.json`, même expression sans `select` pour tous les statuts, puis `bash .ai/scripts/pre-turn-reminder.sh | wc -c` et `AI_CONTEXT_SHOW_ALL_STATUS=1 bash .ai/scripts/pre-turn-reminder.sh | wc -c`. Sur un mesh à forte proportion de features actives, utiliser `AI_CONTEXT_FOCUS=<scope>`.
- Couverture métier initiale limitée : les 69 fiches ont un titre, deux portent désormais des
  `keywords` non vides (`jq` sur `.ai/.feature-index.json`). Le bénéfice sur les synonymes historiques
  reste à confirmer et à enrichir à partir de requêtes réelles, pas de requêtes écrites après coup.
- La recherche reste lexicale : une fiche sans `keywords` métier et nommée d'après le code reste
  difficile à retrouver. Le champ est le remède, son remplissage est une discipline de rédaction.
- La prescription en prose peut être ignorée : la première fiche retouchée après livraison de la
  recherche n'a pas reçu ses `keywords`. Le modèle et le checker portent désormais un nudge
  mécanique et explicite, sans rendre le champ obligatoire pour les 69 fiches existantes.

## Historique / décisions

- 2026-08-20 — constat remonté depuis un dépôt consommateur au template `v1.0.1-6-g06bbbbc` :
  `.ai/index.md` annonce « l'intent ou les paths », seul `paths` est outillé. Vérifié sur HEAD
  `06bbbbc`.
- 2026-08-20 — après review contradictoire, la route `aic.sh search` reste disponible mais classée
  `interne`, hors manifeste stable, jusqu'à une mesure de rappel non circulaire sur corpus réel.
- 2026-08-20 — robustesse : `keywords` scalaire reproduit un plantage jq global ; le checker le
  bloque désormais, l'indexeur le normalise avec warning et le consommateur se protège d'un ancien
  index. Les acronymes courts utilisent une égalité de token.
- 2026-08-20 — arbitrage : enrichir l'index (`title` déjà présent dans toutes les fiches mais jeté à
  l'indexation, plus `keywords` optionnel) et prescrire `features-search.sh`, plutôt qu'étendre le
  hook aux outils de lecture ou activer le knowledge hub.
- 2026-08-21 — retour contradictoire : la feature `session-injection-dedup` précédait ce commit dans
  l'historique Git, mais sa première retouche postérieure a bien ignoré la prescription. Décision :
  conserver `keywords` optionnel et ajouter un nudge mécanique (`keywords: []` dans le starter,
  warning tant que la décision n'est pas prise), puis verrouiller les cas scalaire, `[123]` et index
  déjà corrompu dans le test de recherche.
