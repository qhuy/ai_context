#!/bin/bash
# check-agent-native-context.sh -- valide le registre de support AGENTS.md natif.
#
# Usage:
#   bash .ai/scripts/check-agent-native-context.sh
#   bash .ai/scripts/check-agent-native-context.sh --require-confirmed claude

set -euo pipefail

cd "$(dirname "$0")/../.."

support_file=".ai/native-context-support.tsv"
require_agent=""

usage() {
  cat <<'EOF'
Usage: bash .ai/scripts/check-agent-native-context.sh [--file PATH] [--require-confirmed AGENT]

Valide .ai/native-context-support.tsv et bloque le collapse d'un shim agent tant
que son statut n'est pas "confirmed".
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --file)
      [[ "$#" -ge 2 ]] || { echo "✗ --file exige un chemin" >&2; exit 1; }
      support_file="$2"
      shift 2
      ;;
    --require-confirmed)
      [[ "$#" -ge 2 ]] || { echo "✗ --require-confirmed exige un agent" >&2; exit 1; }
      require_agent="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "✗ argument inconnu: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

fail() {
  echo "✗ $*" >&2
  exit 1
}

[[ -f "$support_file" ]] || fail "registre introuvable: $support_file"

echo "═══ check-agent-native-context ═══"
echo "registre: $support_file"

line_no=0
records=0
require_seen=0
require_status=""

while IFS=$'\t' read -r agent entrypoint status checked_at evidence note extra; do
  line_no=$((line_no + 1))

  [[ -z "${agent//[[:space:]]/}" ]] && continue
  [[ "${agent:0:1}" == "#" ]] && continue

  [[ -z "${extra:-}" ]] || fail "ligne $line_no: trop de colonnes"
  [[ -n "${note:-}" ]] || fail "ligne $line_no: note manquante"

  case "$agent" in
    claude|codex|cursor|gemini|copilot) ;;
    *) fail "ligne $line_no: agent inconnu '$agent'" ;;
  esac

  [[ "$entrypoint" == "AGENTS.md" ]] || fail "ligne $line_no: shared_entrypoint doit etre AGENTS.md"

  case "$status" in
    confirmed|pending|unsupported) ;;
    *) fail "ligne $line_no: status invalide '$status'" ;;
  esac

  [[ "$checked_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] \
    || fail "ligne $line_no: checked_at doit etre YYYY-MM-DD"
  [[ "$evidence" =~ ^https:// ]] \
    || fail "ligne $line_no: evidence doit etre une URL https"

  records=$((records + 1))
  printf '  ✓ %s: %s (%s, checked_at=%s)\n' "$agent" "$status" "$entrypoint" "$checked_at"

  if [[ -n "$require_agent" && "$agent" == "$require_agent" ]]; then
    require_seen=1
    require_status="$status"
  fi
done < "$support_file"

[[ "$records" -gt 0 ]] || fail "registre vide: $support_file"

if [[ -n "$require_agent" ]]; then
  [[ "$require_seen" -eq 1 ]] || fail "agent absent du registre: $require_agent"
  if [[ "$require_status" != "confirmed" ]]; then
    echo "✗ $require_agent non confirme (status=$require_status) ; conserver le shim dedie" >&2
    exit 2
  fi
  printf '  ✓ %s confirme pour AGENTS.md natif\n' "$require_agent"
fi

echo
echo "✅ PASS"
