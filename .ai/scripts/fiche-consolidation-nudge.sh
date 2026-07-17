#!/bin/bash
# fiche-consolidation-nudge.sh — Hook PreToolUse(Write|Edit|MultiEdit).
#
# Quand un agent ÉDITE une fiche feature EXISTANTE (.docs/features/<scope>/<id>.md,
# hors *.worklog.md), réinjecte en contexte une question de raison d'être + la liste
# des fiches sœurs (même scope, familles d'id en tête) pour repérer le sur-découpage
# et consolider/fusionner/supprimer au fil de l'eau (pas en une passe).
#
# ADVISORY, NON bloquant : additionalContext + exit 0 toujours. Cohérent avec la
# décision workflow/feature-granularity (« pas de contrôle fragile/bloquant dans
# les scripts »). Pendant edit-time du « Check anti fourre-tout » de feature-new.
#
# Early-exit (coût ~nul) si l'édition ne porte pas sur une fiche existante :
#   - tool ∉ {Write,Edit,MultiEdit} ;
#   - chemin = *.worklog.md ou hors features/<scope>/<id>.md ;
#   - fichier absent (= création → feature-new a sa propre discipline).
#
# Read-only, best-effort : aucune écriture, jamais de blocage.

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"
repo_root="$(cd "$script_dir/../.." && pwd)"
features_root="$repo_root/$AI_CONTEXT_FEATURES_DIR"

# Mode hook uniquement (stdin JSON). Sinon no-op.
[[ -t 0 ]] && exit 0
payload="$(cat 2>/dev/null || true)"
[[ -z "$payload" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // ""' 2>/dev/null || echo "")"
case "$tool_name" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac

file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")"
[[ -z "$file_path" ]] && exit 0

# Early-exit : uniquement une fiche canonique existante, jamais index/log/worklog.
case "$file_path" in
  /*) ;;
  *) file_path="$repo_root/${file_path#./}" ;;
esac
[[ -f "$file_path" ]] || exit 0
file_path="$(cd "$(dirname "$file_path")" && pwd -P)/$(basename "$file_path")"
if [[ -d "$features_root" ]]; then
  features_root="$(cd "$features_root" && pwd -P)"
fi
is_canonical_feature_doc "$file_path" "$features_root" || exit 0

# Édition d'une fiche EXISTANTE seulement (PreToolUse = avant écriture : fichier
# absent ⇒ création ⇒ skip). On travaille sur file_path absolu (robuste aux
# symlinks / repo_root non aligné), pas besoin de repo_root.
abs_dir="${file_path%/*}"      # .../features/<scope>
id="${file_path##*/}"; id="${id%.md}"
scope="${abs_dir##*/}"
[[ -d "$abs_dir" ]] || exit 0

# Fiches sœurs (même scope = même dossier). Familles d'id (<base>-<suffixe>) en tête.
oth_cap=12
family=""
others=""
oth_total=0
oth_shown=0
for f in "$abs_dir"/*.md; do
  [[ -e "$f" ]] || continue
  is_canonical_feature_doc "$f" "$features_root" || continue
  bn="${f##*/}"; bn="${bn%.md}"
  [[ "$bn" == "$id" ]] && continue
  if [[ "$bn" == "$id"-* || "$id" == "$bn"-* ]]; then
    family="${family}  • ${scope}/${bn}  ← même famille d'id"$'\n'
  else
    oth_total=$((oth_total + 1))
    if [[ "$oth_shown" -lt "$oth_cap" ]]; then
      others="${others}  • ${scope}/${bn}"$'\n'
      oth_shown=$((oth_shown + 1))
    fi
  fi
done
if [[ "$oth_total" -gt "$oth_cap" ]]; then
  others="${others}  • … (+$((oth_total - oth_cap)) autres fiches du scope)"$'\n'
fi

msg="🧭 Tu édites la fiche ${scope}/${id} — réinterroge sa raison d'être AVANT d'enrichir :"$'\n'
msg="${msg}  - Objectif / DONE / validations encore DISTINCTS d'une fiche voisine ? Sinon → consolider/fusionner, ou supprimer si redondante."$'\n'
msg="${msg}  - Une fiche = un livrable cohérent, pas un fragment de domaine (cf. workflow/feature-granularity)."$'\n'
if [[ -n "$family" || -n "$others" ]]; then
  msg="${msg}Fiches du même scope (candidats consolidation) :"$'\n'
  [[ -n "$family" ]] && msg="${msg}${family}"
  [[ -n "$others" ]] && msg="${msg}${others}"
  msg="${msg}Si une voisine couvre le même objectif/DONE/validations → fusionner plutôt qu'enrichir."
else
  msg="${msg}(Aucune fiche voisine dans ce scope — si l'intention n'est plus livrable, envisager archive/suppression.)"
fi
msg="${msg}"$'\n'"Advisory (workflow/feature-consolidation-nudge) — non bloquant."

jq -nc --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$c}}'
exit 0
