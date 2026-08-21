---
id: feature-index-cache
scope: core
title: Cache JSON déterministe du feature mesh
status: done
depends_on:
  - core/feature-mesh
touches:
  - .ai/scripts/build-feature-index.sh
  - template/.ai/scripts/build-feature-index.sh.jinja
  - template/.ai/scripts/_lib.sh.jinja
  - .ai/scripts/_lib.sh
  - .ai/.gitignore
  - template/.ai/.gitignore
  - tests/smoke-test.sh
  - template/.ai/scripts/pr-report.sh.jinja
  - .ai/scripts/pr-report.sh
  - tests/unit/test-build-feature-index-robust.sh
  - tests/unit/test-build-feature-index-fallback-frontmatter.sh
  - .docs/features/core/feature-index-cache.md
  - .docs/features/core/feature-index-cache.worklog.md
progress:
  phase: done
  step: ""
  blockers: []
  resume_hint: "feature clôturée le 2026-08-21"
  updated: 2026-08-21
type: feature
---

# Cache JSON du feature mesh

## Résumé

`build-feature-index.sh` agrège les frontmatter de toutes les fiches en un cache `.ai/.feature-index.json` déterministe et gitignoré, pour que les hooks d'injection consomment le mesh sans reparser le markdown à chaque appel.

## Objectif

Éviter de re-parser le markdown à chaque appel de hook : `build-feature-index.sh` agrège tous les frontmatter en un `.ai/.feature-index.json` reconstruit déterministiquement, gitignoré.

## Périmètre

### Inclus

- L'agrégation des frontmatter (`id`, `scope`, `title`, `keywords`, `status`, `type`, `depends_on`, `touches`, `touches_shared`, `product`, `external_refs`, `progress`, `path`) dans une **enveloppe** JSON `{schema_version, project_id, generated_at, features[]}`. `title` et `keywords` servent au consommateur de récupération par intention.
- Le parsing YAML (`yq v4` si dispo, fallback awk/sed bash 3.2) et l'échappement JSON sûr via `jq -nc --arg`.
- Le verrou atomique `mkdir` autour de l'écriture du cache, le témoin volatil de dernier scan réussi et le rebuild on-demand des consommateurs.
- Les deux variantes maintenues en parallèle : runtime dogfoodé (`.ai/scripts/build-feature-index.sh`) et gabarit Copier (`.jinja`), plus les helpers de matching partagés dans `_lib.sh`.

### Hors périmètre

- La détection de cycles dans `depends_on` (portée par `cycle-detection`, exécutée en validation post-build).
- La sémantique de blocage cross-scope et les checks de cohérence du mesh (portés par `feature-mesh` / `check-features.sh`).
- Le rendu métier du cache par les consommateurs downstream (`pre-turn-reminder`, `features-for-path`, `features-search`, `resume-features`). Leur décision commune de fraîcheur appartient en revanche au présent contrat.

## Comportement attendu

- Trigger : `post-checkout` git hook + `pre-turn-reminder` (rebuild si manquant).
- Lecture YAML via `yq v4` si dispo, sinon fallback awk/sed (bash 3.2 compatible).
- Échappement JSON sûr (paths avec quotes/backslashes via `jq -nc --arg`).
- Lock atomique `mkdir` (pas `flock`, portable macOS).
- Après chaque scan `--write` réussi, `.ai/.feature-index.checked` avance même si la projection JSON est identique. Les consommateurs comparent les fiches à ce témoin ; s'il manque, ils retombent sur le mtime de l'index.

## Invariants

- Deux builds successifs sans changement de source **ne réécrivent pas le fichier** `.ai/.feature-index.json` (mtime stable) : l'ordre des features est déterministe et le contrat est comparé hors `generated_at`. La sortie **stdout**, elle, diffère d'un run à l'autre par `generated_at` — l'idempotence porte sur le fichier écrit, pas sur le flux.
- Un `--write` réussi publie séparément `.ai/.feature-index.checked`, y compris quand seul le corps d'une fiche a changé et que la projection JSON reste identique. Ce témoin n'altère ni le mtime du JSON ni son `generated_at`.
- Une fiche au frontmatter invalide est exclue avec warning mais n'arrête jamais le build (cache toujours produit).
- Un `keywords` bien formé en YAML mais contraire au schéma est normalisé en tableau sûr avec warning ; la fiche reste indexée et les autres consommateurs restent disponibles.
- Les paths contenant quotes/backslashes sont échappés sûrement (`jq -nc --arg`), jamais concaténés à la main.
- Le cache et son témoin restent gitignorés et reconstructibles : aucune source de vérité ne vit dans `.feature-index.json` ni `.feature-index.checked`.
- Les helpers de matching `touches:` sont centralisés dans `_lib.sh` ; runtime et gabarit `.jinja` partagent la même sémantique.

## Décisions

- Cache pré-agrégé plutôt que reparsing à chaque hook : le coût markdown est payé une fois au `post-checkout`.
- Verrou `mkdir` plutôt que `flock` : portable sur macOS où `flock` est absent.
- `yq v4` privilégié quand présent, fallback awk/sed pour rester exécutable sous bash 3.2 (macOS système).
- Matching `touches:` direct volontairement séparé de `touches_shared` : `features_matching_path` reste limité aux touches directs pour préserver la sémantique bloquante.
- Objets `product` et `external_refs` optionnels et inertes par défaut : les scripts read-only les exploitent sans imposer de reparsing spécifique.
- Témoin séparé plutôt que `touch` du JSON : le contrat d'idempotence du fichier reste vrai, tandis qu'un changement de source sans effet sur la projection n'entraîne qu'un seul rebuild. Le helper central `feature_docs_newer_than` utilise le témoin lorsqu'il accompagne `.feature-index.json`, ce qui aligne les quatre consommateurs sans dupliquer la règle.

## Contrats

- Sortie : enveloppe JSON typée
  - `schema_version` (string), `project_id` (string), `generated_at` (string ISO-8601 UTC), `features` (array) ;
  - par feature : `id`, `scope`, `title`, `status`, `type`, `path` (string) ; `keywords`, `touches`, `touches_shared`, `depends_on` (array) ; `product`, `external_refs`, `progress` (object) ;
  - `progress` : `phase`, `step`, `resume_hint`, `updated` (string), `blockers` (array).
  Aucune clé n'est émise à `null` : les champs absents du frontmatter reçoivent leur valeur vide typée (`[]`, `{}`, `""`).
- Idempotent au niveau du fichier : deux `--write` successifs sans changement laissent `.ai/.feature-index.json` intact (comparaison hors `generated_at`). La sortie stdout varie par `generated_at`.
- Fraîcheur : `.ai/.feature-index.checked` est un fichier vide, volatil et reconstructible, publié après chaque `--write` réussi sous le même verrou que l'index. Son absence est compatible avec les dépôts existants : la référence redevient `.ai/.feature-index.json` jusqu'au prochain rebuild.
- Lecture : quand `feature_docs_newer_than` reçoit `.ai/.feature-index.json`, il compare les fiches à `.ai/.feature-index.checked` si ce témoin existe ; les autres références conservent leur sémantique historique.
- Tolérance : feature au frontmatter invalide → exclue + warning, pas d'arrêt.
- Tolérance typée : `keywords` invalide → warning + normalisation locale, sans arrêt du build.

## Validation

- Idempotence : deux `build-feature-index.sh --write` consécutifs laissent le fichier inchangé ; le contrat stdout est stable hors `generated_at` (couvert par `tests/unit/test-build-feature-index-contract.sh`, qui compare aussi le jeu de clés émises à un snapshot couplé à `schema_version`).
- Fraîcheur sans boucle : après une édition du seul corps d'une fiche, le premier des quatre consommateurs reconstruit et avance le témoin ; les trois suivants ne relancent pas le build. Le mtime du JSON et son `generated_at` restent stables (couvert dans le projet généré par `tests/smoke-test.sh`).
- Échappement : une fiche dont un `touches:` contient quote/backslash produit un JSON valide (`jq .` ne lève pas d'erreur).
- Tolérance : une fiche au frontmatter invalide est exclue avec warning sans faire échouer le build.
- Parité runtime/gabarit : le smoke-test rejoue `copier copy` puis vérifie que le script généré (`.jinja`) produit le même cache que le runtime dogfoodé.
- Validation post-build du mesh déléguée à `cycle-detection`.

## Cross-refs

- Source consommée par tous les hooks d'injection (`pre-turn-reminder`, `features-for-path`, `resume-features`).
- Validation post-build via `cycle-detection`.

## Historique / décisions

- 2026-08-21 : un changement du corps d'une fiche rendait l'index éternellement « stale » lorsque le frontmatter projeté restait identique : `write_index` préservait correctement le JSON, mais aucun état ne mémorisait le scan réussi. Décision : ajouter le témoin volatil `.ai/.feature-index.checked`, séparé du contrat JSON et consommé par le helper de fraîcheur commun. Le schéma JSON, son mtime idempotent et `generated_at` restent inchangés.
- 2026-08-20 : `core/feature-intent-retrieval` ajoute `title` et `keywords` au contrat d'index afin de permettre la recherche par vocabulaire humain. Cette décision remplace explicitement la conclusion historique du 2026-07-24 selon laquelle `title` n'avait aucun consommateur. Un `keywords` mal typé est normalisé avec warning pour préserver la disponibilité globale.
- 2026-07-24 (v1.0, chantier B7 du gel P16) : **fiche réconciliée avec la sortie réelle**, sur les 4 points relevés par la review Codex round 3. (a) `title` était promis dans Périmètre et Contrats mais n'est **pas** émis par `build-feature-index.sh` — vérifié par `jq keys` sur l'index réel, 11 clés dont aucune `title` ; retiré et justifié (utile à la lecture humaine, inutile aux consommateurs). (b) « tableau JSON » remplacé par l'enveloppe réelle `{schema_version, project_id, generated_at, features[]}`. (c) L'invariant « JSON byte-identique, pas de timestamp » était faux dans les deux moitiés : il Y A un timestamp (`generated_at`) et l'idempotence porte sur le **fichier** (non réécrit quand le contrat est inchangé), pas sur stdout — vérifié empiriquement : deux runs stdout diffèrent d'une seconde sur `generated_at`, deux `--write` laissent le mtime stable. (d) Contrats enrichi des **types et nullabilités** par clé (exigence de l'élément 5 du contrat v1.0), dont le fait qu'aucune clé n'est émise à `null` (valeur vide typée à la place, constaté sur les 67 fiches).
- v0.7.2 : fix bug silencieux d'escaping JSON (paths avec quotes corrompaient le JSONL).
- 2026-04-24 : centralisation du matching `touches:` dans `_lib.sh` (`path_matches_touch` + `features_matching_path`). Les hooks/scripts consommateurs partagent désormais la même sémantique exact/dossier/glob/`/**`.
- 2026-04-24 : `AI_CONTEXT_DOCS_ROOT` et `AI_CONTEXT_FEATURES_DIR` ajoutés dans `_lib.sh` pour que les scripts runtime suivent le `docs_root` rendu par Copier au lieu de réencoder `.docs/features`.
- 2026-04-28 : ajout `is_valid_phase()` dans `.ai/scripts/_lib.sh` (dogfoodé) **et** `template/.ai/scripts/_lib.sh.jinja` (la doc d'en-tête le promettait déjà via `PHASE_ENUM`). Suppression de la définition locale dupliquée dans `template/.ai/scripts/check-features.sh.jinja`. Aucun changement de comportement runtime — la fonction délègue à `PHASE_ENUM` (lui-même dérivé du schema). Smoke-test [11/28] couvre toujours le warning `progress.phase='typo'`.
- 2026-05-03 : index enrichi avec `touches_shared` et helpers `_lib.sh` dédiés (`features_matching_shared_path`, `features_related_to_path`). `features_matching_path` reste volontairement limité aux `touches` directs pour préserver la sémantique bloquante.
- 2026-05-03 : index enrichi avec l'objet optionnel `product` afin que les scripts read-only puissent calculer status, portfolio et review sans reparsing spécifique.
- 2026-05-04 : index enrichi avec l'objet optionnel `external_refs` pour exposer les liens BMAD, Spec Kit, tickets ou docs externes aux rapports et outils downstream.
- 2026-06-26 : **fix robustesse** — l'invariant « fiche invalide exclue + warning, build jamais arrêté » (déjà documenté) n'était PAS implémenté côté `yq` : un frontmatter YAML malformé (ex. titre non quoté finissant par `:`) faisait planter `build-feature-index` et, en cascade, tous les hooks qui l'appellent (`features-for-path`, `pre-turn-reminder`, auto-worklog…), bloquant toute édition. Fix : validation `yq -e` du frontmatter AVANT extraction (warn + `return 1` si illisible) + isolation par fiche dans la boucle (`if entry=$(feature_to_json …)`), sous `set -e`. Le fallback awk était déjà tolérant. Test : `tests/unit/test-build-feature-index-robust.sh`. `check-features` reste le validateur strict (signale + exit 1, sans cascade).
- 2026-06-28 : **fix fallback body-leak** (item A1 du frame `2026-06-28-audit-strategique-remediation`). Le parseur sans `yq` (`extract_scalar_awk` / `extract_list_awk`) scannait le fichier ENTIER, pas le frontmatter : un `status:` / `depends_on:` / `touches:` présent dans le corps markdown injectait de fausses valeurs dans l'index — bien formé, sans signal, sur tout environnement sans yq (CI nue, conteneur), polluant injection contextuelle, détection de cycles et rapports. Les deux extracteurs sont désormais **bornés au 1er bloc `---...---`**, et `extract_list_awk` gère aussi le **flow-style** (`touches: [a, b]`, auparavant vidé en fallback). Parité jinja conservée (aucun hazard `{% raw %}`). Test : `tests/unit/test-build-feature-index-fallback-frontmatter.sh`. Résiduel documenté (risque moindre, champs reports/best-effort) : les awk inline `product` scalaires, `external_refs` et `progress` du fallback restaient à border — clos le 2026-06-29 (entrée suivante).
- 2026-06-29 : **fix résiduel fallback body-leak (clôture A1)** — les awk inline `external_refs`, `product` (scalaires) et `progress` (`phase`/`step`/`resume_hint`/`updated`/`blockers`) scannaient encore le fichier entier ; un `product:`/`external_refs:`/`progress:` en colonne 0 dans le corps injectait des valeurs fantômes en fallback (reproduit empiriquement sur HEAD pré-fix). Même prélude `fence` que A1 appliqué à chaque awk inline → extraction bornée au 1er bloc frontmatter (`extract_product_portfolio_scalar_awk` était déjà fence-aware). Plus aucun champ fallback non borné. Parité jinja conservée (single-brace awk, pas de `{% raw %}`) ; drift + smoke-test ✅. Test étendu : fiche-piège `objleak`. Worklog : voir `.worklog.md`.
- 2026-07-03 : fiche clôturée en `done` après validation du contrat d'index, du fallback frontmatter et de la fraîcheur documentaire. Doc Impact Decision : C — fiche feature et worklog mis à jour pour refléter la livraison effective.
