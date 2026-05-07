#!/bin/bash
# tests/unit/test-context-relevance.sh
#
# Couvre `context-relevance-log.sh` (3 événements) et `context-relevance-report.sh`.
# Cas obligatoires (cf. quality/context-relevance-tracker) :
#   1. unit logger : 3 événements écrits, JSONL parsable.
#   2. unit reporter : 10 summaries synthétiques, ratios précision/rappel corrects.
#   3. E2E inject sans touch → injected_not_touched non vide.
#   4. E2E touch sans inject → touched_not_injected non vide.
#   5. Rotation taille basse → .old produit.
#   6. Best-effort : écriture impossible (permissions) → exit 0.

set -uo pipefail

cd "$(dirname "$0")/../.."
repo_root=$(pwd)

logger="$repo_root/.ai/scripts/context-relevance-log.sh"
reporter="$repo_root/.ai/scripts/context-relevance-report.sh"

pass=0
fail=0
failures=()

# Mock isolé : tmp dir avec structure .ai/, on appelle le logger via export
# du repo_root (script_dir + ../..). Pour ça, copier le logger dans un sous-dir
# qui simule .ai/scripts/.
setup_tmp_repo() {
  local d
  d=$(mktemp -d 2>/dev/null || mktemp -d -t 'crl-test')
  mkdir -p "$d/.ai/scripts"
  cp "$logger" "$d/.ai/scripts/context-relevance-log.sh"
  cp "$reporter" "$d/.ai/scripts/context-relevance-report.sh"
  echo "$d"
}

# ─── Cas 1 : logger 3 événements ───
tmp1=$(setup_tmp_repo)
bash "$tmp1/.ai/scripts/context-relevance-log.sh" inject Edit src/foo.ts \
  '["core/x"]' '["core/y"]' '["core/x","core/y"]' '[]' false 10000 '' warn 0 3 \
  >/dev/null 2>&1
bash "$tmp1/.ai/scripts/context-relevance-log.sh" touch Edit src/foo.ts \
  '["core/x"]' >/dev/null 2>&1
bash "$tmp1/.ai/scripts/context-relevance-log.sh" summary >/dev/null 2>&1

if [[ -f "$tmp1/.ai/.context-relevance.jsonl" ]] && \
   [[ "$(grep -c '^' "$tmp1/.ai/.context-relevance.jsonl")" -eq 3 ]]; then
  # Vérifier parsabilité jq de chaque ligne
  if jq -s 'all(.event)' "$tmp1/.ai/.context-relevance.jsonl" >/dev/null 2>&1; then
    pass=$((pass + 1))
    echo "PASS: cas 1 logger 3 événements JSONL parsables"
  else
    fail=$((fail + 1))
    failures+=("cas 1: JSONL non parsable")
  fi
else
  fail=$((fail + 1))
  failures+=("cas 1: 3 événements attendus, log manquant ou incomplet")
fi
rm -rf "$tmp1"

# ─── Cas 2 : reporter sur 10 summaries synthétiques ───
tmp2=$(setup_tmp_repo)
log2="$tmp2/.ai/.context-relevance.jsonl"
for i in 1 2 3 4 5 6 7 8 9 10; do
  cat >> "$log2" <<EOF
{"ts":"2026-05-07T10:0$i:00Z","event":"summary","files":["a.ts"],"injected_features":["core/a","core/b"],"touched_features":["core/a"],"intersection":["core/a"],"injected_not_touched":["core/b"],"touched_not_injected":[],"precision_approx":0.5,"recall_approx":1}
EOF
done
report=$(bash "$tmp2/.ai/scripts/context-relevance-report.sh" --last 10 --format json 2>/dev/null)
core_a=$(printf '%s' "$report" | jq -r '.features[] | select(.feature == "core/a") | .injected' 2>/dev/null)
core_b=$(printf '%s' "$report" | jq -r '.features[] | select(.feature == "core/b") | .injected' 2>/dev/null)
core_a_recall=$(printf '%s' "$report" | jq -r '.features[] | select(.feature == "core/a") | .recall' 2>/dev/null)
if [[ "$core_a" == "10" && "$core_b" == "10" && "$core_a_recall" == "1" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas 2 reporter agrège 10 summaries (core/a injected=10 recall=1, core/b=10)"
else
  fail=$((fail + 1))
  failures+=("cas 2: reporter incorrect. core_a=$core_a core_b=$core_b core_a_recall=$core_a_recall")
fi
rm -rf "$tmp2"

# ─── Cas 3 : E2E inject sans touch ───
tmp3=$(setup_tmp_repo)
bash "$tmp3/.ai/scripts/context-relevance-log.sh" inject Edit src/foo.ts \
  '["core/x"]' '[]' '["core/x"]' '[]' false 10000 '' warn 0 3 >/dev/null 2>&1
# Pas de touch
bash "$tmp3/.ai/scripts/context-relevance-log.sh" summary >/dev/null 2>&1

summary=$(jq -s '.[] | select(.event == "summary")' "$tmp3/.ai/.context-relevance.jsonl" 2>/dev/null)
inj_not_tch=$(printf '%s' "$summary" | jq -r '.injected_not_touched | length' 2>/dev/null)
tch_not_inj=$(printf '%s' "$summary" | jq -r '.touched_not_injected | length' 2>/dev/null)
if [[ "$inj_not_tch" == "1" && "$tch_not_inj" == "0" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas 3 inject-sans-touch → injected_not_touched=1, touched_not_injected=0"
else
  fail=$((fail + 1))
  failures+=("cas 3: inj_not_tch=$inj_not_tch tch_not_inj=$tch_not_inj (attendu 1/0)")
fi
rm -rf "$tmp3"

# ─── Cas 4 : E2E touch sans inject ───
tmp4=$(setup_tmp_repo)
bash "$tmp4/.ai/scripts/context-relevance-log.sh" touch Edit src/bar.ts \
  '["core/y"]' >/dev/null 2>&1
# Pas de inject
bash "$tmp4/.ai/scripts/context-relevance-log.sh" summary >/dev/null 2>&1

summary=$(jq -s '.[] | select(.event == "summary")' "$tmp4/.ai/.context-relevance.jsonl" 2>/dev/null)
inj_not_tch=$(printf '%s' "$summary" | jq -r '.injected_not_touched | length' 2>/dev/null)
tch_not_inj=$(printf '%s' "$summary" | jq -r '.touched_not_injected | length' 2>/dev/null)
if [[ "$inj_not_tch" == "0" && "$tch_not_inj" == "1" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas 4 touch-sans-inject → injected_not_touched=0, touched_not_injected=1"
else
  fail=$((fail + 1))
  failures+=("cas 4: inj_not_tch=$inj_not_tch tch_not_inj=$tch_not_inj (attendu 0/1)")
fi
rm -rf "$tmp4"

# ─── Cas 5 : rotation taille basse ───
tmp5=$(setup_tmp_repo)
# Force rotation à 0 MB (immédiate dès écriture)
AI_CONTEXT_RELEVANCE_ROTATION_MB=0 bash "$tmp5/.ai/scripts/context-relevance-log.sh" inject \
  Edit src/foo.ts '[]' '[]' '[]' '[]' false 0 '' warn 0 3 >/dev/null 2>&1
AI_CONTEXT_RELEVANCE_ROTATION_MB=0 bash "$tmp5/.ai/scripts/context-relevance-log.sh" inject \
  Edit src/foo.ts '[]' '[]' '[]' '[]' false 0 '' warn 0 3 >/dev/null 2>&1

if [[ -f "$tmp5/.ai/.context-relevance.jsonl.old" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas 5 rotation taille basse → .old produit"
else
  fail=$((fail + 1))
  failures+=("cas 5: .context-relevance.jsonl.old absent après rotation forcée")
fi
rm -rf "$tmp5"

# ─── Cas 6 : best-effort écriture impossible ───
tmp6=$(setup_tmp_repo)
chmod -w "$tmp6/.ai" 2>/dev/null
bash "$tmp6/.ai/scripts/context-relevance-log.sh" inject Edit src/foo.ts \
  '[]' '[]' '[]' '[]' false 0 '' warn 0 3 >/dev/null 2>&1
rc=$?
chmod +w "$tmp6/.ai" 2>/dev/null
if [[ $rc -eq 0 ]]; then
  pass=$((pass + 1))
  echo "PASS: cas 6 best-effort écriture impossible → exit 0"
else
  fail=$((fail + 1))
  failures+=("cas 6: logger devrait exit 0 même sur erreur. rc=$rc")
fi
rm -rf "$tmp6"

# ─── Cas 7 : sous-commande inconnue → silent no-op exit 0 ───
tmp7=$(setup_tmp_repo)
bash "$tmp7/.ai/scripts/context-relevance-log.sh" unknown_cmd >/dev/null 2>&1
rc=$?
if [[ $rc -eq 0 && ! -f "$tmp7/.ai/.context-relevance.jsonl" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas 7 sous-commande inconnue → silent exit 0"
else
  fail=$((fail + 1))
  failures+=("cas 7: sous-commande inconnue rc=$rc, fichier inattendu")
fi
rm -rf "$tmp7"

# ─── Cas 8 : disabled via env var ───
tmp8=$(setup_tmp_repo)
AI_CONTEXT_RELEVANCE_DISABLED=1 bash "$tmp8/.ai/scripts/context-relevance-log.sh" inject \
  Edit src/foo.ts '[]' '[]' '[]' '[]' false 0 '' warn 0 3 >/dev/null 2>&1
if [[ ! -f "$tmp8/.ai/.context-relevance.jsonl" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas 8 AI_CONTEXT_RELEVANCE_DISABLED=1 → no-op"
else
  fail=$((fail + 1))
  failures+=("cas 8: env disabled non respectée")
fi
rm -rf "$tmp8"

# ─── Cas 9 : E2E wiring — CLI mode ne crée pas d'event inject ───
# (Finding 1 Codex post-0ce2094 : éviter faux injects en mode CLI.)
log_runtime="$repo_root/.ai/.context-relevance.jsonl"
log_runtime_backup=""
[[ -f "$log_runtime" ]] && log_runtime_backup=$(mktemp) && mv "$log_runtime" "$log_runtime_backup"

bash "$repo_root/.ai/scripts/features-for-path.sh" "$repo_root/.ai/scripts/_lib.sh" >/dev/null 2>&1 || true
if [[ -f "$log_runtime" ]] && grep -q '"event":"inject"' "$log_runtime" 2>/dev/null; then
  fail=$((fail + 1))
  failures+=("cas 9 : CLI mode a créé un event inject (Finding 1 Codex non corrigé)")
else
  pass=$((pass + 1))
  echo "PASS: cas 9 CLI mode ne crée pas d'event inject"
fi
rm -f "$log_runtime" 2>/dev/null

# ─── Cas 10 : E2E wiring — Hook mode crée un event inject ───
echo '{"tool_name":"Edit","tool_input":{"file_path":".ai/scripts/_lib.sh"}}' \
  | bash "$repo_root/.ai/scripts/features-for-path.sh" >/dev/null 2>&1 || true
if [[ -f "$log_runtime" ]] && grep -q '"event":"inject".*"hook":"PreToolUse"' "$log_runtime" 2>/dev/null; then
  pass=$((pass + 1))
  echo "PASS: cas 10 Hook mode crée un event inject"
else
  fail=$((fail + 1))
  failures+=("cas 10 : Hook mode n'a pas créé d'event inject")
fi
rm -f "$log_runtime" 2>/dev/null

# ─── Cas 11 : matcher émet "pattern non supporté" sur stderr ───
# (Finding 2 Codex post-0ce2094 : la capture wrapper grep ce message stderr.)
# Test ciblé sur le contrat matcher → wrapper. Le wiring E2E complet
# avec mock index n'est pas testable sans répliquer tout le script_dir.
# Ce cas valide que le matcher émet bien le pattern dans stderr, donc
# que la regex `grep -oE 'pattern non supporté : .+'` dans log_inject_event
# capture quelque chose à parser.
matcher_stderr=$(. "$repo_root/.ai/scripts/_lib.sh" && _FEATURES_MATCHING_POLICY=warn path_matches_touch "src/foo.ts" "foo**bar" 2>&1 1>/dev/null)
if printf '%s' "$matcher_stderr" | grep -qE 'pattern non supporté : foo\*\*bar'; then
  pass=$((pass + 1))
  echo "PASS: cas 11 matcher émet stderr pour pattern unsupported (foo**bar)"
else
  fail=$((fail + 1))
  failures+=("cas 11 : matcher silent sur foo**bar — wrapper capture grep ne trouvera rien")
fi

# ─── Cas 12 : Budget bas force truncated=true ───
# (Finding 3 Codex post-0ce2094 : log inject APRÈS load_feature_context.)
echo '{"tool_name":"Edit","tool_input":{"file_path":".ai/scripts/_lib.sh"}}' \
  | AI_CONTEXT_FEATURE_DOC_MAX_CHARS=300 AI_CONTEXT_FEATURE_DOC_PER_DOC_CHARS=300 \
  bash "$repo_root/.ai/scripts/features-for-path.sh" >/dev/null 2>&1 || true
if [[ -f "$log_runtime" ]] && \
   jq -s '[.[] | select(.event == "inject" and .truncated == true)] | length > 0' "$log_runtime" 2>/dev/null | grep -q true; then
  pass=$((pass + 1))
  echo "PASS: cas 12 budget bas force truncated=true"
else
  fail=$((fail + 1))
  failures+=("cas 12 : truncated reste false avec budget 300 chars (Finding 3 Codex non corrigé)")
fi
rm -f "$log_runtime" 2>/dev/null

# Restaurer log runtime original si présent
[[ -n "$log_runtime_backup" && -f "$log_runtime_backup" ]] && mv "$log_runtime_backup" "$log_runtime"

# ─── Rapport ───
total=$((pass + fail))
echo
echo "═══ test-context-relevance ═══"
echo "Total : $total | OK : $pass | KO : $fail"
if [[ $fail -gt 0 ]]; then
  printf '\nÉchecs :\n'
  for f in "${failures[@]}"; do
    printf '  ✗ %s\n' "$f"
  done
  exit 1
fi
echo "✅ Tous les cas passent"
exit 0
