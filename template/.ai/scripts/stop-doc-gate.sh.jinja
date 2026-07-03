#!/bin/bash
# stop-doc-gate.sh — Hook Stop (fin de tour Claude) : forcing function doc.
#
# Ferme la fenetre "edite -> verifie -> done annonce, mais ni commit ni doc a
# jour". A la fin du tour, si du code couvert par une feature a ete modifie dans
# le working tree SANS que la fiche/worklog de cette feature soit aussi modifiee,
# bloque la fin de tour et reinjecte le motif : l'agent doit mettre la doc a jour
# (ou commiter) avant de pouvoir clore. Signale en avertissement NON bloquant les
# chemins touches couverts par AUCUNE feature (orphelins -> fiche a creer/rattacher).
#
# Severite differenciee :
#   - fraicheur (code couvert edite sans doc) = BLOQUANT. Signal present-based
#     working-tree (check-feature-freshness.sh --worktree), jamais base sur des
#     timestamps de commit : il ne souffre pas du "treadmill staleness".
#   - couverture / orphelin = WARN. Creer/rattacher une fiche est un jugement
#     scope/id que le hook ne peut pas automatiser ; on alerte sans bloquer.
#
# Mecanisme de blocage Claude Code : JSON {"decision":"block","reason":...} sur
# stdout, exit 0. Anti-boucle : si stop_hook_active=true (Claude relance deja
# suite a un block), on relache (exit 0).
#
# GARANTIE STABLE = hooks/checks VCS (Git commit-msg ou pre-checkin/CI TFVC) + CI.
# Ce hook est une couche de forcing CLAUDE-ONLY, read-only, jamais la garantie
# unique. Les agents non-Claude sont couverts au commit/checkin et en CI.
#
# ORDRE STOP (IMPORTANT) : ce hook DOIT etre cable AVANT auto-worklog-flush.sh.
# Sinon le flush auto-touche le worklog de la feature, et le gate passe a vide.
#
# Echappatoire tracee : AIC_DOC_GATE=off (ou 0/false/no) => exit 0 (WIP
# multi-tour, refactor pur). A utiliser sciemment : la garantie commit/CI reste.
#
# Read-only : index temporaire via mktemp, jamais d'ecriture de
# .ai/.feature-index.json (cf. quality/read-only-checks-contract).
#
# Best-effort : provider VCS/jq absents => exit 0 (on ne bloque jamais faute d'outil).

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

# ─── Echappatoire tracee ───
case "${AIC_DOC_GATE:-on}" in
  off|0|false|no) exit 0 ;;
esac

# ─── Payload Stop (stdin JSON) + anti-boucle ───
stdin_json=""
if [[ ! -t 0 ]]; then
  stdin_json="$(cat 2>/dev/null || true)"
fi
if [[ -n "$stdin_json" ]] && command -v jq >/dev/null 2>&1; then
  active="$(printf '%s' "$stdin_json" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
  [[ "$active" == "true" ]] && exit 0
fi

# ─── Dependances best-effort ───
command -v jq  >/dev/null 2>&1 || exit 0
[[ "$(vcs_provider)" != "none" ]] || exit 0
repo_root="$(vcs_root)"
[[ -z "$repo_root" ]] && exit 0
cd "$repo_root"

# ─── 1. Fraicheur working-tree (bloquant) ───
fresh_out="$(bash "$script_dir/check-feature-freshness.sh" --worktree --strict 2>&1)"
fresh_rc=$?

# ─── 2. Orphelins sur le change set substantiel (warn, non bloquant) ───
index_tmp="$(mktemp "${TMPDIR:-/tmp}/aic-stopgate-index.XXXXXX")"
trap 'rm -f "$index_tmp"' EXIT
index_for_orphans=""
if bash "$script_dir/build-feature-index.sh" > "$index_tmp" 2>/dev/null; then
  index_for_orphans="$index_tmp"
elif [[ -f ".ai/.feature-index.json" ]]; then
  index_for_orphans=".ai/.feature-index.json"
fi

orphans=""
if [[ -n "$index_for_orphans" ]]; then
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    path_in_coverage_scope "$rel" || continue
    if [[ -z "$(features_matching_path "$index_for_orphans" "$rel")" ]]; then
      orphans="${orphans}  - ${rel}"$'\n'
    fi
  done < <(collect_uncommitted_paths)
fi

# ─── 3. Verdict ───
if [[ "$fresh_rc" -ne 0 ]]; then
  reason="🚨 Doc gate (fin de tour) — fraicheur documentaire non satisfaite."$'\n\n'
  reason="${reason}${fresh_out}"$'\n\n'
  reason="${reason}Action : mets a jour la fiche feature impactee (ou son worklog) AVANT de terminer, ou commit le delta. Echappatoire WIP : export AIC_DOC_GATE=off."
  if [[ -n "$orphans" ]]; then
    reason="${reason}"$'\n\n'"⚠️ Chemins touches couverts par AUCUNE feature (creer/rattacher une fiche) :"$'\n'"${orphans}"
  fi
  jq -nc --arg r "$reason" '{decision:"block", reason:$r}'
  exit 0
fi

# Fraicheur OK. Orphelins eventuels => warn non bloquant (stderr + additionalContext).
if [[ -n "$orphans" ]]; then
  {
    echo "⚠️ Doc gate (fin de tour) — chemins touches couverts par AUCUNE feature :"
    printf '%s' "$orphans"
    echo "  → creer/rattacher une fiche .docs/features/<scope>/<id>.md (non bloquant)."
  } >&2
  jq -nc --arg c "$orphans" '{hookSpecificOutput:{hookEventName:"Stop", additionalContext:("⚠️ Doc gate — chemins touches couverts par aucune feature (creer/rattacher une fiche) :\n" + $c)}}'
fi

exit 0
