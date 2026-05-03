#!/bin/bash
# Non-regression: a staged file matching multiple features must stage doc for each feature.

set -euo pipefail

cd "$(dirname "$0")/../.."

tmp="$(mktemp -d /tmp/aic-freshness-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

cp -R . "$tmp/repo"
cd "$tmp/repo"

git init -q
git config user.email "test@example.com"
git config user.name "test"
git config core.hooksPath /dev/null

mkdir -p .docs/features/review
printf 'seed\n' > shared.txt

cat > .docs/features/review/a.md <<'FEAT'
---
id: a
scope: review
title: A
status: active
depends_on: []
touches:
  - shared.txt
progress:
  phase: implement
  step: test
  blockers: []
  resume_hint: test
  updated: 2026-05-03
---
# A
FEAT

cat > .docs/features/review/b.md <<'FEAT'
---
id: b
scope: review
title: B
status: active
depends_on: []
touches:
  - shared.txt
progress:
  phase: implement
  step: test
  blockers: []
  resume_hint: test
  updated: 2026-05-03
---
# B
FEAT

git add shared.txt .docs/features/review/a.md .docs/features/review/b.md >/dev/null
git commit -q -m "chore: seed review fixture"

printf 'changed\n' > shared.txt
printf '\n- documented a only\n' >> .docs/features/review/a.md
git add shared.txt .docs/features/review/a.md >/dev/null

out="$(bash .ai/scripts/check-feature-freshness.sh --staged --strict 2>&1 || true)"

if ! echo "$out" | grep -q "review/b"; then
  echo "✗ freshness check should require docs for every matching feature"
  echo "$out"
  exit 1
fi

if echo "$out" | grep -q "review/a"; then
  echo "✗ freshness check should not report the feature whose doc is staged"
  echo "$out"
  exit 1
fi

printf '\n- documented b too\n' >> .docs/features/review/b.md
git add .docs/features/review/b.md >/dev/null

if ! bash .ai/scripts/check-feature-freshness.sh --staged --strict >/dev/null; then
  echo "✗ freshness check should pass once every matching feature has staged docs"
  exit 1
fi

echo "✅ test-check-feature-freshness PASS"
