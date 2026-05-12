#!/bin/bash
# Non-regression: dogfood drift must detect runtime files present only in the source repo.

set -euo pipefail

cd "$(dirname "$0")/../.."

if ! command -v copier >/dev/null 2>&1; then
  echo "⚠ copier introuvable, test ignoré"
  exit 0
fi

tmp="$(mktemp -d /tmp/aic-dogfood-drift-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

cp -R . "$tmp/repo"
cd "$tmp/repo"

mkdir -p .ai/scripts
printf '# stale runtime\n' > .ai/scripts/stale-runtime.sh

out="$(bash .ai/scripts/check-dogfood-drift.sh 2>&1 || true)"

if ! echo "$out" | grep -q "extra-runtime: .ai/scripts/stale-runtime.sh"; then
  echo "✗ check-dogfood-drift should detect destination-only runtime files"
  echo "$out"
  exit 1
fi

rm .ai/scripts/stale-runtime.sh

cp .docs/frames/0000-template.md "$tmp/frame-template.bak"
printf '\n# local drift\n' >> .docs/frames/0000-template.md
out="$(bash .ai/scripts/check-dogfood-drift.sh 2>&1 || true)"

if ! echo "$out" | grep -q "drift: .docs/frames/0000-template.md"; then
  echo "✗ check-dogfood-drift should detect frame template drift"
  echo "$out"
  exit 1
fi

cp "$tmp/frame-template.bak" .docs/frames/0000-template.md

if ! bash .ai/scripts/check-dogfood-drift.sh >/dev/null; then
  echo "✗ check-dogfood-drift should pass after removing the extra runtime file"
  exit 1
fi

echo "✅ test-dogfood-drift-extra PASS"
