#!/bin/bash
# test-check-features-yaml-strict.sh — core/feature-mesh.
#
# check-features (le gate) doit BLOQUER sur une fiche dont le frontmatter ne
# parse pas en YAML strict. Sinon le builder l'exclut silencieusement de l'index
# (build-feature-index.sh : warn + skip) et ses touches: cessent d'être couverts
# par les gates freshness/commit — régression invisible (finding #3 audit hebdo).
# Conditionné à yq (même condition que le drop côté builder ; le fallback awk ne
# valide pas le YAML).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

if ! command -v yq >/dev/null 2>&1; then
  echo "⏭️  test-check-features-yaml-strict SKIP (yq absent)"
  exit 0
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-check-features-yaml.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test" "$tmp/src"
for s in check-features.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "check-features-yaml-test"\n' > "$tmp/.ai/config.yml"
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

# Fiche malformée : flow-seq non fermée → yq échoue, mais grep voit toutes les
# clés (id/scope/title/status/depends_on/touches). C'est le cas exact du finding
# #3 : grep-passable mais YAML illisible → droppée par le builder sans le gate.
cat > "$tmp/.docs/features/test/broken.md" <<'MD'
---
id: broken
scope: test
title: Broken
status: active
type: feature
depends_on: []
touches: [src/real.ts, src/other.ts
---
# Broken
MD

(
  cd "$tmp"
  set +e
  out="$(bash .ai/scripts/check-features.sh --no-write 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || { echo "$out"; fail "fiche YAML malformée aurait dû faire échouer le gate"; }
  echo "$out" | grep -q "YAML invalide" || { echo "$out"; fail "message 'YAML invalide' attendu absent"; }
  echo "$out" | grep -q "broken.md" || { echo "$out"; fail "le fichier malformé devrait être nommé"; }

  # Contrôle : la fiche valide seule passe (le gate ne sur-bloque pas).
  rm .docs/features/test/broken.md
  bash .ai/scripts/check-features.sh --no-write >/dev/null 2>&1 || fail "fiche valide seule devrait passer"
)

echo "✅ test-check-features-yaml-strict PASS"
