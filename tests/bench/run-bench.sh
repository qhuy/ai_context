#!/bin/bash
# run-bench.sh — Harnais de benchmark d'efficacité agent (ai_context).
#
# Initiative product/agent-efficacy-benchmark (P1). v1 MAINTAINER-ONLY.
# Mesure le taux de succès de tâche AVEC vs SANS ai_context, sur repos de
# référence, N runs. Voir docs/benchmarks/PROTOCOL.md.
#
# Usage :
#   bash tests/bench/run-bench.sh --self-check      # valide le plumbing, n'invoque PAS d'agent
#   AGENT_CMD='claude -p' BENCH_REPOS='/path/a /path/b' bash tests/bench/run-bench.sh
#
# Le runner n'embarque aucun agent : il appelle le seam $AGENT_CMD (commande
# non-interactive recevant le prompt de la tâche et opérant dans le cwd).
#
# Config (env) :
#   AGENT_CMD    — commande agent (obligatoire pour un run réel)
#   BENCH_REPOS  — chemins de repos de référence, séparés par espaces
#   BENCH_N      — runs par (repo × tâche × condition), défaut 3
#   BENCH_TASKS  — dossier des tâches, défaut tests/bench/tasks

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

BENCH_N="${BENCH_N:-3}"
BENCH_TASKS="${BENCH_TASKS:-$script_dir/tasks}"
mode="run"
[[ "${1:-}" == "--self-check" ]] && mode="self-check"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { sed -n '1,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

fail=0
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko()   { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; fail=1; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1" >&2; }

# --- Découverte + validation des tâches (commune aux deux modes) ---
tasks=()
if [[ -d "$BENCH_TASKS" ]]; then
  while IFS= read -r d; do tasks+=("$d"); done \
    < <(find "$BENCH_TASKS" -mindepth 1 -maxdepth 1 -type d | sort)
fi

validate_tasks() {
  [[ ${#tasks[@]} -gt 0 ]] || { ko "aucune tâche sous $BENCH_TASKS"; return; }
  for t in "${tasks[@]}"; do
    local id; id="$(basename "$t")"
    [[ -f "$t/task.md" ]]    || ko "tâche $id : task.md manquant"
    if [[ -f "$t/check.sh" ]]; then
      [[ -x "$t/check.sh" ]] || ko "tâche $id : check.sh non exécutable (chmod +x)"
    else
      ko "tâche $id : check.sh (grader objectif) manquant"
    fi
  done
}

# --- Conditions : dépouiller la couche ai_context pour 'without' ---
strip_ai_context() {
  local dir="$1"
  ( cd "$dir" && rm -rf .ai .docs AGENTS.md CLAUDE.md GEMINI.md \
      .github/copilot-instructions.md .cursor 2>/dev/null || true )
}

echo "═══ run-bench ($mode) ═══"
validate_tasks

if [[ "$mode" == "self-check" ]]; then
  # Repos : présence seulement (optionnels en self-check).
  repos=()
  if [[ -n "${BENCH_REPOS:-}" ]]; then
    # shellcheck disable=SC2206
    repos=( ${BENCH_REPOS} )
    for r in "${repos[@]}"; do
      [[ -d "$r" ]] && ok "repo présent : $r" || ko "repo introuvable : $r"
    done
  else
    warn "BENCH_REPOS non défini (requis pour un run réel)"
  fi
  [[ -n "${AGENT_CMD:-}" ]] && ok "AGENT_CMD défini" || warn "AGENT_CMD non défini (requis pour un run réel)"

  # Matrice qui SERAIT exécutée.
  n_repos=${#repos[@]}; [[ $n_repos -eq 0 ]] && n_repos=0
  total=$(( n_repos * ${#tasks[@]} * 2 * BENCH_N ))
  echo "  matrice : ${n_repos} repo(s) × ${#tasks[@]} tâche(s) × 2 conditions × N=${BENCH_N} = ${total} runs"
  echo
  if [[ "$fail" -eq 0 ]]; then echo "✅ self-check OK (plumbing valide ; aucun agent invoqué)"; exit 0
  else echo "❌ self-check FAIL"; exit 1; fi
fi

# --- Run réel ---
[[ -n "${AGENT_CMD:-}" ]]   || { ko "AGENT_CMD requis pour un run réel"; }
[[ -n "${BENCH_REPOS:-}" ]] || { ko "BENCH_REPOS requis pour un run réel"; }
[[ "$fail" -eq 0 ]] || { echo "❌ run impossible (config incomplète) — voir --self-check"; exit 1; }

# shellcheck disable=SC2206
repos=( ${BENCH_REPOS} )
report_dir="$script_dir/../../docs/benchmarks/reports"
mkdir -p "$report_dir"
echo "  (run réel : copie repo → condition with/without → AGENT_CMD → check.sh → tally)"
echo "  ⚠ dépend de \$AGENT_CMD ; coûteux + non-déterministe. Rapport sous $report_dir/"
# Boucle réelle : laissée au câblage mainteneur (AGENT_CMD spécifique à l'agent/CLI).
# Le squelette d'orchestration (copie, strip, grade, tally, report) est décrit
# dans PROTOCOL.md ; le point d'extension est l'appel AGENT_CMD ci-dessus.
echo "ℹ️  Câbler l'appel AGENT_CMD dans la boucle repos×tâches×conditions×N avant le premier run réel."
exit 0
