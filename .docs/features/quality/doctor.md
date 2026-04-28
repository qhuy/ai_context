---
id: doctor
scope: quality
title: Diagnostic d'installation non destructif (doctor)
status: active
depends_on:
  - quality/ci-guard
  - core/template-engine
touches:
  - template/.ai/scripts/doctor.sh.jinja
  - README.md
  - PROJECT_STATE.md
  - CHANGELOG.md
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "MVP script doctor (checks dépendances/hooks/index + next actions)"
  blockers: []
  resume_hint: "évaluer extraction future vers ai-context doctor (CLI) avec flags --json/--strict"
  updated: 2026-04-28
---

# Doctor (diagnostic)

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

## Contrats

- Non destructif : aucune écriture.
- Compatible fallback : warnings quand optionnel absent, erreurs quand bloquant.

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
