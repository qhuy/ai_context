#!/bin/bash
# test-build-feature-index-fallback.sh — fallback sans yq.
#
# Vérifie que le parser awk conserve les champs product.portfolio consommés
# par les rapports product quand yq n'est pas disponible.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-index-fallback.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/product"
cp "$repo_root/.ai/scripts/build-feature-index.sh" "$tmp/.ai/scripts/build-feature-index.sh"
cp "$repo_root/.ai/scripts/_lib.sh" "$tmp/.ai/scripts/_lib.sh"
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "index-fallback-test"
YAML

cat > "$tmp/.docs/features/product/activation.md" <<'MD'
---
id: activation
scope: product
title: Activation
status: active
depends_on: []
touches:
  - .ai/scripts/build-feature-index.sh
product:
  type: initiative
  bet: "Tester le fallback"
  target_user: "maintainers"
  success_metric: "portfolio préservé"
  leading_indicator: "test"
  decision_state: commit
  next_decision_date: "2026-05-20"
  portfolio:
    appetite: small
    confidence: high
    expected_impact: medium
    urgency: low
    strategic_fit: high
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-05-14"
---

# Activation
MD

(
  cd "$tmp"
  out="$(PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash .ai/scripts/build-feature-index.sh)"
  printf '%s\n' "$out" | jq -e '
    .features[]
    | select(.scope == "product" and .id == "activation")
    | .product.portfolio == {
        appetite: "small",
        confidence: "high",
        expected_impact: "medium",
        urgency: "low",
        strategic_fit: "high"
      }
  ' >/dev/null || fail "product.portfolio absent ou incorrect en fallback sans yq"

  printf '%s\n' "$out" | jq -e '
    .features[]
    | select(.scope == "product" and .id == "activation")
    | .product.decision_state == "commit"
      and .product.next_decision_date == "2026-05-20"
      and .product.success_metric == "portfolio préservé"
  ' >/dev/null || fail "champs product scalaires régressés en fallback sans yq"

  [[ ! -e .ai/.feature-index.json ]] || fail "fallback stdout a créé l'index"
)

echo "✅ test-build-feature-index-fallback PASS"
