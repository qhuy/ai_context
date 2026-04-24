#!/bin/bash
# resume-features.sh — Affiche un tableau de reprise des features en cours.
#
# Scanne l'index .feature-index.json et regroupe par bucket :
#   EN COURS     : status active/draft avec progress.phase ∈ {spec, implement, test, review}
#   BLOQUÉES     : progress.blockers non vide (peu importe status actif)
#   STALE        : progress.updated > 14 jours (et status active)
#   À FAIRE      : status active/draft sans progress.phase défini
#
# Usage :
#   resume-features.sh                 # texte lisible
#   resume-features.sh --format=json   # JSON pour automation
#   resume-features.sh --scope=back    # filtre par scope
#
# Debug : AI_CONTEXT_DEBUG=1 bash resume-features.sh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

repo_root="$(cd "$script_dir/../.." && pwd)"
index_file="$repo_root/.ai/.feature-index.json"

format="text"
scope_filter=""
for arg in "$@"; do
  case "$arg" in
    --format=json) format="json" ;;
    --format=text) format="text" ;;
    --scope=*) scope_filter="${arg#--scope=}" ;;
    -h|--help)
      echo "Usage: $0 [--format=text|--format=json] [--scope=<scope>]"
      exit 0
      ;;
  esac
done

# Rebuild index si absent
if [[ ! -f "$index_file" ]]; then
  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
fi

if [[ ! -f "$index_file" ]]; then
  echo "Aucun index — lance build-feature-index.sh --write" >&2
  exit 1
fi

# Filtre par scope si demandé
filter_arg="."
if [[ -n "$scope_filter" ]]; then
  filter_arg=".features |= map(select(.scope == \"$scope_filter\"))"
fi

# Calcul staleness : updated plus vieux que 14 jours
today_epoch=$(date +%s)
stale_cutoff=$((today_epoch - 14 * 86400))

buckets=$(jq -r --argjson cutoff "$stale_cutoff" "$filter_arg"' |
  .features
  | map(select(.status == "active" or .status == "draft"))
  | map(. + {
      _updated_epoch: (
        if (.progress.updated // "") == "" then 0
        else (.progress.updated + "T00:00:00Z" | try (fromdateiso8601) // 0)
        end
      )
    })
  | {
      en_cours: [.[] | select((.progress.blockers // [] | length) == 0 and (.progress.phase // "") != "" and (.progress.phase != "done"))],
      bloquees: [.[] | select((.progress.blockers // [] | length) > 0)],
      stale: [.[] | select((.progress.blockers // [] | length) == 0 and ._updated_epoch > 0 and ._updated_epoch < $cutoff and (.progress.phase // "") != "done")],
      a_faire: [.[] | select((.progress.phase // "") == "" and (.progress.blockers // [] | length) == 0)]
    }
' "$index_file")

if [[ "$format" == "json" ]]; then
  echo "$buckets"
  exit 0
fi

print_bucket() {
  local label="$1" key="$2" emoji="$3"
  local rows
  rows=$(echo "$buckets" | jq -r --arg k "$key" '
    .[$k] | if length == 0 then empty else
      map(
        "  " + .scope + "/" + .id
        + (if .progress.phase != "" then "  phase=" + .progress.phase else "" end)
        + (if .progress.step != "" then " step=\"" + .progress.step + "\"" else "" end)
        + (if (.progress.blockers // [] | length) > 0 then "  blockers=" + (.progress.blockers | join(", ")) else "" end)
        + (if .progress.updated != "" then "  updated=" + .progress.updated else "" end)
        + (if .progress.resume_hint != "" then "\n      ↳ " + .progress.resume_hint else "" end)
      )
      | .[]
    end
  ')
  if [[ -n "$rows" ]]; then
    echo "$emoji $label"
    echo "$rows"
    echo
  fi
}

echo "═══ resume-features ═══"
[[ -n "$scope_filter" ]] && echo "  scope filter : $scope_filter"
echo

print_bucket "EN COURS"  "en_cours" "▶"
print_bucket "BLOQUÉES"  "bloquees" "⛔"
print_bucket "STALE (>14j sans update)" "stale" "⏳"
print_bucket "À FAIRE (progress non initialisé)" "a_faire" "◦"

total=$(echo "$buckets" | jq '[.en_cours, .bloquees, .stale, .a_faire] | map(length) | add')
if [[ "$total" == "0" ]]; then
  echo "  (rien à reprendre — tout est done ou aucune feature active)"
fi
