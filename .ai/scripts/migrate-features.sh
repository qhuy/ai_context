#!/bin/bash
# migrate-features.sh — Migration frontmatter features (dry-run par défaut).
#
# Usage :
#   bash .ai/scripts/migrate-features.sh          # dry-run
#   bash .ai/scripts/migrate-features.sh --apply  # écrit les migrations
#
# Migrations v1 :
# - ajoute schema_version: 1 si absent
# - ajoute status/depends_on/touches si absents
# - normalise certains status legacy vers l'enum canonique

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

enable_globstar

repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

apply=0
for arg in "$@"; do
  [[ "$arg" == "--apply" ]] && apply=1
done

features_dir="$AI_CONTEXT_FEATURES_DIR"
if [[ ! -d "$features_dir" ]]; then
  echo "⚠️  $features_dir absent, rien à migrer"
  exit 0
fi

normalize_status() {
  local s="$1"
  s="$(echo "$s" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' | tr '_' '-')"
  case "$s" in
    in-progress|inprogress|wip) echo "active" ;;
    complete|completed|closed) echo "done" ;;
    todo|planned) echo "draft" ;;
    *) echo "$s" ;;
  esac
}

files=()
while IFS= read -r -d '' f; do
  files+=("$f")
done < <(find "$features_dir" -mindepth 2 -maxdepth 2 -type f -name '*.md' ! -name '*.worklog.md' -print0)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "⚠️  aucune feature trouvée sous $features_dir"
  exit 0
fi

echo "═══ migrate-features (v1) ═══"
echo "mode: $([[ "$apply" -eq 1 ]] && echo "apply" || echo "dry-run")"
echo

changed=0
for f in "${files[@]}"; do
  fm="$(awk '/^---$/{c++;next} c==1{print}' "$f")"
  body="$(awk 'BEGIN{c=0} /^---$/{c++;next} c>=2{print}' "$f")"
  [[ -n "$fm" ]] || continue

  new_fm="$fm"
  edits=()

  if ! echo "$new_fm" | grep -qE '^schema_version:'; then
    new_fm="${new_fm}"$'\n'"schema_version: 1"
    edits+=("add schema_version: 1")
  fi

  if ! echo "$new_fm" | grep -qE '^status:'; then
    new_fm="${new_fm}"$'\n'"status: draft"
    edits+=("add status: draft")
  else
    current_status="$(echo "$new_fm" | sed -nE 's/^status:[[:space:]]*//p' | head -n1 | tr -d "\"'")"
    norm_status="$(normalize_status "$current_status")"
    if [[ -n "$norm_status" && "$norm_status" != "$current_status" ]]; then
      new_fm="$(echo "$new_fm" | sed -E "s/^status:[[:space:]]*.*/status: $norm_status/")"
      edits+=("normalize status: $current_status -> $norm_status")
    fi
  fi

  if ! echo "$new_fm" | grep -qE '^depends_on:'; then
    new_fm="${new_fm}"$'\n'"depends_on: []"
    edits+=("add depends_on: []")
  fi

  if ! echo "$new_fm" | grep -qE '^touches:'; then
    new_fm="${new_fm}"$'\n'"touches: []"
    edits+=("add touches: []")
  fi

  if [[ "${#edits[@]}" -eq 0 ]]; then
    continue
  fi

  changed=$((changed + 1))
  echo "- $f"
  for e in "${edits[@]}"; do
    echo "    • $e"
  done

  if [[ "$apply" -eq 1 ]]; then
    {
      echo "---"
      echo "$new_fm"
      echo "---"
      echo "$body"
    } > "$f"
  fi
done

echo
if [[ "$changed" -eq 0 ]]; then
  echo "✓ Aucun changement nécessaire"
  exit 0
fi

if [[ "$apply" -eq 1 ]]; then
  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
  echo "✓ Migration appliquée sur $changed fichier(s)"
else
  echo "ℹ️ Dry-run: $changed fichier(s) à migrer (relancer avec --apply)."
fi
