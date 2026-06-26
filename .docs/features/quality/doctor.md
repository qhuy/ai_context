---
id: doctor
scope: quality
title: Diagnostic d'installation non destructif (doctor)
status: active
depends_on:
  - quality/ci-guard
  - core/template-engine
touches:
  - .ai/scripts/doctor.sh
  - template/.ai/scripts/doctor.sh.jinja
touches_shared:
  - README.md
  - PROJECT_STATE.md
  - CHANGELOG.md
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "MVP script doctor (checks dépendances/hooks/index + next actions) ; smoke-test couvre les régressions review"
  blockers: []
  resume_hint: "évaluer extraction future vers ai-context doctor (CLI) avec flags --json/--strict"
  updated: 2026-04-28
type: feature
---

# Doctor (diagnostic)

## Résumé

`doctor.sh` est le point d'entrée unique de diagnostic d'une installation ai_context : il vérifie dépendances, repo/hooks, fichiers `.ai` critiques et rejoue les checks read-only sans rien écrire. Il réduit la friction d'adoption en donnant un état lisible et des `Next actions` concrètes.

## Objectif

Réduire la friction d'adoption en fournissant un point d'entrée unique de diagnostic qui n'écrit rien et donne des actions concrètes.

## Comportement attendu

- `bash .ai/scripts/doctor.sh` affiche un état lisible :
  - dépendances (`jq`, `yq`, `copier`) ;
  - repo git + hooks ;
  - fichiers `.ai` critiques ;
  - exécution de `check-shims` / `check-features` ;
  - lisibilité `measure-context-size`.
- Mode par défaut (`doctor.sh`) : diagnostic informatif, retourne `0`.
- Mode strict (`doctor.sh --strict`) : retourne non-zéro si blocage.
- Affiche un bloc `Next actions` si des corrections sont suggérées.

## Périmètre

### Inclus

- Le script source `.ai/scripts/doctor.sh` et son gabarit `template/.ai/scripts/doctor.sh.jinja` (CI/diagnostic livrés aux projets générés).
- Diagnostic des dépendances (`jq`, `yq`, `copier`), du repo git + hooks, des fichiers `.ai` critiques.
- Orchestration en lecture seule des checks existants (`check-shims`, `check-features`, `measure-context-size`) et agrégation d'un bloc `Next actions`.

### Hors périmètre

- La logique interne des checks invoqués (portée par leurs propres features : `quality/ci-guard`, `core/template-engine`, etc.) ; `doctor.sh` ne fait que les appeler.
- Toute écriture ou correction automatique : `doctor.sh` reste purement informatif.
- Une CLI dédiée (`ai-context doctor` avec `--json`) : précurseur seulement, extraction future (cf. `resume_hint`).

## Invariants

- Non destructif : aucune écriture, quel que soit le mode.
- Mode par défaut informatif → exit `0` (pas de faux négatif sur scaffold sain en CI smoke-test).
- Mode `--strict` → exit non-zéro uniquement sur blocage réel.
- Optionnel absent ⇒ warning ; bloquant absent ⇒ erreur (fallback gracieux).
- Cohérence entre la source `.ai/scripts/doctor.sh` et le gabarit `.jinja` rendu chez les consommateurs.

## Décisions

- MVP en **Bash** embarqué dans le template avant toute extraction vers une CLI.
- Mode par défaut **informatif** (exit 0), `--strict` **opt-in** : évite de casser le smoke-test sur un scaffold frais sain.
- Repo git absent traité en **warning** (+ action suggérée), pas en blocage : un scaffold fraîchement généré n'a pas encore fait `git init`.
- Présence des scripts critiques testée avec `[[ -f ]]` et non `[[ -x ]]` : le bit `+x` n'est pas préservé après rendu Copier et tous les scripts sont invoqués via `bash <script>`.
- Le contrôle `.githooks` ne cible que les vrais hooks exécutables (`commit-msg`, `pre-commit`, `post-checkout`) et ignore `.githooks/README.md`.

## Contrats

- Non destructif : aucune écriture.
- Compatible fallback : warnings quand optionnel absent, erreurs quand bloquant.

## Validation

- `tests/smoke-test.sh` exécute `doctor.sh --strict` sur le scaffold rendu et garantit la non-régression (exit 0 sur scaffold sain, blocage sur réel manque).
- `doctor.sh` (mode défaut) tourne sur un repo sain et retourne `0` ; `doctor.sh --strict` retourne non-zéro sur dépendance/fichier critique manquant.
- Le gabarit `template/.ai/scripts/doctor.sh.jinja` est rendu sans erreur Jinja par `copier copy` (couvert par le smoke-test).
- Vérifié au sanity check post-tag : présence des scripts via `[[ -f ]]` (pas de faux positif lié au bit `+x` après rendu Copier).

## Cross-refs

- Précurseur de la commande future `ai-context doctor`.
- Complément de `quality/ci-guard` pour le diagnostic local.

## Historique / décisions

- 2026-04-27 : MVP Bash introduit dans le template avant extraction CLI.
- 2026-04-27 : assouplissement pour scaffold frais : `doctor.sh` ne considère plus l'absence de repo git comme bloquante (warning + action suggérée), et skip le contrôle hooks quand `git init` n'a pas encore été fait.
- 2026-04-27 : ajout du mode `--strict` ; le mode par défaut devient informatif (exit 0) pour éviter les faux négatifs sur scaffold sain en CI smoke-test.
- 2026-04-28 : édition cross-feature (PR1 v0.10) — README, PROJECT_STATE et CHANGELOG synchronisés avec la portée actuelle de `doctor.sh` (mode par défaut informatif, `--strict` opt-in). Aucun changement de comportement runtime ; entrée d'historique pour conformité anti-doc-drift (touches inclut README/PROJECT_STATE/CHANGELOG).
- 2026-04-28 : `tests/smoke-test.sh` étendu (assertions `pr-report --format=json` + `--include-docs`, wrapper `ai-context.sh`, `audit-features` paths-with-spaces, `check-features` exige depends_on/touches). Aucun impact sur le comportement de `doctor.sh` lui-même mais le smoke-test reste la garantie de non-régression.
- 2026-04-28 (post-v0.10.0) : fix faux positifs détectés au sanity check post-tag. `doctor.sh` testait la présence des scripts critiques avec `[[ -x ".ai/scripts/X.sh" ]]` (executable bit) alors que le bit +x n'est pas systématiquement préservé après rendu Copier (modes 644 vs 755). Tous les scripts sont invoqués via `bash <script>` qui n'a pas besoin du bit +x. Remplacé par `[[ -f ]]` (présence du fichier). Concerne `check-shims.sh`, `check-features.sh`, `measure-context-size.sh`. Bug pré-existant depuis l'introduction de `doctor.sh` (v0.9+), non bloquant car doctor par défaut exit 0, mais cosmétique et trompeur. Pas de release dédiée — sera embarqué dans v0.10.1 ou la prochaine version.
- 2026-05-03 : correction du contrôle `.githooks` : `doctor --strict` vérifie désormais uniquement les vrais hooks exécutables (`commit-msg`, `pre-commit`, `post-checkout`) et ignore `.githooks/README.md`. Évite de demander `chmod +x` sur une documentation.
- 2026-05-03 : `tests/smoke-test.sh` embarque les tests unitaires de régression `check-feature-freshness` multi-feature et drift dogfood destination-only. Pas de changement de comportement `doctor.sh`, mais la garantie globale exécutée avec le doctor strict reste synchronisée.
- 2026-05-03 : les surfaces transverses `README.md`, `PROJECT_STATE.md`, `CHANGELOG.md` et `tests/smoke-test.sh` passent en `touches_shared` pour rester visibles en review sans rendre chaque édition transverse bloquante pour cette fiche.
