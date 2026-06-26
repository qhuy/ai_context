#!/bin/bash
# stop-sequence.sh — Hook Stop UNIQUE (fin de tour Claude).
#
# Les hooks Stop de Claude Code tournent EN PARALLELE (ordre non garanti, cf.
# doc officielle "All matching hooks run in parallel"). Or le gate doc
# (stop-doc-gate.sh) doit observer le working tree AVANT que auto-worklog-flush.sh
# ne touche les worklogs/fiches : sinon l'entree worklog auto-appendee satisferait
# le gate (proxie "fiche OU worklog touche") et neutraliserait le blocage.
#
# On serialise donc tout dans un seul hook Stop :
#   1. stop-doc-gate.sh (read-only) D'ABORD. S'il renvoie decision:block, on relaie
#      le motif et on N'ARCHIVE PAS ce tour (le worklog reste honnete ; l'archivage
#      se fera au vrai Stop suivant, .session-edits.log n'etant pas consomme).
#   2. Sinon : auto-worklog-flush.sh -> auto-progress.sh -> context-relevance-log.sh
#      summary (sequentiel, ordre preserve), puis on relaie l'eventuel
#      additionalContext (warn orphelins) emis par le gate.
#
# Best-effort : aucune erreur d'archivage ne bloque la fin de tour. Le gate reste
# la seule source de blocage ; l'archivage est non bloquant.

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

# Payload Stop (stdin JSON) lu une seule fois, relaye au gate (stop_hook_active).
stdin_json=""
if [[ ! -t 0 ]]; then
  stdin_json="$(cat 2>/dev/null || true)"
fi

# ─── 1. Gate read-only (stderr du gate relaye tel quel) ───
gate_out="$(printf '%s' "$stdin_json" | bash "$script_dir/stop-doc-gate.sh" || true)"

if printf '%s' "$gate_out" | grep -q '"decision":"block"'; then
  printf '%s\n' "$gate_out"
  exit 0
fi

# ─── 2. Pas de blocage : archivage best-effort, sequentiel ───
bash "$script_dir/auto-worklog-flush.sh" >/dev/null 2>&1 || true
bash "$script_dir/auto-progress.sh" >/dev/null 2>&1 || true
bash "$script_dir/context-relevance-log.sh" summary >/dev/null 2>&1 || true

# Relaie l'eventuel warn (additionalContext orphelins) du gate.
[[ -n "$gate_out" ]] && printf '%s\n' "$gate_out"

exit 0
