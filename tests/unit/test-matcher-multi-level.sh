#!/bin/bash
# tests/unit/test-matcher-multi-level.sh
#
# Acceptance bloquante Phase 2 #2 (quality/features-for-path-ranking-and-
# matcher-correctness). Le matcher path_matches_touch doit :
#   - traiter `**` comme multi-segments (vrai globstar) ;
#   - traiter `*` comme intra-segment (no-overmatch sur /) ;
#   - exposer les patterns non supportés via _FEATURES_MATCHING_POLICY ;
#   - rester compatible bash 3.2 (regex POSIX path-aware).

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
  if path_matches_touch "$path" "$touch" 2>/dev/null; then
    fail=$((fail + 1))
    failures+=("NO-MATCH attendu : $desc — path='$path' touch='$touch'")
  else
    pass=$((pass + 1))
  fi
}

# ─── Acceptance bloquante : ** multi-niveaux ───
assert_match    "src/**/*.ts zéro segment"        "src/foo.ts"             "src/**/*.ts"
assert_match    "src/**/*.ts un segment"          "src/a/foo.ts"           "src/**/*.ts"
assert_match    "src/**/*.ts plusieurs segments"  "src/a/b/foo.ts"         "src/**/*.ts"
assert_no_match "src/**/*.ts mauvaise extension"  "src/a/foo.js"           "src/**/*.ts"

assert_match    "**/x.ts à la racine"             "x.ts"                   "**/x.ts"
assert_match    "**/x.ts profond"                 "a/b/c/x.ts"             "**/x.ts"

assert_match    "foo-*/** profond"                "foo-bar/baz/qux.ts"     "foo-*/**"
assert_match    "foo-*/** racine"                 "foo-bar/x"              "foo-*/**"
assert_no_match "foo-*/** ne déborde pas"         "foobar/x.ts"            "foo-*/**"

# ─── No-overmatch : * intra-segment ───
assert_match    "app/*/page.tsx un segment"       "app/profile/page.tsx"   "app/*/page.tsx"
assert_no_match "app/*/page.tsx multi-segments"   "app/a/b/page.tsx"       "app/*/page.tsx"
assert_no_match "src/*.ts ne traverse pas /"      "src/sub/foo.ts"         "src/*.ts"

# ─── Whitelist B2 supportée ───
assert_match    "exact file"                      "src/auth/login.ts"      "src/auth/login.ts"
assert_match    "dossier sans glob"               "src/auth/login.ts"      "src/auth"
assert_match    "intra-segment ?"                 "src/a.ts"               "src/?.ts"
assert_match    "intra-segment [abc]"             "lib/a.js"               "lib/[ab].js"
assert_match    "glob-prefix /**"                 "aic-frame/x.md"         "aic-*/**"

# ─── Politique unsupported : silent / warn / strict ───
unsupported_pattern='foo**bar'  # ** hors segment complet
unsupported_chained='**/x/**/y/**/z/**/w'  # 4 /**/ chaînés (non explicitement supporté)

# silent : pas de message, retourne 1
output=$(_FEATURES_MATCHING_POLICY=silent path_matches_touch "any" "$unsupported_pattern" 2>&1)
rc=$?
if [[ $rc -eq 1 && -z "$output" ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("policy=silent : attendu rc=1 et stderr vide. rc=$rc, output='$output'")
fi

# warn (défaut) : message stderr, retourne 1
output=$(_FEATURES_MATCHING_POLICY=warn path_matches_touch "any" "$unsupported_pattern" 2>&1)
rc=$?
if [[ $rc -eq 1 && "$output" == *"pattern non supporté"* ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("policy=warn : attendu rc=1 et warning stderr. rc=$rc, output='$output'")
fi

# strict : message stderr, retourne 2 (caller propage exit ≠ 0)
output=$(_FEATURES_MATCHING_POLICY=strict path_matches_touch "any" "$unsupported_pattern" 2>&1)
rc=$?
if [[ $rc -eq 2 && "$output" == *"pattern non supporté"* ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("policy=strict : attendu rc=2 et erreur stderr. rc=$rc, output='$output'")
fi

# Bracket mal formé → unsupported
output=$(_FEATURES_MATCHING_POLICY=warn path_matches_touch "any" "lib/[ab.js" 2>&1)
rc=$?
if [[ $rc -eq 1 && "$output" == *"pattern non supporté"* ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("bracket mal formé : attendu unsupported. rc=$rc, output='$output'")
fi

# ─── Rapport ───
total=$((pass + fail))
echo "═══ test-matcher-multi-level ═══"
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
