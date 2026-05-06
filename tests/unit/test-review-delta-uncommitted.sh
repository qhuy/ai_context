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

# Cas 6 : --committed-only de review-delta.sh n'affiche pas la section uncommitted
# (Test E2E sur le repo source : on ne lance pas review-delta.sh dans le tmp
# car il dépend de l'index feature. On teste directement la sortie sur le
# repo réel avec --committed-only et vérifie l'absence de la section.)
cd "$repo_root"
output=$(bash .ai/scripts/review-delta.sh --committed-only 2>/dev/null)
if printf '%s' "$output" | grep -Fq "Delta uncommitted"; then
  fail "cas 6: --committed-only ne devrait pas produire la section uncommitted"
else
  pass "cas 6: --committed-only n'affiche pas la section uncommitted"
fi

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "❌ $failures test(s) en échec"
  exit 1
fi

echo
echo "✅ tous les cas PASS (6 cas testés)"
