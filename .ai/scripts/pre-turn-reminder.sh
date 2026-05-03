#!/bin/bash
# Pre-turn protocol reminder (ai_context).
#
# Injecte :
#   - le contenu statique de .ai/reminder.md
#   - la liste dynamique des features actives (par scope), filtrée par status
#   - les dépendances inverses (qui dépend de chaque feature)
#
# Source : .ai/.feature-index.json (compilé par build-feature-index.sh)
#
# Filtre par défaut : status ∈ {active, draft}. Override via AI_CONTEXT_SHOW_ALL_STATUS=1.
#
# Focus (graph-aware) :
#   AI_CONTEXT_FOCUS=<scope> ou --focus=<scope> limite l'inventaire au scope
#   demandé + ses voisins 1-hop (features en relation depends_on dans les deux
#   sens). Sur un mesh >100 features, gain ~5× en tokens.
#
# Usage :
#   pre-turn-reminder.sh                      # texte brut sur stdout
#   pre-turn-reminder.sh --format=json        # JSON pour Claude Code hookSpecificOutput
#   pre-turn-reminder.sh --focus=back         # focus scope back + 1-hop
#
# Debug : AI_CONTEXT_DEBUG=1 bash pre-turn-reminder.sh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

format="text"
focus="${AI_CONTEXT_FOCUS:-}"
for arg in "$@"; do
  case "$arg" in
    --format=*) format="${arg#--format=}" ;;
    --focus=*) focus="${arg#--focus=}" ;;
    text) format="text" ;;
    *) echo "Argument inconnu : $arg" >&2
       echo "Usage : $0 [--format=text|--format=json] [--focus=<scope>]" >&2
       exit 2 ;;
  esac
done
repo_root="$(cd "$script_dir/../.." && pwd)"
reminder_file="$script_dir/../reminder.md"
features_dir="$repo_root/$AI_CONTEXT_FEATURES_DIR"
index_file="$repo_root/.ai/.feature-index.json"

if [[ ! -f "$reminder_file" ]]; then
  echo "reminder.md introuvable : $reminder_file" >&2
  exit 1
fi

reminder=$(cat "$reminder_file")

ensure_index() {
  if [[ ! -f "$index_file" ]]; then
    bash "$script_dir/build-feature-index.sh" --write 2>/dev/null || return 0
    return
  fi
  if [[ -d "$features_dir" ]]; then
    if find "$features_dir" -name '*.md' -newer "$index_file" -print -quit 2>/dev/null | grep -q .; then
      bash "$script_dir/build-feature-index.sh" --write 2>/dev/null || true
    fi
  fi
}

# ─── Inventaire dynamique ───
feature_section=""
reverse_section=""
if [[ -d "$features_dir" ]]; then
  ensure_index
  if [[ -f "$index_file" ]]; then
    visible=$(visible_statuses_jq)

    # Validation focus : si le scope demandé n'a aucune feature, ignorer + warn stderr
    if [[ -n "$focus" ]]; then
      has_focus=$(jq --arg f "$focus" '.features | map(select(.scope == $f)) | length' "$index_file")
      if [[ "$has_focus" -eq 0 ]]; then
        echo "⚠️  focus=$focus : aucune feature dans ce scope, focus ignoré" >&2
        focus=""
      fi
    fi

    # Inventaire : group by scope, status visible, éventuellement restreint au focus + 1-hop
    feature_lines=$(jq -r --argjson v "$visible" --arg focus "$focus" '
      (.features | map(select(.status as $s | $v | index($s)))) as $all
      | (if $focus == "" then $all
         else
           ($all | map(select(.scope == $focus))) as $focused
           | ($focused | map(.scope + "/" + .id)) as $fkeys
           | ($focused | map(.depends_on // []) | add // []) as $deps_of_focus
           | $all | map(
               . as $f
               | ($f.scope + "/" + $f.id) as $key
               | select(
                   $f.scope == $focus
                   or (($deps_of_focus | index($key)) != null)
                   or (($f.depends_on // []) | any(. as $d | $fkeys | index($d)))
                 )
             )
         end)
      | group_by(.scope)[]
      | "  • " + (.[0].scope) + "/ :"
        + ([.[] | " " + .id + "(" + .status + ")"] | join(""))
    ' "$index_file")

    total=$(jq '.features | length' "$index_file")
    visible_count=$(jq --argjson v "$visible" '.features | map(select(.status as $s | $v | index($s))) | length' "$index_file")
    hidden=$((total - visible_count))

    # Compter neighbors hors focus (pour hint)
    if [[ -n "$focus" ]]; then
      neighbors=$(jq --argjson v "$visible" --arg focus "$focus" '
        (.features | map(select(.status as $s | $v | index($s)))) as $all
        | ($all | map(select(.scope == $focus))) as $focused
        | ($focused | map(.scope + "/" + .id)) as $fkeys
        | ($focused | map(.depends_on // []) | add // []) as $deps_of_focus
        | $all | map(
            . as $f
            | ($f.scope + "/" + $f.id) as $key
            | select(
                $f.scope != $focus
                and ((($deps_of_focus | index($key)) != null)
                     or (($f.depends_on // []) | any(. as $d | $fkeys | index($d))))
              )
          ) | length
      ' "$index_file")
    fi

    header_suffix=""
    if [[ -n "$focus" ]]; then
      header_suffix=" (focus=$focus, +$neighbors voisin(s) 1-hop)"
    fi

    if [[ -n "$feature_lines" ]]; then
      feature_section=$'\n\n── Features actives'"$header_suffix"$' (lis le .md du scope primaire AVANT toute écriture) ──\n'
      feature_section+="$feature_lines"$'\n'
      if [[ $hidden -gt 0 ]]; then
        feature_section+="  ($hidden masquée(s) — status done/deprecated/archived. AI_CONTEXT_SHOW_ALL_STATUS=1 pour voir)"$'\n'
      fi
      if [[ -n "$focus" ]]; then
        feature_section+="  (AI_CONTEXT_FOCUS vide pour voir tout le mesh)"$'\n'
      fi
    elif [[ $hidden -gt 0 ]]; then
      feature_section=$'\n\n── Features actives ──\n'
      feature_section+="  (aucune feature active — $hidden masquée(s) avec status done/deprecated/archived)"$'\n'
      feature_section+="  AI_CONTEXT_SHOW_ALL_STATUS=1 pour voir l'historique."$'\n'
    else
      feature_section=$'\n\n── Features actives ──\n  (aucune feature documentée — la 1ère tâche DOIT en créer une)\n'
    fi

    # Reverse deps : filter X ET Y dans status visibles ; si focus, ne garde que les paires où X est dans le focus
    reverse_lines=$(jq -r --argjson v "$visible" --arg focus "$focus" '
      (.features | map(select(.status as $s | $v | index($s)))) as $visible_features
      | $visible_features[]
      | . as $f
      | ($f.scope + "/" + $f.id) as $key
      | select($focus == "" or $f.scope == $focus)
      | (
          $visible_features
          | map(select(.depends_on[]? == $key))
          | map(.scope + "/" + .id)
        ) as $reverse
      | select($reverse | length > 0)
      | if ($reverse | length) > 20 then
          "  ⚠️  " + $key + " a " + ($reverse | length | tostring) + " dépendants actifs — envisager un découpage"
        else
          "  • " + $key + " ← " + ($reverse | join(", "))
        end
    ' "$index_file")

    if [[ -n "$reverse_lines" ]]; then
      reverse_section=$'\n── Dépendances inverses (si tu modifies X, les suivants dépendent de lui) ──\n'
      reverse_section+="$reverse_lines"$'\n'
    fi
  fi
fi

full_reminder="${reminder}${feature_section}${reverse_section}"

log_debug "reminder length : ${#full_reminder}"

# Warn si le contexte injecté dépasse le seuil configuré.
# .ai/config.yml → context.max_tokens_warn (int, 0 = désactivé). Défaut 0.
config_file="$repo_root/.ai/config.yml"
max_tokens_warn="$(read_config 'context.max_tokens_warn' '0' "$config_file")"
if [[ "$max_tokens_warn" =~ ^[0-9]+$ ]] && [[ "$max_tokens_warn" -gt 0 ]]; then
  approx_tokens=$(( ${#full_reminder} / 4 ))
  if [[ "$approx_tokens" -gt "$max_tokens_warn" ]]; then
    echo "⚠️  pre-turn-reminder : ~${approx_tokens} tokens (seuil ${max_tokens_warn} via context.max_tokens_warn). Considère AI_CONTEXT_FOCUS=<scope> ou passer des features en status: done." >&2
  fi
fi

case "$format" in
  json)
    jq -n --arg ctx "$full_reminder" '{
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: $ctx
      }
    }'
    ;;
  text)
    echo "$full_reminder"
    ;;
  *)
    echo "Format inconnu : $format" >&2
    echo "Usage : $0 [--format=text|--format=json] [--focus=<scope>]" >&2
    exit 2
    ;;
esac
