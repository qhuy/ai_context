#!/bin/bash
# product-portfolio.sh — Comparaison read-only des initiatives product.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

index_file=".ai/.feature-index.json"
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true

echo "## Product Traceability"
echo
echo "| Initiative | State | Impact | Confidence | Appetite | Evidence | Score | Recommendation |"
echo "|---|---|---:|---:|---:|---:|---:|---|"

jq -r '
  def v($x): if $x == "high" then 3 elif $x == "medium" then 2 elif $x == "low" then 1 else 0 end;
  def cost($x): if $x == "large" then 3 elif $x == "medium" then 2 elif $x == "small" then 1 else 2 end;
  [.features[] | select(.scope == "product")] as $initiatives
  | .features as $features
  | if ($initiatives | length) == 0 then empty else
      $initiatives[]
      | (.scope + "/" + .id) as $key
      | [ $features[] | select((.product.initiative // "") == $key) ] as $linked
      | ($linked | map(select(.status == "done")) | length) as $done
      | (.product.portfolio.expected_impact // "medium") as $impact
      | (.product.portfolio.confidence // "medium") as $confidence
      | (.product.portfolio.urgency // "medium") as $urgency
      | (.product.portfolio.strategic_fit // "medium") as $fit
      | (.product.portfolio.appetite // "medium") as $appetite
      | ((v($impact) + v($confidence) + v($urgency) + v($fit) + (if $done > 0 then 1 else 0 end) - cost($appetite))) as $score
      | (if .status == "done" then "archive/learn"
         elif $score >= 7 then "keep focus"
         elif $score >= 5 then "explore/shrink"
         else "cut or wait" end) as $recommendation
      | "| `" + $key + "` | " + (.product.decision_state // .status // "") + " | " + $impact + " | " + $confidence + " | " + $appetite + " | " + (if $done > 0 then "partial" else "none" end) + " | " + ($score|tostring) + " | " + $recommendation + " |"
    end
' "$index_file"

if [[ "$(jq '[.features[] | select(.scope == "product")] | length' "$index_file")" -eq 0 ]]; then
  echo "| _(aucune)_ | - | - | - | - | - | 0 | create initiative |"
fi

echo
echo "## Focus Decision"
jq -r '
  def v($x): if $x == "high" then 3 elif $x == "medium" then 2 elif $x == "low" then 1 else 0 end;
  def cost($x): if $x == "large" then 3 elif $x == "medium" then 2 elif $x == "small" then 1 else 2 end;
  [.features[] | select(.scope == "product")] as $initiatives
  | if ($initiatives | length) == 0 then
      "- Créer une initiative produit avant arbitrage."
    else
      ($initiatives
        | map(. + {score: (
            v(.product.portfolio.expected_impact // "medium")
            + v(.product.portfolio.confidence // "medium")
            + v(.product.portfolio.urgency // "medium")
            + v(.product.portfolio.strategic_fit // "medium")
            - cost(.product.portfolio.appetite // "medium")
          )})
        | sort_by(.score) | reverse | first) as $top
      | "- Focus recommandé : `" + ($top.scope + "/" + $top.id) + "` (score " + ($top.score|tostring) + ")."
    end
' "$index_file"

echo
echo "## Prochaine action minimale"
echo "- Lancer \`bash .ai/scripts/ai-context.sh product-review product/<id>\` sur l'initiative recommandée."
