#!/bin/bash
# product-status.sh — Vue de traceability des initiatives product et des features liées.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

index_file=".ai/.feature-index.json"
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true

if [[ ! -f "$index_file" ]]; then
  echo "index feature introuvable: $index_file" >&2
  exit 1
fi

echo "## Product Status"
echo
echo "| Initiative | Status | Decision | Metric | Dev linked | Risk |"
echo "|---|---|---|---|---:|---|"

jq -r '
  [.features[] | select(.scope == "product")] as $initiatives
  | .features as $features
  | if ($initiatives | length) == 0 then
      empty
    else
      $initiatives[]
      | (.scope + "/" + .id) as $key
      | [ $features[] | select((.product.initiative // "") == $key) ] as $linked
      | ($linked | map(select(.status == "done")) | length) as $done
      | ($linked | map(select(.status == "active")) | length) as $active
      | (
          if ((.product.success_metric // "") == "") then "metric missing"
          elif ((.product.decision_state // "") != "explore" and ($linked | length) == 0 and .status == "active") then "no dev linked"
          elif ((.progress.blockers // []) | length) > 0 then "blocked"
          else "OK" end
        ) as $risk
      | "| `" + $key + "` | " + (.status // "") + " | " + (.product.decision_state // "n/a") + " | " + (.product.success_metric // "missing") + " | " + (($active|tostring) + " active / " + ($done|tostring) + " done") + " | " + $risk + " |"
    end
' "$index_file"

if [[ "$(jq '[.features[] | select(.scope == "product")] | length' "$index_file")" -eq 0 ]]; then
  echo "| _(aucune)_ | - | - | - | 0 | créer une initiative product |"
fi

echo
echo "## Décalages"
delta=$(bash "$script_dir/check-product-links.sh" 2>/dev/null | awk '/Décalages produit :/{flag=1; next} flag && /^✅/{flag=0} flag {print}' | sed 's/^    /- /' || true)
if [[ -n "$delta" ]]; then
  printf '%s\n' "$delta"
else
  echo "- Aucun décalage produit détecté."
fi

echo
echo "## Recommandation"
jq -r '
  [.features[] | select(.scope == "product")] as $initiatives
  | if ($initiatives | length) == 0 then
      "- Créer une première initiative `product/*` avant de lancer une grosse feature dev."
    else
      ($initiatives | map(select(.status == "active")) | first) as $focus
      | if $focus == null then
          "- Choisir une initiative product à passer en `active` ou garder le portefeuille en discovery."
        else
          "- Garder le focus sur `" + ($focus.scope + "/" + $focus.id) + "` jusqu’à la prochaine décision."
        end
    end
' "$index_file"

echo
echo "## Prochaine action minimale"
echo "- Lancer \`bash .ai/scripts/aic.sh product-portfolio\` pour comparer les initiatives."
