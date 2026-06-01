#!/bin/bash
# Non-regression : le fast-path matcher de pr-report (`path_matches_touch_fast`)
# ne doit PAS sur-matcher un touch en étoile simple (`dir/*`, enfants directs)
# contre un chemin imbriqué. Régression : `[[ "$touch" == */** ]]` non quoté
# traitait `dir/*` comme `dir/**` (récursif) → faux impacted_features.

set -euo pipefail

cd "$(dirname "$0")/../.."

tmp="$(mktemp -d /tmp/aic-pr-glob-XXXXXX)"
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

mkdir -p .docs/features/globtest src/deep
cat > .docs/features/globtest/star.md <<'FEAT'
---
id: star
scope: globtest
title: Single-star touch fixture
status: active
depends_on: []
touches:
  - src/*
progress:
  phase: implement
  step: test
  blockers: []
  resume_hint: test
  updated: 2026-06-01
---
# Star
FEAT

printf 'a\n' > src/a.txt
printf 'b\n' > src/deep/b.txt
git add -A >/dev/null
git commit -q -m "chore: seed glob fixture"

# (1) Delta = chemin IMBRIQUÉ src/deep/b.txt → `src/*` ne doit PAS matcher.
printf 'b2\n' > src/deep/b.txt
git add src/deep/b.txt >/dev/null
git commit -q -m "chore: nested change"
json="$(bash .ai/scripts/pr-report.sh --base=HEAD~1 --head=HEAD --format=json)"
if printf '%s' "$json" | jq -e '.impacted_features | index("globtest/star")' >/dev/null; then
  echo "✗ over-match : 'src/*' ne doit pas couvrir le chemin imbriqué src/deep/b.txt"
  printf '%s\n' "$json" | jq '.impacted_features'
  exit 1
fi

# (2) Delta = enfant DIRECT src/a.txt → `src/*` doit matcher (cas positif).
printf 'a2\n' > src/a.txt
git add src/a.txt >/dev/null
git commit -q -m "chore: direct change"
json="$(bash .ai/scripts/pr-report.sh --base=HEAD~1 --head=HEAD --format=json)"
if ! printf '%s' "$json" | jq -e '.impacted_features | index("globtest/star")' >/dev/null; then
  echo "✗ 'src/*' devrait couvrir l'enfant direct src/a.txt"
  printf '%s\n' "$json" | jq '.impacted_features'
  exit 1
fi

echo "✅ test-pr-report-glob-match PASS"
