#!/bin/bash
# aic-undo.sh — Annule la dernière transition auto-progressée.
#
# Lit le dernier snapshot dans .ai/.progress-history.jsonl, restaure
# le frontmatter (phase + status), append une ligne au worklog, supprime
# la dernière entrée du history, rebuild l'index.
#
# Mode headless : le skill conversationnel /aic undo peut s'appuyer
# dessus (la confirmation interactive reste côté skill).
#
# Usage :
#   bash .ai/scripts/aic-undo.sh           # --dry-run (montre l'action)
#   bash .ai/scripts/aic-undo.sh --apply   # applique
#
# Exit :
#   0 — succès, ou rien à annuler (history vide/absent)
#   1 — erreur (history corrompu, fiche introuvable, ...)

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

repo_root="$(cd "$script_dir/../.." && pwd)"
history_file="$repo_root/.ai/.progress-history.jsonl"

apply=0
for arg in "$@"; do
  case "$arg" in
    --apply) apply=1 ;;
    --dry-run) apply=0 ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--apply|--dry-run]

Annule la dernière transition auto-progressée (snapshot le plus récent dans
.ai/.progress-history.jsonl). Par défaut --dry-run.

En mode --apply :
  - Patche le frontmatter de la fiche (phase + status restaurés)
  - Append une ligne "## <ts> — /aic undo" au worklog
  - Supprime la dernière entrée de .progress-history.jsonl
  - Rebuild .ai/.feature-index.json
EOF
      exit 0 ;;
  esac
done

if [[ ! -f "$history_file" ]] || [[ ! -s "$history_file" ]]; then
  echo "Rien à annuler (aucun snapshot dans .ai/.progress-history.jsonl)."
  exit 0
fi

last=$(tail -n 1 "$history_file")
if ! echo "$last" | jq -e . >/dev/null 2>&1; then
  echo "❌ Dernière entrée du history corrompue (JSON invalide) : $last" >&2
  exit 1
fi

feature=$(echo "$last" | jq -r '.feature')
feat_path=$(echo "$last" | jq -r '.path')
from_phase=$(echo "$last" | jq -r '.from.phase')
from_status=$(echo "$last" | jq -r '.from.status')
to_phase=$(echo "$last" | jq -r '.to.phase')

abs_path="$repo_root/$feat_path"
if [[ ! -f "$abs_path" ]]; then
  echo "❌ Fiche $feat_path introuvable, snapshot peut-être obsolète" >&2
  exit 1
fi

ts_human=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat <<MSG
═══ aic-undo ═══
  feature : $feature
  fiche   : $feat_path
  current : phase=$to_phase   (état après la transition à annuler)
  restore : phase=$from_phase, status=$from_status
MSG

if [[ $apply -eq 0 ]]; then
  echo
  echo "Mode --dry-run. Relance avec --apply pour appliquer."
  exit 0
fi

# 1. Patch frontmatter (phase + status)
tmp=$(mktemp "${abs_path}.XXXXXX")
awk -v fp="$from_phase" -v fs="$from_status" '
  BEGIN{in_fm=0; in_prog=0; c=0; status_done=0; phase_done=0}
  /^---$/{c++; print; if(c==2) in_fm=0; else in_fm=1; next}
  in_fm && /^status:/ && status_done==0 {print "status: " fs; status_done=1; next}
  in_fm && /^progress:/{in_prog=1; print; next}
  in_fm && in_prog && /^  phase:/ && phase_done==0 {print "  phase: " fp; phase_done=1; next}
  in_fm && in_prog && /^[^[:space:]]/{in_prog=0}
  {print}
' "$abs_path" > "$tmp" && mv "$tmp" "$abs_path"

# 2. Append au worklog (best-effort — pas d'erreur si worklog absent)
id="${feature##*/}"
worklog_path="$(dirname "$abs_path")/$id.worklog.md"
if [[ -f "$worklog_path" ]]; then
  {
    printf '\n## %s — /aic undo\n' "$(date +"%Y-%m-%d %H:%M")"
    printf -- '- Restauration : phase %s → %s (status %s)\n' "$to_phase" "$from_phase" "$from_status"
    printf -- '- Snapshot consommé : %s\n' "$ts_human"
  } >> "$worklog_path"
fi

# 3. Supprimer la dernière ligne du history (FIFO consume)
total=$(wc -l < "$history_file")
if [[ "$total" -gt 1 ]]; then
  tmph=$(mktemp "${history_file}.XXXXXX")
  head -n $((total - 1)) "$history_file" > "$tmph" && mv "$tmph" "$history_file"
else
  : > "$history_file"
fi

# 4. Rebuild index
bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true

echo "✅ Undo appliqué. Prochain --apply pointera sur l'entrée précédente."
exit 0
