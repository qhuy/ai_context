#!/bin/bash
# Non-regression: touches_shared is visible in review reports but not blocking freshness.

set -euo pipefail

cd "$(dirname "$0")/../.."

tmp="$(mktemp -d /tmp/aic-review-delta-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

rsync -a \
  --exclude='.git' \
  --exclude='.ai/.feature-index.json' \
  --exclude='.ai/.progress-history.jsonl' \
  --exclude='.ai/.session-edits.log' \
  --exclude='.ai/.session-edits.flushed' \
  --exclude='.ai/.context-relevance.jsonl' \
  --exclude='.ai/.context-relevance.jsonl.old' \
  ./ "$tmp/repo/"
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

# Commit l'arbre complet comme référence : sinon tout le tree copié reste
# untracked et review-delta --staged (qui scanne git status --untracked-files=all
# et forke jq par fichier) explose en O(fichiers). Le delta réellement testé est
# le restage de shared.txt sur une base committée — proche de l'usage réel.
git add -A >/dev/null
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
