#!/bin/bash
# test-resume-features-index-freshness.sh — workflow/resume-index-freshness.
#
# Régression : un cache présent mais antérieur à une fiche ne doit pas faire
# afficher à `resume-features` une phase qui n'existe plus dans la source.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-resume-freshness.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/workflow"
for script in resume-features.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$script" "$tmp/.ai/scripts/$script"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "resume-freshness-test"\n' > "$tmp/.ai/config.yml"

cat > "$tmp/.docs/features/workflow/sample.md" <<'MD'
---
id: sample
scope: workflow
title: Reprise de démonstration
status: active
type: feature
depends_on: []
touches:
  - src/**
progress:
  phase: implement
  step: "ancienne étape"
  blockers: []
  resume_hint: "ancienne reprise"
  updated: 2026-08-19
---

# Reprise de démonstration
MD

(
  cd "$tmp"
  bash .ai/scripts/build-feature-index.sh --write >/dev/null
  touch -t 202608200100.00 .ai/.feature-index.json

  # La source évolue après le cache, comme après une édition manuelle de fiche
  # sans post-checkout ni appel préalable à features-for-path.
  cat > .docs/features/workflow/sample.md <<'MD'
---
id: sample
scope: workflow
title: Reprise de démonstration
status: active
type: feature
depends_on: []
touches:
  - src/**
progress:
  phase: review
  step: "étape actuelle"
  blockers: []
  resume_hint: "reprendre la revue"
  updated: 2026-08-20
---

# Reprise de démonstration
MD
  touch -t 202608200101.00 .docs/features/workflow/sample.md

  output="$(bash .ai/scripts/resume-features.sh --format=json)" \
    || fail "resume-features échoue avec un index reconstruisible"
  printf '%s' "$output" | jq -e '
    .en_cours
    | length == 1
      and .[0].id == "sample"
      and .[0].progress.phase == "review"
      and .[0].progress.step == "étape actuelle"
      and .[0].progress.resume_hint == "reprendre la revue"
  ' >/dev/null || fail "resume-features a lu la phase périmée du cache"

  jq -e '
    .features[] | select(.id == "sample")
    | .progress.phase == "review" and .progress.updated == "2026-08-20"
  ' .ai/.feature-index.json >/dev/null \
    || fail "le cache stale n'a pas été reconstruit depuis la fiche"
)

echo "✅ test-resume-features-index-freshness PASS"
