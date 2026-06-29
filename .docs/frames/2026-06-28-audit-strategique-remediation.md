---
frame_id: "2026-06-28-audit-strategique-remediation"
status: "active"
scope_probable: "product/ai-context-stability-migration"
route: "manual"
level: "high"
evidence: "Audit multi-agents 2026-06-28 (6 cartographies + 5 recherches zeitgeist sourcées + 3 critiques adverses, 312 lectures). Dashboard : artifact claude.ai/code/artifact/abd891d3-a2bf-40ce-80cd-cc183f0def27"
next_hint: "Phase 0 + A1/A2/A4/A9 + touches-breadth 2e vague + C1 (core) livrés (commits b9bb81d→387dbce). C1 reste avant DONE : note migration CHANGELOG/upgrading + check-shims dynamique par agents + HANDOFF pitch readme-positioning. Puis Phase 1 : A3/A5-A8/A10-A13. Phase 2 : C2 (contrat d'index). Phase 3 : D (diagnose churn quality)."
created_at: "2026-06-28"
updated_at: "2026-06-28"
---

# Frame 2026-06-28 — Remédiation de l'audit stratégique

## Intention

Transformer les conclusions de l'audit stratégique du 2026-06-28 en un backlog de remédiation
exécutable, **sans reproduire la maladie diagnostiquée** (sur-fragmentation : 53 fiches, 3 dédiées
à combattre la prolifération de fiches). Conteneur unique plutôt que ~15 fiches : on cadre par
**décision**, pas par finding.

Verdict de l'audit : ingénierie réelle et disciplinée ; philosophie de contexte lean dans l'air
du temps voire en avance ; mais surface > maturité, moat (enforcement déterministe) ni activé ni
mis en avant, stratégie de fichiers rattrapée par `AGENTS.md` + le natif Claude Code, et trajectoire
d'accrétion non gouvernée sur un bus factor de 1.

## Avancement

- **2026-06-28 — Phase 0 (Gouverner) CLOSE.**
  - B0 adopté et ancré dans `.ai/guardrails.md` (+ squelette template pour les consommateurs) — commit `be9b0e2`. Corrige aussi **A4** (référence guardrails cassée).
  - B1 : `product/ai-context-stability-migration` clôturée (`done`) + critère de sortie écrit — commit `df84876`.
  - B2b : `product/product-portfolio-loop` clôturée (`done`) — commit `df84876`.
  - B2a : `product/readme-positioning` passée `decision_state: commit`, re-datée, absorbe A5/A10/C1 — commit `df84876`.
  - Frame conteneur posé — commit `b9bb81d`.
  - Friction observée : exclure guardrails du drift a obligé 5 fiches (sur-couverture `touches:`) → evidence concrète pour `quality/touches-breadth-guard`.
- **2026-06-28 — Phase 1 entamée.**
  - A2 : moat git réactivé sur le dogfood (`core.hooksPath=.githooks`), `doctor` le vérifie, rejet d'un `feat:` sans fiche prouvé — commit `908d14b`.
  - A1 : parseur fallback de `build-feature-index` borné au frontmatter (fin du body-leak) + flow-style + test + parité jinja — commit `919ae39`.
  - A4 : déjà livré en Phase 0.
  - **Signal fort** : A1 a exigé 12 fiches en couverture incidente (sur-couverture `touches:`). Le moat étant désormais actif, cette taxe bloque chaque fix de fichier partagé → **remonter `quality/touches-breadth-guard` avant le reste de la Phase 1.**
- **2026-06-28 — Phase 1 (suite).**
  - touches-breadth 2ᵉ vague : globs catch-all `template/**`/`tests/**` reclassés `touches:` → `touches_shared:`/affinés ; Signal B ne liste plus que les globs légitimes — commit `0099802`.
  - A9 : churn auto-worklog supprimée — le flush saute le bloc auto si la feature est documentée manuellement ce tour (marqueur `.session-docs.log`), filet de sécurité préservé — commit `1148553`.
- **2026-06-29 — Phase 2 (C1) entamée et livrée (core).**
  - Gate `@import` franchi (Claude/Gemini OK ; Cursor/Copilot lisent AGENTS.md nativement) — commit `3228ffa`.
  - Import model livré : AGENTS.md neutralisé (base) ; CLAUDE.md/GEMINI.md = `@AGENTS.md` ; Cursor/Copilot tailored (fallback) ; check-shims/drift/smoke ✅ — commit `387dbce`. Dé-taxe touches-breadth confirmée (2 fiches incidentes vs 12 pour A1).
  - C1 reste avant DONE : note migration (CHANGELOG/upgrading) + check-shims dynamique par agents + HANDOFF pitch readme-positioning.
- **2026-06-29 — C2c + C2b livrés.** C2c : `schema_version` opérationnalisé (snapshot de clés couplé) — `74896f2`. C2b : `id` schema↔checker réconcilié (kebab-strict, 0 fiche en violation) + test différentiel — `57c7691` (HANDOFF index-contract-v2 → feature-mesh). Les 2 volets « le contrat ment » sont corrigés.
- **2026-06-29 — clôture de session.** A7 (PROJECT_STATE pointe vers ce frame, `1a0ca2c`) + C2a-doc (rôle du schéma clarifié, `e7d2d6c`). **Les 3 « contrats qui mentent » de l'audit sont clos** (C2a-doc + C2b + C2c). Régression A9 (`.session-docs.log`↔drift) attrapée par la vérif complète et corrigée (`2a4a74d`). État : 27/27 unit + drift + smoke verts.
- **Reste (backlog, non urgent)** : finir C1 (note migration CHANGELOG/upgrading), Phase 1 (A3, A5/A6/A8, A10–A13 — mineurs/risqués), touches-breadth Signal-A (README*/`_lib.sh`/`aic.sh`), Phase 3 (D — diagnose churn quality), Phase 4 (C3 + later). C2a-full (validateur) seulement si une dépendance de validation est un jour acceptée.

## Niveau de cadrage

Niveau : `high`

Justification :
- Signal A/B/C : touche contrats (index, schema), runtime/template, multi-agent, repositionnement
  produit, reprise externe (ce frame est lui-même un artefact de reprise durable).
- Cross-scope par nature : la remédiation traverse core / quality / workflow / product → exige une
  orchestration humaine et des HANDOFF explicites, d'où `route: manual`.

## Objectif

- Une séquence d'exécution ordonnée et vérifiable couvrant **chaque** point de l'audit, avec pour
  chacun : bac, route (`fix|docs|décision|frame|diagnose`), scope primaire, drapeau cross-scope, et
  critère de fin.
- Un principe anti-prolifération appliqué : ne créer un `aic-frame` que pour les 3 chantiers à
  contrat/stratégie durable (C1–C3) ; tout le reste passe en `fix:`/`docs:` sur fiche existante, en
  décision produit, ou en `aic-diagnose`.

## Non-objectifs

- Implémenter les ~15 items en un seul tour (violerait « un scope par tour »).
- Trancher à la place de l'humain les décisions produit du bac B (clôtures, statut `archived`, budget).
- Cadrer C3 / l'arbitrage mémoire maintenant : exploratoires, à frame seulement au moment de les prendre.
- Réécrire le substrat bash : confirmé bon choix (zéro dépendance, portable, déterministe, auditable).

## Scope et route

Scope primaire probable : `product/ai-context-stability-migration` (l'initiative de stabilisation est
l'ancre ; ce backlog en est l'evidence et son critère de sortie).

Route : `manual`

Justification :
- Aucune route unique ne couvre l'ensemble ; c'est un plan d'orchestration multi-scope. Chaque item
  porte sa propre route et son scope. Les transitions cross-scope (C1 notamment) exigent un HANDOFF
  et une confirmation utilisateur au moment de l'exécution.

## Challenge IA

- Le problème déclaré est-il le vrai problème ? Oui — l'accrétion non gouvernée et le moat inactif
  sont les deux risques de fond, vérifiés (`core.hooksPath=/dev/null` dans le dogfood ; 29/53 fiches
  parquées en `review` ; churn `fix(quality)` 23:10 ; décisions product en retard >1 mois).
- Faut-il reprendre des features existantes ? Oui, massivement : la plupart des items s'attachent à
  des fiches actives (feature-index-cache, git-hooks, index-contract-v2, aic-surface-canonical…),
  pas à des fiches neuves.
- Faut-il découper ? Oui, en bacs A/B/C/D + une séquence. Pas en 15 fiches.
- Doc / ADR / décision / diagnose plus adaptés ? Oui : bac B = décisions, bac D = `aic-diagnose`,
  bac A = `fix:`/`docs:`. Seul le bac C justifie `aic-frame`.

## Analyse technique

### Bac A — Stabiliser (`fix:`/`docs:`, AUCUN frame ; worklog forcé par le gate Stop)

| ID | Item | Route | Scope primaire | Cross-scope / HANDOFF | Critère de fin |
|---|---|---|---|---|---|
| A1 | Fuite du corps du parseur fallback (lit tout le fichier au lieu du frontmatter → status/depends_on/touches fantômes sans yq) | `fix:` | core/feature-index-cache | template (jinja) — miroir | test collision corps/frontmatter + flow-style ; fallback PATH sans yq ; drift OK. *(chip task_702c5f98)* |
| A2 | Activer le moat : `core.hooksPath=.githooks` dans le dogfood + `doctor` le vérifie | `fix:` | workflow/git-hooks | quality/doctor — léger | doctor échoue si hooks non câblés ; smoke vérifie |
| A3 | Clarifier README : `standard = advisory`, enforcement réel = strict + hooks | `docs:` | quality/read-only-checks-contract | quality/doc-freshness | section README explicite ; pas de promesse « gate » sur le défaut warn |
| A4 | `.ai/guardrails.md` référencé (index.md, PROJECT_STATE) mais absent → matérialiser ou retirer la réf | `fix:`/`docs:` | core/aic-surface-canonical | — | aucun pointeur Pack A ne tombe sur un fichier manquant |
| A5 | Canonicité README : `README_AI_CONTEXT.md` (gabarit-rendu, agents en dur) à la racine source | `docs:` | core/aic-surface-canonical | product/readme-positioning | une seule porte d'entrée GitHub non ambiguë |
| A6 | Étendre `shellcheck -S error` à `.githooks/*` et `tests/**/*.sh` | `chore:`/`fix:` | quality/ci-guard | — | CI lint le code d'enforcement réel |
| A7 | `PROJECT_STATE.md` périmé (v0.13.0 vs `[Unreleased]` substantiel) | `docs:` | core/aic-surface-canonical | — | vue mainteneur alignée sur le réel |
| A8 | `check-commit-features` grossier (accepte n'importe quel fichier sous features/) → resserrer via `features_matching_path` | `fix:` | workflow/git-hooks | — | un `feat:` éditant une fiche sans rapport est refusé |
| A9 | Churn `propage la fraîcheur auto-worklog` : plus de bump `progress.updated` hors transition de phase | `fix:` | workflow/auto-worklog | — | zéro commit de churn de date ; historique lisible (déjà amorcé Unreleased) |
| A10 | Honnêteté multi-agent en tête README ; requalifier Codex « parité » → « pilote » | `docs:` | product/readme-positioning | core/aic-surface-canonical | 1ère ligne calibre l'attente ; corps et titre cohérents |
| A11 | Lint préventif `${#` non échappé hors `{% raw %}` (CI) au lieu du crash de rendu | `fix:` | core/dogfood-runtime-sync | core/template-engine | CI échoue à l'édition, plus au rendu Copier |
| A12 | `check-dogfood-drift` sur ≥2 profils + unifier les exclusions `dogfood-update`/`drift` (classe de bug destructif 2026-06-19) | `fix:` | core/dogfood-runtime-sync | — | drift Jinja conditionnel couvert ; exclusions sourcées une fois |
| A13 | DFS cycle exponentiel sur DAG diamant → cache de nœuds explorés (ou doc + test diamant) | `fix:` | quality/cycle-detection | — | linéaire ou coût assumé + test non-régression perf |

### Bac B — Gouverner (décisions produit/portfolio ; `aic-ship` + `decision_state` ; AUCUN frame)

| ID | Item | Route | Scope primaire | Note |
|---|---|---|---|---|
| B0 | **Règle de budget** : « 1 fiche meta-process créée = 1 close » + gel temporaire des nouvelles fiches `workflow/*` meta | décision/policy | product/product-portfolio-loop | Pièce maîtresse — sans elle tout le reste prolifère |
| B1 | Clore ou renommer `product/ai-context-stability-migration` avec critère de sortie mesurable (ex. ratio fix:feat, nb drafts gelés) | décision | product/ai-context-stability-migration | La « stabilisation » ne peut rester active pendant qu'on empile 9 features |
| B2 | Trancher `readme-positioning` + `product-portfolio-loop` (`decision_state`, `next_decision_date`) — dates dépassées >1 mois | décision | product/* | Dogfooder enfin sa propre boucle de décision |
| B3 | Introduire un statut `archived`/`shipped` distinct d'`active` + migrer les ~25 fiches `review` réellement livrées-figées | décision (+ enum) | core/feature-mesh | Touche schema/check-features → exécution légère pilotée par la décision |
| B4 | TTL close-or-kill sur drafts >30j (`feature-audit`, `conversational-skills` gelés ~2 mois) | décision | workflow/feature-consolidation-nudge | Réutiliser l'infra du nudge existant, pas de nouveau script |
| B5 | WARN CI si `next_decision_date` dépassée pour initiative `active` (`product-review.sh` existe) | `fix:` piloté par B | quality/pr-report | Exposer le check sur soi-même |
| B6 | Produire ≥1 preuve de valeur chiffrée (benchmark tokens via `measure-context-size.sh` sur repo démo) | décision + tâche | product/readme-positioning | Transformer « contexte lean » de déclaratif en evidence |

### Bac C — Repositionner (les SEULS `aic-frame`, niveau high ; 3 chantiers)

| ID | Chantier | Route | Scope primaire | Cross-scope / HANDOFF |
|---|---|---|---|---|
| C1 | `AGENTS.md` source unique + **import** (`@AGENTS.md` + fallback tailored, symlink rejeté) ; retirer le multi-shim ; veille kill_criterion « si Claude Code lit AGENTS.md nativement (issue #34235), retirer le double-shim ». **CADRÉ 2026-06-28 → fiche `core/agents-md-shim-canonical` (phase spec, gate : vérifier `@import`)** | `aic-frame` ✅ → impl | core/agents-md-shim-canonical | **HANDOFF** product/readme-positioning + core/template-engine |
| C2c | Opérationnaliser `schema_version` (snapshot des clés couplé, pas `=="1"`) | — | core/index-contract-v2 | **✅ FAIT** (commit `74896f2`) |
| C2b | Réconcilier la divergence `id` schema↔checker (kebab-strict vs underscore, 0 fiche en violation) + test différentiel | — | core/feature-mesh | **✅ FAIT** (commit `57c7691`) |
| C2a | Rôle du schéma (validateur full vs source d'enums+pattern) | clarification doc (`$comment`), pas de validateur — éthos bash/jq/yq | core/index-contract-v2 / feature-mesh | **✅ RÉSOLU (C2a-doc)** (commit `e7d2d6c`) : rôle explicité, aucune dépendance ajoutée |
| C3 | Natif vs bash : migrer `.ai/rules/<scope>.md` vers `paths:` natif là où 1:1 ; recentrer le bash sur la valeur unique = graphe `depends_on`/`touches_shared` (reverse-deps). **Exploratoire — frame au moment de le prendre, pas avant.** | `aic-frame` (high) | core/graph-aware-injection | workflow/pre-turn-reminder |

### Bac D — Comprendre (`aic-diagnose`, pas une feature)

| ID | Item | Route | Scope primaire | Note |
|---|---|---|---|---|
| D1 | Churn `fix(quality)` 23:10 : isoler les 2-3 scripts qui concentrent les patchs → investir en tests de contrat ; cible fix:feat < 1:1 | `aic-diagnose` | quality/* | Le sous-système garant de la stabilité est le moins stable |
| D2 | Instrumenter l'usage réel de `AIC_DOC_GATE=off` (via context-relevance) pour juger la valeur nette du gate Stop | instrumentation rattachée à D1 | quality/context-relevance-tracker | Donnée manquante : protection ou friction contournée ? |

### Plus tard (frame au moment de la prise)

- C4 : livrer une config `.codex/` dogfoodée (commit guard + freshness fin de turn) + sourcer/re-vérifier le claim `.agents/skills reconnu par Codex` → reprise `workflow/codex-hooks-parity`.
- Hook `PreCompact` : note-taking dirigé vers worklog/`resume_hint` (transformer la compaction subie en checkpoint).
- Arbitrage mémoire : worklog maison ↔ memory tool natif (backend de persistance + worklog comme vue gouvernée).
- Packager les skills `aic-*` en plugin Claude versionné (`.claude-plugin/marketplace.json`).
- Localiser EN (`commit_language` existe déjà) pour débloquer la distribution.

Contrats touchés : schema d'index (C2), contrat de shims/parité (C1, A10), contrat read-only (A3),
contrat de fraîcheur (A8/A9), enum de statut des fiches (B3).

Compatibilité Claude/Codex/templates/downstream : tous les `fix:` runtime exigent le miroir
`template/*.jinja` + `check-dogfood-drift`. C1 modifie la surface des shims générés → impact direct
downstream (à versionner/annoncer). C2 peut imposer un bump `schema_version` (premier vrai bump).

## Scénario nominal

1. **Phase 0 — Gouverner (bac B).** Poser B0 (budget), clore/renommer B1, trancher B2, définir B3
   (`archived`). Effet : le portfolio redevient un signal honnête et la création de fiches est bornée.
2. **Phase 1 — Stabiliser (bac A).** A1 (body-leak, déjà chipé) + A2 (activer le moat) en priorité,
   puis A3–A13. Restaure la crédibilité (le moat est enfin dogfoodé, l'index ne ment plus).
3. **Phase 2 — Repositionner.** C1 (AGENTS.md, avec HANDOFF) puis C2 (contrat d'index). Séquencés :
   C1 change la surface des shims que C2 touche.
4. **Phase 3 — Comprendre.** D1/D2 (`aic-diagnose`) ; peut tourner en parallèle de la Phase 1.
5. **Phase 4 — Évoluer.** C3 + items « plus tard », pris un par un, frame à la prise.

## Cas limites

- **C1 régresse l'expérience Claude** : si le passage à `@AGENTS.md`/symlink prive Claude d'un pointeur
  qu'il chargeait, prévoir un CLAUDE.md minimal (1 ligne import + pointeur `.claude/settings.json`).
- **B3 (`archived`) casse des consommateurs** qui filtrent sur `status: active|draft|done` : ajout
  additif d'enum → vérifier `is_valid_status`, smoke-test, et les rapports qui itèrent sur les statuts.
- **A2 active un gate bloquant** qui n'était pas là : risque de friction immédiate sur le dogfood →
  garder l'échappatoire `AIC_DOC_GATE=off` documentée, mesurer son usage (D2).

## Incertitudes

| Catégorie | Point | Décision |
|---|---|---|
| Bloquant maintenant | Les décisions produit (B1/B2) appartiennent à l'humain | Attendre l'arbitrage utilisateur avant de clore/renommer |
| Hypothèse de travail | C1 réversible sans perte côté Claude via CLAUDE.md=`@AGENTS.md` | À valider au moment du frame C1 |
| Risque accepté | Le fallback awk reste best-effort même après A1 (pas d'exclusion stricte sans yq) | Acceptable : non-crash garanti, exclusion stricte = chemin yq |
| À valider plus tard | C3 (`paths:` natif) dépend de la stabilité de l'API Claude Code | Frame seulement quand pris ; ne pas miser maintenant |

## Critères d'acceptation

- Chaque item exécuté est rattaché à une fiche existante (ou décision tracée), avec worklog et
  Conventional Commit fr.
- Aucune nouvelle fiche meta-process créée sans en clore une (B0 appliquée).
- Le moat (git hooks) est actif dans le dogfood et vérifié par `doctor` (A2).
- L'index ne fuit plus le corps markdown (A1, test vert sur chemin fallback).
- Les 3 décisions product sont closes ou re-datées (B1/B2).
- Au plus 3 nouveaux frames créés (C1–C3), pas 15.

## Validation prévue

- Checks : `tests/unit/*` (dont nouveau test fallback A1), `check-dogfood-drift`, `tests/smoke-test.sh`,
  `doctor` (incluant la vérif hooks A2), `shellcheck` étendu (A6).
- Validation documentaire : worklog par item ; ce frame mis à jour (`updated_at`, `status`) à chaque
  phase franchie ; `status: done` quand C1–C3 sont cadrés et A/B exécutés.

## Préconisations

1. Démarrer par **Phase 0 (bac B)** — la règle de budget B0 et les clôtures product débloquent tout
   le reste et stoppent l'accrétion.
2. Enchaîner **A1 + A2** : le bug bloquant et l'activation du moat sont le meilleur rapport
   crédibilité/effort.
3. Ne lancer `aic-frame` que pour **C1 puis C2**. C3 et les items « plus tard » : à la prise.

## Evidence

Audit multi-agents 2026-06-28 (cf. frontmatter `evidence`). Faits vérifiés dans le code :
`core.hooksPath=/dev/null`, parseur fallback non borné au frontmatter, schema non appliqué + divergence
`id`, 29/53 fiches en `review`, `fix(quality)` 23:10, 3 dates de décision product dépassées.

## Next hint

Reprendre par la Phase 0 : poser B0 (budget meta) et trancher B1/B2 avec l'utilisateur. Puis Phase 1
en commençant par A1 (chip `task_702c5f98`) et A2. Mettre à jour ce frame (`status`, `updated_at`) à
chaque phase franchie ; passer `status: done` une fois A+B exécutés et C1–C3 cadrés.
