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
# Le runner n'embarque aucun agent : il appelle le seam $AGENT_CMD dans une
# copie de travail isolée. Le prompt de la tâche est fourni sur stdin.
#
# Config (env) :
#   AGENT_CMD          — commande agent (obligatoire pour un run réel)
#   BENCH_REPOS        — chemins de repos de référence, séparés par espaces
#   BENCH_N            — runs par (repo × tâche × condition), défaut 3
#   BENCH_TASKS        — dossier des tâches, défaut tests/bench/tasks
#   BENCH_AGENT_LABEL  — libellé consigné dans les rapports (évite de logger des secrets)
#   BENCH_REPORT_DIR   — dossier des rapports, défaut docs/benchmarks/reports
#   BENCH_RUN_DIR      — dossier des logs, défaut docs/benchmarks/runs/<stamp>
#   BENCH_SEED         — seed de randomisation de la matrice, défaut epoch seconds
#   BENCH_KEEP_WORKDIR — 1 pour conserver les copies de travail temporaires
#   BENCH_TIMEOUT_SECONDS — timeout par cellule agent, défaut 300

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

BENCH_N="${BENCH_N:-3}"
BENCH_TASKS="${BENCH_TASKS:-$script_dir/tasks}"
BENCH_SEED="${BENCH_SEED:-$(date +%s)}"
BENCH_STAMP="${BENCH_STAMP:-$(date +%Y-%m-%d-%H%M%S)}"
BENCH_AGENT_LABEL="${BENCH_AGENT_LABEL:-non renseigne}"
BENCH_REPORT_DIR="${BENCH_REPORT_DIR:-$repo_root/docs/benchmarks/reports}"
BENCH_RUN_DIR="${BENCH_RUN_DIR:-$repo_root/docs/benchmarks/runs/$BENCH_STAMP}"
BENCH_KEEP_WORKDIR="${BENCH_KEEP_WORKDIR:-0}"
BENCH_TIMEOUT_SECONDS="${BENCH_TIMEOUT_SECONDS:-300}"
mode="run"
[[ "${1:-}" == "--self-check" ]] && mode="self-check"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { sed -n '1,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

fail=0
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko()   { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; fail=1; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1" >&2; }

slugify() {
  printf "%s" "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/^$/repo/'
}

path_hash() {
  printf "%s" "$1" | cksum | awk '{ print $1 }'
}

repo_slug_for() {
  local path="$1" name="$2"
  printf "%s-%s" "$(slugify "$name")" "$(path_hash "$path")"
}

json_escape() {
  printf "%s" "$1" \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e $'s/\t/\\t/g'
}

copy_repo() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
      --exclude '.git' \
      --exclude 'tests/bench' \
      --exclude 'docs/benchmarks/reports' \
      --exclude 'docs/benchmarks/runs' \
      "$src"/ "$dest"/
  else
    ( cd "$src" && tar \
        --exclude='.git' \
        --exclude='tests/bench' \
        --exclude='docs/benchmarks/reports' \
        --exclude='docs/benchmarks/runs' \
        -cf - . ) | ( cd "$dest" && tar -xf - )
  fi
}

# --- Découverte + validation des tâches (commune aux deux modes) ---
tasks=()
if [[ -d "$BENCH_TASKS" ]]; then
  BENCH_TASKS="$(cd "$BENCH_TASKS" && pwd)"
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

validate_n() {
  [[ "$BENCH_N" =~ ^[1-9][0-9]*$ ]] || ko "BENCH_N doit être un entier positif (reçu : $BENCH_N)"
}

validate_timeout() {
  [[ "$BENCH_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]] || ko "BENCH_TIMEOUT_SECONDS doit être un entier positif (reçu : $BENCH_TIMEOUT_SECONDS)"
}

run_agent_command() {
  local workdir="$1" prompt_file="$2" stdout_log="$3" stderr_log="$4" task_id="$5" timeout_seconds="$6" agent_cmd="$7"
  python3 - "$workdir" "$prompt_file" "$stdout_log" "$stderr_log" "$task_id" "$timeout_seconds" "$agent_cmd" <<'PY'
import os
import pathlib
import signal
import subprocess
import sys

workdir, prompt_file, stdout_log, stderr_log, task_id, timeout_seconds, agent_cmd = sys.argv[1:]
timeout_seconds = int(timeout_seconds)

env = dict(os.environ)
for key in list(env):
    if key.startswith("BENCH_") or key == "AGENT_CMD":
        env.pop(key, None)
env["BENCH_TASK_ID"] = task_id
env["BENCH_WORKDIR"] = workdir

with open(prompt_file, "rb") as stdin, open(stdout_log, "wb") as stdout, open(stderr_log, "ab") as stderr:
    proc = subprocess.Popen(
        agent_cmd,
        shell=True,
        executable="/bin/bash",
        cwd=workdir,
        stdin=stdin,
        stdout=stdout,
        stderr=stderr,
        env=env,
        start_new_session=True,
    )
    try:
        proc.wait(timeout=timeout_seconds)
        raise SystemExit(proc.returncode)
    except subprocess.TimeoutExpired:
        stderr.write(f"\nBENCH_TIMEOUT after {timeout_seconds}s\n".encode("utf-8"))
        stderr.flush()
        try:
            os.killpg(proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            proc.wait()
        raise SystemExit(124)
PY
}

# --- Conditions : dépouiller la couche ai_context pour 'without' ---
strip_ai_context() {
  local dir="$1"
  ( cd "$dir" && rm -rf .ai .docs AGENTS.md CLAUDE.md GEMINI.md \
      .agents .claude/skills .github/copilot-instructions.md .cursor 2>/dev/null || true )
}

echo "═══ run-bench ($mode) ═══"
validate_tasks
validate_n
validate_timeout

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
for r in "${repos[@]}"; do
  [[ -d "$r" ]] && ok "repo présent : $r" || ko "repo introuvable : $r"
done
[[ "$fail" -eq 0 ]] || { echo "❌ run impossible (config incomplète) — voir --self-check"; exit 1; }

mkdir -p "$BENCH_REPORT_DIR" "$BENCH_RUN_DIR"
work_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-bench.XXXXXX")"
cleanup() {
  if [[ "$BENCH_KEEP_WORKDIR" == "1" ]]; then
    warn "copies de travail conservées : $work_root"
  else
    rm -rf "$work_root"
  fi
}
trap cleanup EXIT

results_tsv="$BENCH_REPORT_DIR/$BENCH_STAMP-results.tsv"
results_jsonl="$BENCH_REPORT_DIR/$BENCH_STAMP-results.jsonl"
matrix_file="$BENCH_RUN_DIR/matrix.tsv"
: > "$results_jsonl"
printf "repo_slug\trepo_name\trepo_path\ttask_id\tcondition\trun_index\tsuccess\tagent_exit\tcheck_exit\tduration_seconds\tworkdir\tstdout_log\tstderr_log\tcheck_log\n" > "$results_tsv"

for r in "${repos[@]}"; do
  for t in "${tasks[@]}"; do
    task_id="$(basename "$t")"
    for condition in with without; do
      run_index=1
      while [[ "$run_index" -le "$BENCH_N" ]]; do
        printf "%s\t%s\t%s\t%s\n" "$r" "$t" "$condition" "$run_index"
        run_index=$((run_index + 1))
      done
    done
  done
done \
  | awk -v seed="$BENCH_SEED" 'BEGIN { srand(seed) } { print rand() "\t" $0 }' \
  | sort -n \
  | cut -f2- > "$matrix_file"

echo "  run réel : ${#repos[@]} repo(s) × ${#tasks[@]} tâche(s) × 2 conditions × N=$BENCH_N"
echo "  seed : $BENCH_SEED"
echo "  agent : $BENCH_AGENT_LABEL"
echo "  timeout : ${BENCH_TIMEOUT_SECONDS}s"
echo "  rapports : $BENCH_REPORT_DIR"
echo "  logs : $BENCH_RUN_DIR"

while IFS=$'\t' read -r repo_path task_path condition run_index; do
  repo_name="$(basename "$repo_path")"
  repo_slug="$(repo_slug_for "$repo_path" "$repo_name")"
  task_id="$(basename "$task_path")"
  cell_slug="$(slugify "$repo_slug-$task_id-$condition-$run_index")"
  workdir="$work_root/$cell_slug/work"
  logdir="$BENCH_RUN_DIR/$cell_slug"
  stdout_log="$logdir/agent.stdout.log"
  stderr_log="$logdir/agent.stderr.log"
  check_log="$logdir/check.log"
  mkdir -p "$logdir"

  printf "  ▶ %s / %s / %s / run %s\n" "$repo_name" "$task_id" "$condition" "$run_index"
  copy_repo "$repo_path" "$workdir"
  [[ "$condition" == "without" ]] && strip_ai_context "$workdir"

  start_ts="$(date +%s)"
  set +e
  run_agent_command "$workdir" "$task_path/task.md" "$stdout_log" "$stderr_log" "$task_id" "$BENCH_TIMEOUT_SECONDS" "$AGENT_CMD"
  agent_exit=$?

  (
    cd "$workdir" || exit 127
    BENCH_PROMPT_FILE="$task_path/task.md" \
    BENCH_TASK_DIR="$task_path" \
    BENCH_TASK_ID="$task_id" \
    BENCH_CONDITION="$condition" \
    BENCH_RUN_INDEX="$run_index" \
    BENCH_REPO_NAME="$repo_name" \
    BENCH_SOURCE_REPO="$repo_path" \
    BENCH_WORKDIR="$workdir" \
      "$task_path/check.sh"
  ) > "$check_log" 2>&1
  check_exit=$?
  set -e
  end_ts="$(date +%s)"
  duration=$((end_ts - start_ts))

  success=0
  if [[ "$agent_exit" -eq 0 && "$check_exit" -eq 0 ]]; then
    success=1
    ok "$repo_name / $task_id / $condition / run $run_index"
  else
    warn "$repo_name / $task_id / $condition / run $run_index FAIL (agent=$agent_exit check=$check_exit)"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$repo_slug" "$repo_name" "$repo_path" "$task_id" "$condition" "$run_index" \
    "$success" "$agent_exit" "$check_exit" "$duration" "$workdir" "$stdout_log" "$stderr_log" "$check_log" \
    >> "$results_tsv"

  printf '{"stamp":"%s","repo_slug":"%s","repo_name":"%s","repo_path":"%s","task_id":"%s","condition":"%s","run_index":%s,"success":%s,"agent_exit":%s,"check_exit":%s,"duration_seconds":%s,"stdout_log":"%s","stderr_log":"%s","check_log":"%s"}\n' \
    "$(json_escape "$BENCH_STAMP")" "$(json_escape "$repo_slug")" "$(json_escape "$repo_name")" "$(json_escape "$repo_path")" \
    "$(json_escape "$task_id")" "$(json_escape "$condition")" "$run_index" "$success" "$agent_exit" "$check_exit" "$duration" \
    "$(json_escape "$stdout_log")" "$(json_escape "$stderr_log")" "$(json_escape "$check_log")" \
    >> "$results_jsonl"
done < "$matrix_file"

report_files=()
while IFS= read -r repo_slug; do
  [[ -n "$repo_slug" ]] || continue
  report="$BENCH_REPORT_DIR/$BENCH_STAMP-$repo_slug.md"
  repo_name="$(awk -F '\t' -v repo="$repo_slug" 'NR > 1 && $1 == repo { print $2; exit }' "$results_tsv")"
  repo_path="$(awk -F '\t' -v repo="$repo_slug" 'NR > 1 && $1 == repo { print $3; exit }' "$results_tsv")"

  {
    echo "# Benchmark agent — $repo_name"
    echo
    echo "- Date : $BENCH_STAMP"
    echo "- Repo : \`$repo_path\`"
    echo "- Agent : $BENCH_AGENT_LABEL"
    echo "- N : $BENCH_N"
    echo "- Seed : $BENCH_SEED"
    echo "- Résultats bruts : \`$results_tsv\`"
    echo "- Artefact JSONL : \`$results_jsonl\`"
    echo
    echo "## Synthèse"
    echo
    echo "| Condition | Succès | Total | Taux |"
    echo "|---|---:|---:|---:|"
    for condition in with without; do
      awk -F '\t' -v repo="$repo_slug" -v condition="$condition" '
        NR > 1 && $1 == repo && $5 == condition { total += 1; success += $7 }
        END {
          rate = total ? (100 * success / total) : 0
          printf "| `%s` | %d | %d | %.1f%% |\n", condition, success, total, rate
        }
      ' "$results_tsv"
    done
    echo
    awk -F '\t' -v repo="$repo_slug" '
      NR > 1 && $1 == repo && $5 == "with" { with_total += 1; with_success += $7 }
      NR > 1 && $1 == repo && $5 == "without" { without_total += 1; without_success += $7 }
      END {
        with_rate = with_total ? (100 * with_success / with_total) : 0
        without_rate = without_total ? (100 * without_success / without_total) : 0
        printf "Δ succès (`with` - `without`) : **%.1f points**.\n", with_rate - without_rate
      }
    ' "$results_tsv"
    echo
    echo "## Détail"
    echo
    echo "| Tâche | Condition | Run | Résultat | Agent | Check | Logs |"
    echo "|---|---|---:|---|---:|---:|---|"
    awk -F '\t' -v repo="$repo_slug" '
      NR > 1 && $1 == repo {
        result = ($7 == 1) ? "PASS" : "FAIL"
        printf "| `%s` | `%s` | %s | %s | %s | %s | `%s` |\n", $4, $5, $6, result, $8, $9, $14
      }
    ' "$results_tsv"
    echo
    echo "## Notes"
    echo
    echo "- \`AGENT_CMD\` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser \`BENCH_AGENT_LABEL\` pour tracer le modèle/runner."
    echo "- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec."
  } > "$report"
  report_files+=("$report")
done < <(awk -F '\t' 'NR > 1 { print $1 }' "$results_tsv" | sort -u)

echo
echo "✅ run terminé"
printf "  rapport : %s\n" "${report_files[@]}"
echo "  résultats : $results_tsv"
echo "  jsonl : $results_jsonl"
