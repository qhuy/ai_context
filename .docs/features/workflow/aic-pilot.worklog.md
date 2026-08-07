# Worklog — workflow/aic-pilot

## 2026-06-29 — création

- Feature créée via cadrage conversationnel validé par l'utilisateur.
- Scope : workflow.
- Intent initial : ajouter `aic-pilot` comme couche de pilotage transverse et faire débrayer `aic-frame` quand une demande est trop large.

## 2026-06-30 — implémentation + reclassification freshness

- Ajout du skill public `aic-pilot` côté Claude/Codex et templates Copier.
- Ajout du template durable `.docs/pilots/0000-template.md` + rendu `{{docs_root}}/pilots`.
- `aic-frame` route désormais vers `pilot` pour audits larges, suivis transverses et paquets de bugs/features/décisions.
- `aic.sh` expose seulement un bootstrap `pilot` informatif : le pilotage reste skill-only et conversationnel.
- Dogfood update/drift préservent les registres pilot datés comme les frames datés.
- Reclassification associée au contrat freshness `(a')` : `aic-pilot` garde l'ownership exact de ses skills et registres ; les surfaces partagées (`aic.sh`, README, Copier, dogfood, smoke, frame) restent reliées en `touches_shared`.

## 2026-06-30 15:41 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-06-30-ze-solution.md

## 2026-06-30 16:12 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-06-30-ze-solution.md

## 2026-06-30 16:29 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-06-30-ze-solution.md

## 2026-06-30 — pilotage "ZE SOLUTION" (usage du skill)

- Session de pilotage via `aic-pilot` : registre `.docs/pilots/2026-06-30-ze-solution.md` créé et maintenu (7 axes triés, axe directeur "prouver & positionner").
- Routage exécuté : P1 → `product/agent-efficacy-benchmark`, P3 → `quality/feature-schema-validator`, P2 (hedge) → HANDOFF product→core → `core/agents-md-native-collapse-path`.
- Contrat vérifié en conditions réelles : `aic-pilot` garde l'ownership de `.docs/pilots/**` (`touches:`), donc la freshness staged exige le worklog `aic-pilot` quand le registre change.
- Suivi : P1/P3/P2 fichés (commits `ebc371c`/`c444caf`) ; P3 recadré (zéro dép) + incrément 1 livré (`dc9c4c6`) et câblé smoke (`885f169`). Registre `next_hint` rafraîchi (retrait de la mention obsolète `check-jsonschema`).
- P2 incr.1 livré (`ed78af8`, verrou self-suffisance AGENTS.md) ; worklogs orphelins (traces auto CHANGELOG périmées) nettoyés.
- **P4 différé après mesure** (measure-first) : bench ad-hoc du matching → matching ≠ goulot (grandit à peine à mesh 10×) ; le coût est le parsing yq de `build-index` (linéaire ~80 ms/fiche, négligeable + caché à ≤100 fiches). La réécriture Python cadrée contredit l'éthos bash/jq/yq ET rate la cible → `dropped tel que cadré`. Même leçon que P3 : vérifier la prémisse avant de coder.
- Branche `pilot/ze-solution-axes` mergée dans `main` (fast-forward, 7 commits) — le hook commit-msg refuse un commit de merge non conforme, d'où le ff.
- **P5 différé (déjà résolu)** : `dogfood-update.sh --apply` génère déjà le runtime depuis le template (source unique existante) ; taxe résiduelle inhérente au Jinja + mitigée par drift-check → rien à refactorer. **Méta : P3/P4/P5 = 3/3 prémisses recadrées vers le bas** — le projet traite déjà plus que la vue externe ne supposait ; la valeur restante est P1 (prouver) et P6 (friction), pas plus de machinerie.
- **P6 diagnostiqué** (aic-diagnose) : bottleneck = `qualité` (largeur de `touches:`). `check-touches-breadth.sh` liste 9 surfaces transverses en `touches:` bloquant (CHANGELOG.md, _lib.sh, build-feature-index.sh, .ai/index.md, docs/upgrading.md…) → cascade freshness + bruit auto-worklog. Fix = reclasser en `touches_shared:` (détecteur + champ déjà là — appliquer, pas construire). **P6 indépendant de P1** ; seul « jusqu'où relâcher le gate » gagnerait à connaître l'efficacité agent. 1ère action : CHANGELOG.md → touches_shared: dans ses 6 coverers (chantier quality/cross-scope).
- **P6 incr.1 livré** (`84d54aa`, branche `quality/touches-breadth-changelog`) : CHANGELOG.md reclassé `touches_shared:` dans les 6 fiches (2ᵉ vague `quality/touches-breadth-guard`). Cascade freshness supprimée à la racine, vérifié (check-features PASS, breadth-guard ne liste plus CHANGELOG). **Bilan pilotage : tous les axes traités** — P1 fiché ; P2/P3 incr.1 ; P4/P5 différés (mesure/déjà-résolu) ; P6 diagnostiqué + incr.1 ; P7 différé. Seul gros reste = build P1.
- **P1 incr.1 livré** (`0164289`) : scaffold benchmark (PROTOCOL + runner `--self-check` + tâche + README) ; runner = seam externe `AGENT_CMD`. Runs réels = action mainteneur.
- **PILOTAGE CLOS** (`status: done`) : les 2 branches feature (`quality/touches-breadth-changelog`, `product/agent-efficacy-benchmark-scaffold`) mergées dans `main` (ff + cherry-pick, historique linéaire) ; main vérifié (check-features/shims/docs + 3 tests d'incréments + run-bench --self-check + breadth-guard sans CHANGELOG). Résiduel = follow-ups feature-level (runs P1 mainteneur, kill_criterion #34235, HANDOFFs smoke, breadth vagues futures) suivis dans les fiches, plus dans le pilot.

## 2026-07-03 — done
- Intent : clôturer `aic-pilot` après validation du skill, des registres `.docs/pilots/**` et du contrat dogfood.
- Fichiers/surfaces : `.docs/features/workflow/aic-pilot.md`, `.docs/features/workflow/aic-pilot.worklog.md`.
- Décision : statut `done`; les follow-ups restent portés par leurs fiches propriétaires, pas par le pilot.
- Validation : `bash .ai/scripts/check-feature-docs.sh --strict workflow/aic-pilot`; `bash tests/unit/test-dogfood-update-preserves-frames.sh`; `bash tests/unit/test-dogfood-drift-extra.sh`; `bash .ai/scripts/check-dogfood-drift.sh`; `bash .ai/scripts/check-features.sh --no-write`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-06 — couverture incidente (workflow/evidence-discipline)
- workflow.md des skills d'analyse (aic-review/diagnose/pilot/frame, Claude+Codex+templates) : une règle non négociable « discipline de preuve » ajoutée — toute affirmation prouvée (source citée) ou étiquetée Hypothèse / À vérifier. Aucun changement du contrat propre de cette fiche. Validation portée par `workflow/evidence-discipline`.

## 2026-07-07 18:51 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-07-audit-remediation.md

## 2026-07-23 18:32 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-23 — pilotage « analyse fonctionnelle générale » : cadrage corrigé après review Codex #1

- Registre `.docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md` créé (propositions P1–P18 de l'analyse fonctionnelle du jour : carte, challenges, séquencement), puis **corrigé suite à la review Codex #1 (bloquante)** :
  - P9a maintenu `blocked` : checklist RELEASE.md non exécutée, HANDOFF product→workflow non acté — aucun tag lancé ;
  - P1 requalifié : hub knowledge routé et documenté (`aic.sh:65-66,915` vérifié) — l'enjeu est le wiring automatisé absent + l'adoption non mesurée, pas une « île » ;
  - P2a requalifié : `check-agent-native-context.sh` documenté consommateur (`docs/upgrading.md:231,241` vérifié) — décision brancher/déprécier, pas suppression d'office ;
  - P10 scindé : P10a = fix enum `status` warn→fail (`check-features.sh:162-165`) ; P10b = dropped, prémisse invalidée (`check-features.sh:123-130` bloque déjà le frontmatter illisible) ;
  - routes normalisées vers le contrat aic-pilot (une route unique par item) ;
  - section « Prémisses vérifiées » ajoutée : preuves actuelles par item (commandes/fichier:ligne), hypothèses étiquetées (TFVC, consommateurs externes).
- Intégration des décisions antérieures ZE SOLUTION (2026-06-30) pour ne pas re-litiger : P7 reframé sur les trous du dispositif dogfood existant (drift content-check limité au profil `minimal`, pas de guard anti-édition-directe) ; P11 borné measure-first sans réécriture ; P17 relié à `product/agent-efficacy-benchmark` (runs réels en attente).
- Aucun chantier lancé. En attente : re-review Codex du cadrage corrigé.

## 2026-07-23 — re-review Codex #2 (go avec réserves) : cadrage v3

- Verdict Codex #2 extrait de sa session locale : **go avec réserves** — blocages de méthode levés, 3 corrections factuelles exigées. Chacune re-vérifiée dans le code avant application :
  - `status: published` = **faux positif** : `product/knowledge-federation.md:5` est `active` en frontmatter ; le `published` vu initialement est un exemple YAML du schéma knowledge dans un corps de fiche (`knowledge-source-contract.md:138,146`). → P1 recompté (1 fiche non close), P10a purgé de toute correction de donnée (fixture de test uniquement).
  - `context-relevance-report.sh` documenté en interne (`quality/context-relevance-tracker.md:39,62`) → P2a reformulé « aucune doc utilisateur publique ni route aic » ; lien explicité entre `check-agent-native-context.sh` et le kill criterion de `core/agents-md-native-collapse-path.md:106` (instrument de P4).
  - P9a reformulé « **préparer la release `vNext`** » : bump SemVer d'abord (RELEASE.md §5), inventaire complet des recos `--vcs-ref=HEAD` consommateur (README_AI_CONTEXT:57,64, README:298, PROJECT_STATE:20,76, variables:90, upgrading:9,18, CHANGELOG:118), usages mainteneur HEAD préservés (RELEASE.md:27-33,49) ; nuance consignée : la reco HEAD est une mitigation délibérée du retard de tags → P9a inclut l'engagement de cadence.
- Leçon méthodo consignée au registre : `rg` sans `--hidden` ignore `.docs/` — cause racine des deux erreurs de prémisse.
- Toujours aucun tag ni chantier lancé. En attente : GO complet Codex sur le cadrage v3.

## 2026-07-23 — review Codex #3 : fond validé, cadrage v4 (final)

- Verdict #3 : go avec réserves, **fond validé**, pas de nouvelle review complète requise. 2 corrections appliquées après vérification :
  - **Ordre P9a corrigé** : le HANDOFF product→workflow + confirmation précède désormais la checklist RELEASE.md (elle contient des éditions documentaires de ce scope — CHANGELOG, PROJECT_STATE, README). Séquence actée : décision SemVer → HANDOFF + confirmation → checklist intégrale → confirmation tag/push → tag.
  - **P1/P2a reformulés « invocation opérationnelle »** : la CI couvre bien ces surfaces via leurs tests unitaires dans la boucle générique (`ai-context-check.yml:98-103` + `tests/unit/test-knowledge-workflow.sh`, vérifié) ; le manque est l'usage opérationnel hooks/skills, pas la couverture de test.
- Le pilotage passe en phase d'exécution conditionnée : question active = activation de P9a par l'utilisateur (bump SemVer → HANDOFF à confirmer). Toujours aucun tag ni chantier lancé à ce stade.

## 2026-07-24 00:23 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-24 — P9a exécuté de bout en bout et clos (release v0.14.0)
- Mandat utilisateur « go jusqu'au bout, test, dogfooding, commit, push » : checklist RELEASE.md §1-7 exécutée intégralement. Détail complet et preuves dans le registre (section « Preuve de clôture P9a »).
- 2 bugs réels trouvés et corrigés en cours de route (hors périmètre initial du registre) : syntaxe `--data agents=<multiselect>` de RELEASE.md §2 cassée sous Copier 9.14.3 (contournée) ; positionnel source inexistant pour `copier update` documenté à RELEASE.md:49 (corrigé avec la méthode clone-jetable + `_src_path`).
- `copier update` testé sur une copie jetable de `ai_debate` (jamais l'original) : 214 commits de rattrapage, 0 `.rej`, mesh utilisateur intact.
- Gate freshness a détecté un vrai trou de couverture sur `MIGRATION.md` (2 fiches voisines non anticipées) — corrigé par entrées « couverture incidente ».
- Tag `v0.14.0` sur `5c34108`, poussé sur `origin/main` et `origin/v0.14.0`. `git describe --tags` = `v0.14.0` exact : le décrochage de 213 commits identifié en début de pilotage est résolu.
- Sanity post-release (RELEASE.md §7) : rendu depuis GitHub PASS, `check-shims`/`doctor` PASS.
- P9a : `done`. Le registre reste `active` (19 autres items en triage/inbox) ; prochaine question posée à l'utilisateur = quel item traiter ensuite.

## 2026-07-24 — mandat autopilot, scope product clos (6/6)

- Utilisateur : « auto pilot les 19 items ». Séquencement par scope (précédent ZE SOLUTION 2026-06-30), HANDOFF explicite entre scopes, arbitrages produit structurants proposés (pas décidés seuls).
- **P3** (`f0619c0`) : `docs/benchmarks/runs/` untracked (246 fichiers, conservés sur disque). Prémisse `.DS_Store` corrigée : déjà gitignorés, jamais tracked.
- **P13** (`8703973`) : `GLOSSARY.md` livré via template avec `{{docs_root}}` substitué (sert aussi les consommateurs, pas seulement le repo source). A révélé et corrigé une sur-couverture `.ai/index.md` (6 fiches en `touches:` direct → `touches_shared:`, même pattern que `quality/touches-breadth-guard`).
- **P14** (`ea3fd47`) : `docs/getting-started.md` réécrit pour la surface v0.14+, `docs/variables.md` complété à 12/12, `examples/*.yml` régénérés et testés (`copier copy --data-file`, 3/3 OK), `--no-write` aligné dans README.
- **P18b** (`9f109a4`) : cadence d'audit recalibrée (release + mensuelle, honnête sur l'absence d'automatisation réelle). Frames : décision de ne rien changer — mécanisme légitime pour décisions structurantes uniques, la faible fréquence n'est pas un problème.
- **P1** et **P17** : investigués (measure-first), pas décidés unilatéralement — routés `validated`, recommandation prête :
  - P1 : adoption du hub knowledge mesurée à zéro (`.ai/.context-relevance.jsonl` 0 occurrence, aucun commit/worklog d'usage). Recommandation : geler.
  - P17 : **prémisse corrigée** — les runs réels du benchmark existent déjà (`docs/benchmarks/reports/2026-07-03-product-decision-readout.md`, N=3, 2 repos, +66.7 pts, -39.6% tokens, `decision_state=commit` déjà acté 2026-07-03). Ce qui reste ouvert : validation par repo vraiment indépendant, `next_decision_date` dépassée sans nouvelle décision tracée.
- Tous les gates (check-features/shims/docs/ai-references/freshness/dogfood-drift) et smoke-test complet PASS avant chaque commit.
- HANDOFF product→quality émis pour P5/P10a/P18a.

## 2026-07-24 — mandat autopilot, scope quality clos (3/3)

- **P5** (`d94830d`) : dégraissage `PROJECT_STATE.md` (146→91 lignes — section Architecture retirée, cascade « État actuel/rappels » collapsée). Prémisse initiale du registre invalidée après lecture complète : `quality/QUALITY_GATE.md` (contrat), `workflows/quality-gate.md` (procédure), `rules/core.md`/`rules/quality.md` (extension-points volontairement minimaux) ne sont PAS une triplication — aucun changement sur ces 3 fichiers.
- **P10a** (`7b5005d`) : enum `status` warn→fail dans `check-features.sh` + miroir template. Nouveau test fixture `test-check-features-status-enum-strict.sh`. Mesh réel (65 fiches) vérifié inchangé avant durcissement.
- **P18a** (`5629e69`) : nouveau script source-only `check-release-coherence.sh` (version CHANGELOG↔PROJECT_STATE + complétude `docs/variables.md` vs `copier.yml`), testé positif et négatif. A révélé que `.github/workflows/ai-context-check.yml` ne se déclenchait même pas sur un diff limité à CHANGELOG/PROJECT_STATE/copier.yml (path triggers manquants — corrigé). Câblé aussi dans `RELEASE.md` §4. Non mirroré côté template (fichiers comparés inexistants côté consommateur, cohérent avec l'exemption drift déjà accordée à ce workflow).
- Tous les gates + smoke-test complet PASS avant chaque commit.
- HANDOFF quality→core émis pour P2a/P4/P6/P7/P8/P11.

## 2026-07-24 — mandat autopilot, scope core clos (6/6 : 3 exécutés, 3 investigués)

- **P7** (`8494b6e`) : prémisse initiale corrigée — aucune copie runtime des fichiers scopés à comparer (ce repo dogfoode `scope_profile=minimal`), comparaison octet-à-octet structurellement impossible. Fix livré : sanity de rendu (non-vide, pas de Jinja non résolu) sur les profils `fullstack-cursor`/`codex-hooks` + nouveau `check-runtime-template-mirror.sh` (advisory, source-only, câblé en CI diff PR).
- **P8** (`1015e87`) : prémisse corrigée — une seule divergence réelle sur toute la surface skills (`disable-model-invocation`, intentionnelle). Restructurer en « un seul fichier + pointeurs » aurait été un risque pour un gain marginal. Fix livré : `check-skills-parity.sh`, templaté (pertinent aussi côté consommateur claude+codex), bloquant, câblé quality-gate + CI + smoke-test.
- **P11** (`074438a`) : measure-first confirme un vrai goulot, plus grave qu'estimé — 1024 forks `yq` mesurés (~14-15/fiche), ~5s/build, ~25s sur 5 builds (chemin commit simulé). Consolidé à 1 yq + 8 jq/fiche → ~1.9s/build, ~9.2s (2.7x). Un vrai bug de précédence bash (`read` + `IFS=tab` collapse les tabs consécutifs même sur champ vide isolé) détecté par diff sémantique JSON sur 3 fiches réelles, documenté dans le code. Diff JSON strict identique sur les 65 fiches réelles + 9 tests unitaires PASS.
- **P2a** (validated) : `check-agent-native-context.sh` n'est pas orphelin — il a servi d'instrument au retrait déjà livré des shims cursor/copilot (voir P4). `context-relevance-report.sh` reste à statuer (faible enjeu).
- **P4** (validated) : prémisse partiellement obsolète — cursor/copilot déjà réduits ce cycle (`core/agents-md-native-collapse-path`, déjà dans le CHANGELOG v0.14.0), le README `Honnêteté runtime` le documente déjà. **Trouvaille nouvelle** (recherche web datée) : Google a arrêté Gemini CLI pour la plupart des utilisateurs le 2026-06-18, remplacé par « Antigravity CLI » qui lirait aussi AGENTS.md et supporterait `.agents/skills/` — `gemini` reste pourtant un choix actif dans `copier.yml:210`. Décision de positionnement hors mandat autopilot (changement de surface publique).
- **P6** (validated) : hypothèse TFVC non tranchable par archéologie de code — absence de preuve d'usage réel trouvée, mais nécessite la connaissance directe de l'utilisateur pour trancher.
- Tous les gates + smoke-test complet PASS avant chaque commit exécuté.
- HANDOFF core→workflow émis pour P2b/P9b/P12/P15.

## 2026-07-24 — mandat autopilot, scope workflow clos (4/4)

- **P2b** (`3be389d`) : prémisse d'élagage invalidée après vérification — `mcp-policy.md`/`subagent-contract.md` activement routés (`.ai/rules/workflow.md`, `README_AI_CONTEXT.md`), pas morts ; supprimer `feature-resume.md`/`feature-handoff.md` aurait cassé des chaînes documentées. Seul fix réel : `feature-update.md` citait `feature-handoff.md` comme étape active alors que le HANDOFF cross-scope est désormais le format inline `.ai/rules/workflow.md` — corrigé (+ miroir template).
- **P12** (`f34cec5`) : `aic init` livré — `doctor.sh` informatif, activation idempotente `core.hooksPath`, état bref du mesh, pointeur `aic-frame`/`aic-pilot`. Fiche d'exemple non vide explicitement écartée (redondante avec `FEATURE_TEMPLATE.md` + le pointeur affiché). Smoke étendu (activation + idempotence).
- **P9b** (`1bd808c`) : `aic-release.sh` (checklist RELEASE.md automatisée : smoke, 7 rendus Copier, cohérence doc — jamais §3/§5/§6/§7, irréversibles ou décision humaine) + entrée `_migrations` native `copier.yml` (v0.14.0, lecture seule `aic migrate plan`, non bloquante). **Faux pas détecté et corrigé en cours de route** : le script avait d'abord été câblé dans `aic.sh` + templaté, avant de réaliser que ses dépendances (`RELEASE.md`, `check-release-coherence.sh`) sont elles-mêmes source-only — un consommateur n'a pas de checklist de release du template à exécuter. Corrigé : script source-only, non dispatché, ajouté à l'ignore-list dogfood. Détecté concrètement par une régression réelle du smoke-test (`test-dogfood-drift-extra.sh`), pas par relecture — la gate a fait son travail. Vérification empirique clé : le scénario `v0.11.0→HEAD` du smoke produit de vrais `.rej` (7 fichiers) ; sans garde non-bloquant, la migration native aurait fait échouer `copier update` lui-même.
- **P15** (`bfc6767`) : routes `onboard`/`dev-plan` ajoutées à `aic.sh` (style `pilot` : orientation skill, aucune logique dupliquée — vérifié qu'aucun script ne les porte). Contrat de `core/aic-surface-canonical` corrigé (liste 10/10 intentions, il en manquait 3). Alias `frame-bootstrap`/`frame-context` documentés dans `docs/getting-started.md` (déjà dans `aic.sh --help`, absents de la prose) ; retrait explicitement hors périmètre (breaking, reporté à P16/v1.0).
- Tous les gates + smoke-test complet PASS avant chaque commit ; `check-runtime-template-mirror.sh` et `check-skills-parity.sh` (livrés scope core) désormais systématiquement dans la boucle de vérification.
- HANDOFF core→workflow marqué RÉSOLU. HANDOFF workflow→product émis pour P16 (gel v1.0, dernier item non-utilisateur de la carte).

## 2026-07-24 — P16 investigué, mandat autopilot terminé (18/18 items traités)

- **P16** (validated, non exécuté) : critères de sortie vérifiés 6/6 (P7 `8494b6e`, P9/P9a tag `v0.14.0`, P10a `7b5005d`, P12 `f34cec5`, P13 `8703973`, P14 `ea3fd47`). Contrat public v1.0 proposé avec sources citées (10 intentions `aic-*` confirmées, `.ai/schema/feature.schema.json`, format `index.md` déjà contractualisé par `core/feature-mesh-progressive-indexes`, jeu de hooks lu dans `.claude/settings.json` — 4 types, 5 scripts). Projet de section CONTRIBUTING rédigé (« Moratoire de surface », même style d'enforcement que le moratoire bash existant : règle de revue écrite, pas de gate automatisé). Distinction explicite ajoutée pour répondre au risque de gel prématuré : le gel porte sur le contrat structurel, pas sur les 5 décisions de positionnement encore ouvertes (P1/P2a/P4/P6/P17), qui n'en font pas partie et restent évolutives après v1.0. Non exécuté (aucune écriture CONTRIBUTING) : c'est une décision de gouvernance, routée `manual` par la carte elle-même — cohérent avec le mandat qui exclut les décisions de positionnement de l'exécution unilatérale.
- **Bilan du mandat « auto pilot les 19 items »** : 18/18 items de la carte traités (P9a + P10b déjà clos avant ce mandat). 12 exécutés avec preuve dans ce mandat (P3/P13/P14/P18b/P5/P10a/P18a/P7/P8/P11/P2b/P9b/P12/P15 — 14 en fait, voir carte pour le compte exact), 6 investigués et explicitement laissés à l'arbitrage utilisateur sans décision unilatérale (P1, P2a, P4, P6, P16, P17). Aucune fiche feature fourre-tout créée ; chaque route `feature` a sa fiche propre. Tous les gates (check-features, check-shims, freshness staged strict, dogfood-drift, runtime-template-mirror, skills-parity) + smoke-test complet PASS avant chaque commit exécuté, sans exception. 2 régressions réelles détectées et corrigées en cours de route (P9b), 3 bugs latents trouvés et corrigés (RELEASE.md ×2, `--data agents=codex`), plusieurs prémisses d'audit initial corrigées après vérification directe plutôt qu'exécutées telles quelles (P1, P2a, P2b, P7, P8, P9a, P10, P12, P15).
- Plus aucune action mécanique en attente. Le registre reste `active` jusqu'à ce que l'utilisateur tranche (ou explicitement diffère) les 6 items `validated`.

## 2026-07-24 — arbitrages utilisateur reçus (P1, P2a, P6, P17) + P16 vers review Codex
- Self-review critique des recommandations faite avant les arbitrages : 3 corrections assumées (instrument de preuve P1 — le jsonl ne pouvait pas capturer un usage CLI ; séquencement SemVer — trancher P4 AVANT le tag v1.0 ; gain P6 survendu — 286 lignes = taille totale de `_vcs.sh`, pas le gain).
- Arbitrages actés : **P1** gel exécuté (`knowledge-federation` : `decision_state: cut`, `status: done`, code intact) ; **P2a** statu quo ; **P6** TFVC CONSERVÉ — c'est le repository principal de l'organisation de l'utilisateur (fait non dérivable du repo, l'archéologie concluait à tort « aucun consommateur ») → le gap s'inverse : test e2e TFVC à cadrer ; **P17** opportuniste, `next_decision_date` re-datée 2026-10-01.
- Proposition P16 amendée en conséquence (caveat SemVer/P4, question TFVC-e2e comme critère de sortie potentiel) ; prompt de review Codex rédigé et fourni à l'utilisateur — gate avant adoption, l'auteur de la proposition ne peut pas être son seul validateur.
- État : 16/18 done, P16 (verdict Codex attendu) et P4 (vérification Antigravity avant tag v1.0) restants.

## 2026-07-24 10:26 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-24 — review Codex #4 (P16) bloquante : re-vérifiée, acceptée, proposition v3
- Review récupérée depuis la session Codex locale (rollout du 23-07, poursuivie le 24-07) — le bloc à coller était resté vide dans le message utilisateur.
- Consigne utilisateur respectée : chaque constat re-vérifié dans le dépôt AVANT acceptation. 6 acceptés avec preuve, 1 accepté-réserve recadré (manifeste : routes+questions+enums d'abord, matrice de capacités en extension). Preuves marquantes : incohérence doc `feature-index-cache.md:78` (« tableau » vs enveloppe réelle, vérifiée par `jq keys`) ; câblage hooks Codex ≠ Claude (`.codex/hooks.json.jinja` : 2 événements vs 4) ; `init` livré P12 mais omis du contrat proposé le même jour ; prémisse P4 corrigée et re-vérifiée aux 2 sources officielles (WebFetch) ; preuve interne `smoke-test.sh:2027` que copier update exige un sous-projet git — le chemin d'upgrade TFVC est structurellement non résolu, pas juste non testé.
- § Proposition P16 réécrite en v3 dans le registre : contrat 8 éléments (questions Copier, CLI classifiée, schéma, index JSON, config.yml, shims, garanties comportementales des hooks — pas le câblage —, matrice d'enforcement), checklist de sortie 3 blocs (A décisions, B chantiers dont E2E TFVC, C gouvernance/manifeste), CONTRIBUTING v3 adossé au manifeste. Carte P16 + P4 mises à jour (prémisse corrigée sourcée).
- Aucun chantier Bloc B lancé, aucune décision Bloc A prise — re-review Codex round 2 demandée sur la v3 (prompt fourni à l'utilisateur).

## 2026-07-24 12:05 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-24 — review round 2 (v3) bloquante appliquée : v4 + mandat de convergence autonome
- Round 2 relayé par l'utilisateur : 7 corrections, toutes re-vérifiées dans le dépôt AVANT acceptation (7/7 acceptées, aucune challengée sur le fond — la vérification de la n°5 a révélé une incohérence interne supplémentaire : le commentaire du snapshot test d'index couple tout changement de clés à un bump, contredisant la politique « additif sans bump » écrite dans build-feature-index.sh:357 → chantier B8).
- v4 actée au registre : matrice de capacités et d'enforcement à 3 plans (rendu/disponible/actif) au lieu de garanties universelles ; CLI en 4 niveaux (stable-maintenance créé, interne réduit à `reminder`) ; cycle d'update Copier au contrat (_skip_if_exists, _migrations read-only, .copier-answers.yml) ; 11 enums + 5 patterns du schéma ; politique index alignée sur le code ; TFVC : option copie-Git-hors-workspace + pending change réel + freshness strict au test réel ; manifeste étendu dès v1 (multiselect/when/validateurs, config.yml, matrice de capacités).
- **Mandat utilisateur** : « je vous laisse trouver une entente toi et codex » — les rounds suivants sont menés en autonomie via le CLI Codex local (lecture seule), chaque round consigné au registre. Limite du mandat respectée : les 3 décisions Bloc A (P4, classification CLI finale, `type` requis) restent à l'utilisateur ; aucun tag, aucune release.

## 2026-07-24 14:21 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-24 — round 3 autonome (v4) bloquant : v5 actée, round 4 lancé
- Premier round mené en pleine autonomie via CLI : `npx @openai/codex@latest exec -s read-only` (le CLI npm local 0.139.0 rejette le modèle configuré `gpt-5.6-sol` — la review du matin passait par Codex Desktop 0.145.0-alpha.30 ; contournement npx sans modifier l'installation).
- Verdict round 3 : BLOQUANT. Corrections 2-7 du round 2 jugées bien intégrées ; 2 nouveaux bloquants, chacun re-vérifié avant amendement : (1) cellule CI fausse (prédicat réel `adoption_mode ≠ lite ET (enable_ci_guard OU strict)`, copier.yml:55) + capacités agrégées entre canaux (Claude 5 garanties / Codex 2 / git hooks 3 rôles — vérifiés dans les fichiers de hooks) ; (2) `context.show_statuses`/`default_focus` gelées « actives » sans aucun lecteur (grep vide, PROJECT_STATE.md:46 en roadmap 🚧, le reminder lit les env vars AI_CONTEXT_*).
- v5 : élément 8 réécrit par canal + prédicat CI exact ; élément 6 réduit aux clés réellement lues (chaque clé avec son lecteur cité — `docs_root` vérifié lu par aic.sh:137, contrairement aux 2 exclues) ; nouveau chantier B9 (implémenter ou retirer les 2 clés placeholder, précédent v0.12) ; B7 élargi (title promis mais absent de la sortie réelle de l'index, formulation d'idempotence) ; manifeste approfondi (types/nullabilités index).
- Round 4 lancé. Garde-fou : arrêt et remontée à l'utilisateur si round 5 encore bloquant.

## 2026-07-24 14:36 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-24 — round 4 : GO AVEC RÉSERVES — ENTENTE ATTEINTE (v6)
- Round 4 (CLI autonome, v5) : les 2 bloquants du round 3 jugés résolus, les 2 réserves jugées bien intégrées, Bloc A toujours correctement réservé, « aucun nouveau problème bloquant ». Verdict formel : « VERDICT: go avec réserves ».
- 3 réserves textuelles finales, classées par Codex « intégrables sans nouveau round », chacune re-vérifiée avant intégration : (1) fraîcheur au check-in portée par `commit-msg` → `check-commit-features.sh:169`, PAS par `pre-commit` (`.githooks/pre-commit:73` = auto-progression seule) — attribution corrigée dans le canal git hooks ; (2) dimension `scope_profile`/`scopes` dérivée ajoutée à la matrice (les règles de scope de `_exclude` en dépendent) ; (3) formulations absolues bornées (la CI rendue tourne sur push/PR sans activation locale ; « rien de plus » limité aux 5 garanties).
- **v6 = texte d'entente Claude↔Codex.** Mandat « je vous laisse trouver une entente » rempli côté texte en 2 rounds autonomes (v4→bloquant→v5→go avec réserves→v6). Restent les 3 décisions Bloc A, réservées à l'utilisateur : P4 (gemini/antigravity), classification CLI 4 niveaux, `type` requis.

## 2026-07-24 14:50 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-24 — Bloc A tranché par l'utilisateur : exécution Bloc B/C lancée
- Réponses verbatim : « 1/gemini n'est pas concerné, on n'utilise pas Gemini 2/ok 3/ok ».
- (1) P4 → traduit en option (c) : retrait du choix `gemini` avant gel (0.x breaking-MINOR, précédent v0.13). Traduction exécutive flaggée au registre, veto utilisateur possible jusqu'au tag. (2) Classification CLI 4 niveaux validée telle que proposée. (3) `type` requis dès v1.0.
- Exécution planifiée dans le next_hint du registre (9 étapes, gates complets par commit). Hors automatisation : B5 (TFVC réel de l'org) et C14 (tag) — checkpoints utilisateur.

## 2026-07-28 15:51 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md

## 2026-07-24 — checklist de sortie v1.0 : 13/14 items livrés
- Bloc A (3/3) : P4 tranché, classification CLI en 4 niveaux, `type` requis.
- Bloc B (8/8) : E2E TFVC + fail-open corrigé, chemin d'upgrade workspace TFVC prouvé et documenté, fiche index + politique de bump réconciliées, clés config placeholder implémentées, test d'upgrade v0.14→candidate v1.0, MIGRATION § v1.0 + CHANGELOG structuré.
- Bloc C (2/3) : manifeste de surface (8 dimensions, 2 invariants) gaté en CI et smoke, CONTRIBUTING « Moratoire de surface ». Reste C14 = décision datée + tag, à l'utilisateur.
- **3 bugs réels trouvés par les tests écrits pour le gel**, chacun verrouillé par un test vérifié discriminant : fail-open du gate de fraîcheur en TFVC (normalisation de chemin) ; même fail-open par la locale du client `tf` ; réinitialisation silencieuse de la réponse `agents` quand une valeur quitte `choices` (a fait passer P4 de retrait à dépréciation).
- Méta : sur ce lot, écrire le test a été plus rentable que relire le code — les 3 bugs étaient invisibles à la lecture et tous dans des chemins « déjà validés ».
- Restent 2 actions structurellement hors portée agent : validation TFVC serveur réel (credentials) et tag.

## 2026-07-28 — PILOTAGE CLOS : v1.0.0 releasée
- `chore(release): v1.0.0` (`d00aed5`) + tag poussé. Sanity RELEASE.md §7 exécuté **depuis le tag publié sur GitHub** (pas depuis le working tree) : rendu OK, `check-shims` PASS, `doctor` PASS sans avertissement, surfaces v1.0 livrées au consommateur, et outillage source-only vérifié ABSENT du rendu (`aic-release.sh`, `check-release-coherence.sh`, `GEMINI.md`) — la frontière source-only/templaté tient en conditions réelles.
- Bilan du pilotage : 18/18 items traités depuis l'analyse fonctionnelle du 2026-07-23. 4 reviews Codex (dont 3 bloquantes) intégrées, chacune re-vérifiée dans le dépôt avant application ; 2 rounds de convergence autonome pour le texte du gel.
- Registre passé `done`. Résiduels rendus à leurs fiches propriétaires plutôt que gardés ici : validation TFVC réelle (`core/vcs-provider-abstraction`), repo tiers pour le benchmark (`product/agent-efficacy-benchmark`, décision au 2026-10-01), retrait de `gemini` et des routes `deprecated` en v2.

## 2026-08-07 10:59 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-08-07-retour-ux-restitution.md

## 2026-08-07 11:03 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-08-07-retour-ux-restitution.md

## 2026-08-07 11:11 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-08-07-retour-ux-restitution.md

## 2026-08-07 11:34 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-08-07-retour-ux-restitution.md

## 2026-08-07 — pilotage restitution (chantier A, lot 1)
- `.docs/pilots/2026-08-07-retour-ux-restitution.md` : registre tenu au fil du pilotage — R5 validé (« go »), GO plan 3 étages, lot 1 livré (fiche agent-behavior révisée, condensé canonique, output style, chargement clôture ship/review), question active = HANDOFF core. Usage du contrat aic-pilot, aucun changement du contrat lui-même.

## 2026-08-07 — pilotage restitution (chantier A, lot 2)
- `.docs/pilots/2026-08-07-retour-ux-restitution.md` : HANDOFF core confirmé et lot 2 livré (AGENTS.md condensé, ancre reminder, outputStyle settings, enable_codex_hooks default:true, smoke 28d inversé, MAX_LINES 15→30). Question active = preuve avant/après à consigner. Toujours de l'usage du contrat aic-pilot, pas un changement de contrat.

## 2026-08-07 — pilotage restitution (clôture chantier A)
- `.docs/pilots/2026-08-07-retour-ux-restitution.md` : statuts actés après les commits `a154772` (lot 1) et `408193a` (lot 2) — R2/R5 done, R1/R4 review (preuve avant/après 2 outils restante ; ancre observée live côté Claude), item actif = R3 (diagnose). Usage du contrat, pas de changement de contrat. Friction notée : l'auto-worklog ne trace pas `.docs/pilots/**`, chaque édition de registre exige une entrée manuelle pour passer le gate freshness.
