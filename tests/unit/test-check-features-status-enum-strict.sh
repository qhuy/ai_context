#!/bin/bash
# test-check-features-status-enum-strict.sh — quality/feature-schema-validator (pilotage P10a).
#
# check-features (le gate) doit BLOQUER sur une fiche dont `status` est hors
# de l'enum du schéma (draft|active|done|deprecated|archived). Avant ce
# durcissement, une valeur hors enum ne déclenchait qu'un warning — un statut
# invalide (ex: `published`, confondu avec l'enum du schéma knowledge) passait
# silencieusement la CI.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-check-features-status-enum.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test" "$tmp/src"
for s in check-features.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "check-features-status-enum-test"\n' > "$tmp/.ai/config.yml"
printf 'real\n' > "$tmp/src/real.ts"

# Fiche valide (contrôle).
cat > "$tmp/.docs/features/test/valid.md" <<'MD'
---
id: valid
scope: test
title: Valid
status: active
type: feature
depends_on: []
touches:
  - src/real.ts
---
# Valid
MD

# Fiche avec status hors enum (ex. valeur du schéma knowledge, pas du schéma
# feature — confusion réelle observée pendant l'audit du 2026-07-23).
cat > "$tmp/.docs/features/test/bad-status.md" <<'MD'
---
id: bad-status
scope: test
title: Bad status
status: published
type: feature
depends_on: []
touches:
  - src/real.ts
---
# Bad status
MD

(
  cd "$tmp"
  set +e
  out="$(bash .ai/scripts/check-features.sh --no-write 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || { echo "$out"; fail "status hors enum aurait dû faire échouer le gate"; }
  echo "$out" | grep -q "hors enum" || { echo "$out"; fail "message 'hors enum' attendu absent"; }
  echo "$out" | grep -q "bad-status.md" || { echo "$out"; fail "le fichier fautif devrait être nommé"; }

  # Contrôle : la fiche valide seule passe (le gate ne sur-bloque pas).
  rm .docs/features/test/bad-status.md
  bash .ai/scripts/check-features.sh --no-write >/dev/null 2>&1 || fail "fiche valide seule devrait passer"
)

echo "✅ test-check-features-status-enum-strict PASS"
