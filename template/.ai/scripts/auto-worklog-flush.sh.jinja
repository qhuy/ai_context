#!/bin/bash
# auto-worklog-flush.sh — Hook Stop (fin de tour Claude).
#
# Lit .ai/.session-edits.log (JSONL), groupe par feature, append UNE entrée
# au worklog de chaque feature affectée, bump progress.updated dans le frontmatter,
# puis efface le log. Idempotent (log vide = no-op).
#
# Auto-update factuel uniquement :
#   - progress.updated : date du jour
#   - worklog : ligne "Fichiers modifiés: <liste>"
# Ne touche JAMAIS phase / step / blockers / resume_hint / status.
# Pour changer ces champs volontairement, utiliser /aic-feature-update.
#
# Silencieux et best-effort.

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
log_file="$repo_root/.ai/.session-edits.log"
index_file="$repo_root/.ai/.feature-index.json"

[[ ! -s "$log_file" ]] && exit 0
[[ ! -f "$index_file" ]] && exit 0

today=$(date +%Y-%m-%d)
timestamp=$(date +"%Y-%m-%d %H:%M")

# Grouper log par feature : feature -> liste fichiers (uniques)
# jq : slurpfile lit tout le fichier JSONL comme array
features=$(jq -rs 'group_by(.feature) | .[] | .[0].feature' "$log_file" 2>/dev/null | sort -u)
[[ -z "$features" ]] && { : > "$log_file"; exit 0; }

while IFS= read -r key; do
  [[ -z "$key" ]] && continue

  # Liste unique des fichiers modifiés pour cette feature
  files=$(jq -rs --arg k "$key" '[.[] | select(.feature == $k) | .file] | unique | .[]' "$log_file" 2>/dev/null)
  [[ -z "$files" ]] && continue

  # Résoudre path de la feature depuis l'index
  feature_path=$(jq -r --arg k "$key" '.features[] | select(.scope + "/" + .id == $k) | .path' "$index_file" 2>/dev/null)
  [[ -z "$feature_path" || ! -f "$repo_root/$feature_path" ]] && continue

  feature_md="$repo_root/$feature_path"
  scope="${key%%/*}"
  id="${key##*/}"
  worklog="$repo_root/$(dirname "$feature_path")/$id.worklog.md"

  # Append au worklog (créé si absent)
  if [[ ! -f "$worklog" ]]; then
    printf '# Worklog — %s\n\n' "$key" > "$worklog"
  fi
  {
    printf '\n## %s — auto\n' "$timestamp"
    printf -- '- Fichiers modifiés :\n'
    while IFS= read -r f; do
      [[ -n "$f" ]] && printf -- '  - %s\n' "$f"
    done <<< "$files"
  } >> "$worklog"

  # Bump progress.updated dans le frontmatter (conservateur : n'ajoute pas le bloc s'il n'existe pas)
  if grep -qE '^progress:' "$feature_md"; then
    if grep -qE '^  updated:' "$feature_md"; then
      # Replace existing updated line
      tmp=$(mktemp "${feature_md}.XXXXXX")
      awk -v today="$today" '
        BEGIN{in_fm=0; in_prog=0; c=0}
        /^---$/{c++; print; if(c==2) in_fm=0; else in_fm=1; next}
        in_fm && /^progress:/{in_prog=1; print; next}
        in_fm && in_prog && /^  updated:/{print "  updated: " today; next}
        in_fm && in_prog && /^[^[:space:]]/{in_prog=0}
        {print}
      ' "$feature_md" > "$tmp" && mv "$tmp" "$feature_md"
    fi
    # Si progress: existe mais pas updated:, on ne l'ajoute pas (structure trop fragile en awk).
    # /aic-feature-update s'en occupera au prochain passage manuel.
  fi
done <<< "$features"

# Rebuild index pour que /aic-feature-resume reflète les nouveaux updated
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true

# Préserve la trace pour auto-progress.sh (chaîné après dans le hook Stop).
# auto-progress.sh la consomme puis la vide. Si ce script n'est pas activé,
# .session-edits.flushed ne grossit pas car PostToolUse n'écrit que dans
# .session-edits.log (recréé propre au prochain edit).
mv "$log_file" "$repo_root/.ai/.session-edits.flushed" 2>/dev/null || : > "$log_file"

exit 0
