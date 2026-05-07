#!/bin/bash
# tests/unit/test-auto-progress-filter.sh
#
# Couvre _lib.sh::is_structural_feature_edit (helper Phase 2 #4) et le
# comportement du filtre de transition spec→implement dans
# auto-progress.sh.
#
# 7 cas obligatoires (cf. workflow/auto-progress-file-filter Validation) :
#   1. .docs/features/** seul → no-bump
#   2. *.worklog.md seul → no-bump
#   3. source matchant touches: direct → bump
#   4. test matchant touches: direct → bump (TDD)
#   5. touches_shared: seul → no-bump (helper agnostique : caller filtre)
#   6. feature sans touches: → no-bump (en pratique, pas dans trace)
#   7. override env d'extensions exclues
#
# Plus : tests directs sur is_structural_feature_edit isolément.

set -uo pipefail

cd "$(dirname "$0")/../.."
repo_root=$(pwd)

# shellcheck source=../../.ai/scripts/_lib.sh
. "$repo_root/.ai/scripts/_lib.sh"

pass=0
fail=0
failures=()

assert_structural() {
  local desc="$1" feat="$2" file="$3"
  if is_structural_feature_edit "$feat" "$file"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failures+=("STRUCTUREL attendu : $desc — feat='$feat' file='$file'")
  fi
}

assert_not_structural() {
  local desc="$1" feat="$2" file="$3"
  if is_structural_feature_edit "$feat" "$file"; then
    fail=$((fail + 1))
    failures+=("NON-STRUCTUREL attendu : $desc — feat='$feat' file='$file'")
  else
    pass=$((pass + 1))
  fi
}

FEAT=".docs/features/quality/example.md"

# ─── Cas 1 : édit fiche feature seule → non-structurel ───
assert_not_structural "fiche feature exclue" "$FEAT" ".docs/features/quality/example.md"
assert_not_structural "autre fiche feature exclue" "$FEAT" ".docs/features/core/other.md"

# ─── Cas 2 : worklog seul → non-structurel ───
assert_not_structural "worklog dans .docs exclu" "$FEAT" ".docs/features/quality/example.worklog.md"
assert_not_structural "worklog hors .docs exclu" "$FEAT" "tests/foo.worklog.md"

# ─── Cas 3 : source structurel → structurel ───
assert_structural "source bash" "$FEAT" ".ai/scripts/foo.sh"
assert_structural "source ts" "$FEAT" "src/auth/login.ts"
assert_structural "source python" "$FEAT" "lib/utils.py"

# ─── Cas 4 : test = structurel (TDD valide) ───
assert_structural "test unit bash" "$FEAT" "tests/unit/test-foo.sh"
assert_structural "test source" "$FEAT" "tests/foo.test.ts"

# ─── Cas 5 : touches_shared → helper agnostique, structurel ───
# Le helper ne sait pas si touches/shared. C'est au caller (auto-progress.sh)
# de filtrer en amont via features_matching_path. Le helper reste structurel
# sur n'importe quel chemin non-noise.
assert_structural "fichier transverse (caller filtre direct vs shared)" "$FEAT" "shared/utils.sh"

# ─── Cas 6 : .lock exclu ───
assert_not_structural ".lock exclu" "$FEAT" "package-lock.json.lock"
assert_not_structural "Cargo.lock exclu" "$FEAT" "Cargo.lock"

# ─── Cas 7 : .ai/.* fichiers cachés (logs/cache auto) exclus ───
assert_not_structural ".ai/.feature-index.json" "$FEAT" ".ai/.feature-index.json"
assert_not_structural ".ai/.session-edits.log" "$FEAT" ".ai/.session-edits.log"
assert_not_structural ".ai/.context-relevance.jsonl" "$FEAT" ".ai/.context-relevance.jsonl"
assert_structural ".ai/scripts/x.sh OK (pas dans .ai/.*)" "$FEAT" ".ai/scripts/foo.sh"

# ─── Cas 8 : .md normal NON exclu (livrable doc possible) ───
assert_structural "README.md non exclu" "$FEAT" "README.md"
assert_structural ".md hors .docs/features OK" "$FEAT" "docs/architecture.md"

# ─── Cas 9 : override env AI_CONTEXT_AUTO_PROGRESS_FILTER_EXT ───
(
  export AI_CONTEXT_AUTO_PROGRESS_FILTER_EXT=".tmp,.bak"
  if is_structural_feature_edit "$FEAT" "src/foo.tmp"; then
    fail=$((fail + 1))
    failures+=("override env : .tmp devrait être exclu")
  else
    pass=$((pass + 1))
  fi
  if is_structural_feature_edit "$FEAT" "src/foo.sh"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failures+=("override env : .sh non listé devrait rester structurel")
  fi
)

# ─── Cas 10 : path normalisé (./prefix retiré) ───
assert_structural "path avec ./ prefix" "$FEAT" "./src/foo.sh"
assert_not_structural ".docs avec ./ prefix exclu" "$FEAT" "./.docs/features/x.md"

# ─── Cas 11 : entrées vides → non-structurel (best-effort) ───
assert_not_structural "feature_path vide" "" "src/foo.sh"
assert_not_structural "file_path vide" "$FEAT" ""

# ─── E2E : auto-progress.sh complet (Finding 2 Codex post-77d6d16) ───
# Setup : tmp repo avec mini structure .ai/, fiche feature spec + index
# + .session-edits.flushed. Lance auto-progress.sh, vérifie phase finale.

setup_tmp_repo_e2e() {
  local d
  d=$(mktemp -d 2>/dev/null || mktemp -d -t 'apf-e2e')
  mkdir -p "$d/.ai/scripts" "$d/.docs/features/test"
  cp "$repo_root/.ai/scripts/_lib.sh" "$d/.ai/scripts/_lib.sh"
  cp "$repo_root/.ai/scripts/auto-progress.sh" "$d/.ai/scripts/auto-progress.sh"
  cp "$repo_root/.ai/scripts/build-feature-index.sh" "$d/.ai/scripts/build-feature-index.sh"
  # Mini config schema
  mkdir -p "$d/.ai/schema"
  cat > "$d/.ai/schema/feature.schema.json" <<'EOF'
{"$schema":"https://json-schema.org/draft-07/schema#","type":"object","required":["id","scope","title","status"]}
EOF
  echo "$d"
}

# Cas E2E A : trace source direct → phase devient implement
tmp_a=$(setup_tmp_repo_e2e)
cat > "$tmp_a/.docs/features/test/feat.md" <<'EOF'
---
id: feat
scope: test
title: Test
status: active
touches:
  - src/foo.sh
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: 2026-05-07
---
# Test
EOF
cat > "$tmp_a/.ai/.feature-index.json" <<EOF
{"features":[{"scope":"test","id":"feat","path":".docs/features/test/feat.md","status":"active","touches":["src/foo.sh"],"progress":{"phase":"spec"}}]}
EOF
printf '{"feature":"test/feat","file":"src/foo.sh","ts":"2026-05-07T00:00:00Z"}\n' > "$tmp_a/.ai/.session-edits.flushed"
(cd "$tmp_a" && bash .ai/scripts/auto-progress.sh >/dev/null 2>&1) || true
phase_after=$(grep '^  phase:' "$tmp_a/.docs/features/test/feat.md" | head -1 | sed 's/^  phase:[[:space:]]*//')
if [[ "$phase_after" == "implement" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas E2E A trace source direct → phase=implement"
else
  fail=$((fail + 1))
  failures+=("cas E2E A : phase attendue=implement, obtenue=$phase_after")
fi
rm -rf "$tmp_a"

# Cas E2E B : trace .docs/features/** seule → no-bump
tmp_b=$(setup_tmp_repo_e2e)
cat > "$tmp_b/.docs/features/test/feat.md" <<'EOF'
---
id: feat
scope: test
title: Test
status: active
touches:
  - src/foo.sh
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: 2026-05-07
---
EOF
# Index : feat touches src/foo.sh ET .docs/features/** (cas où la fiche
# elle-même serait listée artificiellement). Trace : seule la fiche éditée.
cat > "$tmp_b/.ai/.feature-index.json" <<EOF
{"features":[{"scope":"test","id":"feat","path":".docs/features/test/feat.md","status":"active","touches":["src/foo.sh",".docs/features/test/feat.md"],"progress":{"phase":"spec"}}]}
EOF
printf '{"feature":"test/feat","file":".docs/features/test/feat.md","ts":"2026-05-07T00:00:00Z"}\n' > "$tmp_b/.ai/.session-edits.flushed"
(cd "$tmp_b" && bash .ai/scripts/auto-progress.sh >/dev/null 2>&1) || true
phase_after=$(grep '^  phase:' "$tmp_b/.docs/features/test/feat.md" | head -1 | sed 's/^  phase:[[:space:]]*//')
if [[ "$phase_after" == "spec" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas E2E B trace .docs/features/** seule → no-bump"
else
  fail=$((fail + 1))
  failures+=("cas E2E B : phase attendue=spec (no-bump), obtenue=$phase_after")
fi
rm -rf "$tmp_b"

# Cas E2E C : trace stale (fichier sans touches direct dans index) → no-bump
# (Finding 1 Codex post-77d6d16 : revalidation index courant.)
tmp_c=$(setup_tmp_repo_e2e)
cat > "$tmp_c/.docs/features/test/feat.md" <<'EOF'
---
id: feat
scope: test
title: Test
status: active
touches:
  - src/foo.sh
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: 2026-05-07
---
EOF
# Index : feat touches uniquement src/foo.sh. Trace : src/stale.sh
# (pas dans touches: direct, simulant trace stale après rebuild index).
cat > "$tmp_c/.ai/.feature-index.json" <<EOF
{"features":[{"scope":"test","id":"feat","path":".docs/features/test/feat.md","status":"active","touches":["src/foo.sh"],"progress":{"phase":"spec"}}]}
EOF
printf '{"feature":"test/feat","file":"src/stale.sh","ts":"2026-05-07T00:00:00Z"}\n' > "$tmp_c/.ai/.session-edits.flushed"
(cd "$tmp_c" && bash .ai/scripts/auto-progress.sh >/dev/null 2>&1) || true
phase_after=$(grep '^  phase:' "$tmp_c/.docs/features/test/feat.md" | head -1 | sed 's/^  phase:[[:space:]]*//')
if [[ "$phase_after" == "spec" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas E2E C trace stale → no-bump (revalidation index)"
else
  fail=$((fail + 1))
  failures+=("cas E2E C : phase attendue=spec (no-bump trace stale), obtenue=$phase_after")
fi
rm -rf "$tmp_c"

# Cas E2E D : trace mix structurel + non-structurel matchant touches: → bump
tmp_d=$(setup_tmp_repo_e2e)
cat > "$tmp_d/.docs/features/test/feat.md" <<'EOF'
---
id: feat
scope: test
title: Test
status: active
touches:
  - src/foo.sh
  - .docs/features/test/feat.md
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: 2026-05-07
---
EOF
cat > "$tmp_d/.ai/.feature-index.json" <<EOF
{"features":[{"scope":"test","id":"feat","path":".docs/features/test/feat.md","status":"active","touches":["src/foo.sh",".docs/features/test/feat.md"],"progress":{"phase":"spec"}}]}
EOF
printf '{"feature":"test/feat","file":".docs/features/test/feat.md","ts":"2026-05-07T00:00:00Z"}\n{"feature":"test/feat","file":"src/foo.sh","ts":"2026-05-07T00:00:01Z"}\n' > "$tmp_d/.ai/.session-edits.flushed"
(cd "$tmp_d" && bash .ai/scripts/auto-progress.sh >/dev/null 2>&1) || true
phase_after=$(grep '^  phase:' "$tmp_d/.docs/features/test/feat.md" | head -1 | sed 's/^  phase:[[:space:]]*//')
if [[ "$phase_after" == "implement" ]]; then
  pass=$((pass + 1))
  echo "PASS: cas E2E D mix .md + source structurel → bump"
else
  fail=$((fail + 1))
  failures+=("cas E2E D : phase attendue=implement (au moins 1 source), obtenue=$phase_after")
fi
rm -rf "$tmp_d"

# ─── Rapport ───
total=$((pass + fail))
echo "═══ test-auto-progress-filter ═══"
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
