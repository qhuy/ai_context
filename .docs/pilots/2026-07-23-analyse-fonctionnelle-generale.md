---
pilot_id: "2026-07-23-analyse-fonctionnelle-generale"
status: "active"
source: "analyse fonctionnelle générale 2026-07-23 (session Claude — 4 sous-audits : runtime .ai/, distribution Copier, surface utilisateur, santé du process) ; review Codex #1 (bloquante) et re-review #2 (go avec réserves) appliquées le 2026-07-23"
scope_primary: "product"
created_at: "2026-07-23"
updated_at: "2026-07-24"
active_item: "P16"
active_question: "Mandat autopilot : scopes product (6/6), quality (3/3), core (3/3 exécutés + 3/3 investigués), workflow (4/4) clos — 17/18 items non-utilisateur traités. Seul P16 (gel v1.0) reste, retour au scope product. 5 items en attente d'arbitrage utilisateur (P1, P17, P2a, P4, P6) — non bloquant pour P16."
next_hint: "Traiter P16 (gel v1.0, scope product) : critères de sortie P7/P9/P10a/P12-14 tous livrés désormais (P12 clos ce scope) — vérifier explicitement, définir le contrat public (index.md + schéma fiche + hook set + 10 intentions aic, désormais toutes routées), étendre le moratoire bash en moratoire de surface, publier une checklist de sortie. Après P16, le registre peut se refermer côté exécution ; P1/P17/P2a/P4/P6 resteront affichés pour arbitrage utilisateur à sa convenance — trouvaille notable P4 : Gemini CLI décommissionné par Google le 2026-06-18 (recherche web), remplacé par Antigravity CLI qui lirait aussi AGENTS.md."
---

# Pilot 2026-07-23 — Analyse fonctionnelle générale : consolidation v1.0

## Intention

Piloter les propositions issues de l'analyse fonctionnelle générale du repo (2026-07-23) jusqu'à décision, exécution avec preuve, report daté ou abandon — sans fiche feature fourre-tout. Une review Codex du cadrage conditionne l'exécution ; la review #1 a bloqué le cadrage initial et ses 6 constats sont appliqués ici (voir Décisions actées).

Constats de fond qui motivent le lot (condensé ; preuves par item dans « Prémisses vérifiées ») :

1. **Versioning décroché** : HEAD à 213 commits du dernier tag pendant que la doc recommande `--vcs-ref=HEAD` → les consommateurs tournent du code `[Unreleased]`.
2. **Copies multiples sous-gardées** : skills en 4 exemplaires sans check de contenu inter-arbres ; drift dogfood limité au contenu du profil `minimal`.
3. **Contrats non appliqués là où c'est voulu strict** : enum `status` en warn seulement — un statut hors schéma passerait la CI (mécanisme vérifié `check-features.sh:162-165` ; aucune occurrence réelle à date, le `published` initialement détecté était un exemple YAML dans un corps de fiche).
4. **Surface >> intentions** : ~69 points d'entrée nominaux pour ~10 intentions documentées ; plusieurs surfaces livrées sans wiring automatisé ni adoption mesurée.
5. **Onboarding en régression** : parcours guidé supprimé sans remplacement, getting-started périmé, mesh livré vide, variables/examples incomplets, pas de glossaire, 15 Mo d'artefacts de bench git-trackés.

Coût méta mesuré : 360 commits en 3 mois dont 39 % `docs:` ; ~17 000 lignes de mesh pour ~10 100 LOC de moteur ; règle anti-drift = 8 fichiers par changement ; 13 findings auto-infligés documentés par l'audit du 07-07.

## Résultat attendu

- Chaque item est routé (route unique du contrat aic-pilot) : exécuté avec preuve, converti en décision documentée, reporté avec reprise datée, ou abandonné avec raison.
- Les corrections structurelles ferment des classes de problèmes, pas des instances.
- La surface publique visée v1.0 est définie et gelée (P16) avant tout nouvel ajout de sous-système.
- Aucune fiche feature globale ; chaque item validé `feature`/`fix` a sa fiche propre.

## Carte des sujets

| ID | Sujet | Statut | Scope probable | Route | Preuve attendue |
|---|---|---|---|---|---|
| P1 | Statuer sur le hub knowledge — **investigué, recommandation prête, décision finale utilisateur** : adoption mesurée à **zéro** (`.ai/.context-relevance.jsonl` 0 occurrence « knowledge » ; aucun worklog ni commit d'usage réel, uniquement des commits de construction). Recommandation : **geler** (rétrograder `product/knowledge-federation` de `active`, code conservé intact, aucune extraction) — measure-first a tranché, cohérent avec ZE SOLUTION P4/P5 | validated | product | manual | Confirmation utilisateur du gel (ou contre-argument) |
| P2a | **Investigué — `check-agent-native-context.sh` n'est PAS orphelin** : c'est l'outil qui a validé le retrait des shims dédiés cursor/copilot déjà livré ce cycle (`core/agents-md-native-collapse-path`, voir P4) — il fait son travail, aucune action requise. `context-relevance-report.sh` reste genuinement indécouvrable (doc interne seule, 0 route `aic`) | validated | core | manual | Recommandation : laisser `check-agent-native-context.sh` tel quel ; décider d'exposer `context-relevance-report.sh` via `aic` ou de l'accepter comme outillage mainteneur — arbitrage utilisateur, faible enjeu |
| P2b | **Recadré — prémisse d'élagage invalidée** : `mcp-policy.md`/`subagent-contract.md` sont activement routés (`.ai/rules/workflow.md`, `README_AI_CONTEXT.md`), pas morts ; supprimer `feature-resume.md`/`feature-handoff.md` casserait des chaînes documentées (`feature-done.md`, `claude-skills.md` via `touches:`). Seul fix réel livré : `feature-update.md` citait `feature-handoff.md` comme étape active alors que le HANDOFF cross-scope est le format inline `.ai/rules/workflow.md` | **done** | workflow | docs | `3be389d` : ligne « Procedure chain » corrigée (+ miroir template) ; zéro workflow supprimé (décision, pas oubli) |
| P3 | Dé-versionner `docs/benchmarks/runs/` | **done** | product | chore | `f0619c0` : 246 fichiers untracked, conservés sur disque ; `.DS_Store` déjà gitignorés (jamais tracked — prémisse initiale corrigée) |
| P4 | **Investigué — largement déjà fait**, prémisse initiale partiellement obsolète : `.ai/native-context-support.tsv` confirme cursor + copilot natifs AGENTS.md (evidence officielle datée 2026-07-06) ; leurs shims dédiés sont déjà retirés/opt-in ce cycle (`core/agents-md-native-collapse-path`, déjà dans le CHANGELOG v0.14.0) — le README `Honnêteté runtime` le documente déjà honnêtement. Reste ouvert et **nouveau** (recherche web datée) : Google a arrêté Gemini CLI pour la plupart des utilisateurs le 2026-06-18, remplacé par « Antigravity CLI » qui lirait aussi AGENTS.md et supporterait `.agents/skills/` — `gemini` reste pourtant un choix `agents` actif dans `copier.yml:210`. Claude lui-même est `pending` (non confirmé) dans le même registre | validated | core | manual | Décision produit requise : (a) retirer/déprécier `gemini`, (b) ajouter `antigravity` comme choix (recherche plus approfondie d'abord), ou (c) statu quo documenté. Hors mandat autopilot — changement de surface publique (copier.yml, MIGRATION.md) |
| P5 | Dégraisser PROJECT_STATE.md | **done** (prémisse quality-gate ×3 invalidée) | quality | docs | `d94830d` : 146→91 lignes. Quality gate ×3 relu en entier : contrat/procédure/extension-point, pas une triplication — aucun changement là |
| P6 | **Investigué, hypothèse non tranchable par archéologie de code** : `copier.yml:181` avoue toujours « best-effort, non testé end-to-end » ; aucune trace d'un consommateur TFVC réel trouvée dans ce repo (git log, docs, mémoire) — mais l'absence de preuve n'est pas la preuve de l'absence, seul l'utilisateur sait s'il existe un client TFVC réel | validated | core | manual | Question directe à l'utilisateur : connais-tu un usage TFVC réel ? Sinon → retrait propre (option + MIGRATION.md, ~286 LOC `_vcs.sh` simplifiées) ; sinon → cadrer un test e2e réel |
| P7 | Combler les 3 trous du dispositif de parité existant (la génération template→runtime existe déjà — décision ZE SOLUTION P5) : (i) drift content-check limité au profil `minimal`, (ii) aucun guard contre l'édition directe du miroir runtime, (iii) discipline « éditer les deux copies » encore codifiée dans PROJECT_STATE | triage | core | feature | Drift strict multi-profils ; édition directe du miroir bloquée ou re-générée ; PROJECT_STATE aligné sur le flux à sens unique |
| P8 | Copie unique des skills : corps en un seul fichier, `SKILL.md` Claude/Codex = pointeurs ; check CI d'égalité inter-arbres `.claude/skills` ↔ `.agents/skills` | inbox (dép. P7) | core | feature | `diff -rq` des deux arbres vide en CI ; 40 fichiers dupliqués → pointeurs |
| P9a | **Préparer la release `vNext`** : décider le bump SemVer, inventorier et basculer les recos `--vcs-ref=HEAD` consommateur vers le comportement par défaut de Copier, conserver les usages HEAD mainteneur légitimes | **done** | workflow | chore | Voir « Preuve de clôture P9a » ci-dessous |
| P9b | Scripter la release (`aic release` : checklist RELEASE.md automatisée) et brancher des `_migrations` Copier natives sur les tags | **done** | workflow | feature | `1bd808c` : `aic-release.sh` (source-only, comme RELEASE.md dont il dépend) + `_migrations` v0.14.0 (read-only, non bloquant) — jouée dans le smoke `[28c/28]` |
| P10a | Durcir l'enum `status` | **done** | quality | fix | `7b5005d` : warn→fail + miroir template ; test fixture dédié ; mesh réel (65 fiches) inchangé et vert |
| P10b | (retiré) « Builder tolérant au YAML invalide = risque silencieux » — prémisse invalidée : la compensation existe et est commentée comme telle | **dropped** | quality | dropped | Raison consignée : `check-features.sh:123-130` fait échouer (`ko`) toute fiche au frontmatter illisible ; la tolérance du builder est un contrat volontaire des hooks non-bloquants |
| P11 | Réduire les **invocations redondantes** sur le chemin de commit (~5 builds d'index temporaires par commit `feat:` ; 3 forks jq au source-time de `_lib.sh` payés par chaque hook ; hook PreToolUse Bash évaluant chaque commande) — measure-first, pas de réécriture (leçon ZE SOLUTION P4 : matching ≠ goulot, rewrite dropped) | triage | core | refactor | Mesure avant/après sur un commit `feat:` réel : builds temp 5 → 1 (réutilisation d'un index par opération), 0 fork jq sur commande bash non-commit ; aucun changement de langage |
| P12 | `aic init` (successeur du `first-run` supprimé en v0.13 sans alias) + fiche d'exemple livrée non-vide (ex. `workflow/ai-context-adoption.md` pré-remplie avec les réponses Copier en `touches:` réels) | **done** (fiche d'exemple explicitement écartée) | workflow | feature | `f34cec5` : `aic init` (doctor + hooks git idempotents + prochaine étape) livré et testé smoke ; fiche d'exemple jugée redondante avec `FEATURE_TEMPLATE.md` + le pointeur affiché — voir Décisions actées |
| P13 | `GLOSSARY.md` | **done** | product | docs | `8703973` : glossaire livré via template (`{{docs_root}}` substitué), lié README/index.md/README_AI_CONTEXT. A aussi corrigé une sur-couverture `.ai/index.md` (6 fiches → `touches_shared:`) |
| P14 | Réparer les docs d'onboarding | **done** | product | docs | `ea3fd47` : getting-started réécrit, variables.md 12/12, examples testés + référencés, `--no-write` aligné dans README |
| P15 | Aligner les noms sur l'axe `aic *`, partie **additive seulement** : route `aic onboard` manquante, alias non documentés (`frame-bootstrap`, `frame-context`), mismatch `aic plan` ↔ skill `aic-dev-plan` documenté ; tout renommage breaking reporté au chantier v1.0 (P16) | **done** | workflow | feature | `bfc6767` : routes `onboard`/`dev-plan` ajoutées (style `pilot`, skill-only) ; contrat 10/10 intentions explicité ; alias `frame-bootstrap`/`frame-context` documentés (`docs/getting-started.md`), retrait reporté à P16 |
| P16 | Gel v1.0 : étendre le moratoire bash en moratoire de surface ; définir le contrat public (format `index.md` + schéma fiche + jeu de hooks + ~10 intentions `aic`) ; critères de sortie = P7, P9, P10a, P12–P14 livrés | triage | product | manual | Décision datée ; CONTRIBUTING étendu ; contrat v1.0 énuméré ; checklist de sortie publiée |
| P17 | Boucle de feedback réelle — **prémisse initiale corrigée** : les runs réels ont déjà eu lieu (`docs/benchmarks/reports/2026-07-03-product-decision-readout.md` : N=3, 2 repos `ai_context`+`ai_debate`, +66.7 pts succès, -39.6% tokens, `decision_state=commit` déjà acté le 2026-07-03). Ce qui reste réellement ouvert : validation par un repo **vraiment indépendant** (non-mainteneur) avant tout claim `scale` — condition posée par la fiche elle-même ; `next_decision_date: 2026-07-15` dépassée sans nouvelle décision tracée ; repo démo public (publication = permission explicite requise, hors mandat autopilot) | validated | product | manual | Confirmation utilisateur : chercher un repo tiers indépendant / republier next_decision_date / accepter l'état actuel comme suffisant |
| P18a | Check CI de cohérence CHANGELOG↔PROJECT_STATE↔copier.yml | **done** | quality | feature | `5629e69` : `check-release-coherence.sh` (source-only) + path triggers CI ajoutés (sans eux le diff-only sur ces fichiers ne déclenchait même pas la CI) + RELEASE.md §4 |
| P18b | Recalibrer les rituels | **done** | product | manual | `9f109a4` : cadence recalibrée (avant chaque release + mensuelle si volume) dans `REVIEW_PROMPT.md` ; frames conservés tels quels (mécanisme légitime pour décisions structurantes uniques, distinct de pilot — pas un problème à corriger) |

## Prémisses vérifiées (preuves actuelles)

Toute affirmation ci-dessous est issue d'une commande exécutée ou d'un fichier lu en session (2026-07-23) ; les hypothèses restantes sont étiquetées.

- **P1** — `aic.sh:65-66` (aide CLI) et `aic.sh:915` (dispatch `knowledge`) : verbe routé et documenté [vérifié, rg ce jour]. Aucune invocation opérationnelle dans `.claude/settings.json`, `.githooks/`, skills [vérifié] ; la CI couvre en revanche le sous-système via `tests/unit/test-knowledge-workflow.sh` exécuté par la boucle générique (`ai-context-check.yml:98-103`) [vérifié ce jour, précision review #3] — le manque est l'usage opérationnel hooks/skills, pas la couverture de test. `.ai/index.md:62` le classe on-demand. Statuts réels [vérifiés frontmatter ce jour, correction review #2] : `product/knowledge-federation` = `active` (`:5`), stale (`progress.updated: 2026-07-03`, listée par `resume-features.sh`) ; `core/knowledge-source-contract` et `workflow/knowledge-publish-search-link` = `done`. Le `status: published` initialement rapporté était un **faux positif** : exemple YAML du schéma knowledge dans un corps de fiche (`knowledge-source-contract.md:138,146`), pas un frontmatter.
- **P2a** — `check-agent-native-context` : documenté consommateur `docs/upgrading.md:231,241` [vérifié] et **instrument du kill criterion** de `core/agents-md-native-collapse-path.md:106` (« un statut `pending` bloque tout retrait du shim ») [vérifié ce jour] ; `context-relevance-report` : documenté en interne par sa fiche `quality/context-relevance-tracker.md` (touches `:11,14`, `resume_hint:39` « calibrer via context-relevance-report --last 50 », rôle `:62`) [vérifié ce jour], mais aucune doc utilisateur publique. Aucune route `aic` pour les deux [vérifié : rg vide sur `aic.sh`]. Les deux dans `template/.ai/scripts/*.jinja` [vérifié]. `.ai/.context-relevance.jsonl` ≈ 278 Ko [mesuré]. **Leçon méthodo (review #2)** : le `rg` initial omettait les dossiers cachés (`.docs/`) faute de `--hidden` — recherches refaites avec `--hidden` ce jour.
- **P2b** — Audit runtime session : `feature-resume.md` non routé (le skill `aic-status` appelle `resume-features.sh`) ; `feature-handoff.md` référencé seulement par PROJECT_STATE/CHANGELOG/smoke ; `mcp-policy`/`subagent-contract` : 1 réf hors workflows chacun.
- **P3** — `du -sh docs/benchmarks` = 15 Mo ; 276 fichiers git-trackés [exécuté] ; plus gros `agent.stderr.log` = 1,18 Mo ; 3 `.DS_Store` trackés sous `template/` [relevé audit distribution].
- **P4** — `.ai/native-context-support.tsv` : lecture native d'`AGENTS.md` confirmée pour codex et cursor [relevé] ; ~10 règles `_exclude` de copier.yml dédiées cursor/gemini/copilot [copier.yml lu].
- **P5** — Trois artefacts gate (`quality/QUALITY_GATE.md` 100 l., `workflows/quality-gate.md` 67 l., `rules/quality.md` 7 l.) ; `index.md:59` propose les deux premiers par « ou » ; `PROJECT_STATE.md` figé sur v0.13.0/08-07 pendant que CHANGELOG `[Unreleased]` porte 16 chantiers dont ceux du 23-07 [lu].
- **P6** — `copier.yml:181` (help `vcs_provider`) : « best-effort : … aucun scaffold Copier complet n'est exercé de bout en bout » [lu] ; `_vcs.sh` 286 lignes, `tf` mocké en unit. **Hypothèse — à vérifier : aucun projet TFVC réel ne consomme l'option.**
- **P7** — `check-dogfood-drift.sh:138-145` : comparaison de contenu sur le seul profil `minimal`, profils `fullstack-cursor`/`codex-hooks` vérifiés en existence [lu audit distribution]. Décision antérieure ZE SOLUTION P5 (worklog `workflow/aic-pilot`, 2026-06-30) : la génération template→runtime existe (`dogfood-update.sh --apply`), « rien à refactorer » — l'item ne rouvre pas cette décision, il cible les trous résiduels : profil unique, absence de guard anti-édition-directe, règle des « deux copies » encore dans `PROJECT_STATE.md:115`. Casses historisées : frames supprimés (2026-06-19), échappement Jinja (2026-07-03) — `core/dogfood-runtime-sync.md` §Historique.
- **P8** — `diff -rq .claude/skills .agents/skills` : 1 seul fichier diffère (`aic/SKILL.md`) [relevé audit] ; `check-shims.sh:253-296` valide le pairage de noms, pas le contenu ; 40 fichiers `.jinja` de skills ≈ 26 % du template.
- **P9a** — `git describe --tags` = `v0.13.0-213-g1c6faaa` [exécuté ce jour] ; dernier tag daté 2026-06-01. Recos `--vcs-ref=HEAD` destinées aux consommateurs [inventaire rg --hidden ce jour] : `README_AI_CONTEXT.md:57,64`, `README.md:298`, `PROJECT_STATE.md:20,76`, `docs/variables.md:90`, `docs/upgrading.md:9,18`, `CHANGELOG.md:118` ; usages HEAD mainteneur légitimes à préserver : `RELEASE.md:27-33,49` (rendus smoke du working tree). La reco HEAD est une **mitigation délibérée** du retard de tags (`README_AI_CONTEXT.md:64`, `CHANGELOG.md:118` : « évite les downgrades involontaires ») — la cause racine est la cadence de tags. `RELEASE.md` §5 exige la décision de bump SemVer avant le tag [lu ce jour] → `vNext`, pas de version présupposée. Préconditions **non remplies** à date : bump non décidé, checklist non exécutée, HANDOFF non acté — d'où `blocked`.
- **P10a** — `check-features.sh:8` et `:162-165` : « status enum (warn, pas fail) » [lu ce jour] — le mécanisme laisserait passer un statut hors enum. Aucune occurrence réelle à date [vérifié rg --hidden ce jour, correction review #2] : tous les frontmatter du mesh sont dans l'enum ; le durcissement se prouve par fixture dédiée, sans toucher aux données. Phasage OKF : `type` volontairement en warn Phase 0 (`:184-195`).
- **P10b** — `check-features.sh:123-130` : `ko` bloquant « frontmatter YAML invalide (illisible par yq) — la fiche serait exclue de l'index » [lu ce jour] → compensation présente et commentée ; prémisse initiale invalidée, item retiré.
- **P11** — Chaîne relevée en session : PreToolUse (`check-commit-features` → build temp + freshness → build temp) + commit-msg (rebelote) + pre-commit (`auto-progress` → build `--write`) ≈ 5 builds par commit `feat:` ; `_lib.sh:96-98` : 3 forks jq au source-time. Mesure antérieure (ZE SOLUTION P4, worklog 2026-06-30) : matching ≠ goulot, parsing yq ~80 ms/fiche, réécriture Python **dropped** — l'item respecte cette décision : réduction des invocations, pas de rewrite.
- **P12** — CHANGELOG (réf. `first-run`, parcours guidé 10 min) supprimé en v0.13 sans alias (`PROJECT_STATE.md:58`) ; mesh rendu vide au scaffold (`docs/getting-started.md:38` : « aucune feature (normal au départ) »).
- **P13** — « Pack A » cité `README.md:36,402`, défini uniquement dans `.ai/index.md` [relevé] ; aucun glossaire du vocabulaire ai_context (le glossaire de `guardrails.md` est réservé au métier du projet consommateur).
- **P14** — `docs/getting-started.md` : dernier commit 2026-05-05, antérieur à la surface `aic` ; lien vers `../template/AGENTS.md.jinja` ; `docs/variables.md` documente 9 questions sur 12 (`vcs_provider`, `enable_codex_hooks` absents) ; `examples/*.yml` : 6-8 clés sur 12, zéro référence entrante [relevés audit surface].
- **P15** — Dispatch `aic.sh` : pas de route `onboard` ; route `plan` face au skill `aic-dev-plan` ; alias `frame`/`frame-bootstrap`/`frame-context` dont 1 seul documenté README [relevé].
- **P16** — Moratoire moteur bash déjà posé (commit `51e3261`, CONTRIBUTING) ; mesh à 64/65 fiches closes [comptés] : la phase de construction est finie.
- **P17** — Roadmap P3 `PROJECT_STATE.md:102` « Repo démo externe » ouverte ; fiche `product/agent-efficacy-benchmark` : scaffold livré (`0164289`), runs réels = action mainteneur en attente [worklog aic-pilot:42]. **Hypothèse — à vérifier : aucun consommateur externe actuel.**
- **P18a** — Recommandation de l'audit 07-07 (« check CI de cohérence… sinon la dette se reforme ») non implémentée [aucun script correspondant trouvé] ; récidive constatée : PROJECT_STATE ignore les chantiers du 23-07.
- **P18b** — Audits datés : 06-05, 08-06, 03-07, 07-07 ; aucun depuis (16 j au 23-07) ; frames : 3 réels, dernier le 2026-06-28 [comptés].

## Challenges (phase 2 — à l'attention de la review Codex #2)

- **P1** : trois options non équivalentes — mesurer (cohérent avec l'éthos measure-first du repo), geler (solde les fiches, garde le verbe CLI), extraire (le plus lourd). Le travail de conception investi (contrat minimal + MVP décidés) plaide contre l'extraction sèche. Arbitrage produit utilisateur requis ; critère de kill à poser quelle que soit l'option.
- **P2a** : les deux scripts ne sont pas dans la même situation — l'un est documenté consommateur ET porte le kill criterion qui gate P4 (le déprécier pendant que P4 est ouvert serait incohérent ; l'exposer via `doctor`/CI serait cohérent) ; l'autre est un reporter contractuel documenté en interne mais sans surface publique. Si `context-relevance-report.sh` est déprécié, trancher aussi le logging câblé (`context-relevance-log.sh`, hooks Stop/PostToolUse) : conserver une télémétrie que rien ne lit n'a pas de sens ; l'exposer via `aic` en a peut-être un.
- **P4** : réduit la promesse « 5 agents » du README — décision de positionnement, pas technique. La table Honnêteté runtime assume déjà que cursor/gemini/copilot sont des shims passifs.
- **P5** : `PROJECT_STATE.md` est un point d'entrée mainteneur cité par plusieurs docs : dégraisser ≠ supprimer (garder but/remote/version/reprise + roadmap).
- **P6** : coût de portage déjà payé ; le coût réel est le maintien + l'aveu « non testé e2e » dans un fichier lu par tout nouvel utilisateur. Si un client TFVC existe, inverser la route : tester e2e au lieu de retirer.
- **P7** : ne PAS re-ouvrir la décision ZE SOLUTION P5 (« rien à refactorer » sur la génération) — l'item ne vise que les trous du dispositif : multi-profils, guard, doc de flux. Point d'attention ergonomie : l'édition des `.jinja` impose l'échappement `{% raw %}` (garde `test-template-jinja-raw-braces.sh` existante).
- **P9a** : item le plus rentable du lot mais bloqué à juste titre. Ordre corrigé en review #3 : le HANDOFF product→workflow + confirmation doivent précéder la checklist RELEASE.md, car elle **contient des éditions documentaires** de ce scope (CHANGELOG finalisé, PROJECT_STATE, README…) — séquence actée : décision SemVer → HANDOFF + confirmation → checklist intégrale → confirmation tag/push → tag. Attention de fond : la reco HEAD étant une mitigation documentée du retard de tags, la basculer vers `--vcs-ref=<tag>` sans rétablir une cadence de tags recréerait le problème qu'elle évite (downgrade involontaire) — P9a doit donc inclure l'engagement de cadence (relayé par P9b).
- **P11** : borné par la mesure antérieure — interdiction de réécriture, obligation de mesurer avant/après ; si la mesure montre que les builds temp sont déjà négligeables (~80 ms/fiche × 65 fiches à confirmer), l'item se réduit ou se droppe comme ZE SOLUTION P4.
- **P15** : la v0.13 a déjà cassé la surface CLI sans aliases ; seule la partie additive passe maintenant, les renommages attendent v1.0.
- **P17** : partiellement hors repo (projets réels) ; le registre ne suit que la partie repo (démo, runs bench, rapport).

## Question active

Contexte affiché :

- Review #1 (bloquante) : 6 constats appliqués. Review #2 (go avec réserves) : 3 corrections factuelles appliquées. Review #3 (go avec réserves) : **fond validé** — ordre HANDOFF/checklist corrigé dans P9a, précision CI/opérationnel intégrée à P1 ; Codex indique qu'aucune nouvelle review complète n'est nécessaire.
- Le cadrage est donc validé ; l'exécution reste conditionnée aux confirmations utilisateur prévues item par item.

Question à traiter maintenant :

- **P9a est livré et clos (voir preuve ci-dessous).** Quel item de la carte devient actif ensuite ? Candidats : vague hygiène (P3, P10a, P13, P14) ou une décision structurante (P1, P2a, P4, P6, P16).

## Preuve de clôture P9a

- Bump : **v0.14.0** (MINOR), motivé dans les Décisions actées ci-dessous.
- Commit préalable des artefacts de pilotage : `f62e2d8`.
- Smoke-test : PASS (exit 0, relancé 3× à des étapes différentes, dernière fois immédiatement avant le commit de release — aucune régression).
- 7 rendus Copier critiques (RELEASE.md §2) : tous OK. A révélé un bug réel — `--data agents=codex` (syntaxe documentée) rejeté par Copier 9.14.3 car `agents` est `multiselect` (attend une liste YAML, ex. `agents=[codex]`) ; contourné pour ce run, non corrigé dans RELEASE.md (documentation de la syntaxe multiselect — hors scope P9a, à reporter si récurrent).
- `copier update` sur consommateur réel : testé sur une **copie jetable** de `ai_debate` (jamais l'original — vérifié `git status` propre avant et après sur le repo réel). 214 commits de rattrapage depuis `v0.13.0-205-g5e441a6`, 0 fichier `.rej`, mesh utilisateur (18 fiches) intact, `check-shims`/`check-features --no-write` PASS sur le résultat. A révélé un bug réel dans `RELEASE.md:49` — corrigé (voir Décisions actées).
- Documentation (RELEASE.md §4) : CHANGELOG (section `[0.14.0]` + nouveau `[Unreleased]` vide), PROJECT_STATE (version, état v0.14.0 avec rappel v0.13.0 préservé, tags), README.md + README_AI_CONTEXT.md (+ miroir `template/*.jinja`, parité confirmée par `check-dogfood-drift`), MIGRATION.md (nouvelle section cockpit de migrations, comblant un écart réel trouvé en cours de route), docs/upgrading.md, docs/variables.md. 8 fiches feature mises à jour (Historique ou worklog « couverture incidente »).
- Gates finaux, tous PASS : `check-features --no-write`, `check-shims`, `check-feature-docs --strict`, `check-ai-references`, `check-feature-freshness --staged --strict` (a détecté un vrai trou de couverture sur `MIGRATION.md` pour 2 fiches non anticipées — corrigé), `check-dogfood-drift`, `tests/smoke-test.sh`.
- Tag + push : `git tag v0.14.0` sur commit `5c34108` ; `git push origin main` (`1c6faaa..5c34108`) ; `git push origin v0.14.0`. `git describe --tags` = `v0.14.0` exact (le décrochage de 213 commits est résolu).
- RELEASE.md §7 (sanity post-release) : `copier copy --vcs-ref=v0.14.0 gh:qhuy/ai_context` depuis GitHub (donc après push) → rendu OK ; `check-shims` PASS ; `doctor.sh` PASS (3 avertissements attendus : pas de repo git initialisé dans le rendu brut, exactement le comportement documenté).
- Worktree final : propre (`git status --short` vide).

## Décisions actées

| Date | Item | Décision | Raison | Suite |
|---|---|---|---|---|
| 2026-07-23 | (registre) | Pilotage enclenché sur les 18 propositions ; registre durable créé ; review Codex demandée avant exécution large | Demande utilisateur explicite | Registre soumis à review |
| 2026-07-23 | (registre) | Review Codex #1 = BLOQUANTE ; 6 constats appliqués : P9a maintenu `blocked` (préconditions RELEASE.md + HANDOFF), P1 requalifié (verbe CLI routé — enjeu adoption, vérifié `aic.sh:915`), P2a requalifié (CLI documentée consommateur, vérifié `upgrading.md:231`), P10 scindé (P10a fix enum ; P10b dropped — compensation prouvée `check-features.sh:123-130`), routes normalisées (une route unique/item), prémisses actuelles ajoutées avec preuves | Constats re-vérifiés dans le code avant application ; 2 prémisses initiales étaient sur-qualifiées (P1 « île », P2a « orphelin ») et 1 invalide (P10 builder) | Re-review Codex |
| 2026-07-23 | P10b | dropped | Prémisse invalidée : `check-features.sh:123-130` bloque (`ko`) toute fiche au frontmatter illisible ; tolérance du builder = contrat volontaire des hooks non-bloquants | — |
| 2026-07-23 | P7, P11, P17 | Reframés sur les décisions antérieures du pilotage ZE SOLUTION (worklog `workflow/aic-pilot`, 2026-06-30) : P7 ne rouvre pas « source unique » (existante), il comble ses trous ; P11 est measure-first sans réécriture ; P17 s'appuie sur la fiche `product/agent-efficacy-benchmark` existante | Cohérence avec l'historique du repo ; éviter de re-litiger des décisions actées | Intégrés à la carte |
| 2026-07-23 | (registre) | Re-review Codex #2 = **go avec réserves** ; 3 corrections appliquées après re-vérification code : (1) `published` = faux positif (exemple YAML de corps de fiche, `knowledge-source-contract.md:138` — le frontmatter réel est `active`) → P1 recompté à 1 fiche non close, P10a sans correction de donnée ; (2) `context-relevance-report.sh` documenté en interne (`quality/context-relevance-tracker.md`) → P2a reformulé « aucune doc utilisateur publique ni route aic » ; (3) P9a reformulé « préparer la release `vNext` » : bump SemVer d'abord (RELEASE.md §5), inventaire complet des recos HEAD consommateur (6 fichiers), usages mainteneur préservés | Les 3 réserves vérifiées fondées ; cause racine du (2) consignée : `rg` sans `--hidden` ignore `.docs/` | Soumis pour GO complet |
| 2026-07-23 | (registre) | Review Codex #3 = go avec réserves, **fond validé** ; 2 corrections appliquées après vérification : (1) ordre P9a corrigé — HANDOFF product→workflow + confirmation AVANT la checklist RELEASE.md (elle contient des éditions documentaires de ce scope ; séquence : SemVer → HANDOFF → checklist → confirmation tag/push → tag) ; (2) P1/P2a reformulés « invocation opérationnelle » — la CI couvre bien ces surfaces via leurs tests unitaires dans la boucle générique (`ai-context-check.yml:98-103`, vérifié), le manque est l'usage hooks/skills | Codex précise qu'aucune nouvelle review complète n'est requise ; le cadrage passe en phase d'exécution conditionnée aux confirmations utilisateur | Question active = activation de P9a |
| 2026-07-24 | P5, P10a, P18a | Scope quality clos (3/3, mandat autopilot). P5 : prémisse « quality gate ×3 » invalidée après lecture complète (contrat/procédure/extension-point) — seul PROJECT_STATE.md dégraissé. P10a : durcissement sans impact sur le mesh réel. P18a : nouveau check `check-release-coherence.sh`, a aussi révélé que la CI ne se déclenchait même pas sur un diff limité à CHANGELOG/PROJECT_STATE/copier.yml (path triggers manquants, corrigés) | Gates + smoke-test complets PASS après chaque commit | HANDOFF quality→core émis pour P2a/P4/P6/P7/P8/P11 |
| 2026-07-24 | P7, P8, P11 | Scope core clos (3/3 exécutés). P7 : prémisse corrigée (aucune copie runtime des fichiers scopés à comparer, ce repo dogfoode `minimal` — fix = sanity de rendu + nouveau `check-runtime-template-mirror.sh`). P8 : prémisse corrigée (1 seule divergence réelle sur toute la surface skills, intentionnelle) — fix = `check-skills-parity.sh` templaté plutôt qu'une restructuration risquée. P11 : mesure confirmée et plus grave qu'estimé (1024 forks yq, ~5s/build, ~25s/commit simulé) — optimisé à ~1.9s/~9.2s (2.7x), avec un vrai bug de précédence bash `read`+`IFS=tab` détecté et documenté en cours de route | Diff sémantique JSON strict + 9 tests unitaires + smoke-test complet PASS | HANDOFF core→workflow émis pour P2b/P9b/P12/P15 |
| 2026-07-24 | P2a, P4, P6 | Investigués, non décidés (route `manual`). P2a : `check-agent-native-context.sh` n'est pas orphelin, il a servi à valider le retrait déjà livré des shims cursor/copilot. P4 : prémisse partiellement obsolète — cursor/copilot déjà réduits ce cycle ; **trouvaille nouvelle** (recherche web) : Gemini CLI décommissionné par Google le 2026-06-18, remplacé par Antigravity CLI (lirait aussi AGENTS.md) — `gemini` reste pourtant un choix actif `copier.yml`. P6 : hypothèse TFVC non tranchable par archéologie de code, requiert la connaissance directe de l'utilisateur | Recherche web datée pour P4 ; code lu pour P2a ; absence de preuve non concluante pour P6 | Arbitrage utilisateur requis sur les 3 |
| 2026-07-24 | P2b, P9b, P12, P15 | Scope workflow clos (4/4). P2b : prémisse d'élagage invalidée après vérification (`mcp-policy`/`subagent-contract` activement routés, pas morts) — seul un fix réel livré (référence stale dans `feature-update.md`). P9b : `aic-release.sh` livré source-only après découverte en cours de route qu'il dépend de `RELEASE.md`/`check-release-coherence.sh`, eux-mêmes source-only — câblage initial dans `aic.sh`+template corrigé ; migration native `_migrations` v0.14.0 câblée en lecture seule (garde non-bloquant en fin de commande) après avoir prouvé empiriquement que le scénario `v0.11.0→HEAD` produit de vrais `.rej` (sans le garde-fou, `copier update` aurait échoué). P12 : `aic init` livré, fiche d'exemple explicitement écartée (redondante avec `FEATURE_TEMPLATE.md`). P15 : 2 routes manquantes ajoutées (`onboard`, `dev-plan`), écart de contrat corrigé (liste 10/10 intentions), alias documentés | Gates + smoke-test complets PASS après chaque commit ; 2 régressions réelles détectées et corrigées en cours de route (P9b : dogfood-drift cassé par un fichier non mirrorré ; design flaw source-only découvert avant merge, pas après) | HANDOFF core→workflow marqué RÉSOLU ; HANDOFF workflow→product émis pour P16 |
| 2026-07-23 | P9a | **Activé** (« go » utilisateur). Bump proposé : **v0.14.0 (MINOR)** — `[Unreleased]` dominé par de l'additif (2 nouvelles questions Copier à défaut sûr, cockpit `aic migrate`, index progressifs, 2 skills, gates advisory, OKF Phase 0 explicitement non-cassant) ; les 2 changements de comportement (élagage shims Copilot/Cursor, gate Stop) ont migration documentée + échappatoires, conformes au précédent v0.13.0 (breaking documenté = MINOR en 0.x). v1.0.0 est réservé au jalon P16 | RELEASE.md §5 ; précédent v0.12→v0.13 ; SemVer 0.x | HANDOFF product→workflow soumis à confirmation utilisateur avant toute édition |
| 2026-07-24 | P9a | **« go jusqu'au bout » utilisateur** (bump + HANDOFF confirmés implicitement par le mandat d'exécution complète). Checklist RELEASE.md §1-7 exécutée intégralement. 2 bugs réels trouvés et corrigés en route, hors registre initial : (a) `RELEASE.md:32` syntaxe `--data agents=codex` cassée sous Copier 9.14.3 (multiselect exige une liste YAML) — contournée à l'exécution ; (b) `RELEASE.md:49` `copier update` documenté avec un positionnel source qui n'existe pas (seul `destination_path` est positionnel) — **corrigé dans RELEASE.md** avec la méthode sûre (clone jetable + édition `_src_path`). 1 trou de couverture réel trouvé par la gate freshness elle-même (`MIGRATION.md` non couvert par `core/migration-orchestrator` malgré `touches_shared:` déjà présent — 2 fiches voisines `core/okf-strict-profile`/`quality/read-only-checks-contract` mises à jour en « couverture incidente », pattern déjà établi par `aic-pilot`) | Preuve complète : voir « Preuve de clôture P9a » | **done** — tag `v0.14.0` poussé, sanity post-release PASS |

## Handoffs

```text
HANDOFF
  from_scope: product
  to_scope: workflow
  status: RÉSOLU — exécuté intégralement et confirmé par l'utilisateur (« go jusqu'au bout »), clos 2026-07-24
  files_touched: [
    CHANGELOG.md (Unreleased → section v0.14.0, nouveau Unreleased vide) — fait,
    PROJECT_STATE.md (version publiée, état v0.14.0, tags) — fait,
    README.md (reco HEAD + sync table env vars, AIC_DOC_GATE ajouté) — fait,
    README_AI_CONTEXT.md + template/README_AI_CONTEXT.md.jinja (parité vérifiée check-dogfood-drift) — fait,
    docs/upgrading.md, docs/variables.md — fait,
    MIGRATION.md (nouvelle section cockpit de migrations — écart réel trouvé et comblé) — fait,
    RELEASE.md (2 bugs réels corrigés : syntaxe multiselect §2, positionnel update §3) — fait,
    8 fiches feature (Historique ou worklog couverture incidente) — fait,
    tag v0.14.0 (commit 5c34108, poussé) — fait
  ]
  pending: []  # tout résolu, RELEASE.md §7 sanity post-release PASS
  risks: [
    la bascule HEAD→tag sans cadence de tags recrée le risque de downgrade documenté (mitigé : P9b + note de cadence dans les docs),
    le pre-commit flushe les worklogs en attente — vérifié : commit préalable `f62e2d8` ne contenait que les 2 fichiers attendus,
    checklist sans transaction — non matérialisé : les 4 étapes (test/rendus/update/docs) ont toutes réussi avant le commit unique de release `5c34108`
  ]
```

```text
HANDOFF
  from_scope: product
  to_scope: quality
  status: RÉSOLU — 3/3 items livrés, clos 2026-07-24
  files_touched: [PROJECT_STATE.md (d94830d), check-features.sh + template (7b5005d), check-release-coherence.sh nouveau + CI + RELEASE.md (5629e69)]
  pending: []
  risks: [aucun matérialisé]
```

```text
HANDOFF
  from_scope: quality
  to_scope: core
  status: RÉSOLU — 6/6 items traités (3 exécutés, 3 investigués), clos 2026-07-24
  files_touched: [check-dogfood-drift.sh + check-runtime-template-mirror.sh nouveau (8494b6e), check-skills-parity.sh nouveau (1015e87), build-feature-index.sh optimisé (074438a)]
  pending: []
  risks: [aucun matérialisé — P2a/P4/P6 correctement laissés à l'arbitrage utilisateur, pas de retrait exécuté unilatéralement]
```

```text
HANDOFF
  from_scope: core
  to_scope: workflow
  status: RÉSOLU — 4/4 items livrés, clos 2026-07-24
  files_touched: [feature-update.md corrigé (3be389d), aic-init.sh nouveau (f34cec5), aic-release.sh nouveau + _migrations copier.yml (1bd808c), aic.sh routes onboard/dev-plan (bfc6767)]
  pending: []
  risks: [aucun matérialisé — P2b et P12 (fiche d'exemple) ont vu leur prémisse initiale corrigée avant exécution plutôt qu'exécutée telle quelle, cohérent avec la discipline de preuve du registre]
```

```text
HANDOFF
  from_scope: workflow
  to_scope: product
  status: en cours (mandat autopilot, 2026-07-24)
  files_touched: [P16 pas encore commencé]
  pending: [P16 gel v1.0 : vérifier les critères de sortie (P7/P9/P10a/P12-14, tous livrés désormais), définir le contrat public (index.md + schéma fiche + hook set + 10 intentions aic), étendre le moratoire bash en moratoire de surface, publier une checklist de sortie]
  risks: [P16 est une décision de positionnement/gel, pas un fix mécanique — nécessite probablement une confirmation utilisateur explicite avant d'être marqué done, contrairement aux items purement techniques traités jusqu'ici]
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| P9a | Préparation + exécution release v0.14.0 | Claude (mandat « go jusqu'au bout ») | done | tag `v0.14.0` sur `5c34108`, poussé ; sanity RELEASE.md §7 PASS ; voir « Preuve de clôture P9a » |
| P3 | Dé-versionner docs/benchmarks/runs/ | Claude (mandat autopilot) | done | `f0619c0` |
| P13 | GLOSSARY.md | Claude (mandat autopilot) | done | `8703973` |
| P14 | Réparer docs onboarding | Claude (mandat autopilot) | done | `ea3fd47` |
| P18b | Recalibrer rituels | Claude (mandat autopilot) | done | `9f109a4` |
| P1 | Investiguer adoption hub knowledge | Claude (mandat autopilot) | validated | Adoption = 0 mesuré ; recommandation geler ; décision finale utilisateur en attente |
| P17 | Investiguer usage réel | Claude (mandat autopilot) | validated | Prémisse corrigée (runs réels déjà faits, decision_state déjà commit) ; reste ouvert : repo tiers indépendant |
| P5 | Dégraisser PROJECT_STATE.md | Claude (mandat autopilot) | done | `d94830d` |
| P10a | Durcir enum status | Claude (mandat autopilot) | done | `7b5005d` |
| P18a | check-release-coherence.sh | Claude (mandat autopilot) | done | `5629e69` |
| P7 | Combler les 3 trous dogfood-drift | Claude (mandat autopilot) | done | `8494b6e` |
| P8 | check-skills-parity.sh | Claude (mandat autopilot) | done | `1015e87` |
| P11 | Consolider forks yq/jq build-feature-index | Claude (mandat autopilot) | done | `074438a` |
| P2a | Investiguer 2 CLI standalone | Claude (mandat autopilot) | validated | `check-agent-native-context.sh` non orphelin ; `context-relevance-report.sh` reste à statuer |
| P4 | Investiguer réduction agents | Claude (mandat autopilot) | validated | Cursor/copilot déjà réduits ; Gemini CLI décommissionné (recherche web datée) — arbitrage requis |
| P6 | Investiguer sort TFVC | Claude (mandat autopilot) | validated | Hypothèse non tranchable sans connaissance directe utilisateur |
| P2b | Corriger la chaîne de procédure feature-update | Claude (mandat autopilot) | done | `3be389d` (prémisse d'élagage invalidée avant exécution) |
| P12 | aic init | Claude (mandat autopilot) | done | `f34cec5` |
| P9b | aic-release.sh + migration native v0.14.0 | Claude (mandat autopilot) | done | `1bd808c` |
| P15 | Routes aic.sh onboard/dev-plan | Claude (mandat autopilot) | done | `bfc6767` |

## Validation de clôture

- P9a, P3, P13, P14, P18b, P5, P10a, P18a, P7, P8, P11, P2b, P9b, P12, P15 : `done`, preuve complète fournie (15/18 items). P1, P17, P2a, P4, P6 : `validated` (investigués, recommandation prête, arbitrage final utilisateur — 5/18). Seul P16 reste `triage` (18/18 comptabilisés) — le registre reste `active` jusqu'à P16.
- Aucune fiche feature globale créée ; chaque item routé `feature` a sa fiche propre (`workflow/aic-init`, `workflow/aic-release`), les corrections mineures hors mesh (RELEASE.md, feature-update.md) sont restées `docs`/`chore` en place.
- Chaque preuve de P9a est renseignée (commandes exécutées, gates PASS, tag vérifié). Chaque item workflow (P2b/P9b/P12/P15) a vu sa prémisse initiale re-vérifiée avant exécution — 2 corrections notables (P2b : élagage annulé, prémisse fausse ; P9b : `aic-release.sh` re-scopé en source-only après découverte d'une dépendance elle-même source-only, détectée par une régression réelle du smoke-test).
- La quality gate (smoke-test + check-* + freshness + dogfood-drift + check-runtime-template-mirror + check-skills-parity) est passée avant chaque commit, sans exception.

## Next hint

Scope workflow **clos (4/4)**. Seul **P16** (gel v1.0, scope product) reste sur la carte parmi les items non-utilisateur. Ses critères de sortie déclarés (P7, P9, P10a, P12–P14) sont tous livrés désormais — à vérifier explicitement avant de déclarer P16 `done`, puisque c'est une décision de positionnement (probablement `manual`, nécessitant confirmation utilisateur) plutôt qu'un fix mécanique comme les 14 items précédents.

P1, P17, P2a, P4, P6 restent `validated`, affichés pour arbitrage utilisateur à sa convenance — non bloquants pour P16 ni pour la clôture du registre.

Rappels méthodo acquis cette session : `rg --hidden` pour toute recherche de références dans ce repo (sinon `.docs/` est ignoré) ; tester `copier update` uniquement sur une copie jetable, jamais un repo consommateur réel ; `copier copy`/`update` non-interactifs exigent `--defaults` + `--data project_name=...` (pas de TTY dans ce contexte) ; avant de câbler un nouveau script dans `aic.sh`, vérifier s'il dépend d'un artefact source-only (`RELEASE.md`, `check-release-coherence.sh`…) — si oui, il doit lui-même rester source-only, jamais templaté ni dispatché ; pour toute entrée `_migrations` Copier, lire le code source installé plutôt que supposer le schéma, et vérifier empiriquement l'effet d'un `.rej` préexistant avant de la rendre bloquante.
