#!/bin/bash
# tests/unit/test-review-delta-uncommitted.sh
#
# Couvre `_lib.sh::collect_uncommitted_paths` et l'option `--committed-only`
# de `review-delta.sh`. 5 cas reproductibles :
#   1. fichier tracked modifié non commité visible
#   2. fichier staged visible
#   3. fichier untracked visible
#   4. fichier supprimé (deletion) visible avec son chemin
#   5. --committed-only n'affiche pas la section uncommitted

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

# shellcheck source=../../.ai/scripts/_lib.sh
. "$repo_root/.ai/scripts/_lib.sh"

# Setup tmp git repo
tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'review-delta-test')
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

cd "$tmp_dir"
git init -q
git config user.email test@test.test
git config user.name test
git config commit.gpgsign false

# Commit initial : 2 fichiers tracked
mkdir -p src docs
echo "tracked content" > src/tracked.txt
echo "to delete" > src/to-delete.txt
echo "doc" > docs/readme.md
git add . >/dev/null 2>&1
git commit -qm initial

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

# Cas 1 : fichier tracked modifié non commité
echo "modified content" > src/tracked.txt
output=$(collect_uncommitted_paths)
if printf '%s\n' "$output" | grep -Fxq "src/tracked.txt"; then
  pass "cas 1: tracked modifié non commité visible"
else
  fail "cas 1: src/tracked.txt manquant dans la sortie : $output"
fi

# Cas 2 : fichier staged
echo "new staged" > src/new-staged.txt
git add src/new-staged.txt
output=$(collect_uncommitted_paths)
if printf '%s\n' "$output" | grep -Fxq "src/new-staged.txt"; then
  pass "cas 2: fichier staged visible"
else
  fail "cas 2: src/new-staged.txt manquant : $output"
fi

# Cas 3 : fichier untracked
echo "untracked" > src/untracked.txt
output=$(collect_uncommitted_paths)
if printf '%s\n' "$output" | grep -Fxq "src/untracked.txt"; then
  pass "cas 3: fichier untracked visible"
else
  fail "cas 3: src/untracked.txt manquant : $output"
fi

# Cas 4 : fichier supprimé (deletion)
rm src/to-delete.txt
output=$(collect_uncommitted_paths)
if printf '%s\n' "$output" | grep -Fxq "src/to-delete.txt"; then
  pass "cas 4: deletion visible avec son chemin"
else
  fail "cas 4: src/to-delete.txt deletion manquante : $output"
fi

# Cas 5 : rename (commit le delete + add un autre, puis rename)
git add -A >/dev/null 2>&1
git commit -qm "snapshot before rename"
mv src/tracked.txt src/renamed.txt
git add -A >/dev/null 2>&1
output=$(collect_uncommitted_paths)
# Pour un rename, git status --short montre "R old -> new". On veut new.
if printf '%s\n' "$output" | grep -Fxq "src/renamed.txt"; then
  pass "cas 5: rename retourne le path nouveau"
else
  fail "cas 5: src/renamed.txt manquant : $output"
fi

# Cas 6 : path tricky avec espaces et ` -> ` (porcelain -z robuste)
echo "tricky" > "src/a -> b.txt"
echo "spaces" > "src/with spaces.txt"
output=$(collect_uncommitted_paths)
if printf '%s\n' "$output" | grep -Fxq "src/a -> b.txt"; then
  pass "cas 6: path contenant ' -> ' visible (porcelain -z)"
else
  fail "cas 6: 'src/a -> b.txt' manquant : $output"
fi
if printf '%s\n' "$output" | grep -Fxq "src/with spaces.txt"; then
  pass "cas 6b: path avec espaces visible"
else
  fail "cas 6b: 'src/with spaces.txt' manquant : $output"
fi

# Cas 7 : --committed-only de review-delta.sh n'affiche pas la section uncommitted
# E2E sur le repo source. Capture du code retour pour éviter le faux positif
# si le script échoue (Codex finding 3).
cd "$repo_root"
if ! output=$(bash .ai/scripts/review-delta.sh --committed-only 2>&1); then
  fail "cas 7: review-delta.sh --committed-only a échoué (exit ≠ 0). Sortie : $output"
elif printf '%s' "$output" | grep -Fq "Delta uncommitted"; then
  fail "cas 7: --committed-only ne devrait pas produire la section uncommitted"
elif ! printf '%s' "$output" | grep -Fq "## Review Delta"; then
  fail "cas 7: sortie ne contient pas le titre principal '## Review Delta' : $output"
else
  pass "cas 7: --committed-only produit le rapport sans section uncommitted (exit 0)"
fi

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "❌ $failures test(s) en échec"
  exit 1
fi

echo
echo "✅ tous les cas PASS (8 cas testés : 5 + rename + path tricky + --committed-only avec exit code)"
