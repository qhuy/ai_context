#!/bin/bash
# ai-context.sh — Wrapper CLI unifié (MVP) pour les scripts .ai/scripts/*.
#
# Pas de logique propre : route les sous-commandes vers les scripts existants.
# But : offrir une surface stable (`ai-context <verbe>`) sans casser l'invocation
# directe `bash .ai/scripts/<script>.sh`.
#
# Usage :
#   bash .ai/scripts/ai-context.sh <command> [args...]
#   bash .ai/scripts/ai-context.sh --help
#
# Sous-commandes (toutes les options du script cible sont passées telles quelles) :
#   doctor       → bash .ai/scripts/doctor.sh
#   resume       → bash .ai/scripts/resume-features.sh
#   audit        → bash .ai/scripts/audit-features.sh
#   migrate      → bash .ai/scripts/migrate-features.sh
#   pr-report    → bash .ai/scripts/pr-report.sh
#   review       → bash .ai/scripts/review-delta.sh
#   measure      → bash .ai/scripts/measure-context-size.sh
#   check        → bash .ai/scripts/check-features.sh
#   coverage     → bash .ai/scripts/check-feature-coverage.sh
#   shims        → bash .ai/scripts/check-shims.sh
#   index        → bash .ai/scripts/build-feature-index.sh
#   reminder     → bash .ai/scripts/pre-turn-reminder.sh
#
# Exit codes : ceux du script ciblé.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

print_help() {
  cat <<'HELP'
Usage: bash .ai/scripts/ai-context.sh <command> [args...]

Wrapper minimal sans logique propre — délègue aux scripts dédiés.

Commandes :
  doctor       diagnostic non destructif (dépendances, hooks, index, checks)
  resume       buckets EN COURS / BLOQUÉES / STALE / À FAIRE
  audit        audit-features.sh (discover <scope>)
  migrate      migration frontmatter (--apply explicite)
  pr-report    rapport markdown/json d'impact feature depuis un diff git
  review       synthèse review-friendly du delta courant
  measure      taille contexte injecté par les hooks
  check        check-features.sh (frontmatter + scope + depends_on + touches)
  coverage     check-feature-coverage.sh (orphelins)
  shims        check-shims.sh (cohérence shims racine ↔ .ai/index.md)
  index        build-feature-index.sh (rebuild .ai/.feature-index.json)
  reminder     pre-turn-reminder.sh (sortie text ou json)

Aliases : --help, -h, help
HELP
}

cmd="${1:-}"
case "$cmd" in
  ""|-h|--help|help)
    print_help
    exit 0
    ;;
esac
shift

case "$cmd" in
  doctor)     exec bash "$script_dir/doctor.sh" "$@" ;;
  resume)     exec bash "$script_dir/resume-features.sh" "$@" ;;
  audit)      exec bash "$script_dir/audit-features.sh" "$@" ;;
  migrate)    exec bash "$script_dir/migrate-features.sh" "$@" ;;
  pr-report)  exec bash "$script_dir/pr-report.sh" "$@" ;;
  review)     exec bash "$script_dir/review-delta.sh" "$@" ;;
  measure)    exec bash "$script_dir/measure-context-size.sh" "$@" ;;
  check)      exec bash "$script_dir/check-features.sh" "$@" ;;
  coverage)   exec bash "$script_dir/check-feature-coverage.sh" "$@" ;;
  shims)      exec bash "$script_dir/check-shims.sh" "$@" ;;
  index)      exec bash "$script_dir/build-feature-index.sh" "$@" ;;
  reminder)   exec bash "$script_dir/pre-turn-reminder.sh" "$@" ;;
  *)
    echo "Commande inconnue: $cmd" >&2
    print_help >&2
    exit 1
    ;;
esac
