#!/bin/bash
# build-knowledge-index.sh — Génère l'index JSON d'un hub knowledge.
#
# Usage:
#   bash .ai/scripts/build-knowledge-index.sh [--write] [hub_root]
#
# Par défaut, écrit le JSON sur stdout. Avec --write, écrit hub_root/index.json.

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

write=0
hub_root="."
hub_set=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --write)
      write=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ "$hub_set" -eq 0 ]]; then
        hub_root="$1"
        hub_set=1
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

knowledge_file_to_json() {
  local file="$1"
  local rel id type title summary source_project owner confidence checked_at sensitivity status freshness_status
  local source_refs_json usable_by_json
  rel="$(knowledge_rel_path "$file" "$hub_root")"
  id="$(knowledge_fm_scalar "$file" id)"
  type="$(knowledge_fm_scalar "$file" type)"
  title="$(knowledge_fm_scalar "$file" title)"
  summary="$(knowledge_fm_scalar "$file" summary)"
  source_project="$(knowledge_fm_scalar "$file" source_project)"
  owner="$(knowledge_fm_scalar "$file" owner)"
  confidence="$(knowledge_fm_scalar "$file" confidence)"
  checked_at="$(knowledge_fm_nested_scalar "$file" freshness checked_at)"
  freshness_status="$(knowledge_fm_nested_scalar "$file" freshness status)"
  sensitivity="$(knowledge_fm_scalar "$file" sensitivity)"
  status="$(knowledge_fm_scalar "$file" status)"
  source_refs_json="$(knowledge_fm_list "$file" source_refs | jq -R . | jq -s .)"
  usable_by_json="$(knowledge_fm_list "$file" usable_by | jq -R . | jq -s .)"

  jq -n \
    --arg id "$id" \
    --arg type "$type" \
    --arg title "$title" \
    --arg summary "$summary" \
    --arg source_project "$source_project" \
    --arg owner "$owner" \
    --arg confidence "$confidence" \
    --arg checked_at "$checked_at" \
    --arg freshness_status "$freshness_status" \
    --arg sensitivity "$sensitivity" \
    --arg status "$status" \
    --arg path "$rel" \
    --argjson source_refs "$source_refs_json" \
    --argjson usable_by "$usable_by_json" '
      {
        id: $id,
        type: $type,
        title: $title,
        summary: $summary,
        source_project: $source_project,
        owner: $owner,
        confidence: $confidence,
        freshness: ({checked_at: $checked_at} + (if $freshness_status == "" then {} else {status: $freshness_status} end)),
        sensitivity: $sensitivity,
        source_refs: $source_refs,
        usable_by: $usable_by,
        status: $status,
        path: $path,
        uri: ("knowledge://" + $source_project + "/" + $id)
      }
    '
}

generate_index() {
  local objects_file generated_at file issues
  objects_file="$(mktemp "${TMPDIR:-/tmp}/aic-knowledge-objects.XXXXXX")"
  trap 'rm -f "$objects_file"' RETURN

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    set +e
    issues="$(knowledge_validate_file "$file" "$hub_root" 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      echo "$issues" >&2
      return 1
    fi
    knowledge_file_to_json "$file" >> "$objects_file"
  done < <(knowledge_find_files "$hub_root")

  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  jq -s \
    --arg schema_version "$KNOWLEDGE_SCHEMA_VERSION" \
    --arg generated_at "$generated_at" '
      {
        schema_version: $schema_version,
        generated_at: $generated_at,
        knowledge: .
      }
    ' "$objects_file"
}

if [[ "$write" -eq 0 ]]; then
  generate_index
  exit 0
fi

output="$hub_root/index.json"
tmp_output="$(mktemp "${TMPDIR:-/tmp}/aic-knowledge-index.XXXXXX")"
trap 'rm -f "$tmp_output"' EXIT
generate_index > "$tmp_output"

if [[ -f "$output" ]]; then
  existing_contract="$(jq -S 'del(.generated_at)' "$output" 2>/dev/null || true)"
  new_contract="$(jq -S 'del(.generated_at)' "$tmp_output")"
  if [[ -n "$existing_contract" && "$existing_contract" == "$new_contract" ]]; then
    echo "index inchangé : ${output#$hub_root/}"
    exit 0
  fi
fi

mv "$tmp_output" "$output"
echo "index écrit : ${output#$hub_root/}"
