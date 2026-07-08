#!/bin/bash
# test-freshness-unsupported-pattern-warning.sh — quality/doc-freshness.
#
# blocking_coverers() ne doit pas avaler le warning "pattern non supporté"
# émis par le matcher (2>/dev/null) : le gate --staged tourne inconditionnellement
# au hook commit-msg, c'est le seul point où l'agent/l'utilisateur peut le voir.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-freshness-warning.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/back" "$tmp/src"
for s in _lib.sh check-feature-freshness.sh build-feature-index.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "freshness-warning-test"\n' > "$tmp/.ai/config.yml"

cat > "$tmp/.docs/features/back/weird.md" <<'MD'
---
id: weird
scope: back
title: Weird touches
status: active
type: feature
depends_on: []
touches:
  - "src[/]x.ts"
---
# Weird
MD
printf 'seed\n' > "$tmp/src/x.ts"

(
  cd "$tmp"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  git config core.hooksPath /dev/null
  git add -A >/dev/null
  git commit -qm "chore: seed"

  printf 'change\n' > src/x.ts
  git add src/x.ts >/dev/null

  err="$(bash .ai/scripts/check-feature-freshness.sh --staged --strict 2>&1 1>/dev/null)"
  echo "$err" | grep -q "pattern non supporté" \
    || fail "le warning matcher aurait dû être visible sur stderr, pas avalé par blocking_coverers"
)

echo "✅ test-freshness-unsupported-pattern-warning PASS"
