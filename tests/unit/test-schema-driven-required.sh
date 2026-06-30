#!/bin/bash
# test-schema-driven-required.sh — quality/feature-schema-validator.
#
# Durcissement P3 : check-features.sh dérive les clés OBLIGATOIRES du schéma
# (.required) au lieu d'une liste codée en dur. Preuve discriminante : on ajoute
# une clé requise (`owner`) au schéma TEMP ; une fiche qui ne la porte pas DOIT
# échouer — comportement impossible avec l'ancienne liste hardcodée.
# Éthos respecté : bash/jq, aucune dépendance validateur externe.
# Conditionné à jq (sans jq, read_schema_enum retombe sur le fallback hardcodé).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "⏭️  test-schema-driven-required SKIP (jq absent)"
  exit 0
fi
if ! command -v yq >/dev/null 2>&1; then
  echo "⏭️  test-schema-driven-required SKIP (yq absent)"
  exit 0
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-schema-required.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test" "$tmp/src"
for s in check-features.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
# Schéma TEMP : on ajoute `owner` aux clés requises (le runtime n'est pas touché).
jq '.required += ["owner"]' "$repo_root/.ai/schema/feature.schema.json" \
  > "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "schema-required-test"\n' > "$tmp/.ai/config.yml"
printf 'real\n' > "$tmp/src/real.ts"

# Fiche SANS `owner` → doit échouer (clé requise par le schéma temp).
cat > "$tmp/.docs/features/test/missing-owner.md" <<'MD'
---
id: missing-owner
scope: test
title: Missing owner
status: active
type: feature
depends_on: []
touches:
  - src/real.ts
---
# Missing owner
MD

(
  cd "$tmp"
  set +e
  out="$(bash .ai/scripts/check-features.sh --no-write 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || { echo "$out"; fail "une clé requise par le schéma (owner) devrait être enforced"; }
  echo "$out" | grep -q "'owner' manquante" || { echo "$out"; fail "message 'clé owner manquante' attendu (preuve schéma-driven)"; }

  # Contrôle : ajouter owner fait passer (le gate lit bien le schéma, ne sur-bloque pas).
  cat > .docs/features/test/missing-owner.md <<'MD'
---
id: missing-owner
scope: test
title: Missing owner
status: active
type: feature
owner: équipe-test
depends_on: []
touches:
  - src/real.ts
---
# Missing owner
MD
  bash .ai/scripts/check-features.sh --no-write >/dev/null 2>&1 \
    || fail "fiche portant toutes les clés requises (owner inclus) devrait passer"
)

echo "✅ test-schema-driven-required PASS"
