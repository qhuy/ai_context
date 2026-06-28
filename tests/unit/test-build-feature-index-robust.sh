#!/bin/bash
# test-build-feature-index-robust.sh — core/feature-index-cache.
#
# Une fiche au frontmatter YAML malformé ne doit PAS faire planter build-feature-index
# (qui casserait en cascade tous les hooks). Elle est ignorée (warn) ; l'index reste
# valide et contient les autres fiches.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-bfi-robust.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test"
for s in _lib.sh build-feature-index.sh; do cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"; done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "bfi-robust-test"\n' > "$tmp/.ai/config.yml"

# 2 fiches valides
for id in good-a good-b; do
  printf -- '---\nid: %s\nscope: test\ntitle: %s\nstatus: active\ntype: feature\ndepends_on: []\ntouches:\n  - src/%s.ts\n---\n# %s\n' "$id" "$id" "$id" "$id" > "$tmp/.docs/features/test/$id.md"
done
# 1 fiche malformée : titre non quoté finissant par deux-points → YAML invalide
printf -- '---\nid: bad\nscope: test\ntitle: Titre casse finissant par deux points:\nstatus: active\n---\n# bad\n' > "$tmp/.docs/features/test/bad.md"

cd "$tmp"
set +e
out="$(bash .ai/scripts/build-feature-index.sh 2>/tmp/bfi-robust.err)"; rc=$?
set -e

[[ "$rc" -eq 0 ]] || fail "build-feature-index doit exit 0 malgré une fiche malformée (a planté, rc=$rc)"
echo "$out" | jq -e . >/dev/null 2>&1 || fail "l'index produit doit être un JSON valide"
echo "$out" | jq -e '.features[] | select(.id == "good-a")' >/dev/null || fail "good-a doit être présent"
echo "$out" | jq -e '.features[] | select(.id == "good-b")' >/dev/null || fail "good-b doit être présent"

# Comportement spécifique au parseur yq v4 (sinon le fallback awk tolère et inclut).
if command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -qE 'v?4\.'; then
  echo "$out" | jq -e '.features[] | select(.id == "bad")' >/dev/null 2>&1 && fail "la fiche malformée 'bad' ne doit PAS être dans l'index (yq)"
  grep -q 'illisible' /tmp/bfi-robust.err || fail "un avertissement doit signaler la fiche ignorée (yq)"
  echo "  (yq v4 : fiche malformée ignorée + warning ✓)"
else
  echo "  (yq absent : fallback awk tolérant, pas de crash — OK)"
fi

echo "✅ test-build-feature-index-robust PASS"
