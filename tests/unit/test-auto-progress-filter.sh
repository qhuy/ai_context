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
