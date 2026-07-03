#!/bin/bash
# check-knowledge.sh — Valide un hub knowledge Git/Markdown.
#
# Usage:
#   bash .ai/scripts/check-knowledge.sh [hub_root]
#
# Par défaut, hub_root=. ; le script scanne hub_root/knowledge/*/*.md.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"
# shellcheck source=_knowledge.sh
. "$script_dir/_knowledge.sh"

require_cmd jq

usage() {
  sed -n '1,9p' "$0" | sed 's/^# \{0,1\}//'
}

hub_root="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ "$hub_root" == "." ]]; then
        hub_root="$1"
      else
        echo "Argument inconnu: $1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
  shift
done

if [[ ! -d "$hub_root" ]]; then
  echo "❌ hub introuvable: $hub_root" >&2
  exit 1
fi
hub_root="$(cd "$hub_root" && pwd)"
schema_file="$script_dir/../schema/knowledge.schema.json"

echo "═══ check-knowledge ═══"

if [[ ! -f "$schema_file" ]]; then
  echo "  ✗ schema manquant : .ai/schema/knowledge.schema.json" >&2
  exit 1
fi
if ! jq -e . "$schema_file" >/dev/null 2>&1; then
  echo "  ✗ schema invalide : .ai/schema/knowledge.schema.json" >&2
  exit 1
fi
echo "  ✓ schema knowledge présent"

fail=0
count=0

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  count=$((count + 1))
  rel="$(knowledge_rel_path "$file" "$hub_root")"
  set +e
  issues="$(knowledge_validate_file "$file" "$hub_root" 2>&1)"
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]]; then
    echo "  ✓ $rel"
  else
    while IFS= read -r issue; do
      [[ -n "$issue" ]] && echo "  ✗ $issue" >&2
    done <<EOF
$issues
EOF
    fail=1
  fi
done < <(knowledge_find_files "$hub_root")

if [[ "$count" -eq 0 ]]; then
  echo "  ✓ aucune connaissance à valider"
fi

if [[ -f "$hub_root/index.json" ]]; then
  set +e
  generated="$(bash "$script_dir/build-knowledge-index.sh" "$hub_root" 2>&1)"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    echo "  ✗ index.json non vérifiable : build-knowledge-index échoue" >&2
    echo "$generated" >&2
    fail=1
  else
    existing_contract="$(jq -S 'del(.generated_at)' "$hub_root/index.json")"
    generated_contract="$(printf '%s\n' "$generated" | jq -S 'del(.generated_at)')"
    if [[ "$existing_contract" != "$generated_contract" ]]; then
      echo "  ✗ index.json n'est pas synchronisé (relancer build-knowledge-index.sh --write)" >&2
      fail=1
    else
      echo "  ✓ index.json synchronisé"
    fi
  fi
fi

echo
if [[ "$fail" -eq 0 ]]; then
  echo "✅ PASS ($count connaissance(s))"
  exit 0
else
  echo "❌ FAIL" >&2
  exit 1
fi
