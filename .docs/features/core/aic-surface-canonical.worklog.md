# Worklog — core/aic-surface-canonical

## 2026-05-06 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : unifier la surface utilisateur canonique autour de `aic`

## 2026-05-06 — implementation
- Intent : migration breaking propre vers la surface `aic` sans alias legacy.
- Fichiers/surfaces : wrapper runtime/template `aic.sh`, README racine/downstream, message Copier, docs migration/update, smoke-test, fiches feature touchant l'ancien wrapper.
- Décision : `aic-document-feature` est expose comme intention officielle ; `diagnose` evite le faux positif `adr` sur `cadrage`.
- Validation : `bash -n`, `aic.sh --help`, `aic.sh frame`, `aic.sh diagnose`, `aic.sh document-feature`, `check-shims`, `check-ai-references`, `check-features`, `check-feature-docs core/aic-surface-canonical`, `check-feature-coverage`, `measure-context-size`, `tests/smoke-test.sh`.
- Next : relire le delta puis commit dedie du sous-chantier si le scope convient.

## 2026-05-06 — freshness README
- Intent : verifier que la réécriture README conserve la surface canonique `aic` sans réintroduire d'ancien alias public.
- Validation : `check-ai-references`, `check-feature-docs product/readme-positioning`.

## 2026-05-06 — retours review
- Intent : traiter les retours review sur la migration canonique `aic`.
- Fichiers/surfaces : `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`, contrat product `aic.sh product-*`.
- Décision : `aic ship` ne filtre plus les suppressions/renommages staged via `--diff-filter=AM`, le hint ne déduit plus `feat:` d'une fiche seule, et le contrat produit ne mentionne plus l'ancien wrapper.
- Validation : prévue via `bash -n`, `check-*`, `aic ship` et smoke ciblé.
- Next : commit dédié `fix:` après quality gate.

## 2026-05-06 22:46 — auto
- Fichiers modifiés :
  - template/.agents/skills/aic-feature-done/SKILL.md.jinja
  - template/.agents/skills/aic-feature-done/workflow.md.jinja
  - template/.agents/skills/aic-feature-handoff/SKILL.md.jinja
  - template/.agents/skills/aic-feature-handoff/workflow.md.jinja
  - template/.agents/skills/aic-feature-new/SKILL.md.jinja
  - template/.agents/skills/aic-feature-new/workflow.md.jinja
  - template/.agents/skills/aic-feature-resume/SKILL.md.jinja
  - template/.agents/skills/aic-feature-resume/workflow.md.jinja
  - template/.agents/skills/aic-feature-update/SKILL.md.jinja
  - template/.agents/skills/aic-feature-update/workflow.md.jinja
  - template/.agents/skills/aic-frame/workflow.md.jinja
  - template/.agents/skills/aic-quality-gate/SKILL.md.jinja
  - template/.agents/skills/aic-quality-gate/workflow.md.jinja
  - template/.agents/skills/aic-ship/SKILL.md.jinja
  - template/.agents/skills/aic-status/SKILL.md.jinja
  - template/.claude/skills/aic-frame/workflow.md.jinja
  - template/.claude/skills/aic-ship/SKILL.md.jinja
  - template/.claude/skills/aic-status/SKILL.md.jinja

## 2026-05-08 — freshness
- Impact indirect : nettoyage drift README runtime/template + note mainteneur PROJECT_STATE (driver core/dogfood-runtime-sync).
- Aucun changement de contrat propre a cette feature.

## 2026-05-12 — alignement dogfood
- Impact : `PROJECT_STATE.md`, `README_AI_CONTEXT.md` et `template/README_AI_CONTEXT.md.jinja` restent alignes avec la surface publique `aic-*`.
- Validation : `check-dogfood-drift.sh` PASS.

## 2026-05-12 — impact partagé test lock index

- Fichiers/surfaces : `tests/smoke-test.sh`.
- Contexte : `quality/index-lock-contract` ajoute une assertion smoke sur le timeout de `with_index_lock`.
- Impact : aucune evolution de surface AIC ; le smoke couvre une regression runtime supplementaire.
- Validation portée par `quality/index-lock-contract`.

## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `tests/smoke-test.sh`.
- Impact : ajout d'un appel aux tests unitaires de regressions Q4 dans le smoke, sans modifier la surface utilisateur `aic`.
- Validation : `bash tests/smoke-test.sh` PASS.

## 2026-05-12 — veille Claude/Codex
- Impact indirect : README, README runtime/template et smoke-test exposent les contrats subagents/hooks/MCP sans changer la commande canonique `aic`.
- Aucun alias legacy ou nouvelle surface CLI ajoute.
- Validation : `check-ai-references`, `check-shims` et smoke-test PASS.

## 2026-06-01 — copier.yml : ajout _min_copier_version (audit U10)

- `copier.yml` reçoit un plancher `_min_copier_version: "9.0.0"` (setting moteur, porté par core/template-engine). Aucun impact sur le périmètre de cette feature ; entrée de traçabilité car `copier.yml` reste dans son `touches:`.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - copier.yml

## 2026-06-02 10:13 — auto
- Fichiers modifiés :
  - template/.agents/skills/aic-ship/SKILL.md.jinja
  - template/.claude/skills/aic-ship/SKILL.md.jinja

## 2026-06-08 — freshness PROJECT_STATE v0.13.0 (audit DOC-1)
- Intent : corriger l'écart doc↔réalité relevé par l'audit hebdo (DOC-1) — `PROJECT_STATE.md` restait bloqué sur v0.12.0 alors que v0.13.0 est releasée (CHANGELOG + tag `v0.13.0`), en violation de la checklist `RELEASE.md:57`.
- Fichiers/surfaces : `PROJECT_STATE.md` (version publiée, section « État actuel » v0.13.0, liste des tags). Aucun changement de surface `aic`.
- Décision : ajouter une section « État actuel (v0.13.0) » (contrat read-only des checks, index contract v2, surface CLI `aic` breaking, installation Codex `.agents/`) et conserver l'état v0.12.0 en rappel.
- Validation : `check-ai-references`, `check-features --no-write`, `check-dogfood-drift.sh` (PROJECT_STATE root-only, non templaté).

## 2026-06-19 14:53 — auto
- Fichiers modifiés :
  - template/.agents/skills/aic-onboard/SKILL.md.jinja
  - template/.agents/skills/aic-onboard/workflow.md.jinja
  - template/.claude/skills/aic-onboard/SKILL.md.jinja
  - template/.claude/skills/aic-onboard/workflow.md.jinja
  - tests/smoke-test.sh

## 2026-06-19 15:14 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - docs/upgrading.md

## 2026-06-19 17:52 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-19 18:03 — auto
## 2026-06-08 16:51 — auto
- Fichiers modifiés :
  - PROJECT_STATE.md

## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - CHANGELOG.md
  - MIGRATION.md
  - copier.yml
  - docs/upgrading.md
  - template/.ai/scripts/aic.sh.jinja

## 2026-06-26 11:34 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-26 15:48 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-06-26 — couverture incidente (workflow/auto-worklog fix churn date)
- Surface partagée touchée (tests/smoke-test.sh, gabarit flush, ou tests/unit) couverte par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-26 16:56 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-26 17:25 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-28 20:34 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-26 — couverture incidente (CHANGELOG clôture session)
- `CHANGELOG.md` (entrées [Unreleased] des features de la session) couvert par le glob `touches:` de cette feature. Aucun changement de comportement propre. (CHANGELOG.md = candidat touches_shared, cf. quality/touches-breadth-guard.)

## 2026-06-28 21:09 — auto
- Fichiers modifiés :
  - CHANGELOG.md

## 2026-06-29 — PROJECT_STATE : note mainteneur remediation (A7)
- Ajout note 2026-06-29 pointant vers le frame de remediation (registre de reprise) + resume des durcissements de session. Vue mainteneur rendue exacte (audit A7).
- Fichiers : PROJECT_STATE.md

## 2026-06-30 — surface aic-pilot + ownership dispatcher
- `aic.sh` documente `pilot` comme bootstrap skill-only et garde la surface CLI scriptable sans transformer le pilotage en commande déterministe.
- `README_AI_CONTEXT.md` et son template exposent `aic-pilot` dans la surface utilisateur commune Claude/Codex.
- Reclassification freshness `(a')` : `aic.sh`, `template/.ai/scripts/aic.sh.jinja`, `README_AI_CONTEXT.md` et `template/README_AI_CONTEXT.md.jinja` restent propriétaires exacts de `core/aic-surface-canonical`; les features consommatrices passent en `touches_shared`.

## 2026-07-03 — HANDOFF depuis core/vcs-provider-abstraction
- Surface partagée touchée : `aic.sh` consomme le provider VCS pour les compteurs de delta, review et ship. La surface commande reste inchangée.
- Validation portée par `core/vcs-provider-abstraction`.

## 2026-07-03 — done
- Intent : clôture documentaire de `core/aic-surface-canonical`.
- Fichiers/surfaces : `.docs/features/core/aic-surface-canonical.md`, `.docs/features/core/aic-surface-canonical.worklog.md`.
- Décision : statut `done` ; la surface publique `aic`/`aic-*` est stable, `aic-pilot` et `aic-onboard` sont intégrés, et les changements VCS récents n'ont pas ajouté d'alias legacy.
- Doc Impact Decision : C — fiche feature et worklog mis à jour.
- Validation prévue : `aic.sh --help`, checks shims/références/features/freshness, mesure contexte et smoke ciblé/full selon coût avant commit.
- Next : aucune action immédiate ; rouvrir si une nouvelle commande publique `aic` ou un alias legacy est ajouté.
## 2026-07-03 — routage aic knowledge

- Intent : tracer l'extension minimale de la surface CLI publique `aic` pour la feature `workflow/knowledge-publish-search-link`.
- Fichiers/surfaces : `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`.
- Décision : `aic.sh` ajoute seulement l'aide et le dispatch `knowledge` vers `knowledge.sh`; la logique publish/search/link/import reste en scope workflow.
- Validation : couverte par `bash tests/unit/test-knowledge-workflow.sh`, `bash tests/unit/test-template-jinja-raw-braces.sh`, `bash .ai/scripts/check-dogfood-drift.sh`, puis freshness stricte à relancer.
- Next : aucune action core ; rouvrir seulement si la taxonomie publique `aic` change au-delà du routage knowledge.

## 2026-07-06 — couverture incidente (workflow/codex-hooks-parity)
- `README_AI_CONTEXT.md` (+ miroir jinja) : section Runtime — ajout de la ligne Codex (hooks natifs `.codex/hooks.json` si `enable_codex_hooks=true`, trust de la couche projet) ; section Contrats avancés alignée. Aucun changement de la surface `aic`.
- Validation portée par `workflow/codex-hooks-parity`.

## 2026-07-06 — couverture incidente (core/agents-md-shim-canonical, P2 commit ③)
- `template/README_AI_CONTEXT.md.jinja` : ligne Cursor (conditionnelle) réécrite — AGENTS.md natif + `.mdc` scopés par globs, protocol-reminder retiré. Aucun changement de la surface `aic`. Validation portée par `core/agents-md-shim-canonical`.

## 2026-07-06 — couverture incidente (core/agents-md-shim-canonical, P2 commit ④)
- `MIGRATION.md` : nouveau § « Shims Copilot / Cursor — élagage AGENTS.md natif » (conséquences copier update, enable_copilot_shim, rollback). Aucun changement de la surface `aic`. Validation portée par `core/agents-md-shim-canonical`.

## 2026-07-06 15:08 — auto
- Fichiers modifiés :
  - MIGRATION.md

## 2026-07-07 — couverture incidente (fix post-review, core/agents-md-shim-canonical)
- MIGRATION.md / docs/upgrading.md : sémantique `copier update` des shims élagués corrigée sur preuve empirique (copier update ne supprime jamais un chemin `_exclude`). Aucun changement du contrat propre de cette fiche. Validation portée par `core/agents-md-shim-canonical`.
## 2026-07-06 — couverture incidente (workflow/evidence-discipline)
- workflow.md des skills d'analyse (aic-review/diagnose/pilot/frame, Claude+Codex+templates) : une règle non négociable « discipline de preuve » ajoutée — toute affirmation prouvée (source citée) ou étiquetée Hypothèse / À vérifier. Aucun changement du contrat propre de cette fiche. Validation portée par `workflow/evidence-discipline`.

## 2026-07-07 — couverture incidente (workflow/intentional-skills, P3)
- Les 6 wrappers Codex procéduraux `aic-feature-{new,done,handoff,resume,update}` et `aic-quality-gate` (racine `.agents/skills/` + miroirs `template/.agents/skills/`) sont supprimés — surface skills réduite (chantier P3). Aucun canal externe ne les référençait ; zéro perte de capacité (`.ai/workflows/*` reste la source canonique). `copier.yml` (message après copy) et `tests/smoke-test.sh` (étape [19/28], assertion d'absence) alignés. Aucun changement du contrat propre de cette fiche.
- Validation portée par `workflow/intentional-skills`.

## 2026-07-07 — couverture incidente (P4 gouvernance bash, chantier ANALYSE.md)
- `CONTRIBUTING.md` : ajout d'un § « Moratoire sur la croissance du moteur bash » sous « Ajouter un script runtime » — pas de yq obligatoire (décision existante `core/feature-mesh-contract-alignment` maintenue après clarification utilisateur), gel de toute nouvelle logique bash non triviale sans justification écrite. Aucun changement de la surface `aic` ni du runtime.

## 2026-07-07 — couverture incidente (P5 assainissement matrice)
- `README_AI_CONTEXT.md` (+ miroir jinja) : mention TFVC requalifiée « best-effort, non testé end-to-end ». Aucun changement de la surface `aic`.
