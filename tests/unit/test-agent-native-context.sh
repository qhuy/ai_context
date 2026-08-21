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

copilot_line="$(awk -F '\t' '$1 == "copilot" { print; exit }' "$repo_root/.ai/native-context-support.tsv")"
IFS=$'\t' read -r copilot_agent copilot_entrypoint copilot_status copilot_checked copilot_evidence copilot_note <<< "$copilot_line"
[[ "$copilot_status" == "confirmed" && "$copilot_checked" == "2026-08-21" ]] \
  || fail "registre Copilot: statut confirmed et preuve reverifiee le 2026-08-21 attendus"
[[ "$copilot_evidence" == "https://github.blog/changelog/2026-06-18-copilot-code-review-agents-md-support-and-ui-improvements/" ]] \
  || fail "registre Copilot: preuve officielle Code Review inattendue"
[[ "$copilot_note" == *"Code Review lit AGENTS.md"* && "$copilot_note" == *"canal distinct"* ]] \
  || fail "registre Copilot: la note doit distinguer AGENTS.md natif et shim specifique"
grep -qF "Copilot coding agent et Copilot Code Review lisent AGENTS.md nativement" "$repo_root/copier.yml" \
  || fail "aide Copier: support AGENTS.md natif du coding agent et de Code Review absent"
grep -qF "consignes spécifiques à Copilot" "$repo_root/copier.yml" \
  || fail "aide Copier: valeur residuelle du shim Copilot non expliquee"
if grep -qF "Chat/review IDE qui lisent encore ce fichier" "$repo_root/copier.yml"; then
  fail "aide Copier: ancienne affirmation perimee encore presente"
fi

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

dup="$tmp/dup.tsv"
cat > "$dup" <<'TSV'
# agent	shared_entrypoint	status	checked_at	evidence	note
copilot	AGENTS.md	confirmed	2026-07-06	https://example.invalid/a	Confirme.
copilot	AGENTS.md	pending	2026-07-07	https://example.invalid/b	Downgrade en doublon au lieu d'editer.
TSV

set +e
out="$(cd "$repo_root" && bash "$script" --file "$dup" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "$out"; fail "agent en doublon doit echouer (sinon native_confirmed prend la ligne confirmed perimee)"; }
echo "$out" | grep -q "doublon" \
  || { echo "$out"; fail "message de doublon attendu"; }

echo "✅ test-agent-native-context PASS"
