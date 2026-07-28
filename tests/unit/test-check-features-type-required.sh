#!/bin/bash
# test-check-features-type-required.sh — core/okf-strict-profile.
#
# Verrouille le durcissement v1.0 : le champ `type` est REQUIS (il était en warn
# pendant la fenêtre de migration OKF Phase 0). Trois cas discriminants :
#   1. type absent          -> échec, avec le hint de backfill
#   2. type hors enum       -> échec
#   3. type valide          -> succès
# Plus une garde anti-régression : l'absence ne doit produire QU'UN SEUL ✗
# (la présence est dérivée de `.required` du schéma ; une revalidation locale
# dupliquerait le message — régression réellement introduite puis corrigée en
# v1.0, d'où cette assertion).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

for bin in jq yq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "⏭️  test-check-features-type-required SKIP ($bin absent)"; exit 0; }
done

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-type-required.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $1"; exit 1; }

mkdir -p "$tmp/.ai" "$tmp/.docs/features/back"
cp -R "$repo_root/.ai/scripts" "$repo_root/.ai/schema" "$tmp/.ai/"
printf 'docs_root: ".docs"\nproject_id: "type-required-test"\n' > "$tmp/.ai/config.yml"

fiche="$tmp/.docs/features/back/sample.md"
write_fiche() {
  # $1 = ligne type (peut être vide)
  {
    echo "---"
    echo "id: sample"
    echo "scope: back"
    echo "title: Fiche de test"
    echo "status: active"
    [[ -n "${1:-}" ]] && echo "$1"
    echo "depends_on: []"
    echo "touches: []"
    echo "---"
    echo
    echo "# Fiche de test"
  } > "$fiche"
}

# ─── Cas 1 : type absent -> échec + hint, une seule fois ───
write_fiche ""
out="$( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write 2>&1 )" && \
  fail "type absent devrait faire échouer check-features"

echo "$out" | grep -q "clé frontmatter 'type' manquante" \
  || { echo "$out"; fail "message attendu pour type manquant"; }
echo "$out" | grep -q "migrate okf-type --apply" \
  || { echo "$out"; fail "hint de backfill attendu dans le message"; }

count="$(echo "$out" | grep -c "sample.md.*type" || true)"
[[ "$count" -eq 1 ]] \
  || { echo "$out"; fail "type manquant doit produire 1 seul diagnostic, vu $count"; }
echo "  ✓ type absent : échec bloquant, hint présent, pas de doublon"

# ─── Cas 2 : type hors enum -> échec ───
write_fiche "type: bogus"
out="$( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write 2>&1 )" && \
  fail "type hors enum devrait faire échouer check-features"
echo "$out" | grep -q "type='bogus' hors enum" \
  || { echo "$out"; fail "message attendu pour type hors enum"; }
echo "  ✓ type hors enum : échec bloquant"

# ─── Cas 3 : type valide -> succès ───
write_fiche "type: feature"
( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write >/dev/null 2>&1 ) \
  || { ( cd "$tmp" && bash .ai/scripts/check-features.sh --no-write ); fail "type valide devrait passer"; }
echo "  ✓ type valide : PASS"

# ─── Garde : `type` est bien dans .required du schéma ───
jq -e '.required | index("type")' "$repo_root/.ai/schema/feature.schema.json" >/dev/null \
  || fail "type doit figurer dans .required du schéma (contrat v1.0)"
echo "  ✓ schéma : type présent dans .required"

echo "✅ test-check-features-type-required PASS"
