#!/bin/bash
# test-cycle-detection-diamond.sh — quality/cycle-detection.
#
# Garde de non-régression sur la structure en DIAMANT (audit A13). L'ancienne
# DFS récursive de check-features ré-explorait chaque nœud une fois par chemin
# → coût exponentiel sur un DAG en diamant (k=20 ≈ 76s, k≥22 timeout). Le tri
# topologique de Kahn est O(V+E). Ce test exerce un diamant de profondeur k :
#   - acyclique  → check-features PASS, aucun faux cycle ;
#   - + une arête retour (cycle) → détecté, exit non-zéro.
# Perf : avec Kahn le diamant est instantané ; une régression vers la DFS
# exponentielle rendrait ce test très lent (voire timeout CI) à k élevé.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-cycle-diamond.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/t" "$tmp/src"
for s in check-features.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "cycle-diamond-test"\n' > "$tmp/.ai/config.yml"
printf 'x\n' > "$tmp/src/foo.ts"

K=10  # 2^K chemins de a0 à a$K ; suffisant pour exercer le diamant sans coût de build excessif

emit() { # id  dep1 dep2...
  local id="$1"; shift
  local deps=""
  local d
  for d in "$@"; do deps+=$'\n  - t/'"$d"; done
  cat > "$tmp/.docs/features/t/$id.md" <<EOF
---
id: $id
scope: t
title: $id
status: active
type: feature
depends_on:${deps:-" []"}
touches:
  - src/foo.ts
---
EOF
}

# Chaîne de K diamants : a\$i -> b\$i,c\$i ; b\$i,c\$i -> a\$((i+1)) ; a\$K -> []
for ((i=0;i<K;i++)); do
  emit "a$i" "b$i" "c$i"
  emit "b$i" "a$((i+1))"
  emit "c$i" "a$((i+1))"
done
emit "a$K"

# 1. Diamant acyclique → PASS, aucun cycle signalé.
( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write ) >"$tmp/out" 2>&1 \
  || { cat "$tmp/out"; fail "diamant acyclique aurait dû passer (faux cycle ?)"; }
grep -qi "cycle" "$tmp/out" && { cat "$tmp/out"; fail "aucun cycle ne doit être signalé sur un diamant acyclique"; }

# 2. Ajout d'une arête retour a0 -> a$K (déjà atteignable) ne crée PAS de cycle ;
#    en revanche a$K -> a0 referme la boucle → cycle.
emit "a$K" "a0"
if ( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write ) >"$tmp/out2" 2>&1; then
  cat "$tmp/out2"; fail "le cycle (arête retour a\$K -> a0) aurait dû être rejeté"
fi
grep -qi "cycle détecté" "$tmp/out2" || { cat "$tmp/out2"; fail "message 'cycle détecté' attendu"; }

echo "✅ test-cycle-detection-diamond PASS"
