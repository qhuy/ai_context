#!/bin/bash
# test-product-reports-read-only.sh — rapports product non mutants.
#
# Vérifie que les commandes product peuvent fonctionner sans cache
# .ai/.feature-index.json et sans le créer implicitement.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-product-read-only.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/product" "$tmp/.docs/features/core" "$tmp/src"
for script in _lib.sh build-feature-index.sh check-product-links.sh product-status.sh product-portfolio.sh product-review.sh; do
  cp "$repo_root/.ai/scripts/$script" "$tmp/.ai/scripts/$script"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "product-read-only-test"
YAML
printf 'export const activation = true;\n' > "$tmp/src/activation.ts"

cat > "$tmp/.docs/features/product/activation.md" <<'MD'
---
id: activation
scope: product
title: Activation
status: active
depends_on: []
touches:
  - .ai/scripts/product-status.sh
  - .ai/scripts/product-portfolio.sh
  - .ai/scripts/product-review.sh
  - .ai/scripts/check-product-links.sh
product:
  type: initiative
  bet: "Tester la boucle product."
  target_user: "maintainers"
  success_metric: "rapport product lisible"
  leading_indicator: "test read-only"
  decision_state: explore
  next_decision_date: 2026-05-20
  portfolio:
    appetite: small
    confidence: high
    expected_impact: medium
    urgency: medium
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

cat > "$tmp/.docs/features/core/activation-slice.md" <<'MD'
---
id: activation-slice
scope: core
title: Activation Slice
status: active
depends_on: []
touches:
  - src/**
product:
  initiative: product/activation
  contribution: "slice de validation"
  evidence: "test"
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-05-14"
---

# Activation Slice
MD

(
  cd "$tmp"
  rm -f .ai/.feature-index.json

  bash .ai/scripts/check-product-links.sh --strict >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "check-product-links a créé l'index"

  bash .ai/scripts/product-status.sh >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "product-status a créé l'index"

  bash .ai/scripts/product-portfolio.sh >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "product-portfolio a créé l'index"

  bash .ai/scripts/product-review.sh product/activation >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "product-review a créé l'index"
)

echo "✅ test-product-reports-read-only PASS"
