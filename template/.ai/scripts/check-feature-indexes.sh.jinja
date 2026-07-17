#!/bin/bash
# check-feature-indexes.sh — Contrôle read-only des index Markdown du feature mesh.
#
# Usage :
#   bash .ai/scripts/check-feature-indexes.sh          # warn-only (vN)
#   bash .ai/scripts/check-feature-indexes.sh --strict # fail si absent/périmé

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
strict=0
for arg in "$@"; do
  case "$arg" in
    --strict) strict=1 ;;
    -h|--help)
      sed -n '1,6p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Usage: bash .ai/scripts/check-feature-indexes.sh [--strict]" >&2
      exit 2
      ;;
  esac
done

if [[ "$strict" -eq 1 ]]; then
  exec bash "$script_dir/migrate-okf-indexes.sh" --check --strict
fi
exec bash "$script_dir/migrate-okf-indexes.sh" --check
