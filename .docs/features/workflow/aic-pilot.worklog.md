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
