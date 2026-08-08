# Worklog — workflow/agent-behavior

## 2026-05-03 — création

- Feature créée pour tracer la couche comportementale agent.
- Scope : workflow.
- Intent initial : améliorer la posture, l'initiative, le style de réponse et le diagnostic sans gonfler les shims ni le reminder.

## 2026-05-04 — freshness
- Impact indirect : les nouveaux wrappers Codex restent on-demand et ne changent pas le Pack A.
- Validation associée : check-shims et smoke-test complet PASS.
## 2026-05-05 — freshness
- Impact transversal : l'index principal ajoute le chargement optionnel `.ai/project/index.md` sans élargir Pack A.
- Validation associée : `check-shims.sh` PASS.

## 2026-05-06 — freshness
- Impact indirect : le nouveau skill documente les fiches feature sans modifier la posture agent ni le Pack A.
- `legacy` y est traité comme scope custom seulement si le repo l'active.
- Validation associée : `check-shims.sh`, smoke-test PASS.
## 2026-05-06 — freshness
- Intent : tracer l'impact Copier indirect sur la couche comportementale et `aic-diagnose`.
- Validation : couvert par `check-shims`, `measure-context-size` et `tests/smoke-test.sh`.

## 2026-05-06 22:50 — freshness
- Impact indirect : `copier.yml` mis à jour pendant le durcissement post-cross-check (round 4 workflow/intentional-skills).
- Aucun changement sur la posture agent ni le Pack A.
- Validation associée : `check-feature-freshness.sh` (staged) PASS attendu.
## 2026-05-12 — conventions commit et doc.level

- Fichiers/surfaces : `.ai/index.md`, `template/.ai/index.md.jinja`.
- Contexte : l'item AI Debate `0013/Q3` demande une pedagogie explicite sans modifier la gate `commit-msg`.
- Documentation :
  - arbre de decision pour `feat:`, `fix:`, `refactor:`, `chore:` et `docs:` ;
  - usage de `doc.level=brief|standard|full` selon risque et durabilite du contrat.
- Impact : comportement agentique clarifie dans l'entrypoint lean ; aucun changement runtime.
- Validation portée par les checks Q3.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - copier.yml

## 2026-06-19 12:39 — auto
- Fichiers modifiés :
  - .ai/index.md
  - template/.ai/index.md.jinja

## 2026-07-03 — done
- Intent : clôturer la couche comportementale agent après vérification Pack A, coût contexte et dogfood.
- Fichiers/surfaces : `.docs/features/workflow/agent-behavior.md`, `.docs/features/workflow/agent-behavior.worklog.md`.
- Décision : statut `done`; `.ai/agent/*` et `aic-diagnose` restent on-demand.
- Validation : `bash .ai/scripts/check-shims.sh`; `bash .ai/scripts/measure-context-size.sh`; `bash .ai/scripts/check-dogfood-drift.sh`; `bash .ai/scripts/check-feature-docs.sh --strict workflow/agent-behavior`; `bash tests/smoke-test.sh`.
- Next : aucune action immédiate.

## 2026-07-06 — couverture incidente (workflow/evidence-discipline)
- workflow.md des skills d'analyse (aic-review/diagnose/pilot/frame, Claude+Codex+templates) : une règle non négociable « discipline de preuve » ajoutée — toute affirmation prouvée (source citée) ou étiquetée Hypothèse / À vérifier. Aucun changement du contrat propre de cette fiche. Validation portée par `workflow/evidence-discipline`.

## 2026-07-08 — couverture audit strict
- Surfaces couvertes touchées dans le delta d'audit strict : `.ai/index.md` et `template/.ai/index.md.jinja`.
- Rattachement documentaire pour le gate `check-feature-freshness --staged --strict`; aucun nouveau changement du contrat propre de cette fiche.
- Validation : gate ship relancée avant commit.

## 2026-08-07 — correction post-review du chantier restitution
- Intent : rendre la « source unique » vérifiable, corriger les métriques de contexte et aligner l'état réel de la feature après livraison des lots 1+2.
- Fichiers/surfaces : fiche `workflow/agent-behavior`, registre pilot, `CHANGELOG.md` ; HANDOFF confirmé vers les contrôles core/quality propriétaires.
- Décision : `progress.phase: review` ; les blocs session AGENTS/output style sont égaux octet-à-octet au condensé canonique, tandis que l'ancre reminder reste une projection courte mesurée séparément.
- Mesure (corrigée en review du 2026-08-08 — les valeurs initiales 535→674/+139 ne se reproduisaient pas sur le repo source) : `measure-context-size.sh` compte 560 → 706 caractères statiques, soit +146 (`grep '^- Restitution' .ai/reminder.md | wc -c` → 146) ; estimation du script ~37–49 tokens/tour.
- Validation : `check-shims`, test dynamique, dogfood, smoke complet et quality gate documentaire PASS ; couverture stricte 114/114, 0 orphelin.
- Next : preuve live R1/R4 sur un même prompt Claude/Codex, puis diagnostic R3.
