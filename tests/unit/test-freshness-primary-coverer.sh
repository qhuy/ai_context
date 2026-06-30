#!/bin/bash
# test-freshness-primary-coverer.sh — quality/doc-freshness.
#
# Contrat (a') de la gate de fraîcheur (audit D + arbitrage Codex) : parmi les
# coverers DIRECTS (touches:) d'un fichier, seul le rang de spécificité le plus
# élevé est BLOQUANT.
#   - exact-primaire unique documenté → PASS (glob secondaire = advisory) ;
#   - 0 coverer documenté → BLOCK (moat préservé) ;
#   - tie exact 1/N documenté → BLOCK ; N/N documenté → PASS ;
#   - dispatcher reclassé (secondaires en touches_shared) → seul l'owner exact bloque ;
#   - --worktree : même comportement que --staged, sans écrire l'index.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-freshness-primary.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/back" "$tmp/src"
for s in check-feature-freshness.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "freshness-primary-test"\n' > "$tmp/.ai/config.yml"

mkfeat() { # id touches_yaml [shared_yaml]
  local id="$1" tch="$2" shared="${3:-[]}"
  cat > "$tmp/.docs/features/back/$id.md" <<EOF
---
id: $id
scope: back
title: $id
status: active
type: feature
depends_on: []
touches: $tch
touches_shared: $shared
---
EOF
  printf '# %s\n' "$id" > "$tmp/.docs/features/back/$id.worklog.md"
}
docedit() { printf '\n- doc %s\n' "$(basename "$1")" >> "$tmp/.docs/features/back/$1.worklog.md"; }

cd "$tmp"
git init -q; git config user.email t@t; git config user.name t; git config core.hooksPath /dev/null
printf 'x\n' > src/shared.ts
run() { local rc; set +e; bash .ai/scripts/check-feature-freshness.sh "$@" >"$tmp/out" 2>&1; rc=$?; set -e; echo "$rc"; }

# Cas 2 : exact-primaire documenté → PASS ; glob secondaire non requis.
mkfeat owner '[src/shared.ts]'; mkfeat broad '[src/**]'
git add -A; git commit -qm seed
printf 'edit\n' > src/shared.ts; docedit owner; git add src/shared.ts .docs/features/back/owner.worklog.md
[[ "$(run --staged --strict)" == 0 ]] || { cat "$tmp/out"; fail "exact-primaire documenté devrait passer (glob secondaire advisory)"; }

# Moat : 0 doc → BLOCK.
git reset -q; git checkout -q -- .; printf 'edit2\n' > src/shared.ts; git add src/shared.ts
[[ "$(run --staged --strict)" == 1 ]] || { cat "$tmp/out"; fail "code couvert sans aucune doc devrait bloquer (moat)"; }

# Cas tie exact : 1/2 documenté → BLOCK ; 2/2 → PASS.
git reset -q; git checkout -q -- . 2>/dev/null; rm -f .docs/features/back/broad.md .docs/features/back/broad.worklog.md
mkfeat owner '[src/shared.ts]'; mkfeat tieval '[src/shared.ts]'
git add -A; git commit -qm seed2
printf 'edit3\n' > src/shared.ts; docedit owner; git add src/shared.ts .docs/features/back/owner.worklog.md
[[ "$(run --staged --strict)" == 1 ]] || { cat "$tmp/out"; fail "tie exact 1/2 documenté devrait bloquer"; }
docedit tieval; git add .docs/features/back/tieval.worklog.md
[[ "$(run --staged --strict)" == 0 ]] || { cat "$tmp/out"; fail "tie exact 2/2 documenté devrait passer"; }

# Cas dispatcher reclassé : tieval en touches_shared → seul owner exact bloque.
git reset -q; git checkout -q -- . 2>/dev/null
mkfeat owner '[src/shared.ts]'; mkfeat tieval '[]' '[src/shared.ts]'
git add -A; git commit -qm seed3
printf 'edit4\n' > src/shared.ts; docedit owner; git add src/shared.ts .docs/features/back/owner.worklog.md
[[ "$(run --staged --strict)" == 0 ]] || { cat "$tmp/out"; fail "dispatcher reclassé : owner exact seul devrait suffire"; }

# Cas --worktree : même comportement (tie non documenté → BLOCK) + n'écrit pas l'index.
git reset -q; git checkout -q -- . 2>/dev/null
mkfeat owner '[src/shared.ts]'; mkfeat tieval '[src/shared.ts]'
git add -A; git commit -qm seed4
before="$(md5 -q .ai/.feature-index.json 2>/dev/null || echo none)"
printf 'edit5\n' > src/shared.ts
[[ "$(run --worktree --strict)" == 1 ]] || { cat "$tmp/out"; fail "--worktree devrait bloquer comme --staged"; }
after="$(md5 -q .ai/.feature-index.json 2>/dev/null || echo none)"
[[ "$before" == "$after" ]] || fail "--worktree ne doit pas écrire .ai/.feature-index.json"

echo "✅ test-freshness-primary-coverer PASS"
