#!/bin/bash
# check-product-links.sh — Valide les liens Product Portfolio Loop.
#
# Usage :
#   bash .ai/scripts/check-product-links.sh          # warn, exit 0
#   bash .ai/scripts/check-product-links.sh --strict # warnings => exit 1

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

mode="${1:---warn}"
if [[ "$mode" != "--warn" && "$mode" != "--strict" ]]; then
  echo "Usage: bash .ai/scripts/check-product-links.sh [--strict]" >&2
  exit 2
fi

index_file=".ai/.feature-index.json"
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
if [[ ! -f "$index_file" ]]; then
  echo "  ⚠️  pas d'index feature, rien à vérifier" >&2
  exit 0
fi

warns=()
add_warn() { warns+=("$1"); }

product_count=$(jq '[.features[] | select(.scope == "product")] | length' "$index_file")
active_product_count=$(jq '[.features[] | select(.scope == "product" and (.status == "active" or .status == "draft"))] | length' "$index_file")

if [[ "$active_product_count" -gt 3 ]]; then
  add_warn "plus de 3 initiatives product draft/active ($active_product_count) : risque de focus dilué"
fi

while IFS=$'\t' read -r key status type bet metric decision next_date linked_count; do
  [[ -n "$key" ]] || continue
  if [[ "$type" != "initiative" ]]; then
    add_warn "$key : scope product sans product.type=initiative"
  fi
  if [[ "$status" == "active" ]]; then
    [[ -n "$bet" ]] || add_warn "$key : active sans product.bet"
    [[ -n "$metric" ]] || add_warn "$key : active sans product.success_metric"
    [[ -n "$decision" ]] || add_warn "$key : active sans product.decision_state"
    [[ -n "$next_date" ]] || add_warn "$key : active sans product.next_decision_date"
    if [[ "$decision" != "explore" && "$linked_count" -eq 0 ]]; then
      add_warn "$key : active/$decision sans feature dev liée via product.initiative"
    fi
  fi
done < <(jq -r '
  [.features[] | select(.scope == "product")] as $initiatives
  | .features as $features
  | $initiatives[]
  | (.scope + "/" + .id) as $key
  | [
      $key,
      (.status // ""),
      (.product.type // ""),
      (.product.bet // ""),
      (.product.success_metric // ""),
      (.product.decision_state // ""),
      (.product.next_decision_date // ""),
      ([ $features[] | select((.product.initiative // "") == $key) ] | length | tostring)
    ] | @tsv
' "$index_file")

while IFS=$'\t' read -r key field value; do
  [[ -n "$key" && -n "$value" ]] || continue
  case "$field" in
    decision_state)
      case "$value" in explore|commit|cut|pivot|scale) ;; *) add_warn "$key : product.decision_state='$value' hors enum" ;; esac
      ;;
    appetite)
      case "$value" in small|medium|large) ;; *) add_warn "$key : product.portfolio.appetite='$value' hors enum" ;; esac
      ;;
    confidence|expected_impact|urgency|strategic_fit)
      case "$value" in low|medium|high) ;; *) add_warn "$key : product.portfolio.$field='$value' hors enum" ;; esac
      ;;
  esac
done < <(jq -r '
  .features[]
  | (.scope + "/" + .id) as $key
  | [
      ["decision_state", (.product.decision_state // "")],
      ["appetite", (.product.portfolio.appetite // "")],
      ["confidence", (.product.portfolio.confidence // "")],
      ["expected_impact", (.product.portfolio.expected_impact // "")],
      ["urgency", (.product.portfolio.urgency // "")],
      ["strategic_fit", (.product.portfolio.strategic_fit // "")]
    ][]
  | select(.[1] != "")
  | [$key, .[0], .[1]] | @tsv
' "$index_file")

while IFS=$'\t' read -r feature_key initiative initiative_status; do
  [[ -n "$feature_key" && -n "$initiative" ]] || continue
  if [[ "$initiative_status" == "__missing__" ]]; then
    add_warn "$feature_key : product.initiative '$initiative' introuvable"
  elif [[ "$initiative_status" == "done" || "$initiative_status" == "deprecated" || "$initiative_status" == "archived" ]]; then
    add_warn "$feature_key : lié à une initiative '$initiative' status=$initiative_status"
  fi
done < <(jq -r '
  .features as $features
  | $features[]
  | select(.scope != "product" and ((.product.initiative // "") != ""))
  | (.product.initiative // "") as $initiative
  | ([ $features[] | select((.scope + "/" + .id) == $initiative and .scope == "product") ][0].status // "__missing__") as $status
  | [(.scope + "/" + .id), $initiative, $status] | @tsv
' "$index_file")

echo "═══ check-product-links ═══"
echo "  initiatives product : $product_count"

if [[ ${#warns[@]} -eq 0 ]]; then
  echo "  ✓ liens produit OK"
  echo
  echo "✅ OK"
  exit 0
fi

echo
echo "  Décalages produit :"
printf '%s\n' "${warns[@]}" | sort -u | while IFS= read -r w; do
  echo "    - $w"
done

if [[ "$mode" == "--strict" ]]; then
  echo
  echo "❌ FAIL (--strict)"
  exit 1
fi

echo
echo "✅ OK (--warn)"
exit 0
