#!/bin/bash
# test-agent-native-context.sh -- core/agents-md-native-collapse-path.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-native-context.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

script="$repo_root/.ai/scripts/check-agent-native-context.sh"

out="$(cd "$repo_root" && bash "$script")"
echo "$out" | grep -q "claude: pending" \
  || { echo "$out"; fail "registre par defaut: statut claude pending attendu"; }

set +e
out="$(cd "$repo_root" && bash "$script" --require-confirmed claude 2>&1)"
rc=$?
set -e
[[ "$rc" -eq 2 ]] || { echo "$out"; fail "--require-confirmed claude doit echouer tant que le statut est pending"; }
echo "$out" | grep -q "conserver le shim dedie" \
  || { echo "$out"; fail "message de conservation du shim attendu"; }

confirmed="$tmp/confirmed.tsv"
cat > "$confirmed" <<'TSV'
# agent	shared_entrypoint	status	checked_at	evidence	note
claude	AGENTS.md	confirmed	2026-07-03	https://example.invalid/claude-agents-md	Signal externe confirme.
TSV

out="$(cd "$repo_root" && bash "$script" --file "$confirmed" --require-confirmed claude)"
echo "$out" | grep -q "claude confirme" \
  || { echo "$out"; fail "cas confirme: validation attendue"; }

bad="$tmp/bad.tsv"
cat > "$bad" <<'TSV'
# agent	shared_entrypoint	status	checked_at	evidence	note
claude	AGENTS.md	maybe	2026-07-03	https://example.invalid/claude-agents-md	Statut invalide.
TSV

set +e
out="$(cd "$repo_root" && bash "$script" --file "$bad" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "status invalide doit echouer"; }
echo "$out" | grep -q "status invalide" \
  || { echo "$out"; fail "message status invalide attendu"; }

echo "✅ test-agent-native-context PASS"
