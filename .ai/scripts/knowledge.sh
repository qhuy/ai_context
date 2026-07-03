#!/bin/bash
# knowledge.sh — Flux workflow pour hub knowledge Git/Markdown.
#
# Usage:
#   bash .ai/scripts/knowledge.sh <publish|search|link|import|freshness> [options]

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"
# shellcheck source=_knowledge.sh
. "$script_dir/_knowledge.sh"

require_cmd jq

usage() {
  cat <<'HELP'
Usage: bash .ai/scripts/knowledge.sh <command> [options]

Commands:
  publish   Build a knowledge markdown candidate; writes only with --apply.
  search    Search the local knowledge hub.
  link      Print an external_refs.knowledge snippet for a knowledge URI.
  import    Print a local markdown synthesis with provenance.
  freshness List checked_at/status metadata for the hub.

Common options:
  --hub <path>   Hub root. Defaults to AI_CONTEXT_KNOWLEDGE_HUB or current repo.
  --json         JSON output for search/link/import/freshness.

Reference forms:
  knowledge://<source_project>/<id>
  <source_project>/<id>
  <id> if unambiguous in the hub
HELP
}

die() {
  echo "knowledge: $*" >&2
  exit 1
}

default_hub_root() {
  if [[ -n "${AI_CONTEXT_KNOWLEDGE_HUB:-}" ]]; then
    printf '%s\n' "$AI_CONTEXT_KNOWLEDGE_HUB"
  else
    printf '%s\n' "."
  fi
}

resolve_hub_root() {
  local hub="$1"
  [[ -d "$hub" ]] || die "hub introuvable: $hub"
  (cd "$hub" && pwd)
}

yaml_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

append_line() {
  local current="$1"
  local value="$2"
  if [[ -n "$current" ]]; then
    printf '%s\n%s\n' "$current" "$value"
  else
    printf '%s\n' "$value"
  fi
}

emit_yaml_list() {
  local values="$1"
  printf '%s\n' "$values" | while IFS= read -r value; do
    [[ -n "$value" ]] || continue
    printf '  - '
    yaml_quote "$value"
    printf '\n'
  done
}

load_index_json() {
  local hub_root="$1"
  bash "$script_dir/build-knowledge-index.sh" "$hub_root"
}

entry_matches_json() {
  local hub_root="$1"
  local ref="$2"
  load_index_json "$hub_root" | jq --arg ref "$ref" '
    [
      .knowledge[]
      | select(
          .uri == $ref
          or ((.source_project + "/" + .id) == $ref)
          or (.id == $ref)
        )
    ]
  '
}

require_entry_json() {
  local hub_root="$1"
  local ref="$2"
  local matches count
  matches="$(entry_matches_json "$hub_root" "$ref")"
  count="$(printf '%s\n' "$matches" | jq 'length')"
  if [[ "$count" -eq 0 ]]; then
    die "connaissance introuvable: $ref"
  fi
  if [[ "$count" -gt 1 ]]; then
    printf '%s\n' "$matches" | jq -r '.[] | "- " + .uri' >&2
    die "reference ambigue: $ref"
  fi
  printf '%s\n' "$matches" | jq '.[0]'
}

run_search() {
  local hub query json index results count
  hub="$(default_hub_root)"
  query=""
  json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hub) hub="${2:?--hub requiert un chemin}"; shift 2 ;;
      --json) json=1; shift ;;
      -h|--help)
        echo "Usage: knowledge search [--hub <path>] [--json] <query>"
        exit 0
        ;;
      *)
        if [[ -z "$query" ]]; then
          query="$1"
        else
          query="$query $1"
        fi
        shift
        ;;
    esac
  done
  [[ -n "$query" ]] || die "search requiert une requete"
  hub="$(resolve_hub_root "$hub")"
  query="$(printf '%s' "$query" | LC_ALL=C tr '[:upper:]' '[:lower:]')"
  index="$(load_index_json "$hub")"
  results="$(printf '%s\n' "$index" | jq --arg q "$query" '
    [
      .knowledge[]
      | select(
          ([.id, .uri, .type, .title, .summary, .source_project, .owner, .status] | map(. // "") | join(" ") | ascii_downcase)
          | contains($q)
        )
    ]
  ')"
  count="$(printf '%s\n' "$results" | jq 'length')"
  if [[ "$json" -eq 1 ]]; then
    printf '%s\n' "$results"
    [[ "$count" -gt 0 ]]
    return
  fi
  if [[ "$count" -eq 0 ]]; then
    echo "Aucun resultat."
    return 1
  fi
  printf '%s\n' "$results" | jq -r '.[] |
    "- " + .uri
    + " | " + .title
    + " | status=" + .status
    + " confidence=" + .confidence
    + " sensitivity=" + .sensitivity
    + " checked_at=" + .freshness.checked_at'
}

emit_candidate_markdown() {
  printf '%s\n' "---"
  printf 'id: %s\n' "$publish_id"
  printf 'type: %s\n' "$publish_type"
  printf 'title: '; yaml_quote "$publish_title"; printf '\n'
  printf 'summary: '; yaml_quote "$publish_summary"; printf '\n'
  printf 'source_project: %s\n' "$publish_source_project"
  printf 'owner: '; yaml_quote "$publish_owner"; printf '\n'
  printf 'confidence: %s\n' "$publish_confidence"
  printf '%s\n' "freshness:"
  printf '  status: %s\n' "$publish_freshness_status"
  printf '  checked_at: %s\n' "$publish_checked_at"
  printf 'sensitivity: %s\n' "$publish_sensitivity"
  printf '%s\n' "source_refs:"
  emit_yaml_list "$publish_source_refs"
  printf '%s\n' "usable_by:"
  emit_yaml_list "$publish_usable_by"
  printf 'status: %s\n' "$publish_status"
  printf '%s\n\n' "---"
  printf '# %s\n\n' "$publish_title"
  printf '%s\n' "$publish_summary"
}

validate_candidate_file() {
  local candidate="$1"
  local tmp_hub
  tmp_hub="$(mktemp -d "${TMPDIR:-/tmp}/aic-knowledge-publish.XXXXXX")"
  trap 'rm -rf "$tmp_hub"' RETURN
  mkdir -p "$tmp_hub/knowledge/$publish_source_project"
  cp "$candidate" "$tmp_hub/knowledge/$publish_source_project/$publish_id.md"
  bash "$script_dir/check-knowledge.sh" "$tmp_hub" >/dev/null
}

run_publish() {
  local hub apply candidate target
  hub="$(default_hub_root)"
  apply=0
  publish_id=""
  publish_type=""
  publish_title=""
  publish_summary=""
  publish_source_project=""
  publish_owner=""
  publish_confidence=""
  publish_checked_at="$(date -u +%F)"
  publish_freshness_status="verified"
  publish_sensitivity=""
  publish_status="draft"
  publish_source_refs=""
  publish_usable_by=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hub) hub="${2:?--hub requiert un chemin}"; shift 2 ;;
      --apply) apply=1; shift ;;
      --id) publish_id="${2:?--id requiert une valeur}"; shift 2 ;;
      --type) publish_type="${2:?--type requiert une valeur}"; shift 2 ;;
      --title) publish_title="${2:?--title requiert une valeur}"; shift 2 ;;
      --summary) publish_summary="${2:?--summary requiert une valeur}"; shift 2 ;;
      --source-project) publish_source_project="${2:?--source-project requiert une valeur}"; shift 2 ;;
      --owner) publish_owner="${2:?--owner requiert une valeur}"; shift 2 ;;
      --confidence) publish_confidence="${2:?--confidence requiert une valeur}"; shift 2 ;;
      --checked-at) publish_checked_at="${2:?--checked-at requiert une valeur}"; shift 2 ;;
      --freshness-status) publish_freshness_status="${2:?--freshness-status requiert une valeur}"; shift 2 ;;
      --sensitivity) publish_sensitivity="${2:?--sensitivity requiert une valeur}"; shift 2 ;;
      --status) publish_status="${2:?--status requiert une valeur}"; shift 2 ;;
      --source-ref) publish_source_refs="$(append_line "$publish_source_refs" "${2:?--source-ref requiert une valeur}")"; shift 2 ;;
      --usable-by) publish_usable_by="$(append_line "$publish_usable_by" "${2:?--usable-by requiert une valeur}")"; shift 2 ;;
      -h|--help)
        cat <<'HELP'
Usage: knowledge publish --hub <path> --id <id> --type <type> --title <title>
       --summary <text> --source-project <project> --owner <owner>
       --confidence <low|medium|high> --sensitivity <public|internal|restricted>
       --source-ref <ref>... --usable-by <target>... [--checked-at YYYY-MM-DD]
       [--freshness-status verified|stale|unknown] [--status draft|published|deprecated|retracted]
       [--apply]
HELP
        exit 0
        ;;
      *) die "argument publish inconnu: $1" ;;
    esac
  done

  for pair in \
    "id:$publish_id" \
    "type:$publish_type" \
    "title:$publish_title" \
    "summary:$publish_summary" \
    "source-project:$publish_source_project" \
    "owner:$publish_owner" \
    "confidence:$publish_confidence" \
    "sensitivity:$publish_sensitivity"; do
    key="${pair%%:*}"
    value="${pair#*:}"
    [[ -n "$value" ]] || die "publish requiert --$key"
  done
  [[ -n "$publish_source_refs" ]] || die "publish requiert au moins un --source-ref"
  [[ -n "$publish_usable_by" ]] || die "publish requiert au moins un --usable-by"

  hub="$(resolve_hub_root "$hub")"
  candidate="$(mktemp "${TMPDIR:-/tmp}/aic-knowledge-candidate.XXXXXX")"
  trap 'rm -f "$candidate"' RETURN
  emit_candidate_markdown > "$candidate"
  validate_candidate_file "$candidate" || die "candidate invalide"

  target="$hub/knowledge/$publish_source_project/$publish_id.md"
  if [[ "$apply" -eq 0 ]]; then
    echo "Mode: dry-run (ajoute --apply pour ecrire)"
    echo "Path: ${target#$hub/}"
    echo
    sed -n '1,220p' "$candidate"
    return 0
  fi

  bash "$script_dir/check-knowledge.sh" "$hub" >/dev/null || die "hub existant invalide"
  [[ ! -e "$target" ]] || die "la connaissance existe deja: ${target#$hub/}"
  mkdir -p "$(dirname "$target")"
  mv "$candidate" "$target"
  echo "knowledge ecrite: ${target#$hub/}"
  bash "$script_dir/check-knowledge.sh" "$hub"
  bash "$script_dir/build-knowledge-index.sh" --write "$hub"
}

feature_path_for_ref() {
  local feature_ref="$1"
  local target="$AI_CONTEXT_FEATURES_DIR/$feature_ref.md"
  [[ -f "$target" ]] || return 1
  printf '%s\n' "$target"
}

run_link() {
  local hub ref feature json entry feature_path uri
  hub="$(default_hub_root)"
  ref=""
  feature=""
  json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hub) hub="${2:?--hub requiert un chemin}"; shift 2 ;;
      --feature) feature="${2:?--feature requiert scope/id}"; shift 2 ;;
      --json) json=1; shift ;;
      -h|--help)
        echo "Usage: knowledge link [--hub <path>] [--feature scope/id] [--json] <knowledge-ref>"
        exit 0
        ;;
      *)
        [[ -z "$ref" ]] || die "link accepte une seule reference"
        ref="$1"
        shift
        ;;
    esac
  done
  [[ -n "$ref" ]] || die "link requiert une reference knowledge"
  hub="$(resolve_hub_root "$hub")"
  entry="$(require_entry_json "$hub" "$ref")"
  uri="$(printf '%s\n' "$entry" | jq -r '.uri')"
  feature_path=""
  if [[ -n "$feature" ]]; then
    feature_path="$(feature_path_for_ref "$feature" 2>/dev/null || true)"
    [[ -n "$feature_path" ]] || die "feature introuvable: $feature"
  fi
  if [[ "$json" -eq 1 ]]; then
    jq -n --arg uri "$uri" --arg feature "$feature" --arg feature_path "$feature_path" \
      '{uri: $uri, feature: $feature, feature_path: $feature_path, external_refs: {knowledge: [$uri]}}'
    return 0
  fi
  echo "Knowledge link"
  echo "- uri: $uri"
  [[ -n "$feature" ]] && echo "- feature: $feature ($feature_path)"
  echo
  cat <<EOF
external_refs:
  knowledge:
    - $uri
EOF
}

run_import() {
  local hub ref json entry
  hub="$(default_hub_root)"
  ref=""
  json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hub) hub="${2:?--hub requiert un chemin}"; shift 2 ;;
      --json) json=1; shift ;;
      -h|--help)
        echo "Usage: knowledge import [--hub <path>] [--json] <knowledge-ref>"
        exit 0
        ;;
      *)
        [[ -z "$ref" ]] || die "import accepte une seule reference"
        ref="$1"
        shift
        ;;
    esac
  done
  [[ -n "$ref" ]] || die "import requiert une reference knowledge"
  hub="$(resolve_hub_root "$hub")"
  entry="$(require_entry_json "$hub" "$ref")"
  if [[ "$json" -eq 1 ]]; then
    printf '%s\n' "$entry"
    return 0
  fi
  printf '%s\n' "$entry" | jq -r '
    "## " + .title,
    "",
    "Source: `" + .uri + "`",
    "Owner: `" + .owner + "`",
    "Confidence: `" + .confidence + "`",
    "Sensitivity: `" + .sensitivity + "`",
    "Checked at: `" + .freshness.checked_at + "`",
    "",
    .summary,
    "",
    "Source refs:",
    (.source_refs[] | "- `" + . + "`"),
    "",
    "Usable by:",
    (.usable_by[] | "- `" + . + "`")
  '
}

run_freshness() {
  local hub json index
  hub="$(default_hub_root)"
  json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hub) hub="${2:?--hub requiert un chemin}"; shift 2 ;;
      --json) json=1; shift ;;
      -h|--help)
        echo "Usage: knowledge freshness [--hub <path>] [--json]"
        exit 0
        ;;
      *) die "argument freshness inconnu: $1" ;;
    esac
  done
  hub="$(resolve_hub_root "$hub")"
  index="$(load_index_json "$hub")"
  if [[ "$json" -eq 1 ]]; then
    printf '%s\n' "$index" | jq '[.knowledge[] | {uri, title, owner, status, confidence, sensitivity, freshness}]'
    return 0
  fi
  if [[ "$(printf '%s\n' "$index" | jq '.knowledge | length')" -eq 0 ]]; then
    echo "Aucune connaissance."
    return 0
  fi
  printf '%s\n' "$index" | jq -r '.knowledge[] |
    "- " + .uri
    + " | checked_at=" + .freshness.checked_at
    + " status=" + (.freshness.status // "unknown")
    + " owner=" + .owner
    + " confidence=" + .confidence
    + " sensitivity=" + .sensitivity'
}

cmd="${1:-}"
case "$cmd" in
  ""|-h|--help|help)
    usage
    exit 0
    ;;
esac
shift

case "$cmd" in
  publish) run_publish "$@" ;;
  search) run_search "$@" ;;
  link) run_link "$@" ;;
  import) run_import "$@" ;;
  freshness) run_freshness "$@" ;;
  *)
    echo "Commande knowledge inconnue: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
