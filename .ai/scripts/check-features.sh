#!/bin/bash
# check-features.sh — Valide le maillage de features (ai_context).
#
# Vérifie pour chaque fichier sous .docs/features/*/*.md :
#   - présence du frontmatter YAML
#   - clés obligatoires : id, scope, title, status, depends_on, touches
#     (depends_on / touches peuvent valoir [] mais doivent être déclarées)
#   - status ∈ {draft, active, done, deprecated, archived} (warn si hors enum)
#   - progress.phase ∈ {spec, implement, test, review, done, blocked} (warn si hors enum)
#   - scope == nom du dossier parent
#   - chaque depends_on pointe vers un fichier existant
#   - chaque touches / touches_shared pointe vers un chemin existant (fichier, dossier, ou glob)
#
# Rafraîchit .ai/.feature-index.json si tout passe.
#
# Usage : bash .ai/scripts/check-features.sh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

enable_globstar

cd "$script_dir/../.."

FEATURES_DIR="$AI_CONTEXT_FEATURES_DIR"

fail=0
ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; fail=1; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1" >&2; }

echo "═══ check-features ═══"

if [[ ! -d "$FEATURES_DIR" ]]; then
  echo "  ⚠️  $FEATURES_DIR absent (aucune feature documentée)"
  exit 0
fi

files=()
while IFS= read -r -d '' f; do
  files+=("$f")
done < <(find "$FEATURES_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.md' ! -name '*.worklog.md' -print0 2>/dev/null)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "  ⚠️  aucune feature sous $FEATURES_DIR"
  exit 0
fi

for f in "${files[@]}"; do
  file_fail=0

  fm=$(awk '/^---$/{c++;next} c==1' "$f")
  if [[ -z "$fm" ]]; then
    ko "$f : frontmatter manquant"
    continue
  fi

  for key in id scope title status depends_on touches; do
    if ! echo "$fm" | grep -qE "^$key:"; then
      ko "$f : clé frontmatter '$key' manquante"
      file_fail=1
    fi
  done

  folder_scope=$(basename "$(dirname "$f")")
  declared_scope=$(echo "$fm" | grep -E '^scope:' | sed -E 's/^scope:[[:space:]]*//; s/["'"'"']//g' | tr -d '[:space:]')
  if [[ -n "$declared_scope" && "$declared_scope" != "$folder_scope" ]]; then
    ko "$f : scope '$declared_scope' ne matche pas le dossier '$folder_scope'"
    file_fail=1
  fi

  # id / scope : regex stricte. Sécu : ces deux champs servent à construire
  # des chemins worklog et des clés "scope/id" (auto-worklog-flush, auto-progress).
  # Un id="../foo" ou scope avec espace ouvrirait un path traversal sur le worklog.
  declared_id=$(echo "$fm" | grep -E '^id:' | sed -E 's/^id:[[:space:]]*//; s/["'"'"']//g' | tr -d '[:space:]')
  if [[ -n "$declared_id" && ! "$declared_id" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    ko "$f : id='$declared_id' invalide (attendu : ^[a-z0-9][a-z0-9_-]*$ — minuscules, chiffres, tirets, underscores)"
    file_fail=1
  fi
  if [[ -n "$declared_scope" && ! "$declared_scope" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    ko "$f : scope='$declared_scope' invalide (attendu : ^[a-z0-9][a-z0-9_-]*$)"
    file_fail=1
  fi

  # status enum (warn, pas fail)
  declared_status=$(echo "$fm" | grep -E '^status:' | sed -E 's/^status:[[:space:]]*//; s/["'"'"']//g' | tr -d '[:space:]')
  if [[ -n "$declared_status" ]] && ! is_valid_status "$declared_status"; then
    warn "$f : status='$declared_status' hors enum ($STATUS_ENUM)"
  fi

  # progress.phase enum (warn, pas fail) — aligné avec .ai/schema/feature.schema.json
  declared_phase=$(awk '
    /^progress:[[:space:]]*$/ { in_progress=1; next }
    in_progress && /^[^[:space:]]/ { in_progress=0 }
    in_progress && /^[[:space:]]*phase:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*phase:[[:space:]]*/, "", line)
      gsub(/["'\''[:space:]]/, "", line)
      print line
      exit
    }
  ' "$f")
  if [[ -n "$declared_phase" ]] && ! is_valid_phase "$declared_phase"; then
    warn "$f : progress.phase='$declared_phase' hors enum ($PHASE_ENUM)"
  fi

  deps=$(awk '/^depends_on:/{flag=1; next} flag && /^  *-/{print; next} flag && /^[^[:space:]]/{flag=0}' "$f" \
    | sed -E 's/^[[:space:]]*-[[:space:]]*//; s/["'"'"']//g')
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    [[ "$dep" == "[]" ]] && continue
    if ! is_path_within_repo "$dep"; then
      ko "$f : depends_on '$dep' hors repo (chemin absolu, traversée .. ou ~ rejetés ; format attendu : scope/id)"
      file_fail=1
      continue
    fi
    target="$FEATURES_DIR/$dep.md"
    if [[ ! -f "$target" ]]; then
      ko "$f : depends_on '$dep' → $target introuvable"
      file_fail=1
    else
      # Warn si current feature active/draft dépend d'une feature deprecated/archived
      dep_fm=$(awk '/^---$/{c++;next} c==1' "$target")
      dep_status=$(echo "$dep_fm" | grep -E '^status:' | sed -E 's/^status:[[:space:]]*//; s/["'"'"']//g' | tr -d '[:space:]')
      if [[ "$dep_status" == "deprecated" || "$dep_status" == "archived" ]]; then
        if [[ "$declared_status" == "active" || "$declared_status" == "draft" || -z "$declared_status" ]]; then
          warn "$f : depends_on '$dep' est '$dep_status' (envisager de migrer)"
        fi
      fi
    fi
  done <<< "$deps"

  for touch_key in touches touches_shared; do
    tchs=$(awk -v k="^${touch_key}:" '
      $0 ~ k {flag=1; next}
      flag && /^  *-/ {print; next}
      flag && /^[^[:space:]]/ {flag=0}
    ' "$f" | sed -E 's/^[[:space:]]*-[[:space:]]*//; s/["'"'"']//g')
    while IFS= read -r t; do
      [[ -z "$t" ]] && continue
      [[ "$t" == "[]" ]] && continue
      if ! is_path_within_repo "$t"; then
        ko "$f : $touch_key '$t' hors repo (chemin absolu, traversée .. ou ~ rejetés)"
        file_fail=1
        continue
      fi
      # shellcheck disable=SC2206
      matches=( $t )
      if [[ ${#matches[@]} -eq 0 ]] || [[ ! -e "${matches[0]}" && ! -d "${matches[0]}" ]]; then
        if [[ -e "$t" || -d "$t" ]]; then
          :
        else
          ko "$f : $touch_key '$t' ne résout aucun chemin réel"
          file_fail=1
        fi
      fi
    done <<< "$tchs"
  done

  [[ "$file_fail" -eq 0 ]] && ok "$f"
done

echo
if [[ "$fail" -eq 0 ]]; then
  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true

  # Détection des cycles dans depends_on (via l'index JSON)
  cycle_idx="$script_dir/../.feature-index.json"
  if [[ -f "$cycle_idx" ]] && command -v jq >/dev/null 2>&1; then
    cycle=$(jq -r '
      (.features | map({key: (.scope + "/" + .id), value: (.depends_on // [])}) | from_entries) as $graph
      | [$graph | keys[]] as $nodes
      | def dfs($node; $stack; $visited):
          if ($stack | index($node)) then
            ($stack + [$node]) | join(" → ")
          elif ($visited | index($node)) then
            empty
          else
            ($graph[$node] // [])
            | map(dfs(.; $stack + [$node]; $visited + [$node]))
            | add // empty
          end;
      $nodes
      | map(dfs(.; []; []))
      | map(select(. != null and . != ""))
      | first // empty
    ' "$cycle_idx" 2>/dev/null)
    if [[ -n "$cycle" ]]; then
      ko "cycle détecté dans depends_on : $cycle"
      echo "❌ FAIL"
      exit 1
    fi
  fi

  echo "✅ PASS"
  exit 0
else
  echo "❌ FAIL"
  exit 1
fi
