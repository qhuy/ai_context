#!/bin/bash
# test-pre-commit-worklog-stage.sh — workflow/git-hooks.
#
# Cas nominal : une feature dont un fichier touches: est stagé dans CE commit
# bascule de phase ; son worklog (créé ou complété par auto-progress.sh) DOIT
# être re-stagé, sinon la bascule ne serait jamais committée automatiquement.
# Cas résiduel : une trace laissée par une session interrompue (feature dont
# AUCUN fichier n'est stagé dans ce commit) ne doit pas embarquer son worklog
# hors intention.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-pre-commit-stage.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.githooks" "$tmp/.docs/features/back" "$tmp/src"
for s in _lib.sh auto-progress.sh build-feature-index.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.githooks/pre-commit" "$tmp/.githooks/pre-commit"
chmod +x "$tmp/.githooks/pre-commit"
printf 'docs_root: ".docs"\nproject_id: "pre-commit-stage-test"\n' > "$tmp/.ai/config.yml"
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"

cat > "$tmp/.docs/features/back/specfeat.md" <<'MD'
---
id: specfeat
scope: back
title: Spec feature
status: active
type: feature
depends_on: []
touches:
  - src/app.ts
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: 2026-07-07
---
# Spec feature
MD

cat > "$tmp/.docs/features/back/otherfeat.md" <<'MD'
---
id: otherfeat
scope: back
title: Other feature
status: active
type: feature
depends_on: []
touches:
  - src/other.ts
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: 2026-07-07
---
# Other feature
MD
printf 'seed\n' > "$tmp/src/app.ts"
printf 'seed\n' > "$tmp/src/other.ts"

(
  cd "$tmp"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  git config core.hooksPath /dev/null
  git add -A >/dev/null
  git commit -qm "chore: seed"

  bash .ai/scripts/build-feature-index.sh --write >/dev/null

  # Cas nominal : src/app.ts est stagé dans ce commit -> specfeat bascule.
  printf 'change\n' > src/app.ts
  git add src/app.ts >/dev/null

  # Cas résiduel : trace laissée par une session interrompue pour otherfeat,
  # dont aucun fichier (src/other.ts) n'est stagé dans ce commit.
  jq -nc --arg feature "back/otherfeat" --arg file "src/other.ts" --arg ts "2026-07-01T00:00:00Z" \
    '{feature: $feature, file: $file, ts: $ts}' > .ai/.session-edits.flushed

  .githooks/pre-commit

  git diff --cached --name-only | grep -Fx 'src/app.ts' >/dev/null \
    || fail "src/app.ts doit rester staged"
  git diff --cached --name-only | grep -Fx '.docs/features/back/specfeat.md' >/dev/null \
    || fail "la fiche auto-progressée doit être re-stagée"
  git diff --cached --name-only | grep -Fx '.docs/features/back/specfeat.worklog.md' >/dev/null \
    || fail "le worklog d'une feature touchée par un fichier stagé dans ce commit doit être re-stagé"

  if git diff --cached --name-only | grep -Fx '.docs/features/back/otherfeat.worklog.md' >/dev/null; then
    fail "le worklog d'une trace résiduelle (feature non touchée par ce commit) ne doit pas être embarqué hors intention"
  fi
)

echo "✅ test-pre-commit-worklog-stage PASS"
