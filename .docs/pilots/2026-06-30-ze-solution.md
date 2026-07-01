---
pilot_id: "2026-06-30-ze-solution"
status: "done"
source: "Analyse à froid du repo (regard neuf) + cadrage axes d'amélioration"
scope_primary: "product"
created_at: "2026-06-30"
updated_at: "2026-06-30"
active_item: "CLOS — tous les axes soldés ; résiduel = follow-ups feature-level (pas pilot)"
active_question: "Aucune — pilotage clos. Reprise = suivi dans les fiches feature."
next_hint: "PILOTAGE CLOS (tout sur main). Bilan : cadrage 7 axes ; P2/P3/P6/P1 = incr.1 livrés + testés ; P4/P5 dropped (mesure / déjà résolu) ; P7 différé. Méta : P3/P4/P5 = 3/3 prémisses recadrées → dette de PREUVE, pas d'ingénierie. Résiduel = follow-ups feature-level (suivis dans les fiches, PAS le pilot) : (1) P1 runs RÉELS = action mainteneur (câbler AGENT_CMD + ≥2 repos + N → 1er rapport docs/benchmarks/reports/) ; (2) kill_criterion #34235 (P2) ; (3) HANDOFFs quality/smoke-test = brancher run-bench --self-check + test-agents-md-self-sufficient dans le smoke ; (4) breadth-guard vagues futures (au cas par cas)."
---

# Pilot 2026-06-30 — « ZE SOLUTION » : axes pour faire d'ai_context la référence

## Intention

Faire d'`ai_context` la solution de référence de la couche-contexte agent. Le
cadrage est issu d'une analyse à froid : les *intuitions* sont bonnes (lean
context, just-in-time, scope, evidence-before-done) mais la valeur reste
**affirmée et non mesurée**, le moteur est fragile (bash), la maintenance double
(dual-tree) et le pari d'indirection `.ai/index.md` est érodé par la convergence
`AGENTS.md`.

Axe directeur tranché (2026-06-30) : **Prouver & positionner** — la crédibilité
est le goulot ; on prouve la valeur (P1) et on sécurise le pari stratégique (P2)
avant de durcir/optimiser.

## Résultat attendu

- P1 : benchmark reproductible montrant un Δ mesurable avec vs sans ai_context.
- P2 : décision archi tranchée sur l'indirection `.ai/index.md` face à AGENTS.md
  natif, avec chemin de *collapse* documenté.
- P3–P7 : routés et ordonnancés, aucun chantier bundlé à tort (P3 ≠ P4).
- Aucun item oublié ; chaque item validé a une route et une preuve attendue.

## Carte des sujets

| ID | Sujet | Statut | Scope probable | Route | Preuve attendue |
|---|---|---|---|---|---|
| P1 | Benchmark d'efficacité agent — **incr.1 : scaffold exécutable livré** | doing | product | feature (initiative) | scaffold (PROTOCOL + runner --self-check + tâche) ✅ ; runs réels = action mainteneur |
| P2 | Pari `.ai/index.md` vs AGENTS.md lecture native — **fiche core créée** | doing | core | manual → feature core | chemin de collapse documenté + kill_criterion #34235 opérationnalisé |
| P3 | Validateur clés requises schéma-driven (recadré : zéro dép) — **incr. 1 livré + CI** | doing | quality/core | feature | clé ajoutée au schéma → exigée : test PASS + smoke [0q/28] ✅ |
| P4 | Noyau moteur hors bash (index/cycles/glob) | **dropped (tel que cadré)** | core | mesuré → différé | mesure faite : matching ≠ goulot ; coût = parsing yq de build-index (linéaire), négligeable+caché à échelle réaliste |
| P5 | Taxe dual-tree (runtime généré depuis template) | **dropped (déjà résolu)** | core | — | `dogfood-update.sh --apply` génère DÉJÀ le runtime depuis le template ; taxe résiduelle inhérente au Jinja + mitigée par drift-check |
| P6 | Calibrage cérémonie / anti `--no-verify` — **incr.1 livré** | doing | quality | diagnose → reclass | racine = largeur `touches:` ; **CHANGELOG.md reclassé touches_shared: dans 6 fiches** (84d54aa) → cascade supprimée. Reste (optionnel) : autres surfaces >4, au cas par cas |
| P7 | Sprawl docs racine + cadence auto-audit | inbox | product/docs | docs/chore (différé) | doc racine consolidée, cadence audit bornée |

Statuts : `inbox`, `triage`, `validated`, `blocked`, `handoff`, `doing`, `review`, `done`, `dropped`.

Routes : `feature`, `fix`, `docs`, `refactor`, `chore`, `diagnose`, `handoff`, `manual`, `dropped`.

## Question active

Contexte affiché :

- P2 suit immédiatement P1 (décision archi `manual`).
- P3 est scopé et débloque C2a ; ne jamais le bundler avec P4 (gros refactor, fortes deps inverses).
- P6 est **indépendant de P1** (diagnostic 2026-07-01) : la friction est autoportée par l'evidence de dogfooding ; seul « jusqu'où relâcher le gate » gagnerait à connaître l'efficacité agent (P1).

Question à traiter maintenant :

- Quelle **métrique primaire** ancre le benchmark P1 ? Elle deviendra le
  `product.success_metric` de la fiche, donc à trancher **avant** création.

## Décisions actées

| Date | Item | Décision | Raison | Suite |
|---|---|---|---|---|
| 2026-06-30 | — | Axe directeur = « Prouver & positionner » | Crédibilité = goulot ; valeur non prouvée | P1 actif, P2 ensuite |
| 2026-06-30 | P3/P4 | Splitter validateur (P3) et réécriture moteur (P4) | P4 a de fortes deps inverses ; P3 débloque C2a seul | P3 routé feature, P4 refactor à décider |
| 2026-06-30 | P7 | Différé (candidat `dropped`) | Coût de suivi > valeur court terme | Revue après P1/P2 |
| 2026-06-30 | P1 | Métrique primaire = **taux de succès de tâche** | Claim qui confère le titre ; tokens = leading indicator | Fiche prête ; attend feu vert création |
| 2026-06-30 | P1 | v1 maintainer-only + ≥2 repos de référence, N runs | Prouver avant de packager ; absorber la stochasticité | Cadré dans la spec fiche |
| 2026-06-30 | P1 | Fiche `product/agent-efficacy-benchmark` créée + checks verts | Routage feature confirmé (« go ») | Build harnais = travail feature (phase spec) |
| 2026-06-30 | P2 | Posture = **préparer le collapse (hedge)** | Lecture native AGENTS.md ≠ protocole de chargement `.ai/` ; assurance peu coûteuse, pas de pivot prématuré | HANDOFF product→core ; nouvelle feature core à confirmer |
| 2026-06-30 | P3 | Routé feature `quality/feature-schema-validator` ; validateur réel + **fallback bash** ; runtime recommandé `check-jsonschema` (pip) | Débloque C2a sans dépendance dure ni nouvel écosystème ; enforce le contrat OKF | Fiche créée + checks verts ; runtime exact à trancher |
| 2026-06-30 | P3 | Scope = quality (enforce), depends_on core/okf-strict-profile (contrat) | Séparer contrat (core) et enforcement (quality) | — |
| 2026-06-30 | P2 | HANDOFF exécuté : fiche `core/agents-md-native-collapse-path` créée (hedge) | AGENTS.md auto-suffisant, indirection optionnelle, invariant `.ai/` préservé | Build = travail feature core ; kill_criterion à opérationnaliser |
| 2026-06-30 | — | Cadrage clos ; passage à l'implémentation **un scope par tour** | Ne pas mélanger code core+quality en un tour (règle dogfoodée) | P3 d'abord (isolé), puis P2 |
| 2026-07-01 | P3/P2 | Incréments 1 livrés (dc9c4c6 / ed78af8) + smoke (885f169) | Zéro dép, éthos bash/jq/yq respecté (recadrage P3 vs check-jsonschema) | Follow-ups tracés dans les fiches |
| 2026-07-01 | P4 | **Différé (dropped tel que cadré)** après mesure | Matching ≠ goulot (grandit à peine) ; coût = parsing yq build-index, LINÉAIRE, négligeable + caché à ≤100 fiches. Réécriture Python contredit l'éthos ET rate la cible | Si perf mord un jour : batcher le yq de build-index (in-éthos), pas de Python |
| 2026-07-01 | P5 | **Différé (dropped, déjà résolu)** | `dogfood-update.sh --apply` génère déjà le runtime depuis le template ; la source unique existe. Taxe résiduelle inhérente au Jinja + mitigée par drift-check → rien à refactorer | Ergonomie template-first possible plus tard, faible ROI |
| 2026-07-01 | méta | **P3/P4/P5 = 3/3 prémisses recadrées vers le bas** | Le projet traite déjà plus que la vue externe ne supposait. La vraie valeur restante demande de la PREUVE, pas de la machinerie | Concentrer sur P1 (prouver) et P6 (friction adoption) |
| 2026-07-01 | P6 | **Diagnostiqué** (aic-diagnose) : racine = largeur `touches:` | 9 surfaces transverses en `touches:` bloquant (breadth-guard) → cascade freshness + bruit auto-worklog. Fix = reclasser en `touches_shared:` (outil déjà là). Indépendant de P1 | 1ère action : CHANGELOG.md touches:→touches_shared: dans ses 6 coverers (chantier quality/cross-scope dédié) |
| 2026-07-01 | P6 | **Incr.1 livré** : CHANGELOG.md reclassé touches_shared: (6 fiches, 84d54aa) | Cascade freshness supprimée à la racine ; feature `quality/touches-breadth-guard` 2ᵉ vague. Vérifié : check-features PASS, breadth-guard ne liste plus CHANGELOG | Reste optionnel : autres surfaces >4 (code réel, au cas par cas) |
| 2026-07-01 | P1 | **Incr.1 livré** : scaffold benchmark (0164289) | PROTOCOL + runner self-checkable (seam AGENT_CMD) + tâche exemple ; runner = seam externe (tranche « runner ouvert »). Runs réels = action mainteneur | Câbler AGENT_CMD + ≥2 repos + N → 1er rapport |
| 2026-07-01 | — | **Pilotage CLOS** : les 2 branches feature mergées dans main, checks + tests + self-check verts | Tous les axes soldés (incr.1 ou dropped) ; résiduel = follow-ups feature-level, pas pilot | Suivi dans les fiches ; runs P1 = mainteneur |

## Handoffs

```text
HANDOFF
  from_scope: product
  to_scope: core
  status: exécuté (fiche core/agents-md-native-collapse-path créée)
  files_touched:
    - .docs/features/core/agents-md-native-collapse-path.md (créée)
    - .docs/features/core/agents-md-native-collapse-path.worklog.md (créée)
  pending:
    - créer feature core "chemin de collapse" : AGENTS.md auto-suffisant, .ai/index.md OPTIONNEL
    - opérationnaliser le kill_criterion #34235 (veille/test, déjà amorcé dans agents-md-shim-canonical)
    - étendre check-shims aux agents activés (.copier-answers) — follow-up existant
  risks:
    - chevauchement avec core/agents-md-shim-canonical → nouvelle fiche justifiée : l'indirection .ai/index.md est explicitement HORS-périmètre de la fiche shim ("chantier séparé")
    - invariant aic-surface-canonical (".ai/ source unique de contenu") : le hedge GARDE .ai/ comme source et rend l'ENTRÉE AGENTS.md auto-suffisante — ne pas violer l'invariant
```

```text
HANDOFF  (P3) product → quality   |  status: exécuté
  from_scope: product
  to_scope: quality
  files_touched:
    - .docs/features/quality/feature-schema-validator.md (créée)
    - .docs/features/quality/feature-schema-validator.worklog.md (créée)
  pending:
    - trancher le runtime validateur (check-jsonschema pip vs ajv node vs lib jsonschema)
    - brancher en mode warn dans check-features ; conserver le fallback bash
    - flip fail en vN+1, coordonné avec core/okf-strict-profile
  risks:
    - ne PAS hard-requérir un binaire → dégradation gracieuse si absent
    - tenir la parité runtime/template si check-features est modifié
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| P1 | Fiche `product/agent-efficacy-benchmark` créée + checks verts | — | routé (build = travail feature) | check-features ✅ / check-feature-docs ✅ |
| P2 | Décision archi indirection vs AGENTS.md natif | — | décidé (hedge) → HANDOFF core | décision actée 2026-06-30 |
| P2→ | Fiche core `agents-md-native-collapse-path` créée + checks verts | — | routé (build = travail feature) | check-features ✅ / check-feature-docs ✅ |
| P3 | Fiche `quality/feature-schema-validator` créée + checks verts | — | routé (build = travail feature) | check-features ✅ / check-feature-docs ✅ |

## Validation de clôture

- Tous les items sont `done`, `dropped`, `handoff` ou explicitement reportés.
- Les features validées ont une fiche `.docs/features/<scope>/<id>.md`.
- Les checks et preuves associées sont renseignés.

## Next hint

Trancher la métrique primaire de P1, créer `product/agent-efficacy-benchmark`,
puis ouvrir la décision P2 (archi AGENTS.md). P3 prêt à router en parallèle si
besoin (scope quality, sans dépendance à P1).
