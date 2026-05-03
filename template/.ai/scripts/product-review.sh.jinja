#!/bin/bash
# product-review.sh — Review décisionnelle d'une initiative product/<id>.
#
# Usage : bash .ai/scripts/product-review.sh product/<id>

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

target="${1:-}"
if [[ -z "$target" || "$target" != product/* ]]; then
  echo "Usage: bash .ai/scripts/product-review.sh product/<id>" >&2
  exit 2
fi

index_file=".ai/.feature-index.json"
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true

if ! jq -e --arg target "$target" '.features[] | select((.scope + "/" + .id) == $target and .scope == "product")' "$index_file" >/dev/null; then
  echo "initiative introuvable: $target" >&2
  exit 1
fi

jq -r --arg target "$target" '
  .features as $features
  | ($features[] | select((.scope + "/" + .id) == $target and .scope == "product")) as $i
  | [ $features[] | select((.product.initiative // "") == $target) ] as $linked
  | ($linked | map(select(.status == "done")) | length) as $done
  | ($linked | map(select(.status == "active")) | length) as $active
  | (
      if ($i.status == "done") then "archive/learn"
      elif (($i.product.success_metric // "") == "") then "explore"
      elif (($i.product.decision_state // "") == "cut") then "cut"
      elif (($i.product.decision_state // "") == "pivot") then "pivot"
      elif ($done > 0) then "continue"
      elif ($active > 0) then "continue"
      else "shrink or link dev slice" end
    ) as $decision
  | "## Product Review\n"
    + "\nInitiative :\n- `" + $target + "`\n"
    + "\nDécision recommandée :\n- " + $decision + "\n"
    + "\nPourquoi :\n"
    + "- Status : " + ($i.status // "n/a") + "\n"
    + "- Decision state : " + ($i.product.decision_state // "n/a") + "\n"
    + "- Metric : " + ($i.product.success_metric // "missing") + "\n"
    + "- Dev linked : " + ($active|tostring) + " active / " + ($done|tostring) + " done\n"
    + "\nEvidence :\n"
    + (if ($linked | length) == 0 then "- _(aucune feature dev liée)_\n" else ($linked | map("- `" + (.scope + "/" + .id) + "` — " + (.status // "n/a") + " — " + (.product.evidence // .product.contribution // "no evidence")) | join("\n")) + "\n" end)
    + "\nRisques :\n"
    + (if (($i.product.success_metric // "") == "") then "- métrique de succès manquante\n" else "" end)
    + (if (($i.product.next_decision_date // "") == "") then "- prochaine date de décision manquante\n" else "" end)
    + (if ($linked | length) == 0 and (($i.product.decision_state // "") != "explore") then "- initiative non exécutable : aucune feature dev liée\n" else "" end)
    + (if (($i.product.success_metric // "") != "" and ($i.product.next_decision_date // "") != "" and (($linked | length) > 0 or (($i.product.decision_state // "") == "explore"))) then "- aucun risque majeur détecté\n" else "" end)
    + "\nProchaine action minimale :\n"
    + (if (($i.product.success_metric // "") == "") then "- Définir `product.success_metric`.\n"
       elif (($i.product.next_decision_date // "") == "") then "- Définir `product.next_decision_date`.\n"
       elif ($linked | length) == 0 then "- Créer ou relier une feature dev via `product.initiative: " + $target + "`.\n"
       else "- Relire la prochaine slice dev liée et décider `continue / cut / pivot / scale`.\n" end)
' "$index_file"
