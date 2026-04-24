#!/bin/bash
# check-feature-coverage.sh — Détecte le code orphelin (non couvert par feature).
#
# Pour chaque répertoire surveillé (COVERAGE_ROOTS), liste les fichiers qui
# ne sont référencés par aucune entrée `touches:` de feature.
#
# Comportement :
#   - exit 0 : tout est couvert, OU mode --warn (par défaut) → sortie informative
#   - exit 1 : mode --strict ET orphelins détectés
#
# Usage :
#   bash .ai/scripts/check-feature-coverage.sh            # warn (exit 0 même avec orphelins)
#   bash .ai/scripts/check-feature-coverage.sh --strict   # exit 1 si orphelins
#
# Config : éditer COVERAGE_ROOTS ci-dessous selon le repo.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq
enable_globstar

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

index_file=".ai/.feature-index.json"
mode="${1:---warn}"

# Zones de code à auditer. Ajuste selon ton repo.
COVERAGE_ROOTS=(
  "src"
  "app"
  "lib"
)

# Extensions prises en compte
COVERAGE_EXTS="ts tsx js jsx py rb go rs java kt swift php"

# Rebuild index si besoin
if [[ ! -f "$index_file" ]]; then
  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
fi
if [[ ! -f "$index_file" ]]; then
  echo "  ⚠️  pas d'index feature, rien à vérifier" >&2
  exit 0
fi

# Toutes les entrées touches:, dédupliquées
touches=()
while IFS= read -r t; do
  [[ -n "$t" ]] && touches+=("$t")
done < <(jq -r '.features[].touches[]?' "$index_file" | sort -u)

if [[ ${#touches[@]} -eq 0 ]]; then
  echo "  ⚠️  aucun touches: déclaré dans les features" >&2
  [[ "$mode" == "--strict" ]] && exit 1
  exit 0
fi

# Construit les prédicats find pour les extensions
ext_args=()
first=1
for ext in $COVERAGE_EXTS; do
  if [[ $first -eq 1 ]]; then
    ext_args+=( -name "*.$ext" )
    first=0
  else
    ext_args+=( -o -name "*.$ext" )
  fi
done

echo "═══ check-feature-coverage ═══"

total=0
orphans=()
for root in "${COVERAGE_ROOTS[@]}"; do
  [[ -d "$root" ]] || continue
  while IFS= read -r -d '' file; do
    total=$((total + 1))
    covered=0
    for entry in "${touches[@]}"; do
      # shellcheck disable=SC2053
      if [[ "$file" == $entry ]] || [[ "$file" == $entry/* ]]; then
        covered=1
        break
      fi
    done
    [[ $covered -eq 0 ]] && orphans+=("$file")
  done < <(find "$root" -type f \( "${ext_args[@]}" \) -print0 2>/dev/null)
done

covered_count=$((total - ${#orphans[@]}))
echo "  fichiers scannés : $total"
echo "  couverts         : $covered_count"
echo "  orphelins        : ${#orphans[@]}"

if [[ ${#orphans[@]} -gt 0 ]]; then
  echo
  echo "  Orphelins (aucune feature.touches ne les couvre) :"
  for f in "${orphans[@]}"; do
    echo "    - $f"
  done
  if [[ "$mode" == "--strict" ]]; then
    echo
    echo "❌ FAIL (--strict)"
    exit 1
  fi
fi

echo
echo "✅ OK"
exit 0
