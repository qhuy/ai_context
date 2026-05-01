#!/bin/bash
# test-is-path-within-repo.sh — Tests unitaires sur le helper is_path_within_repo.
#
# Source : .ai/scripts/_lib.sh (dogfood — identique au template rendu).
# is_path_within_repo est l'unique rempart contre les motifs `touches:`/`depends_on:`
# malveillants (chemins absolus, traversées, expansion home, UNC Windows).
# Une régression silencieuse ouvrirait un vecteur de pollution du contexte injecté.
#
# Usage :
#   bash tests/unit/test-is-path-within-repo.sh
#
# Exit 0 si tous les cas passent, 1 sinon.

set -uo pipefail

cd "$(dirname "$0")/../.."

# shellcheck source=../../.ai/scripts/_lib.sh
. .ai/scripts/_lib.sh

pass=0
fail=0
failures=()

assert_safe() {
  local desc="$1" path="$2"
  if is_path_within_repo "$path"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failures+=("SAFE attendu : $desc — path='$path'")
  fi
}

assert_unsafe() {
  local desc="$1" path="$2"
  if is_path_within_repo "$path"; then
    fail=$((fail + 1))
    failures+=("UNSAFE attendu : $desc — path='$path'")
  else
    pass=$((pass + 1))
  fi
}

# ─── Cas safe (chemins relatifs valides) ───
assert_safe   "fichier relatif"                  "src/foo.ts"
assert_safe   "dossier relatif"                  "src/auth"
assert_safe   "glob simple"                      "src/**/*.ts"
assert_safe   "glob ?"                           "src/a?.ts"
assert_safe   "glob []"                          "lib/[ab].js"
assert_safe   "/**"                              "src/auth/**"
assert_safe   "chemin avec espace"               "src/with space/file.ts"
assert_safe   "chemin avec tirets"               "src/auth-v2/x.ts"
assert_safe   "fichier sans dossier"             "README.md"
assert_safe   ".. en milieu de nom (pas séparé)" "src/v..2/foo.ts"

# ─── Cas unsafe (absolu Unix) ───
assert_unsafe "absolu Unix /etc/passwd"          "/etc/passwd"
assert_unsafe "absolu Unix /tmp"                 "/tmp/foo"
assert_unsafe "racine seule"                     "/"
assert_unsafe "double slash (UNC forward)"       "//server/share"

# ─── Cas unsafe (absolu Windows lettre+drive) ───
assert_unsafe "Windows backslash absolu"         "C:\\Windows\\System32"
assert_unsafe "Windows forward absolu"           "C:/Windows/System32"
assert_unsafe "Windows lettre minuscule"         "c:/users"
assert_unsafe "Windows juste drive"              "D:"

# ─── Cas unsafe (UNC + backslash absolu) ───
assert_unsafe "UNC backslash"                    "\\\\server\\share\\foo"
assert_unsafe "backslash absolu"                 "\\Windows\\System32"
assert_unsafe "single backslash leading"         "\\foo"

# ─── Cas unsafe (traversée) ───
assert_unsafe "traversée seule"                  ".."
assert_unsafe "traversée préfixe"                "../escape.ts"
assert_unsafe "traversée milieu"                 "src/../../etc/passwd"
assert_unsafe "traversée suffixe"                "src/.."
assert_unsafe "traversée multiple"               "../../etc/passwd"

# ─── Cas unsafe (home expansion) ───
assert_unsafe "home expansion"                   "~/secrets.txt"
assert_unsafe "home + dossier"                   "~/.ssh/id_rsa"

# ─── Cas unsafe (caractères de contrôle) ───
assert_unsafe "newline dans path"                $'src\nfoo.ts'
assert_unsafe "tab dans path"                    $'src\tfoo.ts'

# ─── Cas unsafe (vide) ───
assert_unsafe "chaîne vide"                      ""

# ─── Rapport ───
total=$((pass + fail))
echo "═══ test-is-path-within-repo ═══"
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
