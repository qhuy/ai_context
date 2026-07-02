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
#                        si personnalisé, son basename doit rester BENCH_STAMP
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

display_path() {
  local path="$1"
  if [[ "$path" == "$repo_root" ]]; then
    printf "."
  elif [[ "$path" == "$repo_root/"* ]]; then
    printf "%s" "${path#$repo_root/}"
  elif [[ -n "${work_root:-}" && "$path" == "$work_root/"* ]]; then
    printf "<tmp>/%s" "${path#$work_root/}"
  elif [[ -n "${BENCH_REPORT_DIR:-}" && "$path" == "$BENCH_REPORT_DIR/"* ]]; then
    printf "%s/%s" "$(basename "$BENCH_REPORT_DIR")" "${path#$BENCH_REPORT_DIR/}"
  elif [[ -n "${BENCH_RUN_DIR:-}" && "$path" == "$BENCH_RUN_DIR/"* ]]; then
    printf "%s/%s" "$(basename "$BENCH_RUN_DIR")" "${path#$BENCH_RUN_DIR/}"
  else
    printf "%s" "$path"
  fi
}

resolved_target_path() {
  local target="$1" parent base resolved_parent
  parent="$(dirname "$target")"
  base="$(basename "$target")"
  resolved_parent="$(cd "$parent" 2>/dev/null && pwd -P)" || return 1
  printf "%s/%s" "$resolved_parent" "$base"
}

path_is_under() {
  local target="$1" prefix="$2" resolved prefix_resolved
  resolved="$(resolved_target_path "$target")" || return 1
  prefix_resolved="$(cd "$prefix" 2>/dev/null && pwd -P)" || return 1
  [[ "$resolved" == "$prefix_resolved" || "$resolved" == "$prefix_resolved/"* ]]
}

rm_target_is_safe() {
  local target="${1:-}" required_prefix="${2:-}" required_basename="${3:-}"
  local base resolved required_resolved

  [[ -n "$target" ]] || return 1
  [[ "$target" != "/" && "$target" != "." && "$target" != ".." ]] || return 1

  base="$(basename "$target")"
  [[ -n "$base" && "$base" != "/" && "$base" != "." && "$base" != ".." ]] || return 1

  resolved="$(resolved_target_path "$target")" || return 1
  [[ "$resolved" != "/" && "$resolved" != "$repo_root" && "$resolved" != "${HOME:-}" ]] || return 1
  [[ "$resolved" != "/tmp" && "$resolved" != "/private/tmp" && "$resolved" != "${TMPDIR:-/tmp}" ]] || return 1

  if [[ -n "$required_prefix" ]]; then
    required_resolved="$(cd "$required_prefix" 2>/dev/null && pwd -P)" || return 1
    [[ "$resolved" == "$required_resolved" || "$resolved" == "$required_resolved/"* ]] || return 1
  fi

  if [[ -n "$required_basename" ]]; then
    [[ "$base" == "$required_basename" ]] || return 1
  fi

  return 0
}

safe_rm_rf() {
  local target="$1" label="${2:-target}" required_prefix="${3:-}" required_basename="${4:-}"
  if ! rm_target_is_safe "$target" "$required_prefix" "$required_basename"; then
    ko "refus rm -rf dangereux ($label) : ${target:-<vide>}"
    return 1
  fi
  rm -rf "$target"
}

repo_ref_for() {
  basename "$1"
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

validate_stamp() {
  [[ "$BENCH_STAMP" =~ ^[A-Za-z0-9._-]+$ ]] || ko "BENCH_STAMP doit rester un nom de dossier simple (reçu : $BENCH_STAMP)"
}

validate_run_dir() {
  [[ "$(basename "$BENCH_RUN_DIR")" == "$BENCH_STAMP" ]] || ko "BENCH_RUN_DIR doit terminer par BENCH_STAMP (run dir : $BENCH_RUN_DIR ; stamp : $BENCH_STAMP)"
  path_is_under "$BENCH_RUN_DIR" "$repo_root/docs/benchmarks/runs" \
    || path_is_under "$BENCH_RUN_DIR" "${TMPDIR:-/tmp}" \
    || ko "BENCH_RUN_DIR doit être sous docs/benchmarks/runs ou sous TMPDIR (reçu : $BENCH_RUN_DIR)"
}

matrix_sort_with_tiebreak() {
  sort -k1,1n -k2,2n | cut -f3-
}

randomize_matrix() {
  local seed="$1"
  awk -v seed="$seed" 'BEGIN { srand(seed) } { printf "%.17g\t%d\t%s\n", rand(), NR, $0 }' \
    | matrix_sort_with_tiebreak
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

extract_tokens_used() {
  local log="$1"
  [[ -f "$log" ]] || { printf "NA"; return; }
  awk '
    BEGIN { seen = 0; value = "" }
    tolower($0) ~ /^[[:space:]]*tokens used[[:space:]]*$/ { seen = 1; next }
    seen {
      candidate = $0
      gsub(/[^0-9]/, "", candidate)
      if (candidate != "") {
        value = candidate
        seen = 0
      }
    }
    END {
      if (value == "") print "NA"
      else print value
    }
  ' "$log"
}

task_class_for() {
  local task_dir="$1" task_id="$2" class_file value
  class_file="$task_dir/task.class"
  if [[ -f "$class_file" ]]; then
    value="$(sed -n '1p' "$class_file" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    value="${value//$'\t'/ }"
    if [[ -n "$value" ]]; then
      printf "%s" "$value"
      return
    fi
  fi
  printf "%s" "$task_id"
}

emit_token_class_delta_table() {
  local results_tsv="$1" repo_slug="$2"
  echo "| Classe | with n | with moy. | without n | without moy. | Δ tokens/run | Δ tokens/run % |"
  echo "|---|---:|---:|---:|---:|---:|---:|"
  awk -F '\t' -v repo="$repo_slug" '
    NR > 1 && $1 == repo && $12 ~ /^[0-9]+$/ {
      cls = ($17 != "" ? $17 : $4)
      count[cls SUBSEP $5] += 1
      total[cls SUBSEP $5] += $12
      classes[cls] = 1
    }
    END {
      for (cls in classes) {
        wc = count[cls SUBSEP "with"] + 0
        nc = count[cls SUBSEP "without"] + 0
        wt = total[cls SUBSEP "with"] + 0
        nt = total[cls SUBSEP "without"] + 0
        wm = wc ? wt / wc : 0
        nm = nc ? nt / nc : 0
        wms = wc ? sprintf("%.0f", wm) : "NA"
        nms = nc ? sprintf("%.0f", nm) : "NA"
        if (wc && nc) {
          delta = wm - nm
          delta_s = sprintf("%+.0f", delta)
          pct_s = nm ? sprintf("%+.1f%%", 100 * delta / nm) : "NA"
        } else {
          delta_s = "NA"
          pct_s = "NA"
        }
        printf "| `%s` | %d | %s | %d | %s | %s | %s |\n", cls, wc, wms, nc, nms, delta_s, pct_s
      }
    }
  ' "$results_tsv" | sort
}

emit_success_summary_table() {
  local results_tsv="$1" repo_slug="$2"
  echo "| Condition | Succès | Total | Taux | IC 95% Wilson |"
  echo "|---|---:|---:|---:|---:|"
  for condition in with without; do
    awk -F '\t' -v repo="$repo_slug" -v condition="$condition" '
      function wilson_lo(success, total, z, phat, denom, center, half, value) {
        if (total <= 0) return 0
        z = 1.959963984540054
        phat = success / total
        denom = 1 + z * z / total
        center = (phat + z * z / (2 * total)) / denom
        half = z * sqrt((phat * (1 - phat) + z * z / (4 * total)) / total) / denom
        value = 100 * (center - half)
        return value < 0 ? 0 : value
      }
      function wilson_hi(success, total, z, phat, denom, center, half, value) {
        if (total <= 0) return 0
        z = 1.959963984540054
        phat = success / total
        denom = 1 + z * z / total
        center = (phat + z * z / (2 * total)) / denom
        half = z * sqrt((phat * (1 - phat) + z * z / (4 * total)) / total) / denom
        value = 100 * (center + half)
        return value > 100 ? 100 : value
      }
      NR > 1 && $1 == repo && $5 == condition { total += 1; success += $7 }
      END {
        rate = total ? (100 * success / total) : 0
        lo = wilson_lo(success, total)
        hi = wilson_hi(success, total)
        printf "| `%s` | %d | %d | %.1f%% | [%.1f%% ; %.1f%%] |\n", condition, success, total, rate, lo, hi
      }
    ' "$results_tsv"
  done
}

emit_success_delta_line() {
  local results_tsv="$1" repo_slug="$2"
  awk -F '\t' -v repo="$repo_slug" '
    function wilson_lo(success, total, z, phat, denom, center, half, value) {
      if (total <= 0) return 0
      z = 1.959963984540054
      phat = success / total
      denom = 1 + z * z / total
      center = (phat + z * z / (2 * total)) / denom
      half = z * sqrt((phat * (1 - phat) + z * z / (4 * total)) / total) / denom
      value = 100 * (center - half)
      return value < 0 ? 0 : value
    }
    function wilson_hi(success, total, z, phat, denom, center, half, value) {
      if (total <= 0) return 0
      z = 1.959963984540054
      phat = success / total
      denom = 1 + z * z / total
      center = (phat + z * z / (2 * total)) / denom
      half = z * sqrt((phat * (1 - phat) + z * z / (4 * total)) / total) / denom
      value = 100 * (center + half)
      return value > 100 ? 100 : value
    }
    NR > 1 && $1 == repo && $5 == "with" { with_total += 1; with_success += $7 }
    NR > 1 && $1 == repo && $5 == "without" { without_total += 1; without_success += $7 }
    END {
      with_rate = with_total ? (100 * with_success / with_total) : 0
      without_rate = without_total ? (100 * without_success / without_total) : 0
      with_lo = wilson_lo(with_success, with_total)
      with_hi = wilson_hi(with_success, with_total)
      without_lo = wilson_lo(without_success, without_total)
      without_hi = wilson_hi(without_success, without_total)
      delta = with_rate - without_rate
      delta_lo = with_lo - without_hi
      delta_hi = with_hi - without_lo
      printf "Δ succès (`with` - `without`) : **%.1f points** (IC 95%% approx. Newcombe : **[%.1f ; %.1f] points**).\n", delta, delta_lo, delta_hi
    }
  ' "$results_tsv"
}

is_agent_infra_error() {
  local log="$1"
  [[ -f "$log" ]] || return 1
  grep -Eiq "usage limit|purchase more credits|try again at|quota exceeded|too many requests|(^|[^[:digit:]])429([^[:digit:]]|$)|rate limit (exceeded|reached|hit)|rate-limited|rate limited|authentication failed|invalid api key|provider error|server error|service unavailable" "$log"
}

failure_kind_for() {
  local agent_exit="$1" check_exit="$2" stderr_log="$3"
  if [[ "$agent_exit" -eq 0 && "$check_exit" -eq 0 ]]; then
    printf "none"
  elif [[ "$agent_exit" -eq 124 ]]; then
    printf "timeout"
  elif [[ "$agent_exit" -ne 0 ]] && is_agent_infra_error "$stderr_log"; then
    printf "agent_infra_error"
  elif [[ "$agent_exit" -ne 0 ]]; then
    printf "agent_error"
  elif [[ "$check_exit" -ne 0 ]]; then
    printf "task_fail"
  else
    printf "unknown"
  fi
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
validate_stamp
validate_run_dir

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
  parser_probe="$(mktemp)"
  printf "noise\ntokens used\n46 684\n" > "$parser_probe"
  [[ "$(extract_tokens_used "$parser_probe")" == "46684" ]] && ok "parseur tokens" || ko "parseur tokens"
  printf "tokens used\n1\nnoise\ntokens used\n46,684\n" > "$parser_probe"
  [[ "$(extract_tokens_used "$parser_probe")" == "46684" ]] && ok "parseur tokens dernier bloc" || ko "parseur tokens dernier bloc"
  task_class_probe="$(mktemp -d)"
  printf "contextual\n" > "$task_class_probe/task.class"
  [[ "$(task_class_for "$task_class_probe" "fallback-id")" == "contextual" ]] && ok "classe tâche explicite" || ko "classe tâche explicite"
  printf "\n" > "$task_class_probe/task.class"
  [[ "$(task_class_for "$task_class_probe" "fallback-id")" == "fallback-id" ]] && ok "classe tâche fallback id" || ko "classe tâche fallback id"
  safe_rm_rf "$task_class_probe" "self-check task class" "${TMPDIR:-/tmp}"
  token_delta_probe="$(mktemp)"
  printf "repo_slug\trepo_name\trepo_ref\ttask_id\tcondition\trun_index\tsuccess\tfailure_kind\tagent_exit\tcheck_exit\tduration_seconds\ttokens_used\tworkdir\tstdout_log\tstderr_log\tcheck_log\ttask_class\n" > "$token_delta_probe"
  printf "repo-a\tRepo A\tref\t0001\twith\t1\t1\tnone\t0\t0\t1\t46684\t<tmp>\tstdout\tstderr\tcheck\ttrivial\n" >> "$token_delta_probe"
  printf "repo-a\tRepo A\tref\t0001\twithout\t1\t1\tnone\t0\t0\t1\t11989\t<tmp>\tstdout\tstderr\tcheck\ttrivial\n" >> "$token_delta_probe"
  printf "repo-a\tRepo A\tref\t0002\twith\t1\t1\tnone\t0\t0\t1\t35873\t<tmp>\tstdout\tstderr\tcheck\tcontextual\n" >> "$token_delta_probe"
  printf "repo-a\tRepo A\tref\t0002\twithout\t1\t0\ttask_fail\t0\t1\t1\t60495\t<tmp>\tstdout\tstderr\tcheck\tcontextual\n" >> "$token_delta_probe"
  token_delta_out="$(emit_token_class_delta_table "$token_delta_probe" "repo-a")"
  printf "%s\n" "$token_delta_out" | grep -Fq '| `trivial` | 1 | 46684 | 1 | 11989 | +34695 | +289.4% |' \
    && ok "delta tokens classe trivial" \
    || ko "delta tokens classe trivial"
  printf "%s\n" "$token_delta_out" | grep -Fq '| `contextual` | 1 | 35873 | 1 | 60495 | -24622 | -40.7% |' \
    && ok "delta tokens classe contextual" \
    || ko "delta tokens classe contextual"
  rm -f "$token_delta_probe"
  success_ci_probe="$(mktemp)"
  printf "repo_slug\trepo_name\trepo_ref\ttask_id\tcondition\trun_index\tsuccess\tfailure_kind\tagent_exit\tcheck_exit\tduration_seconds\ttokens_used\tworkdir\tstdout_log\tstderr_log\tcheck_log\ttask_class\n" > "$success_ci_probe"
  run_index=1
  while [[ "$run_index" -le 12 ]]; do
    printf "repo-a\tRepo A\tref\t0001\twith\t%s\t1\tnone\t0\t0\t1\t100\t<tmp>\tstdout\tstderr\tcheck\ttrivial\n" "$run_index" >> "$success_ci_probe"
    if [[ "$run_index" -le 8 ]]; then success_value=1; failure_kind=none; check_exit=0; else success_value=0; failure_kind=task_fail; check_exit=1; fi
    printf "repo-a\tRepo A\tref\t0001\twithout\t%s\t%s\t%s\t0\t%s\t1\t100\t<tmp>\tstdout\tstderr\tcheck\ttrivial\n" "$run_index" "$success_value" "$failure_kind" "$check_exit" >> "$success_ci_probe"
    run_index=$((run_index + 1))
  done
  success_ci_table="$(emit_success_summary_table "$success_ci_probe" "repo-a")"
  success_ci_delta="$(emit_success_delta_line "$success_ci_probe" "repo-a")"
  printf "%s\n" "$success_ci_table" | grep -Fq '| `with` | 12 | 12 | 100.0% | [75.8% ; 100.0%] |' \
    && ok "IC Wilson succès with" \
    || ko "IC Wilson succès with"
  printf "%s\n" "$success_ci_table" | grep -Fq '| `without` | 8 | 12 | 66.7% | [39.1% ; 86.2%] |' \
    && ok "IC Wilson succès without" \
    || ko "IC Wilson succès without"
  printf "%s\n" "$success_ci_delta" | grep -Fq 'Δ succès (`with` - `without`) : **33.3 points** (IC 95% approx. Newcombe : **[-10.4 ; 60.9] points**).' \
    && ok "IC Newcombe delta succès" \
    || ko "IC Newcombe delta succès"
  rm -f "$success_ci_probe"
  printf "ERROR: You've hit your usage limit. Visit https://chatgpt.com/codex/settings/usage to purchase more credits.\n" > "$parser_probe"
  is_agent_infra_error "$parser_probe" && ok "classification erreur infra agent" || ko "classification erreur infra agent"
  [[ "$(failure_kind_for 1 1 "$parser_probe")" == "agent_infra_error" ]] && ok "failure_kind infra agent" || ko "failure_kind infra agent"
  printf "contenu repo: auth, secrets, rate limiting et provisioning\n" > "$parser_probe"
  [[ "$(failure_kind_for 0 1 "$parser_probe")" == "task_fail" ]] && ok "failure_kind task_fail malgré contenu infra" || ko "failure_kind task_fail malgré contenu infra"
  rm -f "$parser_probe"
  rm_target_is_safe "" && ko "garde rm -rf cible vide" || ok "garde rm -rf cible vide"
  rm_target_is_safe "/" && ko "garde rm -rf racine" || ok "garde rm -rf racine"
  rm_guard_parent="$(mktemp -d)"
  rm_guard_target="$rm_guard_parent/$BENCH_STAMP"
  mkdir -p "$rm_guard_target"
  touch "$rm_guard_target/probe"
  rm_target_is_safe "$rm_guard_parent/not-$BENCH_STAMP" "$rm_guard_parent" "$BENCH_STAMP" \
    && ko "garde BENCH_RUN_DIR impose le stamp" \
    || ok "garde BENCH_RUN_DIR impose le stamp"
  safe_rm_rf "$rm_guard_target" "self-check rm guard" "$rm_guard_parent" "$BENCH_STAMP"
  [[ ! -e "$rm_guard_target" ]] && ok "safe_rm_rf supprime une cible autorisée" || ko "safe_rm_rf supprime une cible autorisée"
  rmdir "$rm_guard_parent" 2>/dev/null || true
  matrix_probe="$(mktemp)"
  printf "0.1\t2\tsecond\n0.1\t1\tfirst\n0.2\t3\tthird\n" | matrix_sort_with_tiebreak > "$matrix_probe"
  [[ "$(tr '\n' ' ' < "$matrix_probe")" == "first second third " ]] \
    && ok "tie-break matrice déterministe" \
    || ko "tie-break matrice déterministe"
  rm -f "$matrix_probe"
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
run_log_root="$work_root/logs"
mkdir -p "$run_log_root"
cleanup() {
  if [[ "$BENCH_KEEP_WORKDIR" == "1" ]]; then
    warn "copies de travail conservées : $work_root"
  else
    safe_rm_rf "$work_root" "work_root" "${TMPDIR:-/tmp}"
  fi
}
trap cleanup EXIT

results_tsv="$work_root/results.tsv"
results_jsonl="$work_root/results.jsonl"
final_results_tsv="$BENCH_REPORT_DIR/$BENCH_STAMP-results.tsv"
final_results_jsonl="$BENCH_REPORT_DIR/$BENCH_STAMP-results.jsonl"
matrix_file="$run_log_root/matrix.tsv"
: > "$results_jsonl"
printf "repo_slug\trepo_name\trepo_ref\ttask_id\tcondition\trun_index\tsuccess\tfailure_kind\tagent_exit\tcheck_exit\tduration_seconds\ttokens_used\tworkdir\tstdout_log\tstderr_log\tcheck_log\ttask_class\n" > "$results_tsv"

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
  | randomize_matrix "$BENCH_SEED" > "$matrix_file"

echo "  run réel : ${#repos[@]} repo(s) × ${#tasks[@]} tâche(s) × 2 conditions × N=$BENCH_N"
echo "  seed : $BENCH_SEED"
echo "  agent : $BENCH_AGENT_LABEL"
echo "  timeout : ${BENCH_TIMEOUT_SECONDS}s"
echo "  rapports : $BENCH_REPORT_DIR"
echo "  logs : $BENCH_RUN_DIR"

while IFS=$'\t' read -r repo_path task_path condition run_index; do
  repo_name="$(basename "$repo_path")"
  repo_slug="$(repo_slug_for "$repo_path" "$repo_name")"
  repo_ref="$(repo_ref_for "$repo_path")"
  task_id="$(basename "$task_path")"
  task_class="$(task_class_for "$task_path" "$task_id")"
  cell_slug="$(slugify "$repo_slug-$task_id-$condition-$run_index")"
  workdir="$work_root/$cell_slug/work"
  logdir="$run_log_root/$cell_slug"
  final_logdir="$BENCH_RUN_DIR/$cell_slug"
  stdout_log="$logdir/agent.stdout.log"
  stderr_log="$logdir/agent.stderr.log"
  check_log="$logdir/check.log"
  final_stdout_log="$final_logdir/agent.stdout.log"
  final_stderr_log="$final_logdir/agent.stderr.log"
  final_check_log="$final_logdir/check.log"
  workdir_ref="$(display_path "$workdir")"
  stdout_log_ref="$(display_path "$final_stdout_log")"
  stderr_log_ref="$(display_path "$final_stderr_log")"
  check_log_ref="$(display_path "$final_check_log")"
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
    BENCH_TASK_CLASS="$task_class" \
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
  tokens_used="$(extract_tokens_used "$stderr_log")"
  failure_kind="$(failure_kind_for "$agent_exit" "$check_exit" "$stderr_log")"

  success=0
  if [[ "$agent_exit" -eq 0 && "$check_exit" -eq 0 ]]; then
    success=1
    ok "$repo_name / $task_id / $condition / run $run_index"
  else
    warn "$repo_name / $task_id / $condition / run $run_index FAIL (agent=$agent_exit check=$check_exit)"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$repo_slug" "$repo_name" "$repo_ref" "$task_id" "$condition" "$run_index" \
    "$success" "$failure_kind" "$agent_exit" "$check_exit" "$duration" "$tokens_used" "$workdir_ref" "$stdout_log_ref" "$stderr_log_ref" "$check_log_ref" "$task_class" \
    >> "$results_tsv"

  if [[ "$tokens_used" == "NA" ]]; then
    tokens_json="null"
  else
    tokens_json="$tokens_used"
  fi
  printf '{"stamp":"%s","repo_slug":"%s","repo_name":"%s","repo_ref":"%s","task_id":"%s","task_class":"%s","condition":"%s","run_index":%s,"success":%s,"failure_kind":"%s","agent_exit":%s,"check_exit":%s,"duration_seconds":%s,"tokens_used":%s,"stdout_log":"%s","stderr_log":"%s","check_log":"%s"}\n' \
    "$(json_escape "$BENCH_STAMP")" "$(json_escape "$repo_slug")" "$(json_escape "$repo_name")" "$(json_escape "$repo_ref")" \
    "$(json_escape "$task_id")" "$(json_escape "$task_class")" "$(json_escape "$condition")" "$run_index" "$success" "$(json_escape "$failure_kind")" "$agent_exit" "$check_exit" "$duration" \
    "$tokens_json" "$(json_escape "$stdout_log_ref")" "$(json_escape "$stderr_log_ref")" "$(json_escape "$check_log_ref")" \
    >> "$results_jsonl"
done < "$matrix_file"

safe_rm_rf "$BENCH_RUN_DIR" "BENCH_RUN_DIR" "$(dirname "$BENCH_RUN_DIR")" "$BENCH_STAMP"
mkdir -p "$BENCH_RUN_DIR" "$BENCH_REPORT_DIR"
if command -v rsync >/dev/null 2>&1; then
  rsync -a "$run_log_root"/ "$BENCH_RUN_DIR"/
else
  ( cd "$run_log_root" && tar -cf - . ) | ( cd "$BENCH_RUN_DIR" && tar -xf - )
fi
cp "$results_tsv" "$final_results_tsv"
cp "$results_jsonl" "$final_results_jsonl"

report_files=()
while IFS= read -r repo_slug; do
  [[ -n "$repo_slug" ]] || continue
  report="$BENCH_REPORT_DIR/$BENCH_STAMP-$repo_slug.md"
  repo_name="$(awk -F '\t' -v repo="$repo_slug" 'NR > 1 && $1 == repo { print $2; exit }' "$results_tsv")"
  repo_ref="$(awk -F '\t' -v repo="$repo_slug" 'NR > 1 && $1 == repo { print $3; exit }' "$results_tsv")"

  {
    echo "# Benchmark agent — $repo_name"
    echo
    echo "- Date : $BENCH_STAMP"
    echo "- Repo : \`$repo_ref\`"
    echo "- Agent : $BENCH_AGENT_LABEL"
    echo "- N : $BENCH_N"
    echo "- Seed : $BENCH_SEED"
    echo "- Timeout : ${BENCH_TIMEOUT_SECONDS}s"
    echo "- Résultats bruts : \`$(display_path "$final_results_tsv")\`"
    echo "- Artefact JSONL : \`$(display_path "$final_results_jsonl")\`"
    echo
    echo "## Synthèse"
    echo
    emit_success_summary_table "$results_tsv" "$repo_slug"
    echo
    emit_success_delta_line "$results_tsv" "$repo_slug"
    echo
    echo "## Coût tokens"
    echo
    echo "| Condition | Runs avec mesure | Total tokens | Moyenne tokens/run |"
    echo "|---|---:|---:|---:|"
    for condition in with without; do
      awk -F '\t' -v repo="$repo_slug" -v condition="$condition" '
        NR > 1 && $1 == repo && $5 == condition && $12 ~ /^[0-9]+$/ {
          count += 1
          total += $12
        }
        END {
          mean = count ? total / count : 0
          printf "| `%s` | %d | %d | %.0f |\n", condition, count, total, mean
        }
      ' "$results_tsv"
    done
    echo
    echo "## Δ tokens par classe de tâche"
    echo
    emit_token_class_delta_table "$results_tsv" "$repo_slug"
    echo
    echo "## Détail"
    echo
    echo "| Tâche | Condition | Run | Résultat | Failure | Agent | Check | Tokens | Logs |"
    echo "|---|---|---:|---|---|---:|---:|---:|---|"
    awk -F '\t' -v repo="$repo_slug" '
      NR > 1 && $1 == repo {
        result = ($7 == 1) ? "PASS" : "FAIL"
        printf "| `%s` | `%s` | %s | %s | `%s` | %s | %s | %s | `%s` |\n", $4, $5, $6, result, $8, $9, $10, $12, $16
      }
    ' "$results_tsv"
    echo
    echo "## Notes"
    echo
    echo "- \`AGENT_CMD\` n'est pas écrit dans le rapport pour éviter de consigner des secrets ; utiliser \`BENCH_AGENT_LABEL\` pour tracer le modèle/runner."
    echo "- Les échecs de tâche sont des données de benchmark : le runner termine et les agrège au lieu de s'arrêter au premier échec."
    echo "- \`failure_kind=agent_infra_error\` signale une erreur d'environnement agent (quota, auth, provider) : le run est alors invalide comme preuve benchmark."
  } > "$report"
  report_files+=("$report")
done < <(awk -F '\t' 'NR > 1 { print $1 }' "$results_tsv" | sort -u)

infra_errors="$(awk -F '\t' 'NR > 1 && $8 == "agent_infra_error" { count += 1 } END { print count + 0 }' "$results_tsv")"

echo
echo "✅ run terminé"
printf "  rapport : %s\n" "${report_files[@]}"
echo "  résultats : $final_results_tsv"
echo "  jsonl : $final_results_jsonl"
if [[ "$infra_errors" -gt 0 ]]; then
  warn "run invalide pour benchmark : $infra_errors erreur(s) infra agent détectée(s)"
  exit 2
fi
