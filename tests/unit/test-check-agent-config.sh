#!/bin/bash
# Non-regression: check-agent-config validates present agent configs without requiring them.

set -euo pipefail

cd "$(dirname "$0")/../.."

tmp="$(mktemp -d /tmp/aic-agent-config-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

make_repo() {
  local d="$1"
  mkdir -p "$d/.ai/scripts"
  cp .ai/scripts/check-agent-config.sh "$d/.ai/scripts/check-agent-config.sh"
  chmod +x "$d/.ai/scripts/check-agent-config.sh"
}

repo_empty="$tmp/empty"
make_repo "$repo_empty"
if ! ( cd "$repo_empty" && bash .ai/scripts/check-agent-config.sh ) >/dev/null; then
  echo "✗ check-agent-config doit passer sans config agent"
  exit 1
fi

repo_claude="$tmp/claude"
make_repo "$repo_claude"
mkdir -p "$repo_claude/.claude"
touch "$repo_claude/.ai/scripts/pre-turn-reminder.sh"
touch "$repo_claude/.ai/scripts/check-commit-features.sh"
touch "$repo_claude/.ai/scripts/features-for-path.sh"
touch "$repo_claude/.ai/scripts/auto-worklog-log.sh"
touch "$repo_claude/.ai/scripts/auto-worklog-flush.sh"
cat > "$repo_claude/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/pre-turn-reminder.sh --format=json", "timeout": 5}]}],
    "PreToolUse": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/check-commit-features.sh", "timeout": 5}, {"type": "command", "command": "bash .ai/scripts/features-for-path.sh", "timeout": 3}]}],
    "PostToolUse": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/auto-worklog-log.sh", "timeout": 3}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/auto-worklog-flush.sh", "timeout": 5}]}]
  }
}
JSON
if ! ( cd "$repo_claude" && bash .ai/scripts/check-agent-config.sh ) >/dev/null; then
  echo "✗ check-agent-config doit accepter une config Claude valide"
  ( cd "$repo_claude" && bash .ai/scripts/check-agent-config.sh )
  exit 1
fi

repo_bad="$tmp/bad"
make_repo "$repo_bad"
mkdir -p "$repo_bad/.claude"
cat > "$repo_bad/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/missing.sh", "timeout": 5}]}],
    "PreToolUse": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/missing.sh", "timeout": 5}]}],
    "PostToolUse": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/missing.sh", "timeout": 3}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "bash .ai/scripts/missing.sh", "timeout": 5}]}]
  }
}
JSON
if ( cd "$repo_bad" && bash .ai/scripts/check-agent-config.sh ) >/dev/null 2>&1; then
  echo "✗ check-agent-config doit refuser un script Claude absent"
  exit 1
fi

repo_codex="$tmp/codex"
make_repo "$repo_codex"
mkdir -p "$repo_codex/.codex"
touch "$repo_codex/.ai/scripts/check-commit-features.sh"
cat > "$repo_codex/.codex/hooks.toml" <<'TOML'
[[hooks]]
command = "bash .ai/scripts/check-commit-features.sh"
TOML
if ! ( cd "$repo_codex" && bash .ai/scripts/check-agent-config.sh ) >/dev/null; then
  echo "✗ check-agent-config doit accepter une config Codex référencée vers un script existant"
  ( cd "$repo_codex" && bash .ai/scripts/check-agent-config.sh )
  exit 1
fi

cat > "$repo_codex/.codex/hooks.toml" <<'TOML'
[[hooks]]
command = "bash .ai/scripts/missing.sh"
TOML
if ( cd "$repo_codex" && bash .ai/scripts/check-agent-config.sh ) >/dev/null 2>&1; then
  echo "✗ check-agent-config doit refuser un script Codex absent"
  exit 1
fi

echo "✅ test-check-agent-config PASS"
