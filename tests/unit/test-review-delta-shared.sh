#!/bin/bash
# Non-regression: touches_shared is visible in review reports but not blocking freshness.

set -euo pipefail

cd "$(dirname "$0")/../.."

tmp="$(mktemp -d /tmp/aic-review-delta-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

cp -R . "$tmp/repo"
cd "$tmp/repo"

git init -q
git config user.email "test@example.com"
git config user.name "test"
git config core.hooksPath /dev/null

mkdir -p .docs/features/review
printf 'seed\n' > shared.txt

cat > .docs/features/review/shared.md <<'FEAT'
---
id: shared
scope: review
title: Shared surface
status: active
depends_on: []
touches: []
touches_shared:
  - shared.txt
progress:
  phase: implement
  step: test
  blockers: []
  resume_hint: test
  updated: 2026-05-03
---
# Shared
FEAT

git add shared.txt .docs/features/review/shared.md >/dev/null
git commit -q -m "chore: seed shared fixture"

printf 'changed\n' > shared.txt
git add shared.txt >/dev/null

if ! bash .ai/scripts/check-feature-freshness.sh --staged --strict >/dev/null; then
  echo "✗ touches_shared should not block staged freshness"
  exit 1
fi

out="$(bash .ai/scripts/review-delta.sh --staged)"

if ! echo "$out" | grep -q "Features liées (shared)"; then
  echo "✗ review delta should expose shared feature section"
  echo "$out"
  exit 1
fi

if ! echo "$out" | grep -q "review/shared"; then
  echo "✗ review delta should list feature linked via touches_shared"
  echo "$out"
  exit 1
fi

if ! echo "$out" | grep -q "couvert seulement via touches_shared"; then
  echo "✗ review delta should flag shared-only coverage as an informational risk"
  echo "$out"
  exit 1
fi

echo "✅ test-review-delta-shared PASS"
