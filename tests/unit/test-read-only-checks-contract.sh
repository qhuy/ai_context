#!/bin/bash
# test-read-only-checks-contract.sh — diagnostics quality non mutants.
#
# Vérifie qu'un repo sans .ai/.feature-index.json peut lancer les checks
# read-only ciblés sans créer le cache dans le repo.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-read-only-checks.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/core" "$tmp/src"
for script in _lib.sh aic.sh build-feature-index.sh check-features.sh check-feature-freshness.sh check-feature-coverage.sh check-shims.sh check-product-links.sh review-delta.sh pr-report.sh doctor.sh measure-context-size.sh stop-doc-gate.sh; do
  cp "$repo_root/.ai/scripts/$script" "$tmp/.ai/scripts/$script"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "read-only-checks-test"
YAML
printf '# index\n' > "$tmp/.ai/index.md"
printf '# reminder\n' > "$tmp/.ai/reminder.md"
printf 'seed\n' > "$tmp/src/app.txt"
printf 'export const x = 1;\n' > "$tmp/src/app.ts"

cat > "$tmp/.docs/features/core/sample.md" <<'MD'
---
id: sample
scope: core
title: Sample
status: active
depends_on: []
touches:
  - src/**
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-05-14"
---

# Sample
MD

cat > "$tmp/.docs/features/core/sample.worklog.md" <<'MD'
# Worklog — core/sample

## 2026-05-14 — création
- seed
MD

(
  cd "$tmp"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  git add .
  git commit -qm "chore: seed"
  rm -f .ai/.feature-index.json

  bash .ai/scripts/check-features.sh --no-write >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "check-features --no-write a créé l'index"

  bash .ai/scripts/check-feature-freshness.sh --warn >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "check-feature-freshness --warn a créé l'index"

  bash .ai/scripts/check-feature-coverage.sh >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "check-feature-coverage a créé l'index"

  printf 'change\n' >> src/app.txt
  git add src/app.txt
  set +e
  bash .ai/scripts/check-feature-freshness.sh --staged --strict >/dev/null 2>&1
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || fail "check-feature-freshness --staged --strict aurait dû échouer sans doc staged"
  [[ ! -e .ai/.feature-index.json ]] || fail "check-feature-freshness --staged a créé l'index"

  bash .ai/scripts/check-feature-freshness.sh --worktree --warn >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "check-feature-freshness --worktree a créé l'index"

  printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-doc-gate.sh >/dev/null 2>&1 || true
  [[ ! -e .ai/.feature-index.json ]] || fail "stop-doc-gate a créé l'index"

  bash .ai/scripts/review-delta.sh >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "review-delta a créé l'index"

  bash .ai/scripts/pr-report.sh >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "pr-report a créé l'index"

  bash .ai/scripts/doctor.sh >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "doctor a créé l'index"

  bash .ai/scripts/aic.sh frame "quality checks" >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "aic.sh frame a créé l'index"

  bash .ai/scripts/aic.sh diagnose "quality checks" >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "aic.sh diagnose a créé l'index"

  bash .ai/scripts/aic.sh status >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "aic.sh status a créé l'index"

  bash .ai/scripts/aic.sh ship >/dev/null
  [[ ! -e .ai/.feature-index.json ]] || fail "aic.sh ship a créé l'index"
)

echo "✅ test-read-only-checks-contract PASS"
