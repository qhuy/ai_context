#!/bin/bash
# context-relevance-report.sh — Rapport de pertinence du contexte injecté.
#
# Lit .ai/.context-relevance.jsonl, agrège les N derniers summary par
# feature et produit un rapport markdown (ou JSON via --format json).
#
# Usage :
#   bash .ai/scripts/context-relevance-report.sh [--last N] [--feature scope/id] [--format markdown|json]
#
# Defaults :
#   --last 50
#   --format markdown
#
# Sortie markdown :
#   - Tableau par feature : injected_count, touched_count, intersection,
#     precision_approx, recall_approx
#   - Top features `injected_not_touched` (candidats à ranker plus bas)
#   - Top features `touched_not_injected` (candidats à matcher mieux)

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
log_file="$repo_root/.ai/.context-relevance.jsonl"

last_n=50
feature_filter=""
format="markdown"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --last) last_n="$2"; shift 2 ;;
    --last=*) last_n="${1#--last=}"; shift ;;
    --feature) feature_filter="$2"; shift 2 ;;
    --feature=*) feature_filter="${1#--feature=}"; shift ;;
    --format) format="$2"; shift 2 ;;
    --format=*) format="${1#--format=}"; shift ;;
    -h|--help)
      cat <<'USAGE'
Usage: bash .ai/scripts/context-relevance-report.sh [options]

Options :
  --last N           Agrège les N derniers summary (défaut 50).
  --feature scope/id Filtre sur une feature spécifique.
  --format FMT       markdown (défaut) ou json.
  -h, --help         Affiche cette aide.

Lit .ai/.context-relevance.jsonl. Best-effort : exit 0 même si fichier
absent ou vide.
USAGE
      exit 0
      ;;
    *) echo "Argument inconnu : $1" >&2; exit 2 ;;
  esac
done

[[ "$last_n" =~ ^[0-9]+$ ]] || { echo "--last doit être un entier" >&2; exit 2; }
[[ "$format" == "markdown" || "$format" == "json" ]] || { echo "--format doit être markdown ou json" >&2; exit 2; }

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq requis" >&2
  exit 1
fi

if [[ ! -f "$log_file" ]]; then
  if [[ "$format" == "json" ]]; then
    printf '{"summaries_count":0,"features":[],"note":"log file absent"}\n'
  else
    echo "## Context Relevance Report"
    echo
    echo "_Aucun log .ai/.context-relevance.jsonl. Le tracker n'a pas encore enregistré d'événement._"
  fi
  exit 0
fi

# Récupère les N derniers summary (filtrés feature si demandé) et agrège.
agg=$(jq -cs --arg last_n "$last_n" --arg feature "$feature_filter" '
  [.[] | select(.event == "summary")]
  | (if (length > ($last_n | tonumber)) then .[(length - ($last_n | tonumber)):] else . end) as $window
  | $window
  | reduce .[] as $s ({features: {}, summaries_count: 0};
      .summaries_count += 1
      | reduce ($s.injected_features // [])[] as $f (.;
          .features[$f] = (.features[$f] // {injected:0, touched:0, intersection:0})
          | .features[$f].injected += 1
        )
      | reduce ($s.touched_features // [])[] as $f (.;
          .features[$f] = (.features[$f] // {injected:0, touched:0, intersection:0})
          | .features[$f].touched += 1
        )
      | reduce ($s.intersection // [])[] as $f (.;
          .features[$f] = (.features[$f] // {injected:0, touched:0, intersection:0})
          | .features[$f].intersection += 1
        )
    )
  | .features = (.features | to_entries
      | (if ($feature != "") then map(select(.key == $feature)) else . end)
      | map({
          feature: .key,
          injected: .value.injected,
          touched: .value.touched,
          intersection: .value.intersection,
          precision: (if .value.injected > 0 then (.value.intersection / .value.injected) else 0 end),
          recall: (if .value.touched > 0 then (.value.intersection / .value.touched) else 0 end)
        })
      | sort_by(-.injected))
' "$log_file" 2>/dev/null) || agg='{"summaries_count":0,"features":[]}'

if [[ "$format" == "json" ]]; then
  printf '%s\n' "$agg"
  exit 0
fi

# Format markdown
summaries_count=$(printf '%s' "$agg" | jq -r '.summaries_count')

echo "## Context Relevance Report"
echo
echo "- Summaries analysés : $summaries_count (last $last_n max)"
[[ -n "$feature_filter" ]] && echo "- Filtre feature : \`$feature_filter\`"
echo

if [[ "$summaries_count" -eq 0 ]]; then
  echo "_Aucun summary à analyser._"
  exit 0
fi

# Tableau par feature
echo "### Par feature"
echo
echo "| Feature | Injected | Touched | Intersection | Precision | Recall |"
echo "|---|---:|---:|---:|---:|---:|"
printf '%s' "$agg" | jq -r '.features[] | [.feature, .injected, .touched, .intersection, (.precision | . * 100 | round / 100), (.recall | . * 100 | round / 100)] | "| \(.[0]) | \(.[1]) | \(.[2]) | \(.[3]) | \(.[4]) | \(.[5]) |"'
echo

# Top injected_not_touched (low precision = trop injectée)
echo "### Top candidats à ranker plus bas (injected, jamais touched)"
echo
low_p=$(printf '%s' "$agg" | jq -r '.features[] | select(.injected > 0 and .intersection == 0) | "- \(.feature) (\(.injected) injections, 0 touched)"' | head -10)
if [[ -z "$low_p" ]]; then
  echo "_Aucun._"
else
  printf '%s\n' "$low_p"
fi
echo

# Top touched_not_injected (recall raté = candidats à matcher mieux)
echo "### Top candidats à matcher mieux (touched, jamais injected)"
echo
low_r=$(printf '%s' "$agg" | jq -r '.features[] | select(.touched > 0 and .intersection == 0) | "- \(.feature) (\(.touched) touches, 0 injected)"' | head -10)
if [[ -z "$low_r" ]]; then
  echo "_Aucun._"
else
  printf '%s\n' "$low_r"
fi
