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
  updated: 2026-04-27
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
- Retourne `0` si aucun blocage ; non-zéro si blocage.
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
