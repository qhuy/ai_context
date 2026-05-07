#!/bin/bash
# tests/unit/test-stop-hook-idempotence.sh
#
# Tests E2E sur auto-worklog-log.sh post Phase 2 #5 :
# Le filtre is_structural_feature_edit (helper #4) doit court-circuiter
# l'alimentation de .session-edits.log pour les édits non-structurels,
# tout en laissant le logger context-relevance touch agnostique.
#
# 7 cas obligatoires (cf. workflow/stop-hook-idempotence Validation) :
#   1. édit fiche feature .md seule → log vide
#   2. édit worklog seul → log vide
#   3. édit .lock → log vide
#   4. édit source structurel (.sh) → log alimenté
#   5. édit .md normal matchant touches: (livrable doc) → log alimenté
#   6. édit hors touches: direct → log vide (non-régression)
#   7. mix structurel + non-structurel → log alimenté pour structurel uniquement

set -uo pipefail

cd "$(dirname "$0")/../.."
repo_root=$(pwd)

pass=0
fail=0
failures=()

setup_tmp_e2e() {
  local d
  d=$(mktemp -d 2>/dev/null || mktemp -d -t 'shi-e2e')
  mkdir -p "$d/.ai/scripts" "$d/.docs/features/test"
  cp "$repo_root/.ai/scripts/_lib.sh" "$d/.ai/scripts/_lib.sh"
  cp "$repo_root/.ai/scripts/auto-worklog-log.sh" "$d/.ai/scripts/auto-worklog-log.sh"
  # Stub context-relevance-log.sh : le test ne valide pas son comportement,
  # juste qu'il ne casse pas auto-worklog-log.
  cat > "$d/.ai/scripts/context-relevance-log.sh" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$d/.ai/scripts/context-relevance-log.sh"
  echo "$d"
}

run_log() {
  local d="$1" file_path="$2"
  cd "$d"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$file_path" \
    | bash .ai/scripts/auto-worklog-log.sh 2>/dev/null || true
  cd "$repo_root"
}

count_log_lines() {
  local d="$1"
  if [[ -f "$d/.ai/.session-edits.log" ]]; then
    wc -l < "$d/.ai/.session-edits.log" | tr -d '[:space:]'
  else
    echo 0
  fi
}

assert_log_lines() {
  local desc="$1" d="$2" expected="$3"
  local actual
  actual=$(count_log_lines "$d")
  if [[ "$actual" -eq "$expected" ]]; then
    pass=$((pass + 1))
    echo "PASS: $desc (log=$actual lignes)"
  else
    fail=$((fail + 1))
    failures+=("$desc : log=$actual lignes attendu=$expected")
  fi
}

# Mini index : 1 feature avec touches: src/foo.sh + README.md (livrable doc) + .docs/features/test/feat.md
make_index() {
  local d="$1"
  cat > "$d/.ai/.feature-index.json" <<EOF
{"features":[{"scope":"test","id":"feat","path":".docs/features/test/feat.md","status":"active","touches":["src/foo.sh","README.md",".docs/features/test/feat.md","feat.lock"]}]}
EOF
  cat > "$d/.docs/features/test/feat.md" <<'EOF'
---
id: feat
scope: test
status: active
touches:
  - src/foo.sh
  - README.md
  - .docs/features/test/feat.md
  - feat.lock
---
EOF
}

# ─── Cas 1 : édit fiche feature seule → log vide ───
d1=$(setup_tmp_e2e); make_index "$d1"
run_log "$d1" ".docs/features/test/feat.md"
assert_log_lines "cas 1 fiche feature seule" "$d1" 0
rm -rf "$d1"

# ─── Cas 2 : édit worklog seul → log vide ───
d2=$(setup_tmp_e2e); make_index "$d2"
run_log "$d2" ".docs/features/test/feat.worklog.md"
assert_log_lines "cas 2 worklog seul" "$d2" 0
rm -rf "$d2"

# ─── Cas 3 : édit .lock → log vide ───
d3=$(setup_tmp_e2e); make_index "$d3"
run_log "$d3" "feat.lock"
assert_log_lines "cas 3 .lock" "$d3" 0
rm -rf "$d3"

# ─── Cas 4 : édit source structurel → log alimenté ───
d4=$(setup_tmp_e2e); make_index "$d4"
run_log "$d4" "src/foo.sh"
assert_log_lines "cas 4 source structurel" "$d4" 1
# Vérifie le contenu
if [[ -f "$d4/.ai/.session-edits.log" ]] && grep -q '"feature":"test/feat"' "$d4/.ai/.session-edits.log"; then
  pass=$((pass + 1))
  echo "PASS: cas 4b feature key dans log"
else
  fail=$((fail + 1))
  failures+=("cas 4b : feature key manquante dans log")
fi
rm -rf "$d4"

# ─── Cas 5 : édit .md normal (livrable doc) matchant touches: → log alimenté ───
# README.md est dans touches: mais hors .docs/features/** et n'est pas un worklog.
d5=$(setup_tmp_e2e); make_index "$d5"
run_log "$d5" "README.md"
assert_log_lines "cas 5 .md normal livrable doc" "$d5" 1
rm -rf "$d5"

# ─── Cas 6 : édit hors touches: direct → log vide (non-régression) ───
d6=$(setup_tmp_e2e); make_index "$d6"
run_log "$d6" "outside/random.ts"
assert_log_lines "cas 6 hors touches: direct" "$d6" 0
rm -rf "$d6"

# ─── Cas 7 : édits successifs mix → log alimenté uniquement pour structurel ───
d7=$(setup_tmp_e2e); make_index "$d7"
run_log "$d7" ".docs/features/test/feat.md"
run_log "$d7" "src/foo.sh"
run_log "$d7" "feat.lock"
run_log "$d7" "README.md"
assert_log_lines "cas 7 mix (structurel + non-structurel)" "$d7" 2
# Vérifie que seuls src/foo.sh et README.md sont loggés
if [[ -f "$d7/.ai/.session-edits.log" ]]; then
  if grep -q '"file":"src/foo.sh"' "$d7/.ai/.session-edits.log" && \
     grep -q '"file":"README.md"' "$d7/.ai/.session-edits.log" && \
     ! grep -q '"file":".docs/features/test/feat.md"' "$d7/.ai/.session-edits.log" && \
     ! grep -q '"file":"feat.lock"' "$d7/.ai/.session-edits.log"; then
    pass=$((pass + 1))
    echo "PASS: cas 7b log contient seulement les édits structurels"
  else
    fail=$((fail + 1))
    failures+=("cas 7b : log contient des fichiers non-structurels OU il manque des structurels")
  fi
fi
rm -rf "$d7"

# ─── Rapport ───
total=$((pass + fail))
echo
echo "═══ test-stop-hook-idempotence ═══"
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
