---
pilot_id: "2026-07-23-analyse-fonctionnelle-generale"
status: "active"
source: "analyse fonctionnelle générale 2026-07-23 (session Claude — 4 sous-audits : runtime .ai/, distribution Copier, surface utilisateur, santé du process) ; review Codex #1 (bloquante) et re-review #2 (go avec réserves) appliquées le 2026-07-23"
scope_primary: "product"
created_at: "2026-07-23"
updated_at: "2026-07-24"
active_item: "P16"
active_question: "Review Codex #4 (P16) = BLOQUANTE, 7 constats re-vérifiés (6 acceptés, 1 accepté-réserve recadré), verdict confirmé par les preuves. Proposition v3 rédigée : contrat 8 éléments, checklist 3 blocs, CONTRIBUTING adossé à un manifeste de surface. En attente : re-review Codex round 2 de la v3 (prompt fourni), puis décisions utilisateur Bloc A (P4 gemini/antigravity — prémisse corrigée et vérifiée aux sources, classification CLI, `type` requis dès v1.0 ou non)."
next_hint: "1) Re-review Codex de la § Proposition P16 v3 (prompt fourni 2026-07-24). 2) Après verdict : décisions utilisateur Bloc A (P4 : conserver gemini qualifié Enterprise / ajouter antigravity / déprécier ; classification CLI stable-deprecated-interne ; type requis). 3) Puis chantiers Bloc B (E2E TFVC smoke + validation réelle mainteneur + chemin d'upgrade TFVC tranché, fix doc feature-index-cache, test upgrade v0.14→v1, MIGRATION/CHANGELOG) et Bloc C (manifeste de surface, CONTRIBUTING v3, tag)."
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
| P1 | Statuer sur le hub knowledge — gel confirmé par l'utilisateur le 2026-07-24 et **exécuté**. Nuance de preuve actée en self-review : `.context-relevance.jsonl` ne loggue que les événements inject/touch des hooks Write/Edit et ne pouvait structurellement PAS capturer un usage CLI `aic knowledge` — la preuve porteuse est l'archéologie worklogs/commits (uniquement des commits de construction), pas la télémétrie. Aucun kill criterion déclenché : cut faute de signal d'adoption à date de décision échue (2026-07-15) | **done** | product | manual | `product/knowledge-federation` : `decision_state: cut`, `status: done` (règle product : « done avec décision de cut documentée »), code conservé intact, réversible sur usage réel tracé |
| P2a | **Statu quo acté par l'utilisateur le 2026-07-24** : `check-agent-native-context.sh` reste tel quel (il a validé le retrait des shims cursor/copilot) ; `context-relevance-report.sh` reste outillage mainteneur non exposé via `aic`. Argument retenu : cette télémétrie a un lecteur réel — l'investigation P1 elle-même l'a consommée ce cycle | **done** | core | manual | Décision statu quo documentée ici ; aucun changement de code (c'était le but) |
| P2b | **Recadré — prémisse d'élagage invalidée** : `mcp-policy.md`/`subagent-contract.md` sont activement routés (`.ai/rules/workflow.md`, `README_AI_CONTEXT.md`), pas morts ; supprimer `feature-resume.md`/`feature-handoff.md` casserait des chaînes documentées (`feature-done.md`, `claude-skills.md` via `touches:`). Seul fix réel livré : `feature-update.md` citait `feature-handoff.md` comme étape active alors que le HANDOFF cross-scope est le format inline `.ai/rules/workflow.md` | **done** | workflow | docs | `3be389d` : ligne « Procedure chain » corrigée (+ miroir template) ; zéro workflow supprimé (décision, pas oubli) |
| P3 | Dé-versionner `docs/benchmarks/runs/` | **done** | product | chore | `f0619c0` : 246 fichiers untracked, conservés sur disque ; `.DS_Store` déjà gitignorés (jamais tracked — prémisse initiale corrigée) |
| P4 | **Prémisse corrigée par la review Codex #4 et re-vérifiée aux deux sources officielles (2026-07-24)** : Gemini CLI n'est PAS décommissionné universellement — la coupure du 2026-06-18 vise les offres grand public (AI Pro/Ultra/free) ; **licences Enterprise/Standard, clés API payantes et Google Cloud restent supportés** (annonce developers.googleblog.com vérifiée par fetch). Antigravity CLI lit officiellement `GEMINI.md` + `AGENTS.md` et les skills sous `.agents/skills/` (guide antigravity.google/docs/cli/gcli-migration vérifié par fetch) — mais `.agents` n'est rendu que si `codex` est sélectionné (`copier.yml:26`), le support Antigravity n'est donc pas modélisé. Acquis antérieurs inchangés : cursor/copilot natifs AGENTS.md, shims déjà réduits ce cycle | validated | core | manual | Décision requise **avant le tag v1.0** (cf. Proposition P16 Bloc A) : (a) conserver `gemini` qualifié « Enterprise/API payante » dans le help, (b) ajouter `antigravity` comme valeur indépendante (modéliser `.agents/skills` au-delà de codex), (c) déprécier/retirer avant gel. Jamais de réinterprétation silencieuse d'une réponse `gemini` existante |
| P5 | Dégraisser PROJECT_STATE.md | **done** (prémisse quality-gate ×3 invalidée) | quality | docs | `d94830d` : 146→91 lignes. Quality gate ×3 relu en entier : contrat/procédure/extension-point, pas une triplication — aucun changement là |
| P6 | **Tranché par l'utilisateur le 2026-07-24 : TFVC est le repository PRINCIPAL de son organisation** — la compatibilité est importante, retrait définitivement écarté. L'hypothèse d'archéologie (« aucun consommateur TFVC ») était fausse faute de pouvoir voir hors du repo. Conséquence : le gap réel s'inverse — `copier.yml:181` avoue « best-effort, non testé e2e » sur le provider le plus important de l'utilisateur, et les git hooks n'existent pas en TFVC (enforcement partiel : hooks Claude + CI seulement). La route de la carte prévoyait ce cas : « si un client TFVC existe → cadrer un test e2e réel » | **done** (décision) | core | manual | Décision documentée ; suite recommandée (non exécutée) : cadrer un test e2e TFVC via `aic-frame` — question posée à la review Codex P16 : critère de sortie v1.0 ou post-v1.0 ? |
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
| P16 | **Review Codex #4 = BLOQUANTE** (7 constats : périmètre incomplet + mélange contrat/implémentation, surface CLI > 10 intentions, prémisse P4 à corriger, E2E TFVC exigé, 6/6 nécessaire mais insuffisant, moratoire humain trop faible en réserve). Tous re-vérifiés en session : 6 acceptés avec preuve, 1 accepté-réserve recadré. **Proposition v3 rédigée** : contrat 8 éléments (questions Copier, CLI classifiée stable/deprecated/interne, schéma, index JSON, config.yml, shims, garanties comportementales des hooks, matrice d'enforcement), checklist de sortie en 3 blocs (A décisions, B chantiers, C gouvernance/manifeste) | validated | product | manual | Re-review Codex de la v3 (prompt fourni 2026-07-24), puis décisions Bloc A (P4, classification CLI, `type` requis) |
| P17 | Boucle de feedback réelle — **arbitrage utilisateur 2026-07-24 : mode opportuniste acté**. Pas de chantier dédié ; le benchmark sera rejoué le jour où un vrai projet externe (non-mainteneur) se présente — forcer artificiellement irait contre l'exigence « vraiment indépendant » de la fiche. `next_decision_date` re-datée 2026-07-15 → 2026-10-01 (elle était échue de 9 jours ; même « différer » doit re-stamper la date, sinon la discipline du product loop pourrit). Réserve « pas de scale public avant preuve indépendante » inchangée | **done** (décision) | product | manual | `product/agent-efficacy-benchmark` re-datée + Historique/worklog mis à jour ; au 2026-10-01 : run tiers si disponible, sinon re-dater explicitement |
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
- **P16** — Moratoire moteur bash déjà posé (commit `51e3261`, CONTRIBUTING) ; mesh à 64/65 fiches closes [comptés] : la phase de construction est finie. Vérification complète 2026-07-24 : 6/6 critères de sortie confirmés `done` avec commit (P7 `8494b6e`, P9/P9a tag `v0.14.0`, P10a `7b5005d`, P12 `f34cec5`, P13 `8703973`, P14 `ea3fd47`) [carte relue ce jour]. 10 intentions `aic-*` confirmées routées (`.claude/skills/` : aic, aic-onboard, aic-frame, aic-pilot, aic-dev-plan, aic-status, aic-diagnose, aic-document-feature, aic-review, aic-ship) [`ls` ce jour]. Jeu de hooks lu directement dans `.claude/settings.json` : 4 types (UserPromptSubmit, PreToolUse ×2 matchers, PostToolUse, Stop), 5 scripts distincts. Format `index.md` : contrat déjà écrit dans `core/feature-mesh-progressive-indexes.md` § Contrats (layout, marqueur de propriété, déterminisme). Moratoire bash existant relu en entier (`CONTRIBUTING.md:52-77`) : règle de revue humaine écrite, pas de gate automatisé — modèle d'enforcement proposé pour son extension.
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
- **P16** : risque de geler prématurément si P1/P2a/P4/P6 (encore ouverts) changent la surface après coup. Contre-argument retenu : ces 4 items portent sur des DÉCISIONS DE POSITIONNEMENT (quels agents supportés, quel hub conservé) qui n'altèrent ni le schéma fiche, ni le format index.md, ni le jeu de hooks, ni la liste des 10 intentions `aic-*` — le contrat STRUCTUREL reste stable quelle que soit leur issue. Le gel proposé porte donc explicitement sur ce contrat structurel, pas sur le produit fini. Second risque : un moratoire non gaté automatiquement (comme le moratoire bash) dépend entièrement de la discipline de revue humaine — accepté comme précédent cohérent avec l'ADR bash existante, pas un nouveau risque introduit par cet item.

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

## Proposition P16 — gel v1.0, version 3 (post-review Codex #4, en attente de re-review)

Historique de version : v1 (contrat 4 éléments) → v2 (amendements self-review : caveat SemVer, question TFVC) → **review Codex #4 = BLOQUANTE** (7 constats, tous re-vérifiés en session le 2026-07-24 : 6 acceptés avec preuve, 1 accepté comme réserve recadrée) → **v3 ci-dessous**. Le détail des re-vérifications est consigné dans la ligne « Décisions actées » du 2026-07-24 (review #4).

**Critères de sortie historiques** (P7 `8494b6e`, P9/P9a tag `v0.14.0`, P10a `7b5005d`, P12 `f34cec5`, P13 `8703973`, P14 `ea3fd47`) : tous livrés — **requalifiés par la review #4 (constat 7, accepté) : preuve de livraison du backlog préparatoire, PAS preuve de stabilité du contrat.** Remplacés par la checklist de sortie ci-dessous.

### Contrat public v1.0 (8 éléments)

Règle SemVer transverse : retrait/renommage/resserrement d'un élément gelé = MAJOR ; ajout rétro-compatible à défaut sûr = MINOR ; fix = PATCH.

1. **Questions Copier** : les 12 identifiants, types, valeurs de choix, défauts, et leurs effets de rendu (matrice `_exclude` par `agents`/`scopes`/`adoption_mode`/`vcs_provider`/`tech_profile`/`enable_*`, `copier.yml:19-57`). Retirer une question **ou une valeur de choix** = MAJOR (casse `copier update` des consommateurs l'ayant sélectionnée). Source : déjà qualifié de contrat par `core/template-engine.md` § Contrats.
2. **Surface CLI classifiée** (`aic.sh`, chaque route classée — proposition, décision utilisateur requise) :
   - `stable` (gelées, retrait = MAJOR) : `init`, `frame`, `pilot`, `dev-plan`, `status`, `diagnose`, `document-feature`, `review`, `ship`, `onboard` ;
   - `deprecated` (fonctionnent, sortent de « Commandes utilisateur » dans l'aide, retrait possible v2) : `frame-bootstrap`, `frame-context` (alias stricts), `knowledge` (cohérence avec le cut P1 : code intact, plus présenté comme commande utilisateur) ;
   - `interne/maintenance` (non contractuelles, évolution MINOR documentée) : `repair`, `repair-copier-metadata`, `template-diff`, `doctor`, `resume`, `audit`, `migrate*`, `pr-report`, `measure`, `check`, `check-docs`, `coverage`, `shims`, `index`, `reminder`, `product-*`.
   Les 10 skills `aic-*` restent le noyau produit conversationnel ; la classification ci-dessus est le contrat CLI (constat 2 de la review : les deux ne coïncident pas — `init` est CLI-only, `aic` est skill-only).
3. **Schéma fiche** (`feature.schema.json`) : champs requis + types + sémantiques + enums fermés (`status`, `progress.phase`, `product.decision_state`, `type`). Ajout de champ optionnel = MINOR (`additionalProperties: true`, ligne 9) ; retrait/renommage/durcissement/évolution d'enum fermé = MAJOR. **Point à trancher avant gel** : le schéma annonce `type` « requis à terme » ($comment) — le rendre requis dès v1.0 (migration `aic migrate okf-type` déjà outillée) ou l'assumer comme premier MAJOR planifié.
4. **Contrat machine `.ai/.feature-index.json`** : enveloppe `{schema_version, project_id, generated_at, features[]}` + jeu de clés par feature, gardés par le snapshot test existant (`test-build-feature-index-contract.sh:96` couple clés↔version) ; toute rupture ⇒ bump `schema_version`. Pré-requis avant gel : corriger `core/feature-index-cache.md` § Contrats qui décrit encore « tableau JSON » (incohérence relevée par la review #4, vérifiée par `jq keys` sur l'index réel).
5. **Clés `.ai/config.yml` actives** et leur sémantique : `docs_root`, `project_id`, `vcs.provider`, `coverage.{roots,extensions,exclude_dirs}`, `progress.{stale_after_days,history_max_entries,auto_transitions.spec_to_implement}`, `context.{show_statuses,default_focus,max_tokens_warn}`. Renommage/retrait = MAJOR ; nouvelle clé à défaut sûr = MINOR.
6. **Modèle de shims** : `AGENTS.md` toujours rendu et auto-suffisant (hard rules inline) ; dérivés conditionnels (`CLAUDE.md`/`GEMINI.md` = `@AGENTS.md` + lignes agent, copilot opt-in) ; retrait d'un dérivé gouverné par le registre natif `.ai/native-context-support.tsv` avec transition par phase. Source : déjà contractualisé dans `core/agents-md-shim-canonical.md` § Contrats — le gel le référence, il ne le réinvente pas.
7. **Garanties comportementales des hooks** (PAS le câblage — constat 1 : Claude a 4 types d'événements/5 scripts, Codex n'a que `UserPromptSubmit`+`Stop` dans `.codex/hooks.json.jinja` ; geler le câblage Claude serait geler un détail d'implémentation) : (i) rappel de contexte par tour ; (ii) contexte JIT à l'édition d'un fichier couvert ; (iii) journalisation automatique des fichiers modifiés ; (iv) gate de fraîcheur documentaire avant fin de tour ET avant check-in (pre-commit quand `vcs=git`, chemin CI sinon) ; (v) auto-progression `spec → implement` débrayable. Chaque agent câble ces garanties selon ses moyens.
8. **Matrice d'enforcement par profil** (`adoption_mode` × `vcs_provider`) : `lite` = ni `.githooks` ni CI ; `standard` = complet si git ; `strict` = CI durcie ; `vcs ≠ git` = pas de `.githooks`, garanties (iv)-(v) portées par hooks agent + CI. L'asymétrie TFVC devient **contractuelle et documentée**, pas accidentelle.

La distinction structurel/positionnement de la v2 est conservée mais corrigée par le constat 1 : les décisions de positionnement qui retirent une **valeur de choix Copier** (ex. P4/gemini) touchent bien le contrat gelé (élément 1) — d'où leur place en Bloc A ci-dessous, avant le tag.

### Projet de section CONTRIBUTING.md (v3)

```markdown
### Moratoire de surface (v1.0+)

- À partir de v1.0, le contrat public est gelé — il est énuméré par le
  manifeste de surface (tests/unit/test-surface-manifest.sh) : routes CLI
  stables, questions Copier (identifiants, types, choix, défauts), champs
  requis et enums du schéma fiche, enveloppe de l'index JSON.
- Retirer, renommer ou resserrer un élément du manifeste = MAJOR ; ajout
  rétro-compatible à défaut sûr = MINOR, avec justification écrite (fiche
  feature, section Décisions) — même exigence que le moratoire bash.
- Le manifeste échoue en CI sur tout écart : le changement de contrat devient
  une décision consciente (mettre à jour le manifeste ET bumper en
  conséquence), jamais un effet de bord.
- Les garanties comportementales des hooks sont gelées ; leur câblage par
  agent ne l'est pas.
- Une PR qui grossit le contrat public sans justification écrite doit être
  refusée en review, même si le manifeste est mis à jour.
```

### Checklist de sortie v1.0 (remplace le « 6/6 »)

**Acquis** : ✅ backlog préparatoire 6/6 — nécessaire, pas suffisant (constat 7).

**Bloc A — décisions utilisateur (avant tout chantier)** :
1. **P4 avec prémisse corrigée** (constat 4, sources officielles vérifiées en session) : Gemini CLI n'est PAS décommissionné universellement — coupure 2026-06-18 pour les offres grand public seulement ; licences Enterprise/Standard, clés API payantes et Google Cloud restent supportés. Antigravity CLI lit officiellement `GEMINI.md` + `AGENTS.md` + `.agents/skills/`. Options : (a) conserver `gemini` qualifié « Enterprise/API payante » dans le help copier.yml ; (b) ajouter `antigravity` comme valeur indépendante (nécessite de modéliser `.agents/skills` au-delà de codex — aujourd'hui rendu seulement si `codex` sélectionné, `copier.yml:26`) ; (c) déprécier/retirer `gemini` avant gel. Jamais de réinterprétation silencieuse d'une réponse `gemini` existante.
2. **Valider la classification CLI** (élément 2 du contrat).
3. **`type` requis dès v1.0 ou premier MAJOR planifié** (élément 3).

**Bloc B — chantiers avant tag** :
4. E2E TFVC automatisable : profil `vcs_provider=tfvc` dans RELEASE.md §2 + smoke-test (rendu, absence attendue de `.githooks`, `doctor`/`review`/`check-feature-freshness --staged --strict` avec fake `tf` — modèle : tests unitaires `_vcs` existants).
5. Validation TFVC réelle (gate mainteneur manuel, hors CI — l'outillage `tf` réel n'existe pas en CI) : `doctor`/`status`/`review` sur le TFVC réel de l'organisation (version + langue réelles), résultat documenté dans `core/vcs-provider-abstraction`.
6. Chemin d'upgrade TFVC tranché et documenté : `copier update` exige un sous-projet git-tracké (preuve interne `tests/smoke-test.sh:2027` + doc Copier officielle) → git local auxiliaire documenté comme méthode supportée, OU alternative explicite (re-render + diff), OU « scaffold-only, update manuel » assumé — mais jamais silencieux.
7. Corriger `core/feature-index-cache.md` § Contrats (tableau → enveloppe).
8. Test d'upgrade `v0.14.0 → candidate v1.0` sur réponses représentatives (au minimum : défaut git, tfvc, agents touchés par la décision P4) — modèle : smoke `[28c/28]`.
9. `MIGRATION.md`/`CHANGELOG` : dépréciations actées (frame-*, knowledge, gemini selon P4) documentées selon RELEASE.md § Breaking.

**Bloc C — gouvernance (accompagne le tag ; réserve constat 6, ne bloque pas seule)** :
10. Garde-fou de surface automatisé : manifeste/snapshot testé en CI couvrant routes stables + questions Copier (ids/types/défauts/choix) + champs requis/enums du schéma + enveloppe index — modèle : `test-build-feature-index-contract.sh` (couplage snapshot↔version déjà éprouvé). Périmètre recadré vs review : la « matrice de capacités par profil » en extension ultérieure, pas dans le manifeste v1. Vit dans `tests/` — aucune tension avec le moratoire bash (pas de logique moteur).
11. Section CONTRIBUTING « Moratoire de surface » v3 (adossée au manifeste).
12. Décision datée utilisateur + tag `v1.0.0` + sanity post-release (RELEASE.md §7).

**Gate avant adoption** : re-review Codex de cette v3 (round 2), puis décisions Bloc A. Prompt fourni à l'utilisateur le 2026-07-24.

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
| 2026-07-24 | P16 | **Review Codex #4 = BLOQUANTE**, les 7 constats re-vérifiés en session avant application (consigne utilisateur) : (1) périmètre incomplet/mélange contrat-implémentation — ACCEPTÉ (questions Copier déjà « contrat » dans `template-engine.md` § Contrats ; clés `.ai/config.yml` actives réelles ; enveloppe index versionnée + snapshot test ; shims contractualisés ; matrice `_exclude` vérifiée ; câblage Codex ≠ Claude vérifié dans `.codex/hooks.json.jinja` ; incohérence doc `feature-index-cache.md:78` « tableau » vs enveloppe réelle vérifiée par `jq keys`) ; (2) surface CLI > 10 intentions — ACCEPTÉ (aide réelle : 13 « Commandes utilisateur » dont `init` livré P12 mais omis du contrat, `knowledge` post-cut, alias frame-*) ; (3) schéma+index bons candidats — ACCEPTÉ (`additionalProperties: true` vérifié ; relevé en passant : `type` « requis à terme » annoncé par le $comment du schéma → décision à trancher avant gel) ; (4) prémisse P4 à corriger — ACCEPTÉ, les 2 sources officielles re-fetchées et confirmées ; (5) E2E TFVC critère de sortie — ACCEPTÉ, renforcé par une preuve interne (`smoke-test.sh:2027` : copier update exige un sous-projet git-tracké) + nuance (validation TFVC réelle = gate mainteneur manuel, pas CI) ; (6) moratoire humain trop faible — ACCEPTÉ comme réserve, périmètre recadré (manifeste routes+questions+enums d'abord, matrice de capacités en extension) ; (7) 6/6 insuffisant — ACCEPTÉ. **Proposition v3 rédigée** : contrat 8 éléments + checklist 3 blocs + CONTRIBUTING v3 adossé au manifeste | Consignes utilisateur : re-vérifier chaque constat avant toute édition ; verdict bloquant confirmé par les preuves | Re-review Codex round 2 sur la v3 (prompt fourni), puis décisions Bloc A |
| 2026-07-24 | P1, P2a, P6, P17 | **Arbitrages utilisateur reçus et actés.** P1 : gel du hub knowledge confirmé et exécuté (`decision_state: cut`, `status: done`, code intact, motivation « cut faute de signal, pas kill criterion » — nuance de preuve consignée : la télémétrie jsonl ne pouvait pas capturer un usage CLI, la preuve porteuse est l'archéologie commits/worklogs). P2a : statu quo (les 2 CLI restent outillage mainteneur). P6 : **TFVC est le repository principal de l'organisation de l'utilisateur** — retrait définitivement écarté, le gap s'inverse (provider le plus important = le moins testé) ; suite recommandée : cadrer un test e2e TFVC. P17 : validation tierce en mode opportuniste, `next_decision_date` re-datée 2026-10-01 | Réponses directes de l'utilisateur (session 2026-07-24), après self-review critique des recommandations initiales (2 corrections : instrument de preuve P1, séquencement SemVer P16) | P16 amendé en conséquence ; review Codex demandée (prompt fourni) |
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
  status: RÉSOLU côté investigation — clos 2026-07-24 ; décision finale reste utilisateur
  files_touched: [aucun — investigation et proposition uniquement, voir « Proposition P16 »]
  pending: [décision utilisateur : valider/amender le contrat v1.0 proposé, valider/amender le projet CONTRIBUTING, dater la décision ; exécution (appliquer CONTRIBUTING + checklist de sortie) triviale une fois la décision prise]
  risks: [aucun matérialisé — routé manual comme prévu par la carte, pas exécuté unilatéralement ; cohérent avec P1/P2a/P4/P6/P17]
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| P9a | Préparation + exécution release v0.14.0 | Claude (mandat « go jusqu'au bout ») | done | tag `v0.14.0` sur `5c34108`, poussé ; sanity RELEASE.md §7 PASS ; voir « Preuve de clôture P9a » |
| P3 | Dé-versionner docs/benchmarks/runs/ | Claude (mandat autopilot) | done | `f0619c0` |
| P13 | GLOSSARY.md | Claude (mandat autopilot) | done | `8703973` |
| P14 | Réparer docs onboarding | Claude (mandat autopilot) | done | `ea3fd47` |
| P18b | Recalibrer rituels | Claude (mandat autopilot) | done | `9f109a4` |
| P1 | Gel hub knowledge (arbitrage utilisateur) | Claude (exécution) | done | Fiche `knowledge-federation` : cut/done, Historique + worklog ; code intact |
| P17 | Mode opportuniste + re-datage (arbitrage utilisateur) | Claude (exécution) | done | Fiche `agent-efficacy-benchmark` : next_decision_date 2026-10-01, Historique + worklog |
| P5 | Dégraisser PROJECT_STATE.md | Claude (mandat autopilot) | done | `d94830d` |
| P10a | Durcir enum status | Claude (mandat autopilot) | done | `7b5005d` |
| P18a | check-release-coherence.sh | Claude (mandat autopilot) | done | `5629e69` |
| P7 | Combler les 3 trous dogfood-drift | Claude (mandat autopilot) | done | `8494b6e` |
| P8 | check-skills-parity.sh | Claude (mandat autopilot) | done | `1015e87` |
| P11 | Consolider forks yq/jq build-feature-index | Claude (mandat autopilot) | done | `074438a` |
| P2a | Statu quo (arbitrage utilisateur) | Claude (documentation) | done | Décision documentée dans la carte ; aucun changement de code |
| P4 | Investiguer réduction agents | Claude (mandat autopilot) | validated | Prémisse corrigée review #4 (sources vérifiées : coupure grand public seulement, Antigravity lit AGENTS.md/.agents/skills) — décision Bloc A avant tag v1.0 |
| P6 | TFVC conservé — repo principal de l'org (arbitrage utilisateur) | Claude (documentation) | done | Décision documentée ; suite recommandée : cadrer un test e2e TFVC (question v1.0 posée à la review Codex) |
| P2b | Corriger la chaîne de procédure feature-update | Claude (mandat autopilot) | done | `3be389d` (prémisse d'élagage invalidée avant exécution) |
| P12 | aic init | Claude (mandat autopilot) | done | `f34cec5` |
| P9b | aic-release.sh + migration native v0.14.0 | Claude (mandat autopilot) | done | `1bd808c` |
| P15 | Routes aic.sh onboard/dev-plan | Claude (mandat autopilot) | done | `bfc6767` |
| P16 | Investiguer gel v1.0 | Claude (mandat autopilot) | validated | Critères 6/6 vérifiés ; proposition amendée (caveat SemVer/P4, question TFVC-e2e) ; **review Codex demandée** (prompt fourni 2026-07-24), verdict + décision utilisateur attendus |

## Validation de clôture

- P9a, P3, P13, P14, P18b, P5, P10a, P18a, P7, P8, P11, P2b, P9b, P12, P15 : `done`, preuve complète fournie (15/18 items). Arbitrages utilisateur du 2026-07-24 : P1, P2a, P6, P17 passent aussi `done` (décisions actées et exécutées — **16/18** au total, P2a/P6 comptés décision-seule). Restent : **P16** `validated` (review Codex demandée) et **P4** `validated` (vérification à mener avant tag v1.0). Le registre reste `active` jusqu'à leur résolution.
- Aucune fiche feature globale créée ; chaque item routé `feature` a sa fiche propre (`workflow/aic-init`, `workflow/aic-release`), les corrections mineures hors mesh (RELEASE.md, feature-update.md) sont restées `docs`/`chore` en place.
- Chaque preuve de P9a est renseignée (commandes exécutées, gates PASS, tag vérifié). Chaque item workflow (P2b/P9b/P12/P15) a vu sa prémisse initiale re-vérifiée avant exécution — 2 corrections notables (P2b : élagage annulé, prémisse fausse ; P9b : `aic-release.sh` re-scopé en source-only après découverte d'une dépendance elle-même source-only, détectée par une régression réelle du smoke-test).
- P16 : critères de sortie vérifiés 6/6, contrat v1.0 et projet CONTRIBUTING proposés avec sources citées, distinction structurel/positionnement explicitée pour répondre au risque de gel prématuré. Non exécuté (pas de commit CONTRIBUTING) faute de décision/datation utilisateur — cohérent avec sa route `manual`.
- La quality gate (smoke-test + check-* + freshness + dogfood-drift + check-runtime-template-mirror + check-skills-parity) est passée avant chaque commit, sans exception.

## Next hint

**Arbitrages utilisateur du 2026-07-24 actés (4/6)** : P1 gelé et exécuté, P2a statu quo, P6 TFVC conservé (repository principal de l'organisation — l'hypothèse d'archéologie était fausse, le gap s'inverse vers un test e2e à cadrer), P17 opportuniste + re-daté. **16/18 items `done`.**

Restent ouverts, dans l'ordre :
1. **P16** — review Codex #4 = BLOQUANTE, appliquée (7 constats re-vérifiés, v3 rédigée) ; **re-review round 2 de la v3 en attente** (prompt fourni le 2026-07-24), puis décisions utilisateur Bloc A et chantiers Bloc B/C de la checklist.
2. **P4** — prémisse corrigée et vérifiée aux sources (coupure grand public seulement ; Antigravity lit AGENTS.md/.agents/skills) ; il ne reste que la **décision** (conserver qualifié / ajouter antigravity / déprécier), à prendre en Bloc A **avant le tag v1.0**.
3. L'E2E TFVC n'est plus une question ouverte : la review #4 l'a promu **critère de sortie v1.0** (Bloc B items 4-6 : smoke automatisable + validation réelle mainteneur + chemin d'upgrade tranché — copier update exige un sous-projet git, preuve `smoke-test.sh:2027`).

Rappels méthodo acquis cette session : `rg --hidden` pour toute recherche de références dans ce repo (sinon `.docs/` est ignoré) ; tester `copier update` uniquement sur une copie jetable, jamais un repo consommateur réel ; `copier copy`/`update` non-interactifs exigent `--defaults` + `--data project_name=...` (pas de TTY dans ce contexte) ; avant de câbler un nouveau script dans `aic.sh`, vérifier s'il dépend d'un artefact source-only (`RELEASE.md`, `check-release-coherence.sh`…) — si oui, il doit lui-même rester source-only, jamais templaté ni dispatché ; pour toute entrée `_migrations` Copier, lire le code source installé plutôt que supposer le schéma, et vérifier empiriquement l'effet d'un `.rej` préexistant avant de la rendre bloquante.
