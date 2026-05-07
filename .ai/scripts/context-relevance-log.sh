#!/bin/bash
# context-relevance-log.sh — Logger best-effort pour le tracker de pertinence.
#
# Sous-commandes :
#   inject  <tool_name> <file> <direct_json> <dep_json> <injected_json> \
#           <unsupported_json> <truncated> <budget> <index_mtime> \
#           <matcher_policy> <omitted_count> <top_k>
#   touch   <tool_name> <file> <touched_json>
#   summary (agrège tous les events depuis le dernier summary)
#
# Format JSONL append dans .ai/.context-relevance.jsonl. Rotation 10 MB.
# Best-effort total : exit 0 toujours, erreurs silencieuses (jq absent,
# disque plein, JSONL corrompu, etc. ne bloquent JAMAIS un hook).
#
# Désactivable via AI_CONTEXT_RELEVANCE_DISABLED=1.

set -uo pipefail

[[ "${AI_CONTEXT_RELEVANCE_DISABLED:-0}" == "1" ]] && exit 0

script_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd 2>/dev/null)" || exit 0
repo_root="$(cd "$script_dir/../.." 2>/dev/null && pwd 2>/dev/null)" || exit 0
log_file="$repo_root/.ai/.context-relevance.jsonl"
rotation_mb="${AI_CONTEXT_RELEVANCE_ROTATION_MB:-10}"
[[ "$rotation_mb" =~ ^[0-9]+$ ]] || rotation_mb=10
rotation_bytes=$((rotation_mb * 1024 * 1024))

rotate_if_needed() {
  [[ -f "$log_file" ]] || return 0
  local size
  size=$(wc -c < "$log_file" 2>/dev/null | tr -d '[:space:]')
  [[ -z "$size" || ! "$size" =~ ^[0-9]+$ ]] && return 0
  if [[ "$size" -gt "$rotation_bytes" ]]; then
    mv "$log_file" "$log_file.old" 2>/dev/null || true
  fi
}

append_jsonl() {
  rotate_if_needed
  printf '%s\n' "$1" >> "$log_file" 2>/dev/null || true
}

# jq indisponible → silently no-op (best-effort).
command -v jq >/dev/null 2>&1 || exit 0

cmd="${1:-}"
shift 2>/dev/null || true

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

case "$cmd" in
  inject)
    tool_name="${1:-}"
    file_path="${2:-}"
    direct_features="${3:-[]}"
    dependency_features="${4:-[]}"
    injected_features="${5:-[]}"
    unsupported_patterns="${6:-[]}"
    truncated="${7:-false}"
    budget_chars="${8:-0}"
    feature_index_mtime="${9:-}"
    matcher_policy="${10:-warn}"
    omitted_count="${11:-0}"
    top_k="${12:-3}"

    line=$(jq -nc \
      --arg ts "$ts" \
      --arg tool_name "$tool_name" \
      --arg file_path "$file_path" \
      --argjson direct_features "$direct_features" \
      --argjson dependency_features "$dependency_features" \
      --argjson injected_features "$injected_features" \
      --argjson unsupported_patterns "$unsupported_patterns" \
      --arg truncated "$truncated" \
      --arg budget_chars "$budget_chars" \
      --arg feature_index_mtime "$feature_index_mtime" \
      --arg matcher_policy "$matcher_policy" \
      --arg omitted_count "$omitted_count" \
      --arg top_k "$top_k" \
      '{
        ts: $ts, event: "inject", hook: "PreToolUse",
        tool_name: $tool_name, file: $file_path,
        direct_features: $direct_features,
        dependency_features: $dependency_features,
        injected_features: $injected_features,
        unsupported_patterns: $unsupported_patterns,
        truncated: ($truncated == "true"),
        budget_chars: ($budget_chars | tonumber? // 0),
        feature_index_mtime: $feature_index_mtime,
        matcher_policy: $matcher_policy,
        omitted_count: ($omitted_count | tonumber? // 0),
        top_k: ($top_k | tonumber? // 0)
      }' 2>/dev/null) || exit 0
    [[ -n "$line" ]] && append_jsonl "$line"
    ;;
  touch)
    tool_name="${1:-}"
    file_path="${2:-}"
    touched_features="${3:-[]}"

    line=$(jq -nc \
      --arg ts "$ts" \
      --arg tool_name "$tool_name" \
      --arg file_path "$file_path" \
      --argjson touched_features "$touched_features" \
      '{
        ts: $ts, event: "touch", hook: "PostToolUse",
        tool_name: $tool_name, file: $file_path,
        touched_features: $touched_features
      }' 2>/dev/null) || exit 0
    [[ -n "$line" ]] && append_jsonl "$line"
    ;;
  summary)
    [[ -f "$log_file" ]] || exit 0

    # ts du dernier summary (ou empty au premier run)
    last_summary_ts=$(jq -rs '[.[] | select(.event == "summary")] | last | .ts // ""' "$log_file" 2>/dev/null) || exit 0

    # Agrège events de la fenêtre depuis last_summary
    window=$(jq -cs --arg start "$last_summary_ts" '
      [.[] | select(.event == "inject" or .event == "touch")
            | select(($start == "") or (.ts > $start))]
      | {
          files: [.[].file] | unique,
          injected: [.[] | select(.event == "inject") | .injected_features // [] | .[]] | unique,
          touched: [.[] | select(.event == "touch") | .touched_features // [] | .[]] | unique,
          count: length
        }
    ' "$log_file" 2>/dev/null) || exit 0
    [[ -z "$window" ]] && exit 0

    count=$(printf '%s' "$window" | jq -r '.count // 0' 2>/dev/null) || exit 0
    [[ "$count" -eq 0 ]] && exit 0  # No-op si fenêtre vide

    line=$(jq -nc \
      --arg ts "$ts" \
      --arg window_start_ts "${last_summary_ts:-1970-01-01T00:00:00Z}" \
      --arg window_end_ts "$ts" \
      --argjson w "$window" \
      '
      ($w.injected) as $inj |
      ($w.touched) as $tch |
      ($inj | map(select(. as $x | $tch | index($x)))) as $intersection |
      ($inj | map(select(. as $x | $tch | index($x) | not))) as $inj_not_tch |
      ($tch | map(select(. as $x | $inj | index($x) | not))) as $tch_not_inj |
      ($inj | length) as $inj_n |
      ($tch | length) as $tch_n |
      ($intersection | length) as $i_n |
      {
        ts: $ts, event: "summary",
        window_start_ts: $window_start_ts,
        window_end_ts: $window_end_ts,
        files: $w.files,
        injected_features: $inj,
        touched_features: $tch,
        intersection: $intersection,
        injected_not_touched: $inj_not_tch,
        touched_not_injected: $tch_not_inj,
        precision_approx: (if $inj_n > 0 then ($i_n / $inj_n) else 0 end),
        recall_approx: (if $tch_n > 0 then ($i_n / $tch_n) else 0 end)
      }' 2>/dev/null) || exit 0
    [[ -n "$line" ]] && append_jsonl "$line"
    ;;
  *)
    # Sous-commande inconnue : silent no-op.
    ;;
esac

exit 0
