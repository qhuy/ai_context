# Worklog — core/feature-intent-retrieval

## 2026-08-20 — création

- Constat remonté depuis un dépôt consommateur (template `v1.0.1-6-g06bbbbc`) : `.ai/index.md:59`
  annonce « si l'intent ou les paths matchent une feature », mais aucun outil ne couvre `intent`.
- Vérifié sur HEAD `06bbbbc` : inventaire pre-turn limité à id+status
  (`pre-turn-reminder.sh:107-109`), index sans champ de texte libre
  (`build-feature-index.sh:168`), hook `features-for-path.sh` borné à `Write|Edit|MultiEdit`
  (`.claude/settings.json:28`), `knowledge.sh search` en `contains` littéral sur un hub absent
  (`knowledge.sh:152`).
- Fait décisif : `title` est déjà requis par `.ai/schema/feature.schema.json` et présent dans toutes
  les fiches du corpus initial — il est simplement jeté à l'indexation.
- Arbitrage retenu : enrichir l'index (title + keywords) et prescrire un `features-search.sh`,
  plutôt qu'étendre le hook aux outils de lecture ou activer le knowledge hub.
- next : implémenter l'indexation, le script de recherche, la prescription contrat et la parité template.

## 2026-08-20 — implement / index enrichi, recherche par intention, contrat aligné

- `build-feature-index.sh` (+ template) indexe `title` et `keywords`. Le chemin `yq` lit 9 scalaires
  au lieu de 8 ; le fallback awk passe par deux extracteurs dédiés au texte libre,
  `extract_text_scalar_awk` et `extract_text_list_awk`, parce que `extract_scalar_awk` strippe
  toutes les quotes — il transformait « Conditions d'exposition » en « Conditions dexposition » et
  faisait perdre le mot à la recherche. `extract_list_awk` a été scindé en `extract_list_awk_raw`
  (parsing) + variante historique (strip agressif) pour ne rien changer aux valeurs techniques.
- `keywords` ajouté au schema (`additionalProperties: true` déjà en place, donc rollback sans casse).
- `features-search.sh` (+ template) : recherche lexicale sur id/title/keywords/scope, tous statuts
  par défaut, repli des diacritiques, `--json`/`--status`/`--limit`, code 1 sans résultat.
  Bug corrigé en cours de route : `contains(.)` en jq réévalue `.` sur l'input du pipe, donc chaque
  terme matchait toujours — capture explicite `. as $t` requise.
- `pre-turn-reminder.sh` (+ template) affiche le titre par feature et pointe vers la recherche pour
  les fiches masquées ; `.ai/reminder.md` (fr + en) porte la prescription à chaque tour ;
  `.ai/index.md` (+ template) documente les deux points d'entrée et l'usage de `keywords`.
- `aic.sh search` exposé ; alias `features-search` retiré pour garder une route publique unique.
- Contrats gelés mis à jour : snapshot de clés (`test-build-feature-index-contract.sh`) et manifeste
  de surface (`test-surface-manifest.sh`), routes + clés + types. MINOR sans bump de
  `schema_version`, conformément à la politique du script.
- Validation : `tests/unit/*.sh` 56/56 PASS ; `tests/smoke-test.sh` PASS (3 assertions d'inventaire
  réalignées sur le nouveau format `id (status)`) ; quality gate phase 1 verte
  (shims, skills-parity, agent-config, ai-references, features --no-write, feature-docs --strict,
  coverage --strict 116/116, dogfood-drift) ; `measure-context-size` 1368 chars.
- next : mesure de reprise côté dépôt consommateur après `copier update` — vérifier que la fiche
  cible ressort sur une requête métier, puis renseigner `keywords:` sur les fiches à fort rappel.

## 2026-08-20 — corrections après review contradictoire

- Intent : préserver la recherche globale face à une fiche `keywords` mal typée, éliminer les faux
  positifs sur acronymes courts et éviter de figer une route publique avant preuve terrain.
- Fichiers/surfaces : `features-search.sh`, `build-feature-index.sh`, `check-features.sh`, leurs
  miroirs template, `test-features-search.sh`, `aic.sh` et le manifeste de surface.
- Décision : défense en profondeur (`check-features` bloque, builder normalise avec warning,
  consommateur ignore une valeur résiduelle) ; égalité de token pour les termes de deux caractères
  ou moins ; `aic search` reclassé `interne` jusqu'au benchmark consommateur.
- Validation ciblée : test recherche et manifeste de surface PASS ; gates complètes à relancer
  après réconciliation documentaire.
- Mesure fraîche dans `/private/tmp/ai-context-feature-intent-hardening` après les dernières éditions :
  68 fiches avec titre, 1 avec `keywords` non vides ; surcharge des titres 86 octets pour les 2
  fiches visibles et 3651 octets tous statuts ; sorties pre-turn complètes 1370/7175 octets. Commandes
  reproductibles consignées dans la section Risques de la fiche.
- Next : mesurer le rappel top-1/top-3 sur des requêtes figées avant rédaction des `keywords`.

## 2026-08-20 — handoff product réconcilié, entrée en review

- Intent : fermer le faux blocage de freshness sur les schémas génériques avant la gate finale.
- Fichiers/surfaces : frontmatter de `product/product-portfolio-loop`, ses deux schémas partagés et worklog associé.
- Décision : le scope product reste `done` ; les schémas passent de `touches` à `touches_shared`, car l'ajout générique de `keywords` ne change aucun contrat de portfolio.
- Validation : `check-feature-freshness.sh --staged --strict` PASS ; wrapper `check-commit-features.sh` avec message `feat(core)` PASS.
- Next : quality gate complète et review finale du delta ; mesure de rappel consommateur maintenue comme risque de rollout.

## 2026-08-20 — corrections de review finale

- Finding usage : une requête mixte comme « problème UI » supprimait `UI` dès qu'un terme de plus
  de deux caractères existait. La tokenisation garde désormais tous les termes utiles, avec les
  mêmes mots vides et l'égalité de token pour les acronymes courts.
- Risque performance : la validation de `keywords` avait ajouté un fork `jq` par fiche. Sa
  projection validée/normalisée rejoint le `jq` existant des scalaires, sans nouveau fork par fiche.
  Trois runs après la dernière correction mesurent 2,52 s, 2,54 s et 2,48 s (`/usr/bin/time -p`) : le temps
  historique de juillet n'est pas un baseline causal comparable, donc aucun gain temporel revendiqué.
- Robustesse de l'optimisation : le flux des scalaires passe d'un découpage par ligne à un Record
  Separator non-blanc. Une fixture `title` avec saut de ligne prouve que la projection `keywords`
  ne décale pas les champs et que la fiche reste indexée/retrouvable sous Bash 3.2.
- Validation : test discriminant requête mixte, contrats index, fallback, robustesse et dogfood drift
  PASS ; freshness et smoke final à relancer après staging.

## 2026-08-20 — gate finale verte, feature maintenue en review

- Validation complète sur l'état stagé : `tests/smoke-test.sh` PASS ; `git diff --cached --check`
  PASS ; freshness `--staged --strict` et `--worktree --strict` PASS ; `check-features.sh
  --no-write` PASS ; `check-feature-docs.sh --strict core/feature-intent-retrieval` PASS ; couverture
  stricte 116/116, 0 orphelin ; dogfood drift et miroir runtime/template PASS.
- Le garde-fou de commit accepte `feat(core): retrouve les fiches par intention`. La mesure finale
  du contexte pre-turn est de 1304 caractères, soit environ 326 à 434 tokens sans `tiktoken`.
- Le smoke d'un worktree propre nécessite actuellement la présence du dossier ignoré
  `docs/benchmarks/runs` pour le self-check benchmark. Le dossier a été créé localement avant le run ;
  l'hypothèse implicite du harness est préexistante et reste hors du scope primaire de cette feature.
- Décision : GO technique pour commit, sans passage à `done`. La route `aic search` reste interne et
  le rappel top-1/top-3 doit encore être mesuré sur des requêtes consommateur figées avant enrichissement
  des `keywords`.
- Next : exécuter ce benchmark consommateur, puis décider de stabiliser ou d'ajuster le point d'entrée.

## 2026-08-21 — challenge Claude : adoption et preuve de robustesse

- Intent : traiter les signaux valides du retour sans accepter sa prémisse chronologique erronée.
- Preuve de séquence : `6e814c0` (`session-injection-dedup`) est parent de `d6820de`; la feature
  n'a donc pas été créée après. En revanche, `2caf478` l'a retouchée après sans `keywords`, et la
  requête `coût contexte doublon budget tokens` ne la retrouvait pas.
- Décision adoption : conserver le champ optionnel, ajouter `keywords: []` dans le starter et un
  warning de décision dans `check-features`; enrichir immédiatement la fiche témoin avec son
  vocabulaire métier. Pas de heuristique fragile visant à deviner un « id code-name ».
- Décision contrat : ajouter `keywords` à l'énumération du frontmatter optionnel dans les deux
  templates, qui pointent déjà vers le schéma formel.
- Décision preuve : étendre `test-features-search.sh` aux fixtures `keywords: billet` et
  `keywords: [123]`, puis injecter ces deux formes dans un index déjà construit pour exercer la
  défense du consommateur. Le fallback sans `yq` signale aussi ces deux formes évidentes ; le
  contrat documente désormais sa portée au lieu de promettre un parseur YAML complet.
- Validation ciblée : `bash tests/unit/test-features-search.sh` PASS après implémentation.
- Next : lancer les checks core, dogfood et la quality gate avant proposition de commit.

## HANDOFF — core -> product/workflow (2026-08-21)

- Feature source : `core/feature-intent-retrieval`.
- Status : accepté dans le cadre du « go » utilisateur ; traçabilité documentaire uniquement.
- Contexte : `.docs/FEATURE_TEMPLATE.md` est couvert directement par plusieurs features historiques,
  et la freshness stricte exige leurs worklogs même quand leur comportement ne change pas.
- Fichiers touchés : worklogs `product/product-portfolio-loop` et
  `workflow/feature-granularity`.
- Travail restant : aucun dans ces scopes ; constater que `keywords` n'altère ni la boucle produit
  ni la règle de granularité.
- Contrats / décisions : aucun contrat product ou workflow modifié ; le comportement appartient au
  scope `core` et à `core/feature-mesh`.
- Risques : taxe de sur-couverture persistante sur le starter, déjà visible dans
  `check-touches-breadth.sh`.
- Validation attendue : `check-feature-freshness.sh --staged --strict` puis retour au scope `core`.
- Resume hint : poursuivre la gate et ne pas ouvrir de chantier product/workflow dans ce lot.

## 2026-08-21 — gate finale verte après handoff

- Fait : validation complète du durcissement `keywords`, du cas d'usage
  `session-injection-dedup` et du comportement défensif du consommateur face à un index déjà
  corrompu.
- Vérifié : `tests/unit/test-features-search.sh` passe ; les 57 scripts unitaires passent ;
  `tests/smoke-test.sh` passe après création du répertoire ignoré attendu
  `docs/benchmarks/runs` ; contrôles structurels, fraîcheur staged stricte, dérive dogfood et
  couverture documentaire passent (`117/117`, aucun orphelin).
- Vérifié : la requête `coût contexte doublon budget tokens` classe désormais
  `core/session-injection-dedup` en tête avec `5/5` termes reconnus.
- Vérifié : aucun nouveau diagnostic ShellCheck ; le seul `SC2034` sur `start_ts` dans
  `build-feature-index.sh` est déjà présent dans la révision de base.
- Décision : GO technique pour proposer le commit. La fiche reste en `review` tant que le
  benchmark d'usage du consommateur n'est pas consolidé.
- Risque restant : `keywords` reste volontairement optionnel et non bloquant ; son adoption doit
  être suivie par la mesure plutôt que forcée sur toutes les fiches.
- Next : obtenir la confirmation explicite du commit, puis intégrer le lot avec les commits de
  veille déjà préparés.
