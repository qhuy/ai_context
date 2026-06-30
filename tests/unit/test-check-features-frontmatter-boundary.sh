#!/bin/bash
# test-check-features-frontmatter-boundary.sh — core/feature-mesh.
#
# check-features doit valider depends_on/touches depuis le frontmatter uniquement,
# jamais depuis le corps markdown. Le builder d'index était déjà protégé ; ce test
# verrouille le même invariant côté checker strict.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-check-features-fm.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test" "$tmp/src"
for s in check-features.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "check-features-fm-test"\n' > "$tmp/.ai/config.yml"
printf 'real\n' > "$tmp/src/real.ts"
printf 'flow a\n' > "$tmp/src/a.ts"
printf 'flow b\n' > "$tmp/src/b.ts"

cat > "$tmp/.docs/features/test/boundary.md" <<'MD'
---
id: boundary
scope: test
title: Boundary
status: active
type: feature
depends_on: []
touches:
  - src/real.ts
---
# Boundary

Le corps documente des exemples qui ne doivent jamais être validés :
depends_on:
  - leaked/missing
touches:
  - leaked/missing.ts
MD

cat > "$tmp/.docs/features/test/flow.md" <<'MD'
---
id: flow
scope: test
title: Flow
status: active
type: feature
depends_on: []
touches: ["src/[ab].ts"] # glob char-class inline : DOIT être quoté (sinon YAML invalide → fiche droppée de l'index) ; le ] interne reste préservé par fm_list
---
# Flow
MD

(
  cd "$tmp"
  out="$(bash .ai/scripts/check-features.sh --no-write 2>&1)" || {
    echo "$out"
    fail "check-features ne doit pas lire depends_on/touches du corps markdown"
  }
  echo "$out" | grep -q "leaked/missing" \
    && fail "check-features a validé ou signalé une valeur du corps markdown" || true
)

echo "✅ test-check-features-frontmatter-boundary PASS"
