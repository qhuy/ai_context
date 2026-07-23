---
pilot_id: "2026-07-23-analyse-fonctionnelle-generale"
status: "active"
source: "analyse fonctionnelle générale 2026-07-23 (session Claude — 4 sous-audits : runtime .ai/, distribution Copier, surface utilisateur, santé du process) ; review Codex #1 (bloquante) et re-review #2 (go avec réserves) appliquées le 2026-07-23"
scope_primary: "product"
created_at: "2026-07-23"
updated_at: "2026-07-23"
active_item: "P9a"
active_question: "P9a activé (go utilisateur). Confirmes-tu (a) le bump v0.14.0 (MINOR) et (b) le HANDOFF product→workflow (section Handoffs) pour exécuter la checklist RELEASE.md ? Le tag/push aura sa confirmation séparée."
next_hint: "Sur confirmation du bump + HANDOFF : commit préalable des artefacts de pilotage (worktree propre requis), puis checklist RELEASE.md intégrale (smoke, 7 rendus Copier, update-test si consommateur dispo, docs §4 + bascule recos HEAD consommateur, fiches impactées), puis STOP avant tag — confirmation séparée du tag/push. Ensuite : vague hygiène P3 → P10a → P13 → P14."
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
| P1 | Statuer sur le hub knowledge : verbe CLI routé et documenté mais **aucune invocation opérationnelle automatisée** (hooks/skills — la CI couvre le sous-système via son test unitaire, pas d'usage opérationnel), **adoption non mesurée**, chantier stale 20 j, 1 fiche non close (`product/knowledge-federation` active ; les 2 fiches dev knowledge sont `done`) | triage | product | manual | Décision datée : mesurer l'adoption (critère + échéance) / geler (fiche soldée, code conservé) / extraire (branche) — avec critère de kill explicite |
| P2a | Statuer sur les 2 CLI standalone sans invocation opérationnelle automatisée ni doc utilisateur publique (leur couverture CI se limite à leurs tests unitaires via la boucle générique) : `check-agent-native-context.sh` (documentée consommateur `upgrading.md`, **instrument du kill criterion** de `core/agents-md-native-collapse-path.md:106` — outil de la décision P4) et `context-relevance-report.sh` (reporter standalone contractuel, doc interne `quality/context-relevance-tracker.md`, aucune route `aic`) | triage | core | manual | Décision par script : exposer publiquement (route `aic`/doctor + doc) / conserver en outil interne documenté / déprécier — datée, avec suite routée ; cohérence avec P4 exigée pour le premier |
| P2b | Élaguer les workflows morts et fusionner les contrats transverses (`feature-resume.md` supplanté par script, `feature-handoff.md` mort opérationnel ; `mcp-policy`+`subagent-contract`+`evidence-discipline` → 1 contrat agent) | triage | workflow | refactor | 15 → ~8 workflows ; `check-ai-references.sh` vert ; refs skills mises à jour |
| P3 | Dé-versionner `docs/benchmarks/runs/` (15 Mo, 276 fichiers trackés) ; conserver `reports/` + `PROTOCOL.md` ; retirer les 3 `.DS_Store` trackés sous `template/` | triage | product | chore | `git ls-files docs/benchmarks/runs` vide ; `.gitignore` couvre ; reports conservés |
| P4 | Réduire les cibles agents de 5 à « claude + codex + tier AGENTS.md-natif » (retrait des shims cursor/gemini/copilot dédiés) | triage | core | manual | Décision de positionnement datée ; si oui : suite routée `feature` (copier.yml simplifié, MIGRATION.md documente le retrait) |
| P5 | Dégraisser les artefacts doc triplés : quality gate ×3 → 1 ; stubs `rules/core.md` / `rules/quality.md` ; section « État » de `PROJECT_STATE.md` → pointeur + roadmap | triage | quality | docs | Un seul artefact gate référencé ; `index.md` sans double pointeur ; PROJECT_STATE ≤ ~40 lignes |
| P6 | Sort de TFVC : option `vcs_provider=tfvc` avouée « best-effort, non testé end-to-end » dans copier.yml | triage | core | manual | Usage réel vérifié (Hypothèse ci-dessous) ; décision datée : retrait (option + MIGRATION) ou test e2e réel |
| P7 | Combler les 3 trous du dispositif de parité existant (la génération template→runtime existe déjà — décision ZE SOLUTION P5) : (i) drift content-check limité au profil `minimal`, (ii) aucun guard contre l'édition directe du miroir runtime, (iii) discipline « éditer les deux copies » encore codifiée dans PROJECT_STATE | triage | core | feature | Drift strict multi-profils ; édition directe du miroir bloquée ou re-générée ; PROJECT_STATE aligné sur le flux à sens unique |
| P8 | Copie unique des skills : corps en un seul fichier, `SKILL.md` Claude/Codex = pointeurs ; check CI d'égalité inter-arbres `.claude/skills` ↔ `.agents/skills` | inbox (dép. P7) | core | feature | `diff -rq` des deux arbres vide en CI ; 40 fichiers dupliqués → pointeurs |
| P9a | **Préparer la release `vNext`** : décider le bump SemVer (RELEASE.md §5) avant tout tag ; inventorier et basculer vers le tag **toutes** les recos `--vcs-ref=HEAD` destinées aux consommateurs (`README_AI_CONTEXT.md:57,64`, `README.md:298`, `PROJECT_STATE.md:20,76`, `docs/variables.md:90`, `docs/upgrading.md:9,18`, `CHANGELOG.md:118`) en traitant la crainte documentée du « downgrade involontaire » (la reco HEAD est une mitigation délibérée du retard de tags) ; conserver les usages HEAD mainteneur légitimes (`RELEASE.md:27-33,49` — rendus du working tree) | **handoff** | workflow | chore | Préconditions **ordonnées** (review #3) : (1) bump SemVer décidé et motivé, (2) **HANDOFF product→workflow acté + confirmation utilisateur AVANT toute édition** (la checklist contient des modifications documentaires de ce scope), (3) checklist RELEASE.md exécutée intégralement, (4) confirmation utilisateur séparée du tag/push. Preuve finale : tag `vNext` poussé, CHANGELOG sectionné, zéro reco HEAD consommateur restante, usages mainteneur préservés |
| P9b | Scripter la release (`aic release` : checklist RELEASE.md automatisée) et brancher des `_migrations` Copier natives sur les tags | inbox (dép. P9a) | workflow | feature | Release reproductible en 1 commande ; migration liée à un tag jouée dans le smoke |
| P10a | Durcir l'enum `status` : warn → fail dans `check-features.sh` — **aucune donnée existante à corriger** (aucune fiche réelle hors enum à date) ; durcissement testé par fixture dédiée | triage | quality | fix | Test unitaire sur fixture : statut hors enum ⇒ exit ≠ 0 ; mesh réel inchangé et vert ; cohérence avec le phasage OKF (`type` reste warn Phase 0) |
| P10b | (retiré) « Builder tolérant au YAML invalide = risque silencieux » — prémisse invalidée : la compensation existe et est commentée comme telle | **dropped** | quality | dropped | Raison consignée : `check-features.sh:123-130` fait échouer (`ko`) toute fiche au frontmatter illisible ; la tolérance du builder est un contrat volontaire des hooks non-bloquants |
| P11 | Réduire les **invocations redondantes** sur le chemin de commit (~5 builds d'index temporaires par commit `feat:` ; 3 forks jq au source-time de `_lib.sh` payés par chaque hook ; hook PreToolUse Bash évaluant chaque commande) — measure-first, pas de réécriture (leçon ZE SOLUTION P4 : matching ≠ goulot, rewrite dropped) | triage | core | refactor | Mesure avant/après sur un commit `feat:` réel : builds temp 5 → 1 (réutilisation d'un index par opération), 0 fork jq sur commande bash non-commit ; aucun changement de langage |
| P12 | `aic init` (successeur du `first-run` supprimé en v0.13 sans alias) + fiche d'exemple livrée non-vide (ex. `workflow/ai-context-adoption.md` pré-remplie avec les réponses Copier en `touches:` réels) | triage | workflow | feature | Parcours guidé exécutable post-scaffold ; mesh non vide au jour 1 ; smoke couvre `init` |
| P13 | `GLOSSARY.md` : Pack A, shim, mesh, touches/touches_shared, freshness, frame, HANDOFF, overlay, OKF, dogfood — lié depuis README + `.ai/index.md` | triage | product | docs | Chaque terme employé par README/index défini ; `check-ai-references.sh` vert |
| P14 | Réparer les docs d'onboarding : réécrire `docs/getting-started.md`, compléter `docs/variables.md` (12/12 questions), régénérer + référencer `examples/*.yml`, aligner `--no-write`, source getting-started unique (les 4 autres surfaces = renvois), arbre de décision frame/pilot/dev-plan/diagnose | triage | product | docs | Docs alignées sur la surface v0.13+ ; examples référencés depuis README ; cohérence `--no-write` partout |
| P15 | Aligner les noms sur l'axe `aic *`, partie **additive seulement** : route `aic onboard` manquante, alias non documentés (`frame-bootstrap`, `frame-context`), mismatch `aic plan` ↔ skill `aic-dev-plan` documenté ; tout renommage breaking reporté au chantier v1.0 (P16) | triage | workflow | feature | Routes CLI = noms skills pour les 10 intentions ; aliases documentés ou retirés ; zéro breaking avant v1.0 |
| P16 | Gel v1.0 : étendre le moratoire bash en moratoire de surface ; définir le contrat public (format `index.md` + schéma fiche + jeu de hooks + ~10 intentions `aic`) ; critères de sortie = P7, P9, P10a, P12–P14 livrés | triage | product | manual | Décision datée ; CONTRIBUTING étendu ; contrat v1.0 énuméré ; checklist de sortie publiée |
| P17 | Boucle de feedback réelle : adopter sur 1–2 projets réels, livrer le repo démo (roadmap P3), exécuter les **runs réels** du benchmark A/B (fiche `product/agent-efficacy-benchmark` : scaffold livré, runs = action mainteneur en attente) et publier 1 rapport | triage | product | manual | Hypothèse consommateurs tranchée ; repo démo public ; 1 rapport de runs réels publié ; priorités du trimestre suivant sourcées de cet usage |
| P18a | Check CI de cohérence CHANGELOG ↔ PROJECT_STATE ↔ copier.yml (recommandé par l'audit 07-07, jamais implémenté ; la dette a récidivé 2×) | triage | quality | feature | Le check échoue sur les dérives déjà constatées (variables manquantes, état périmé) ; branché CI |
| P18b | Recalibrer les rituels : cadence d'audit réaliste (« hebdo » sans occurrence depuis 16 j) ; trancher le sort des frames (3 en 3 mois, aucun depuis le 28-06) | triage | product | manual | Décisions datées dans ce registre ; routine replanifiée ou retirée ; frames réhabilités ou retirés du template |

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

- **Actives-tu P9a (préparer la release `vNext`) ?** Si oui, première étape : décider le bump SemVer (RELEASE.md §5 — analyse du `[Unreleased]` fournie à ce moment-là), puis HANDOFF product→workflow soumis à ta confirmation avant toute édition.

## Décisions actées

| Date | Item | Décision | Raison | Suite |
|---|---|---|---|---|
| 2026-07-23 | (registre) | Pilotage enclenché sur les 18 propositions ; registre durable créé ; review Codex demandée avant exécution large | Demande utilisateur explicite | Registre soumis à review |
| 2026-07-23 | (registre) | Review Codex #1 = BLOQUANTE ; 6 constats appliqués : P9a maintenu `blocked` (préconditions RELEASE.md + HANDOFF), P1 requalifié (verbe CLI routé — enjeu adoption, vérifié `aic.sh:915`), P2a requalifié (CLI documentée consommateur, vérifié `upgrading.md:231`), P10 scindé (P10a fix enum ; P10b dropped — compensation prouvée `check-features.sh:123-130`), routes normalisées (une route unique/item), prémisses actuelles ajoutées avec preuves | Constats re-vérifiés dans le code avant application ; 2 prémisses initiales étaient sur-qualifiées (P1 « île », P2a « orphelin ») et 1 invalide (P10 builder) | Re-review Codex |
| 2026-07-23 | P10b | dropped | Prémisse invalidée : `check-features.sh:123-130` bloque (`ko`) toute fiche au frontmatter illisible ; tolérance du builder = contrat volontaire des hooks non-bloquants | — |
| 2026-07-23 | P7, P11, P17 | Reframés sur les décisions antérieures du pilotage ZE SOLUTION (worklog `workflow/aic-pilot`, 2026-06-30) : P7 ne rouvre pas « source unique » (existante), il comble ses trous ; P11 est measure-first sans réécriture ; P17 s'appuie sur la fiche `product/agent-efficacy-benchmark` existante | Cohérence avec l'historique du repo ; éviter de re-litiger des décisions actées | Intégrés à la carte |
| 2026-07-23 | (registre) | Re-review Codex #2 = **go avec réserves** ; 3 corrections appliquées après re-vérification code : (1) `published` = faux positif (exemple YAML de corps de fiche, `knowledge-source-contract.md:138` — le frontmatter réel est `active`) → P1 recompté à 1 fiche non close, P10a sans correction de donnée ; (2) `context-relevance-report.sh` documenté en interne (`quality/context-relevance-tracker.md`) → P2a reformulé « aucune doc utilisateur publique ni route aic » ; (3) P9a reformulé « préparer la release `vNext` » : bump SemVer d'abord (RELEASE.md §5), inventaire complet des recos HEAD consommateur (6 fichiers), usages mainteneur préservés | Les 3 réserves vérifiées fondées ; cause racine du (2) consignée : `rg` sans `--hidden` ignore `.docs/` | Soumis pour GO complet |
| 2026-07-23 | (registre) | Review Codex #3 = go avec réserves, **fond validé** ; 2 corrections appliquées après vérification : (1) ordre P9a corrigé — HANDOFF product→workflow + confirmation AVANT la checklist RELEASE.md (elle contient des éditions documentaires de ce scope ; séquence : SemVer → HANDOFF → checklist → confirmation tag/push → tag) ; (2) P1/P2a reformulés « invocation opérationnelle » — la CI couvre bien ces surfaces via leurs tests unitaires dans la boucle générique (`ai-context-check.yml:98-103`, vérifié), le manque est l'usage hooks/skills | Codex précise qu'aucune nouvelle review complète n'est requise ; le cadrage passe en phase d'exécution conditionnée aux confirmations utilisateur | Question active = activation de P9a |
| 2026-07-23 | P9a | **Activé** (« go » utilisateur). Bump proposé : **v0.14.0 (MINOR)** — `[Unreleased]` dominé par de l'additif (2 nouvelles questions Copier à défaut sûr, cockpit `aic migrate`, index progressifs, 2 skills, gates advisory, OKF Phase 0 explicitement non-cassant) ; les 2 changements de comportement (élagage shims Copilot/Cursor, gate Stop) ont migration documentée + échappatoires, conformes au précédent v0.13.0 (breaking documenté = MINOR en 0.x). v1.0.0 est réservé au jalon P16 | RELEASE.md §5 ; précédent v0.12→v0.13 ; SemVer 0.x | HANDOFF product→workflow soumis à confirmation utilisateur avant toute édition |

## Handoffs

```text
HANDOFF
  from_scope: product
  to_scope: workflow
  status: en attente de confirmation utilisateur (émis 2026-07-23, P9a)
  files_touched: [
    CHANGELOG.md (Unreleased → section v0.14.0),
    PROJECT_STATE.md (version publiée, roadmap, recos HEAD l.20+76),
    README.md (reco HEAD l.298 + sync tableaux §4 RELEASE),
    README_AI_CONTEXT.md (recos HEAD l.57+64) + template/README_AI_CONTEXT.md.jinja (parité),
    docs/upgrading.md (recos HEAD l.9+18),
    docs/variables.md (note HEAD l.90),
    MIGRATION.md (si nécessaire après relecture §4),
    fiches .docs/features/** impactées (section Historique si manquante),
    tag v0.14.0 (après confirmation séparée)
  ]
  pending: [
    commit préalable des artefacts de pilotage (prérequis worktree propre),
    smoke-test local complet,
    7 rendus Copier critiques (RELEASE.md §2),
    test copier update sur consommateur de référence (Hypothèse : aucun dispo — sera consigné si skip),
    docs §4 + bascule recos HEAD consommateur (en préservant la mise en garde downgrade),
    STOP avant §6 : confirmation utilisateur du tag/push
  ]
  risks: [
    la bascule HEAD→tag sans cadence de tags recrée le risque de downgrade documenté (mitigé : P9b + note de cadence dans les docs),
    le pre-commit flushe les worklogs en attente — vérifier le contenu du commit préalable,
    checklist sans transaction : un échec en cours laisse des docs partiellement mises à jour (mitigé : commit unique en fin de checklist)
  ]
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| — | — | — | — | — |

## Validation de clôture

- Tous les items sont `done`, `dropped`, `handoff` ou explicitement reportés avec reprise datée.
- Les items routés `feature`/`fix` ont chacun leur fiche `.docs/features/<scope>/<id>.md` (jamais de fiche globale).
- Chaque preuve attendue de la carte est renseignée (commande, test, ou décision datée).
- La quality gate passe sur chaque livraison intermédiaire.

## Next hint

Cadrage validé par Codex (reviews #1 bloquante, #2 et #3 go avec réserves — toutes réserves appliquées et re-vérifiées ; pas de nouvelle review complète requise). Sur confirmation utilisateur, activer P9a dans l'ordre acté : décision SemVer motivée depuis le `[Unreleased]` → HANDOFF product→workflow + confirmation AVANT toute édition → checklist RELEASE.md intégrale → confirmation séparée du tag/push → tag `vNext` + bascule des recos HEAD consommateur. Ensuite : vague hygiène P3 → P10a → P13 → P14, un item actif à la fois ; décisions structurantes (P1, P2a, P4, P6, P16–P18) une question à la fois. Rappel méthodo pour toute recherche de références dans ce repo : `rg --hidden` (sinon `.docs/` est ignoré).
