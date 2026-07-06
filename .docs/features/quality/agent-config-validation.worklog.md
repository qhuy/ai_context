# Worklog — quality/agent-config-validation

## 2026-05-12 — création
- Feature créée via `.ai/workflows/document-feature.md`.
- Scope : quality.
- Intent initial : ajouter un check non destructif des configurations agent.
- HANDOFF reçu : `workflow -> quality`, validé dans le plan utilisateur.

## 2026-05-12 10:22 — implémentation
- Intent : ajout du check non destructif des configs agents et de son test unitaire.
- Fichiers/surfaces : `.ai/scripts/check-agent-config.sh`, `tests/unit/test-check-agent-config.sh`, quality gate, doctor, CI.
- Décision : absence de config agent = OK ; config présente = scripts référencés existants et timeouts Claude valides.
- Validation : tests ciblés et quality checks à lancer en fin de chantier.
- Next : corriger tout retour shellcheck/test.

## 2026-05-12 10:23 — HANDOFF → core

### What delivered
- Script quality et branchements runtime ajoutés.
- Besoin de miroir template identifié pour éviter `check-dogfood-drift`.

### What next needs
- Propager `check-agent-config.sh`, quality gate, doctor, README_AI_CONTEXT et CI dans `template/`.
- Vérifier le rendu Copier via dogfood drift.

### Blockers
- aucun

### Status
DONE
Source session : automation veille-techno

## 2026-05-12 10:35 — validation
- Validation : `check-agent-config` PASS, `tests/unit/test-check-agent-config.sh` PASS, `doctor.sh` PASS, `check-feature-docs --strict quality/agent-config-validation` PASS, `check-dogfood-drift` PASS, `tests/smoke-test.sh` PASS.
- Note : `shellcheck` non lancé car binaire absent localement.
- Décision : feature en `review`, aucun blocker.

## 2026-05-12 10:36 — smoke
- Intent : intégrer `tests/unit/test-check-agent-config.sh` dans le smoke-test pour éviter que le check agent-config reste hors parcours end-to-end.
- Fichiers/surfaces : `tests/smoke-test.sh`.
- Décision : `tests/smoke-test.sh` reste en `touches_shared` pour cette feature ; la couverture directe du script de smoke reste portée par `quality/smoke-test`.
- Validation : `tests/smoke-test.sh` PASS.

## 2026-06-01 — couvert par la boucle tests unitaires CI (audit U2)

- `ai-context-check.yml` passe à une boucle `for t in tests/unit/*.sh` : `test-check-agent-config.sh` (possédé par cette feature) reste exécuté en CI, sans étape dédiée à maintenir. Aucun changement de `check-agent-config.sh`.
- Validation : `test-check-agent-config.sh` couvert par la boucle ; YAML valide.

## 2026-06-01 12:33 — auto
- Fichiers modifiés :
  - .github/workflows/ai-context-check.yml

## 2026-06-26 11:43 — auto
- Fichiers modifiés :
  - .ai/workflows/quality-gate.md

## 2026-06-26 — couverture incidente (quality/touches-breadth-guard)
- `.ai/workflows/quality-gate.md` (+ jinja) touché (ajout du check check-touches-breadth en Phase 1), couvert par le glob `touches:` de cette feature. Aucun changement de comportement propre.

## 2026-06-28 20:34 — auto
- Fichiers modifiés :
  - .ai/workflows/quality-gate.md

## 2026-07-03 — couverture incidente (A6 ci-guard)
- `.github/workflows/ai-context-check.yml` (+ template jinja) touché pour élargir `shellcheck -S error` aux hooks exécutables et aux tests shell. Aucun changement du contrat `check-agent-config` propre ; l'étape CI qui lance `check-agent-config.sh` reste inchangée.
- Validation portée par `quality/ci-guard` : shellcheck élargi PASS, YAML OK, `check-dogfood-drift` PASS, `tests/smoke-test.sh` PASS.

## 2026-07-03 — HANDOFF depuis core/vcs-provider-abstraction
- Surface partagée touchée : `doctor.sh` diagnostique désormais le provider VCS. Aucun changement du contrat `check-agent-config`.
- Validation portée par `core/vcs-provider-abstraction`.

## 2026-07-03 — done
- Intent : clôturer `quality/agent-config-validation` et lever l'ancien gap shellcheck local.
- Fichiers/surfaces : `.docs/features/quality/agent-config-validation.md`, `.docs/features/quality/agent-config-validation.worklog.md`.
- Décision : statut `done` ; le check non destructif reste limité aux configs présentes et n'installe aucun hook.
- Validation : `bash .ai/scripts/check-agent-config.sh` PASS ; `bash tests/unit/test-check-agent-config.sh` PASS ; `bash .ai/scripts/doctor.sh` PASS ; `shellcheck -S error .ai/scripts/check-agent-config.sh tests/unit/test-check-agent-config.sh` PASS.
- Next : aucune action immédiate.

## 2026-07-06 — durcissement bloc .codex (P1 hooks Codex natifs, commit ①)
- Intent : valider strictement les configs hooks Codex natives avant leur génération opt-in par le template (chantier P1 issu d'ANALYSE.md).
- Fichiers/surfaces : `.ai/scripts/check-agent-config.sh` (+ miroir `template/.ai/scripts/check-agent-config.sh.jinja`, byte-identique), `tests/unit/test-check-agent-config.sh`.
- Décision : un `.codex/*.json` portant un objet `hooks` est validé en parité avec le bloc Claude (command non vide, timeout entier positif OBLIGATOIRE — le défaut Codex 600 s est trop laxiste —, refs scripts existantes, hooks non vide) ; les autres `.codex/*` gardent la validation lenient historique (fichiers user-authored). Doc officielle Codex hooks vérifiée le 2026-07-06 (repo-level `<repo>/.codex/hooks.json` supporté, trust model).
- Validation : `bash tests/unit/test-check-agent-config.sh` PASS (4 nouveaux cas : hooks.json valide accepté, timeout manquant refusé, script absent refusé, hooks vide refusé) ; `shellcheck -S error` PASS sur les deux fichiers modifiés.
- Next : commit ② — génération opt-in `.codex/hooks.json` via copier.yml (`workflow/codex-hooks-parity`).

## 2026-07-06 — durcissement post-review (P1, finding mineur confirmé)
- Intent : fermer les faux négatifs du bloc strict hooks.json détectés en review adversariale — une config morte côté Codex passait le check (garantie fantôme).
- Fichiers/surfaces : `.ai/scripts/check-agent-config.sh` (+ miroir jinja), `tests/unit/test-check-agent-config.sh`.
- Nouvelles règles : ko si un événement mappe sur un tableau vide, si un groupe n'a aucune entrée exécutable, ou si une entrée de hook n'a pas `type:"command"` ; warn (non bloquant, API mouvante) si un nom d'événement sort de la surface Codex documentée 2026-07.
- Validation : `bash tests/unit/test-check-agent-config.sh` PASS (3 nouveaux cas ko + 1 cas warn-only) ; `shellcheck -S error` PASS ; auto-exécution sur le repo PASS.

## 2026-07-06 14:33 — auto
- Fichiers modifiés :
  - .ai/scripts/check-agent-config.sh
  - tests/unit/test-check-agent-config.sh
