#!/bin/bash
# test-path-matches-touch.sh — Tests unitaires sur le helper path_matches_touch.
#
# Source : .ai/scripts/_lib.sh (dogfood — identique au template rendu).
# path_matches_touch est central : il décide quelle feature couvre quel fichier
# édité. Une régression silencieuse fait passer une feature à l'écart du flow
# d'auto-injection, ce qui n'est pas détecté par le smoke-test d'intégration.
#
# Usage :
#   bash tests/unit/test-path-matches-touch.sh
#
# Exit 0 si tous les cas passent, 1 sinon.

set -uo pipefail

cd "$(dirname "$0")/../.."

# shellcheck source=../../.ai/scripts/_lib.sh
. .ai/scripts/_lib.sh

pass=0
fail=0
failures=()

assert_match() {
  local desc="$1" path="$2" touch="$3"
  if path_matches_touch "$path" "$touch"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failures+=("MATCH attendu : $desc — path='$path' touch='$touch'")
  fi
}

assert_no_match() {
  local desc="$1" path="$2" touch="$3"
  if path_matches_touch "$path" "$touch"; then
    fail=$((fail + 1))
    failures+=("NO-MATCH attendu : $desc — path='$path' touch='$touch'")
  else
    pass=$((pass + 1))
  fi
}

# ─── Cas exact ───
assert_match    "fichier exact"                         "src/foo.ts"             "src/foo.ts"
assert_no_match "fichier exact négatif"                 "src/foo.ts"             "src/bar.ts"

# ─── Cas dossier (préfixe) ───
assert_match    "dossier couvre fichier"                "src/auth/service.ts"    "src/auth"
assert_match    "dossier avec / final"                  "src/auth/service.ts"    "src/auth/"
assert_no_match "dossier ne déborde pas"                "src/authority.ts"       "src/auth"

# ─── Cas glob /** ───
assert_match    "/** couvre racine"                     "src/auth"               "src/auth/**"
assert_match    "/** couvre descendant direct"          "src/auth/service.ts"    "src/auth/**"
assert_match    "/** couvre descendant profond"         "src/auth/v2/login.ts"   "src/auth/**"
assert_no_match "/** ne déborde pas hors préfixe"       "src/authority/x.ts"     "src/auth/**"

# ─── Cas glob bash ───
assert_match    "glob *.ts"                             "src/foo.ts"             "src/*.ts"
assert_no_match "glob *.ts ne match pas .js"            "src/foo.js"             "src/*.ts"
assert_match    "glob ** récursif"                      "src/auth/v2/login.ts"   "src/**/*.ts"
assert_match    "glob ? un caractère"                   "src/a.ts"               "src/?.ts"
assert_no_match "glob ? exige exactement 1 char"        "src/ab.ts"              "src/?.ts"
assert_match    "glob []"                               "lib/a.js"               "lib/[ab].js"
assert_no_match "glob [] hors set"                      "lib/c.js"               "lib/[ab].js"

# ─── Edge cases ───
assert_no_match "path vide"                             ""                       "src/foo.ts"
assert_no_match "touch vide"                            "src/foo.ts"             ""
assert_no_match "path identique au préfixe non-glob"    "src"                    "src/auth"

# ─── Cas Windows-friendly (séparateurs / uniquement) ───
assert_match    "chemin avec underscores et tirets"     "src/auth-v2_alpha/x.ts" "src/auth-v2_alpha/**"

# ─── No-overmatch (fix Phase 2 #2 : * ne doit pas absorber /) ───
assert_match    "no-overmatch app/*/page.tsx un segment"   "app/x/page.tsx"        "app/*/page.tsx"
assert_no_match "no-overmatch app/*/page.tsx multi seg"    "app/a/b/page.tsx"      "app/*/page.tsx"
assert_no_match "no-overmatch app/*.tsx ne traverse pas /" "app/sub/page.tsx"      "app/*.tsx"
assert_match    "src/**/*.ts zéro segment intermediaire"   "src/foo.ts"            "src/**/*.ts"
assert_match    "**/x.ts a la racine"                      "x.ts"                  "**/x.ts"
assert_match    "**/x.ts profond"                          "a/b/c/x.ts"            "**/x.ts"
assert_match    "foo-*/** profond"                         "foo-bar/baz/qux.ts"    "foo-*/**"
assert_no_match "foo-*/** ne déborde pas"                  "foobar/x.ts"           "foo-*/**"

# ─── Rapport ───
total=$((pass + fail))
echo "═══ test-path-matches-touch ═══"
echo "Total : $total | OK : $pass | KO : $fail"
if [[ $fail -gt 0 ]]; then
  printf '\nÉchecs :\n'
  for f in "${failures[@]}"; do
    printf '  ✗ %s\n' "$f"
  done
  exit 1
fi
echo "✅ Tous les cas passent"
exit 0
