#!/bin/bash
# Non-regression targets from AI Debate 0013/Q4.

set -euo pipefail

cd "$(dirname "$0")/../.."

tmp="$(mktemp -d /tmp/aic-targeted-regressions-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

copy_repo() {
  local name="$1"
  rsync -a --delete \
    --exclude='.git' \
    --exclude='.ai/.feature-index.json' \
    --exclude='.ai/.progress-history.jsonl' \
    --exclude='.ai/.session-edits.log' \
    --exclude='.ai/.session-edits.flushed' \
    --exclude='.ai/.context-relevance.jsonl' \
    --exclude='.ai/.context-relevance.jsonl.old' \
    ./ "$tmp/$name/"
}

require_copier_or_skip() {
  if ! command -v copier >/dev/null 2>&1; then
    echo "⚠ copier introuvable, tests Copier ciblés ignorés"
    return 1
  fi
  return 0
}

echo "═══ test-targeted-regressions ═══"

copy_repo "fallback"
(
  cd "$tmp/fallback"
  mkdir -p .docs/features/back
  cat > .docs/features/back/fallback.md <<'FEAT'
---
id: fallback
scope: back
title: Fallback parser
status: active
depends_on: []
touches:
  - src/**
touches_shared:
  - README.md
product:
  initiative: product/foo
external_refs:
  ticket: Q4
progress:
  phase: implement
  step: fallback check
  blockers:
    - waiting
  resume_hint: continue fallback
  updated: 2026-05-12
---
# Fallback parser
FEAT
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash .ai/scripts/build-feature-index.sh --write >/dev/null
  jq -e '
    .features[]
    | select(.id == "fallback")
    | .touches == ["src/**"]
      and .touches_shared == ["README.md"]
      and .depends_on == []
      and .product.initiative == "product/foo"
      and .external_refs.ticket == "Q4"
      and .progress.phase == "implement"
      and .progress.blockers == ["waiting"]
  ' .ai/.feature-index.json >/dev/null
)
echo "  ✓ build-feature-index fallback sans yq"

copy_repo "commit"
(
  cd "$tmp/commit"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  mkdir -p src .docs/features/back
  printf 'seed\n' > src/app.txt
  cat > .docs/features/back/commit-message.md <<'FEAT'
---
id: commit-message
scope: back
title: Commit message
status: active
depends_on: []
touches:
  - src/**
progress:
  phase: implement
  step: test
  blockers: []
  resume_hint: test
  updated: 2026-05-12
---
# Commit message
FEAT
  git add src/app.txt .docs/features/back/commit-message.md >/dev/null
  git -c core.hooksPath=/dev/null commit -q -m "chore: seed"

  printf 'changed\n' > src/app.txt
  printf '\n- q4\n' >> .docs/features/back/commit-message.md
  git add src/app.txt .docs/features/back/commit-message.md >/dev/null

  cmd=$'git commit -m "$(cat <<'\''EOF'\''\nfeat: heredoc message\n\nbody\nEOF\n)"'
  jq -nc --arg cmd "$cmd" '{tool_name:"Bash", tool_input:{command:$cmd}}' \
    | bash .ai/scripts/check-commit-features.sh >/dev/null

  cmd=$'git commit -m "fix: multiline message\n\nbody"'
  jq -nc --arg cmd "$cmd" '{tool_name:"Bash", tool_input:{command:$cmd}}' \
    | bash .ai/scripts/check-commit-features.sh >/dev/null
)
echo "  ✓ check-commit-features heredoc et message multiligne"

copy_repo "lock"
(
  cd "$tmp/lock"
  lock_dir="$tmp/held-lock"
  marker="$tmp/lock-ran"
  mkdir "$lock_dir"
  set +e
  AI_CONTEXT_LOCK_DIR="$lock_dir" bash -c '. .ai/scripts/_lib.sh; with_index_lock touch "$1"' _ "$marker" >/dev/null 2>&1
  rc=$?
  set -e
  if [[ "$rc" -eq 0 || -e "$marker" ]]; then
    echo "✗ with_index_lock doit échouer sans exécuter la commande si le lock est tenu"
    exit 1
  fi
)
echo "  ✓ with_index_lock timeout sans exécution"

if require_copier_or_skip; then
  copy_repo "dogfood"
  (
    cd "$tmp/dogfood"
    printf '\n# q4 drift\n' >> template/.ai/scripts/_lib.sh.jinja
    out="$(bash .ai/scripts/check-dogfood-drift.sh 2>&1 || true)"
    if ! echo "$out" | grep -q "drift: .ai/_lib.sh\\|drift: .ai/scripts/_lib.sh"; then
      echo "✗ check-dogfood-drift doit détecter un drift .jinja runtime"
      echo "$out"
      exit 1
    fi
  )
  echo "  ✓ check-dogfood-drift détecte un drift .jinja"

  copy_repo "modes"
  (
    cd "$tmp/modes"
    out_standard="$tmp/mode-standard"
    out_lite="$tmp/mode-lite"
    out_strict="$tmp/mode-strict"
    copier copy --defaults --trust --data project_name=standard --data adoption_mode=standard . "$out_standard" >/dev/null
    [[ -d "$out_standard/.githooks" && -d "$out_standard/.github/workflows" ]]
    copier copy --defaults --trust --data project_name=lite --data adoption_mode=lite . "$out_lite" >/dev/null
    [[ ! -d "$out_lite/.githooks" && ! -d "$out_lite/.github/workflows" ]]
    copier copy --defaults --trust --data project_name=strict --data adoption_mode=strict --data enable_ci_guard=false . "$out_strict" >/dev/null
    [[ -d "$out_strict/.githooks" && -d "$out_strict/.github/workflows" ]]
  )
  echo "  ✓ modes adoption standard/lite/strict"
fi

echo "✅ test-targeted-regressions PASS"
