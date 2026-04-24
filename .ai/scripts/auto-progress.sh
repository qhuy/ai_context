#!/bin/bash
# auto-progress.sh — Hook Stop (chaîné après auto-worklog-flush.sh).
#
# Détecte les transitions de phase légitimes et les applique au frontmatter
# des features touchées dans la session.
#
# V1 — heuristique conservatrice : SEULE la transition `spec → implement` est
# appliquée. Critère :
#   - feature en `progress.phase: spec`
#   - au moins 1 fichier matché (hors la fiche feature elle-même et son worklog)
#     a été édité dans la session
#
# `implement → review` et `review → done` restent manuels (override via /aic),
# pour éviter les faux positifs (le hook Stop ne sait pas si les tests ont été
# lancés ce tour).
#
# Snapshot avant chaque transition dans .ai/.progress-history.jsonl (append-only,
# 50 dernières entrées gardées) pour permettre /aic undo plus tard.
#
# Silencieux et best-effort : ne bloque jamais. Lit le state via les fichiers
# (auto-worklog-flush.sh vient de tourner et a clear .session-edits.log,
# donc on s'appuie sur l'index + une trace volatile pré-flush).

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
index_file="$repo_root/.ai/.feature-index.json"
trace_file="$repo_root/.ai/.session-edits.flushed"
history_file="$repo_root/.ai/.progress-history.jsonl"

[[ ! -f "$index_file" ]] && exit 0
[[ ! -s "$trace_file" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

today=$(date +%Y-%m-%d)
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Collecte les features touchées dans le tour qui vient de finir
features_touched=$(jq -rs 'group_by(.feature) | .[] | .[0].feature' "$trace_file" 2>/dev/null | sort -u)
[[ -z "$features_touched" ]] && exit 0

mkdir -p "$(dirname "$history_file")"

while IFS= read -r key; do
  [[ -z "$key" ]] && continue

  # Extraire phase et path actuels depuis l'index (rebuild fait par flush)
  read -r feature_path current_phase current_status <<< "$(
    jq -r --arg k "$key" '
      .features[]
      | select(.scope + "/" + .id == $k)
      | [.path, (.progress.phase // ""), .status]
      | @tsv
    ' "$index_file" 2>/dev/null
  )"
  [[ -z "$feature_path" || ! -f "$repo_root/$feature_path" ]] && continue

  # Heuristique V1 : applique uniquement spec → implement
  [[ "$current_phase" != "spec" ]] && continue

  # Vérifie qu'au moins 1 fichier édité ≠ la fiche elle-même ou son worklog
  scope="${key%%/*}"
  id="${key##*/}"
  fiche_path="$feature_path"
  worklog_path="$(dirname "$feature_path")/$id.worklog.md"

  has_real_edit=$(jq -rs --arg k "$key" --arg fp "$fiche_path" --arg wp "$worklog_path" '
    [.[] | select(.feature == $k) | .file]
    | unique
    | map(select(. != $fp and . != $wp))
    | length
  ' "$trace_file" 2>/dev/null)

  [[ -z "$has_real_edit" || "$has_real_edit" == "0" ]] && continue

  # Snapshot AVANT modification (pour undo futur)
  snapshot=$(jq -nc \
    --arg ts "$ts" \
    --arg feature "$key" \
    --arg path "$feature_path" \
    --arg from_phase "$current_phase" \
    --arg to_phase "implement" \
    --arg from_status "$current_status" \
    --arg to_status "$current_status" \
    '{ts: $ts, feature: $feature, path: $path, from: {phase: $from_phase, status: $from_status}, to: {phase: $to_phase, status: $to_status}}'
  )
  printf '%s\n' "$snapshot" >> "$history_file"

  # Trim history à 50 entrées (FIFO)
  if [[ "$(wc -l < "$history_file")" -gt 50 ]]; then
    tmp=$(mktemp "${history_file}.XXXXXX")
    tail -n 50 "$history_file" > "$tmp" && mv "$tmp" "$history_file"
  fi

  # Patch frontmatter : phase: spec → implement, updated: today
  feature_md="$repo_root/$feature_path"
  tmp=$(mktemp "${feature_md}.XXXXXX")
  awk -v today="$today" '
    BEGIN{in_fm=0; in_prog=0; c=0}
    /^---$/{c++; print; if(c==2) in_fm=0; else in_fm=1; next}
    in_fm && /^progress:/{in_prog=1; print; next}
    in_fm && in_prog && /^  phase: spec[[:space:]]*$/{print "  phase: implement"; next}
    in_fm && in_prog && /^  updated:/{print "  updated: " today; next}
    in_fm && in_prog && /^[^[:space:]]/{in_prog=0}
    {print}
  ' "$feature_md" > "$tmp" && mv "$tmp" "$feature_md"

  # Append au worklog une ligne d'auto-progression (séparée des edits factuels)
  if [[ -f "$worklog_path" ]]; then
    {
      printf '\n## %s — auto-progress\n' "$(date +"%Y-%m-%d %H:%M")"
      printf -- '- Bascule phase : spec → implement (édits réels détectés sur %s fichier(s))\n' "$has_real_edit"
      printf -- '- Annulable via /aic undo (snapshot dans .ai/.progress-history.jsonl)\n'
    } >> "$worklog_path"
  fi
done <<< "$features_touched"

# Rebuild index pour refléter les nouvelles phases
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true

# Clear trace
: > "$trace_file"

exit 0
