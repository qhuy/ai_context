#!/bin/bash
# test-okf-type.sh — profil strict OKF (core/okf-strict-profile), migrate + Phase 1.
#
# Depuis v1.0, `type` est REQUIS : le rollout annoncé `warn → fail` est tenu (warn
# en v0.14, échec en v1.0 — CHANGELOG § [1.0.0] « Changé — breaking documenté »).
# Ce fichier encodait la moitié v0.14 du contrat (exit 0 + warn) et a été recentré.
#
# PROPRIÉTÉ DES ASSERTIONS — le contrat de MESSAGE et de SÉVÉRITÉ de check-features
# (absent → ✗ + hint, hors-enum → ✗, valide → PASS, non-doublon, `type` dans
# `.required` du schéma) appartient à `tests/unit/test-check-features-type-required.sh`.
# Ne pas le redupliquer ici. Ce fichier couvre ce que l'autre ne voit pas :
#   1. Pas de court-circuit : deux fiches aux défauts `type` DISTINCTS sont
#      diagnostiquées dans la MÊME passe et le script atteint son verdict final.
#      (check-features tourne sous set -euo pipefail ; une extraction directe de
#       champ optionnel via `grep` y casserait le script — bug déjà corrigé. L'autre
#       test n'a qu'une fiche par run, il ne peut donc pas voir un abort de boucle.)
#   2. Le hint dit vrai — bout en bout : `migrate okf-type --apply` fait réellement
#      disparaître le ✗ « type manquante » que check-features conseille de corriger
#      ainsi, et une fois les deux fiches conformes le gate sort 0 (discrimination :
#      le rc=1 venait bien du seul champ `type`).
#   3. migrate okf-type : idempotent (re-run = no-op), n'écrase pas un type présent.
#   4. garde-fou enum : --type=<invalide> refusé avant toute écriture.
#
# Le ✗ « type manquante » dérive de `.required` du schéma via jq (read_schema_enum) :
# sans jq, REQUIRED_FIELDS retombe sur le fallback codé, qui ne contient pas `type`
# — ce seul diagnostic est alors skippé. Le reste ne dépend pas de jq (TYPE_ENUM a
# le même fallback codé, et le backfill migrate est en bash pur).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-okf-type.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

has_jq=0
command -v jq >/dev/null 2>&1 && has_jq=1

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/back"
for s in check-features.sh _lib.sh build-feature-index.sh migrate-okf-type.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "okf-type-test"
YAML

# Deux fiches, deux défauts `type` distincts : c'est le couple qui prouve l'absence
# de court-circuit (les deux diagnostics doivent tomber dans la même passe).
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

# ─── 1 : pas de court-circuit sur deux défauts `type` dans la même passe ───
# Marqueur ✗ dans les motifs : `ko` et `warn` émettent le MÊME texte, seul le
# marqueur les distingue — on veut la preuve que les deux fiches ont été
# diagnostiquées comme bloquantes, pas seulement mentionnées.
rc=0; run_check || rc=$?
[[ "$rc" -eq 1 ]] || fail "prérequis : deux fiches à type défectueux doivent faire sortir 1 (obtenu $rc)"
echo "$CHECK_OUT" | grep -q "✗.*bad-type.md : type='bogus' hors enum" \
  || fail "fiche hors-enum non diagnostiquée dans la passe (court-circuit ?)"
if [[ "$has_jq" -eq 1 ]]; then
  echo "$CHECK_OUT" | grep -q "✗.*no-type.md : clé frontmatter 'type' manquante" \
    || fail "fiche sans type non diagnostiquée dans la passe (court-circuit ?)"
else
  echo "  ⏭️  diagnostic 'type manquante' skippé (jq absent : REQUIRED_FIELDS sur fallback codé)"
fi
# Verdict final atteint = la boucle n'a pas été abortée par set -e / pipefail.
echo "$CHECK_OUT" | grep -q "❌ FAIL" \
  || fail "check-features semble avoir aborté avant son verdict final (set -e / pipefail ?)"
echo "  ✓ pas de court-circuit : les deux défauts tombent dans la même passe, verdict atteint"

# ─── 2 : backfill — migrate applique, sans écraser un type existant ───
( cd "$tmp" && bash .ai/scripts/migrate-okf-type.sh --apply >/dev/null 2>&1 ) \
  || fail "migrate --apply a échoué"
grep -q '^type: feature' "$tmp/.docs/features/back/no-type.md" \
  || fail "migrate n'a pas ajouté type: feature à la fiche sans type"
[[ "$(grep -c '^type:' "$tmp/.docs/features/back/bad-type.md")" -eq 1 ]] \
  || fail "migrate a touché/dupliqué le type d'une fiche qui en avait déjà un"

# Le hint de check-features dit vrai : le ✗ qu'il conseille de corriger par
# `migrate okf-type --apply` a bien disparu ; le hors-enum restant bloque toujours.
rc=0; run_check || rc=$?
if echo "$CHECK_OUT" | grep -q "clé frontmatter 'type' manquante"; then
  fail "le ✗ 'type manquante' survit au backfill : le hint de check-features ne résout pas l'échec"
fi
[[ "$rc" -eq 1 ]] || fail "le type hors-enum restant doit encore bloquer après backfill (obtenu $rc)"
echo "  ✓ hint de backfill effectif : migrate --apply lève le ✗ 'type manquante'"

# ─── 3 : migrate idempotent (les deux fiches déclarent maintenant un type) ───
out2="$( cd "$tmp" && bash .ai/scripts/migrate-okf-type.sh --apply 2>&1 )"
echo "$out2" | grep -q "déjà un type" \
  || fail "migrate n'est pas idempotent (2e --apply devrait être un no-op)"
echo "  ✓ migrate okf-type : idempotent, n'écrase pas un type existant"

# Fin du parcours de remédiation : hors-enum corrigé à la main → plus aucun défaut
# `type`, donc exit 0. Discrimination du rc=1 observé plus haut.
# (Le cas « type valide » isolé appartient à test-check-features-type-required.sh.)
cat > "$tmp/.docs/features/back/bad-type.md" <<'MD'
---
id: bad-type
scope: back
title: Type dans l enum
status: active
type: contract
depends_on: []
touches: []
---

# Type dans l enum
MD
rc=0; run_check || rc=$?
[[ "$rc" -eq 0 ]] || fail "fiches conformes : check-features doit sortir 0 (obtenu $rc) — le rc=1 ne discriminait pas le champ 'type'"
echo "  ✓ remédiation complète : fiches conformes → exit 0"

# ─── 4 : garde-fou enum ───
rc=0
( cd "$tmp" && bash .ai/scripts/migrate-okf-type.sh --type=bogus >/dev/null 2>&1 ) || rc=$?
[[ "$rc" -ne 0 ]] || fail "migrate --type=bogus aurait dû être refusé (hors enum)"
echo "  ✓ garde-fou enum : --type invalide refusé"

echo "✅ test-okf-type PASS"
