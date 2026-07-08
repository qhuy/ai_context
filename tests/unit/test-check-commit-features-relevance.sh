#!/bin/bash
# test-check-commit-features-relevance.sh — workflow/git-hooks + quality/doc-freshness.
#
# Un commit feat: ne doit pas passer seulement parce qu'une fiche quelconque est
# staged. La fiche/worklog staged doit couvrir au moins un fichier non-doc du
# commit via touches:.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-commit-relevance.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/back" "$tmp/src"
for s in check-commit-features.sh check-feature-freshness.sh build-feature-index.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "commit-relevance-test"\n' > "$tmp/.ai/config.yml"

cat > "$tmp/.docs/features/back/real.md" <<'MD'
---
id: real
scope: back
title: Real
status: active
type: feature
depends_on: []
touches:
  - src/app.ts
---
# Real
MD

cat > "$tmp/.docs/features/back/unrelated.md" <<'MD'
---
id: unrelated
scope: back
title: Unrelated
status: active
type: feature
depends_on: []
touches:
  - src/other.ts
---
# Unrelated
MD

printf '# Real worklog\n' > "$tmp/.docs/features/back/real.worklog.md"

(
  cd "$tmp"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  git config core.hooksPath /dev/null
  printf 'seed\n' > src/app.ts
  printf 'seed\n' > src/other.ts
  git add -A >/dev/null
  git commit -qm "chore: seed"

  printf 'changed\n' > src/app.ts
  printf '\n- unrelated doc\n' >> .docs/features/back/unrelated.md
  git add src/app.ts .docs/features/back/unrelated.md >/dev/null
  set +e
  out="$(CLAUDE_COMMIT_MSG="feat: wrong feature doc" bash .ai/scripts/check-commit-features.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || fail "feat: avec fiche sans rapport aurait dû être refusé"
  echo "$out" | grep -q "aucune ne couvre" \
    || fail "message attendu absent pour fiche sans rapport"

  git reset -q
  git checkout -q -- src/app.ts .docs/features/back/unrelated.md

  printf 'changed\n' > src/app.ts
  printf '\n- real doc\n' >> .docs/features/back/real.md
  git add src/app.ts .docs/features/back/real.md >/dev/null
  CLAUDE_COMMIT_MSG="feat: real feature doc" bash .ai/scripts/check-commit-features.sh >/dev/null

  git reset -q
  git checkout -q -- src/app.ts .docs/features/back/real.md

  printf 'changed via worklog\n' > src/app.ts
  printf '\n- real worklog\n' >> .docs/features/back/real.worklog.md
  git add src/app.ts .docs/features/back/real.worklog.md >/dev/null
  CLAUDE_COMMIT_MSG="feat: real feature worklog" bash .ai/scripts/check-commit-features.sh >/dev/null

  printf 'message invalide via fichier\n' > msg.txt
  payload='{"tool_name":"Bash","tool_input":{"command":"git commit -F msg.txt"}}'
  set +e
  out="$(printf '%s\n' "$payload" | bash .ai/scripts/check-commit-features.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || fail "PreToolUse git commit -F aurait dû extraire et refuser le message invalide"

  payload='{"tool_name":"Bash","tool_input":{"command":"git commit --message=\"message invalide via option\""}}'
  set +e
  out="$(printf '%s\n' "$payload" | bash .ai/scripts/check-commit-features.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || fail "PreToolUse git commit --message= aurait dû extraire et refuser le message invalide"

  # AGT-7 : couverture élargie des formes non exercées ci-dessus, + régression
  # P1 (ordre des elif -m avant --message=). Index propre pour ne pas dépendre
  # du staging laissé par les blocs précédents.
  git reset -q
  run_check() {
    jq -nc --arg cmd "$1" '{tool_name: "Bash", tool_input: {command: $cmd}}' \
      | bash .ai/scripts/check-commit-features.sh >/dev/null 2>&1
  }

  set +e; run_check 'git commit -F "msg.txt"'; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "-F \"msg.txt\" (quoté double) aurait dû être extrait et refusé"

  set +e; run_check "git commit -F 'msg.txt'"; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "-F 'msg.txt' (quoté simple) aurait dû être extrait et refusé"

  set +e; run_check "git commit -F $tmp/msg.txt"; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "-F <chemin absolu> aurait dû être extrait et refusé"

  printf 'fix: valide via -F collé\n' > glued.txt
  set +e; run_check "git commit -Fglued.txt"; rc=$?; set -e
  [[ "$rc" -eq 0 ]] || fail "-Fglued.txt (forme collée sans espace) aurait dû être extrait et accepté"

  set +e; run_check "git commit --file=msg.txt"; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "--file=msg.txt aurait dû être extrait et refusé"

  set +e; run_check "git commit --file='msg.txt'"; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "--file='msg.txt' aurait dû être extrait et refusé"

  set +e; run_check 'git commit --file="msg.txt"'; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "--file=\"msg.txt\" aurait dû être extrait et refusé"

  set +e; run_check "git commit --file msg.txt"; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "--file msg.txt (espace) aurait dû être extrait et refusé"

  set +e; run_check "git commit --message='message invalide via option simple'"; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "--message='...' (quoté simple) aurait dû être extrait et refusé"

  set +e; run_check "git commit --message=invalidemessage"; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || fail "--message=... (bare, sans espace) aurait dû être extrait et refusé"

  # Régression P1 : un -m "..." valide contenant littéralement --message= ne
  # doit pas être mal-extrait par la branche --message= (ordre des elif).
  set +e; run_check 'git commit -m "fix: gérer --message=... et -F dans check-commit-features"'; rc=$?; set -e
  [[ "$rc" -eq 0 ]] || fail "-m \"...--message=...\" valide aurait dû être accepté (régression P1)"
)

echo "✅ test-check-commit-features-relevance PASS"
