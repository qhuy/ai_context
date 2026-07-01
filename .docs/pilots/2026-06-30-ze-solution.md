---
pilot_id: "2026-06-30-ze-solution"
status: "active"
source: "Analyse à froid du repo (regard neuf) + cadrage axes d'amélioration"
scope_primary: "product"
created_at: "2026-06-30"
updated_at: "2026-06-30"
active_item: "P1 fiché ; P2/P3 incr.1 livrés ; P4 différé (mesuré) ; reste P5/P6"
active_question: "Prochain : P6 (diagnose adoption / anti --no-verify) ou P5 (dual-tree) ? P6 dépend en partie de l'evidence P1 (non encore construite)."
next_hint: "Branche pilot/ze-solution-axes (6 commits) à PR/merger. Livré : cadrage 7 axes ; P1 fiché ; P3 incr.1 (clés requises schéma-driven, zéro dép) + smoke ; P2 incr.1 (self-suffisance AGENTS.md verrouillée). P4 DIFFÉRÉ après mesure (matching ≠ goulot ; coût = parsing yq build-index, linéaire+caché — pas de réécriture Python : contredit l'éthos). Reste : P5 (dual-tree, core, fortes deps), P6 (diagnose adoption, dépend evidence P1), P7 différé. Follow-ups P2/P3 : kill_criterion #34235, HANDOFFs smoke, CHANGELOG."
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
| P1 | Benchmark d'efficacité agent (valeur mesurée) — **fiche créée** | doing | product | feature (initiative) | bench reproductible : Δ tokens / fiabilité avec vs sans ai_context |
| P2 | Pari `.ai/index.md` vs AGENTS.md lecture native — **fiche core créée** | doing | core | manual → feature core | chemin de collapse documenté + kill_criterion #34235 opérationnalisé |
| P3 | Validateur clés requises schéma-driven (recadré : zéro dép) — **incr. 1 livré + CI** | doing | quality/core | feature | clé ajoutée au schéma → exigée : test PASS + smoke [0q/28] ✅ |
| P4 | Noyau moteur hors bash (index/cycles/glob) | **dropped (tel que cadré)** | core | mesuré → différé | mesure faite : matching ≠ goulot ; coût = parsing yq de build-index (linéaire), négligeable+caché à échelle réaliste |
| P5 | Taxe dual-tree (runtime généré depuis template) | triage | core | refactor | source unique ; drift-check trivial/inutile |
| P6 | Calibrage cérémonie consommateur / anti `--no-verify` | triage | workflow (+product) | diagnose | données d'adoption ; mode soft défini |
| P7 | Sprawl docs racine + cadence auto-audit | inbox | product/docs | docs/chore (différé) | doc racine consolidée, cadence audit bornée |

Statuts : `inbox`, `triage`, `validated`, `blocked`, `handoff`, `doing`, `review`, `done`, `dropped`.

Routes : `feature`, `fix`, `docs`, `refactor`, `chore`, `diagnose`, `handoff`, `manual`, `dropped`.

## Question active

Contexte affiché :

- P2 suit immédiatement P1 (décision archi `manual`).
- P3 est scopé et débloque C2a ; ne jamais le bundler avec P4 (gros refactor, fortes deps inverses).
- P6 dépend de P1 pour son evidence (pas de feature avant données).

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
