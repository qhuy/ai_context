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
