#!/bin/bash
# check-agent-config.sh — Valide les configs agents sans modifier le repo.
#
# Vérifie :
#   - .claude/settings.json si présent : JSON valide, hooks attendus, commandes
#     avec timeout et scripts référencés existants.
#   - .codex/* si présent : références vers .ai/scripts/*.sh existantes et
#     signaux de risque documentés en warning.
#
# Usage : bash .ai/scripts/check-agent-config.sh

set -euo pipefail

cd "$(dirname "$0")/../.."

fail=0
warn_count=0

ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1" >&2; warn_count=$((warn_count + 1)); }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; fail=1; }

extract_script_refs() {
  printf '%s\n' "$1" \
    | grep -oE '(\./)?\.ai/scripts/[A-Za-z0-9._/-]+\.sh' \
    | sed 's#^\./##' \
    | sort -u || true
}

check_command_refs() {
  local label="$1"
  local command_text="$2"
  local refs ref found=0
  refs="$(extract_script_refs "$command_text")"
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    found=1
    if [[ -f "$ref" ]]; then
      ok "$label référence $ref"
    else
      ko "$label référence un script absent : $ref"
    fi
  done <<< "$refs"
  if [[ "$found" -eq 0 ]]; then
    warn "$label ne référence aucun script .ai/scripts/*.sh versionné"
  fi
}

echo "═══ check-agent-config ═══"

if [[ -f ".claude/settings.json" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    ko "jq requis pour valider .claude/settings.json"
  elif ! jq empty .claude/settings.json >/dev/null 2>&1; then
    ko ".claude/settings.json n'est pas un JSON valide"
  else
    ok ".claude/settings.json JSON valide"

    if jq -e '.hooks? | type == "object"' .claude/settings.json >/dev/null 2>&1; then
      ok ".claude/settings.json contient hooks"
    else
      ko ".claude/settings.json ne contient pas hooks objet"
    fi

    expected_hooks="UserPromptSubmit PreToolUse PostToolUse Stop"
    for hook_name in $expected_hooks; do
      if jq -e --arg h "$hook_name" '.hooks[$h]? | type == "array" and length > 0' .claude/settings.json >/dev/null 2>&1; then
        ok "hook Claude présent : $hook_name"
      else
        ko "hook Claude manquant ou vide : $hook_name"
      fi
    done

    while IFS=$'\t' read -r command_text timeout_value; do
      [[ -z "$command_text" ]] && { ko "hook Claude command vide"; continue; }
      if [[ -z "$timeout_value" || ! "$timeout_value" =~ ^[0-9]+$ || "$timeout_value" -le 0 ]]; then
        ko "hook Claude sans timeout positif : $command_text"
      else
        ok "timeout hook Claude OK (${timeout_value}s)"
      fi
      check_command_refs "hook Claude" "$command_text"
    done < <(jq -r '.. | objects | select(.type? == "command") | [.command // "", (.timeout // "")] | @tsv' .claude/settings.json)
  fi
else
  ok "aucune config Claude à valider"
fi

codex_files=""
if [[ -d ".codex" ]]; then
  while IFS= read -r f; do
    codex_files+="$f"$'\n'
  done < <(find .codex -maxdepth 2 -type f \( -name '*.json' -o -name '*.toml' -o -name '*.yaml' -o -name '*.yml' \) | sort)
fi

if [[ -z "$codex_files" ]]; then
  ok "aucune config Codex à valider"
else
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    ok "config Codex détectée : $file"

    if [[ "$file" == *.json ]]; then
      if ! command -v jq >/dev/null 2>&1; then
        ko "jq requis pour valider $file"
        continue
      fi
      if ! jq empty "$file" >/dev/null 2>&1; then
        ko "$file n'est pas un JSON valide"
        continue
      fi
      while IFS= read -r command_text; do
        [[ -n "$command_text" ]] && check_command_refs "$file" "$command_text"
      done < <(jq -r '.. | objects | (.command? // .cmd? // empty)' "$file")
    else
      while IFS= read -r command_text; do
        [[ -n "$command_text" ]] && check_command_refs "$file" "$command_text"
      done < <(awk '
        /^[[:space:]]*(command|cmd)[[:space:]]*=/ {
          line=$0
          sub(/^[^=]*=[[:space:]]*/, "", line)
          gsub(/^["'\''"]|["'\''"][[:space:]]*$/, "", line)
          print line
        }
      ' "$file")
    fi
  done <<< "$codex_files"

  if grep -RiqE 'auto[-_]?review|additionalContext|prompt_hook|agent_hook|llm' .codex 2>/dev/null; then
    warn ".codex contient des signaux non déterministes ou injection contexte ; ne pas les traiter comme garanties"
  fi
fi

echo
if [[ "$fail" -eq 0 ]]; then
  if [[ "$warn_count" -gt 0 ]]; then
    echo "⚠️  PASS avec $warn_count warning(s)"
  else
    echo "✅ PASS"
  fi
  exit 0
else
  echo "❌ FAIL"
  exit 1
fi
