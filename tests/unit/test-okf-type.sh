#!/bin/bash
# test-okf-type.sh — profil strict OKF (core/okf-strict-profile), Phase 0.
#
# Garde-fous de régression du champ `type` :
#   1. NON-CASSANT : une fiche sans `type` produit un WARN, jamais un abort
#      (check-features tourne sous set -euo pipefail ; une extraction directe
#       de champ optionnel via `grep` y casserait le script — bug déjà corrigé).
#   2. type hors-enum → warn (pas exit 1) en Phase 0.
#   3. migrate okf-type : idempotent (re-run = no-op), n'écrase pas un type présent.
#   4. garde-fou enum : --type=<invalide> refusé avant toute écriture.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-okf-type.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/back"
for s in check-features.sh _lib.sh build-feature-index.sh migrate-okf-type.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "okf-type-test"
YAML

# Fiche SANS type, + une 2e fiche traitée après, pour prouver l'absence de court-circuit.
cat > "$tmp/.docs/features/back/no-type.md" <<'MD'
---
id: no-type
scope: back
title: Sans type
status: active
depends_on: []
touches: []
---

# Sans type
MD
cat > "$tmp/.docs/features/back/bad-type.md" <<'MD'
---
id: bad-type
scope: back
title: Type hors enum
status: active
type: bogus
depends_on: []
touches: []
---

# Type hors enum
MD

run_check() {
  # capture exit code sans abort du test (set -e)
  local rc=0
  CHECK_OUT="$( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write 2>&1 )" || rc=$?
  return "$rc"
}

# 1 + 2 : non-cassant + warn hors-enum
rc=0; run_check || rc=$?
[[ "$rc" -eq 0 ]] || fail "check-features doit sortir 0 sur fiches sans type / type hors-enum (obtenu $rc — abort ?)"
echo "$CHECK_OUT" | grep -q "no-type.md : champ 'type' absent" \
  || fail "warn 'type absent' manquant pour la fiche sans type"
echo "$CHECK_OUT" | grep -q "bad-type.md : type='bogus' hors enum" \
  || fail "warn 'type hors enum' manquant pour la fiche type: bogus"
echo "  ✓ non-cassant : type absent/hors-enum → warn, exit 0 (pas d'abort)"

# 3 : migrate idempotent
( cd "$tmp" && bash .ai/scripts/migrate-okf-type.sh --apply >/dev/null 2>&1 ) \
  || fail "migrate --apply a échoué"
grep -q '^type: feature' "$tmp/.docs/features/back/no-type.md" \
  || fail "migrate n'a pas ajouté type: feature à la fiche sans type"
[[ "$(grep -c '^type:' "$tmp/.docs/features/back/bad-type.md")" -eq 1 ]] \
  || fail "migrate a touché/dupliqué le type d'une fiche qui en avait déjà un"
out2="$( cd "$tmp" && bash .ai/scripts/migrate-okf-type.sh --apply 2>&1 )"
echo "$out2" | grep -q "déjà un type" \
  || fail "migrate n'est pas idempotent (2e --apply devrait être un no-op)"
echo "  ✓ migrate okf-type : idempotent, n'écrase pas un type existant"

# 4 : garde-fou enum
rc=0
( cd "$tmp" && bash .ai/scripts/migrate-okf-type.sh --type=bogus >/dev/null 2>&1 ) || rc=$?
[[ "$rc" -ne 0 ]] || fail "migrate --type=bogus aurait dû être refusé (hors enum)"
echo "  ✓ garde-fou enum : --type invalide refusé"

echo "✅ test-okf-type PASS"
