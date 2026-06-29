#!/bin/bash
# test-id-schema-checker-parity.sh — alignement schema ↔ checker sur le pattern `id`.
#
# Régression C2b (frame remédiation 2026-06-28) : le schéma déclarait `id` en
# kebab-case strict (^[a-z0-9]+(?:-[a-z0-9]+)*$) tandis que check-features.sh
# tolérait l'underscore — le schéma "mentait". Ce test verrouille l'alignement :
#   1. SNAPSHOT du pattern `id` du schéma (échoue si le schéma change → MAJ checker).
#   2. check-features REJETTE un id avec underscore (kebab strict appliqué).
#   3. check-features ACCEPTE un id kebab-case (pas de faux positif).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-id-parity.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

# 1. Snapshot du pattern schéma : si le schéma change, ce test échoue → réviser
#    la regex de check-features.sh ET ce snapshot ensemble (anti-re-divergence).
schema_pat="$(jq -r '.properties.id.pattern' "$repo_root/.ai/schema/feature.schema.json")"
[[ "$schema_pat" == '^[a-z0-9]+(?:-[a-z0-9]+)*$' ]] \
  || fail "pattern id du schéma changé ('$schema_pat') — aligner check-features.sh + ce snapshot"
echo "  ✓ snapshot pattern id schéma OK"

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test"
for s in check-features.sh _lib.sh build-feature-index.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "id-parity-test"\n' > "$tmp/.ai/config.yml"

write_fiche() {
  local id="$1"
  cat > "$tmp/.docs/features/test/fiche.md" <<MD
---
id: $id
scope: test
title: Fiche $id
status: active
depends_on: []
touches: []
---

# $id
MD
}

run_check() {
  local rc=0
  CHECK_OUT="$( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write 2>&1 )" || rc=$?
  return "$rc"
}

# 2. underscore → rejeté
write_fiche "foo_bar"
rc=0; run_check || rc=$?
[[ "$rc" -ne 0 ]] || fail "check-features aurait dû ÉCHOUER sur id='foo_bar' (underscore, hors schéma kebab)"
echo "$CHECK_OUT" | grep -q "id='foo_bar' invalide" \
  || fail "message d'invalidité id manquant pour 'foo_bar'"
echo "  ✓ underscore rejeté (aligné sur le schéma)"

# 3. kebab-case → pas de faux positif sur l'id
write_fiche "foo-bar-2"
run_check || true
echo "$CHECK_OUT" | grep -q "id='foo-bar-2' invalide" \
  && fail "faux positif : un id kebab-case valide a été rejeté" || true
echo "  ✓ kebab-case accepté (pas de faux positif)"

echo "✅ test-id-schema-checker-parity PASS"
