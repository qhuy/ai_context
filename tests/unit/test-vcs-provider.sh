#!/bin/bash
# Non-regression: abstraction VCS Git/TFVC.

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

# shellcheck source=../../.ai/scripts/_vcs.sh
. "$repo_root/.ai/scripts/_vcs.sh"

tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'vcs-provider-test')
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

workspace="$tmp_dir/workspace"
fake_bin="$tmp_dir/bin"
mkdir -p "$workspace/.ai" "$workspace/src" "$workspace/docs" "$fake_bin"
printf '# test index\n' > "$workspace/.ai/index.md"
printf 'content\n' > "$workspace/src/app.cs"
printf 'content\n' > "$workspace/docs/feature spec.md"

cat > "$fake_bin/tf" <<'FAKE_TF'
#!/bin/sh
case "$1" in
  status)
    root="$AI_CONTEXT_FAKE_TFVC_ROOT"
    cat <<EOF
$/Project/src/app.cs
  Change: edit
  Local item: $root/src/app.cs

$/Project/docs/feature spec.md
  Change: add
  Local item: $root/docs/feature spec.md
EOF
    ;;
  *) exit 1 ;;
esac
FAKE_TF
chmod +x "$fake_bin/tf"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

PATH="$fake_bin:$PATH"
export PATH
export AI_CONTEXT_REPO_ROOT="$workspace"
export AI_CONTEXT_FAKE_TFVC_ROOT="$workspace"

cd "$workspace" || exit 1

unset AI_CONTEXT_VCS_PROVIDER
cat > .ai/config.yml <<'YAML'
vcs:
  provider: tfvc
YAML

if [[ "$(vcs_provider)" == "tfvc" ]]; then
  pass "config.yml selectionne tfvc"
else
  fail "provider attendu=tfvc, obtenu=$(vcs_provider)"
fi

if [[ "$(vcs_root)" == "$workspace" ]]; then
  pass "racine TFVC resolue"
else
  fail "racine TFVC incorrecte: $(vcs_root)"
fi

if vcs_has_staging_area; then
  fail "tfvc ne doit pas declarer de staging area"
else
  pass "tfvc sans staging area"
fi

pending="$(vcs_pending_paths)"
if printf '%s\n' "$pending" | grep -Fxq "src/app.cs"; then
  pass "pending TFVC: fichier code"
else
  fail "src/app.cs absent des pending: $pending"
fi

if printf '%s\n' "$pending" | grep -Fxq "docs/feature spec.md"; then
  pass "pending TFVC: chemin avec espace"
else
  fail "docs/feature spec.md absent des pending: $pending"
fi

staged="$(vcs_staged_paths)"
if [[ "$staged" == "$pending" && "$(vcs_staged_label)" == "pending" ]]; then
  pass "staged alias pending en TFVC"
else
  fail "alias staged TFVC incorrect: label=$(vcs_staged_label), staged=$staged"
fi

export AI_CONTEXT_VCS_PROVIDER=none
if [[ "$(vcs_provider)" == "none" && -z "$(vcs_pending_paths)" ]]; then
  pass "provider none silencieux"
else
  fail "provider none devrait etre silencieux"
fi

if [[ "$failures" -gt 0 ]]; then
  echo "$failures échec(s)" >&2
  exit 1
fi

echo "OK"
