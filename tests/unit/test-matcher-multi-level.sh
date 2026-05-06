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

# ─── Bracket négatif [!...] (sémantique glob → conversion POSIX [^...]) ───
if path_matches_touch "lib/c.js" "lib/[!ab].js"; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("[!ab] négation : 'lib/c.js' devrait matcher 'lib/[!ab].js'")
fi
if ! path_matches_touch "lib/a.js" "lib/[!ab].js" 2>/dev/null; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("[!ab] négation : 'lib/a.js' ne devrait PAS matcher 'lib/[!ab].js'")
fi
if ! path_matches_touch "lib/b.js" "lib/[!ab].js" 2>/dev/null; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("[!ab] négation : 'lib/b.js' ne devrait PAS matcher 'lib/[!ab].js'")
fi

# ─── Brackets vides [], [!], [^] → unsupported ───
for bad_pattern in 'lib/[].js' 'lib/[!].js' 'lib/[^].js' 'foo\\bar.js'; do
  output=$(_FEATURES_MATCHING_POLICY=warn path_matches_touch "any" "$bad_pattern" 2>&1)
  rc=$?
  if [[ $rc -eq 1 && "$output" == *"pattern non supporté"* ]]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failures+=("brackets/escape vide : '$bad_pattern' attendu unsupported. rc=$rc, output='$output'")
  fi
done

# ─── Propagation strict via features_matching_path(_ranked) ───
# Crée un index temporaire avec une feature au touches: cassé.
tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'strict-test')
cat > "$tmp_dir/index.json" <<'JSONEOF'
{"features":[{"scope":"foo","id":"bar","path":"foo.md","touches":["foo**bar"],"depends_on":[],"touches_shared":[]}]}
JSONEOF

# strict : propagation rc=2 attendue depuis features_matching_path
_FEATURES_MATCHING_POLICY=strict features_matching_path "$tmp_dir/index.json" "any" >/dev/null 2>&1
rc=$?
if [[ $rc -eq 2 ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("propagation strict via features_matching_path : attendu rc=2, obtenu rc=$rc")
fi

# strict : propagation rc=2 attendue depuis features_matching_path_ranked
_FEATURES_MATCHING_POLICY=strict features_matching_path_ranked "$tmp_dir/index.json" "any" >/dev/null 2>&1
rc=$?
if [[ $rc -eq 2 ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("propagation strict via features_matching_path_ranked : attendu rc=2, obtenu rc=$rc")
fi

# warn : pas de propagation (rc=0 même si pattern unsupported)
_FEATURES_MATCHING_POLICY=warn features_matching_path "$tmp_dir/index.json" "any" >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("warn : ne doit pas propager rc=2, obtenu rc=$rc")
fi

rm -rf "$tmp_dir"

# ─── Wrapper features-for-path.sh : --strict accepté en argument ───
# Vérification minimale : --strict ne fait pas exit 2 (usage error) ; il est
# bien parsé. Pas de fail hard sur path commun (aucun touches: cassé chargé
# dans l'index réel).
output=$(bash "$(cd "$(dirname "$0")/../.." && pwd)/.ai/scripts/features-for-path.sh" --strict src/foo.ts 2>&1)
rc=$?
if [[ $rc -ne 2 ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("wrapper --strict mal parsé (usage error). rc=$rc, output='$output'")
fi

# AI_CONTEXT_FEATURES_STRICT=1 accepté en env var (même check minimal).
output=$(AI_CONTEXT_FEATURES_STRICT=1 bash "$(cd "$(dirname "$0")/../.." && pwd)/.ai/scripts/features-for-path.sh" src/foo.ts 2>&1)
rc=$?
if [[ $rc -ne 2 ]]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  failures+=("wrapper env var strict mal interprétée. rc=$rc, output='$output'")
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
