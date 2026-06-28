#!/bin/bash
# test-check-touches-breadth.sh — garde-fou advisory sur-couverture touches:.
#
# Signal A : fichier exact dans touches: direct de > K features.
# Signal B : glob catch-all top-level en touches:. Toujours exit 0 (advisory).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-touches-breadth.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test"
for s in _lib.sh build-feature-index.sh check-touches-breadth.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "touches-breadth-test"\n' > "$tmp/.ai/config.yml"

# 4 features partageant shared.sh en touches: direct (+ 1 avec un glob large lib/**).
mkfiche() {
  local id="$1"; shift
  { printf -- '---\nid: %s\nscope: test\ntitle: %s\nstatus: active\ntype: feature\ndepends_on: []\ntouches:\n' "$id" "$id"
    for t in "$@"; do printf -- '  - %s\n' "$t"; done
    printf -- '---\n# %s\n' "$id"
  } > "$tmp/.docs/features/test/$id.md"
}
mkfiche a shared.sh own-a.sh
mkfiche b shared.sh own-b.sh
mkfiche c shared.sh own-c.sh
mkfiche d shared.sh own-d.sh
mkfiche e 'lib/**'

cd "$tmp"
out="$(AIC_TOUCHES_BREADTH_K=2 bash .ai/scripts/check-touches-breadth.sh 2>&1)"; rc=$?

[[ "$rc" -eq 0 ]] || fail "le garde-fou doit toujours exit 0 (advisory)"
echo "$out" | grep -q 'shared.sh' || fail "Signal A devrait flaguer shared.sh (partagé par 4 > K=2 features)"
echo "$out" | grep -q 'lib/\*\*' || fail "Signal B devrait flaguer le glob top-level lib/**"
echo "$out" | grep -q 'own-a.sh' && fail "un fichier propre à une seule feature ne doit PAS être flagué (own-a.sh)"

# Read-only : pas d'écriture de l'index dans le repo.
[[ ! -e .ai/.feature-index.json ]] || fail "le garde-fou ne doit pas créer .ai/.feature-index.json"

echo "✅ test-check-touches-breadth PASS"
