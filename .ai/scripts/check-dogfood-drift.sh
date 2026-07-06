#!/bin/bash
# check-dogfood-drift.sh — Compare le runtime source avec le rendu dogfood.
#
# Usage:
#   bash .ai/scripts/check-dogfood-drift.sh

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
source "$script_dir/dogfood-runtime-lib.sh"
cd "$repo_root"

if [[ ! -f "copier.yml" || ! -d "template" ]]; then
  echo "❌ check-dogfood-drift doit être lancé depuis le repo source ai_context" >&2
  exit 1
fi
if ! command -v copier >/dev/null 2>&1; then
  echo "❌ copier introuvable" >&2
  exit 1
fi

src_copy="$(mktemp -d /tmp/ai-context-dogfood-src-XXXXXX)"
out_root="$(mktemp -d /tmp/ai-context-dogfood-drift-XXXXXX)"
trap 'rm -rf "$src_copy" "$out_root"' EXIT

rsync -a --delete "${DOGFOOD_SOURCE_COPY_RSYNC_EXCLUDES[@]}" "$repo_root/" "$src_copy/"

diff_found=0

render_profile() {
  local profile="$1"
  local out_dir="$2"
  local scope_profile="$3"
  local adoption_mode="$4"
  local tech_profile="$5"
  local agents_json="$6"
  local enable_ci_guard="$7"
  local copy_log="$out_root/$profile.copy.log"
  shift 7
  local extra_data=()
  local kv
  for kv in "$@"; do
    extra_data+=(--data "$kv")
  done

  if ! copier copy --defaults --trust \
    --data project_name=ai_context \
    --data project_description='Template copier pour industrialiser le contexte des agents IA' \
    --data scope_profile="$scope_profile" \
    --data adoption_mode="$adoption_mode" \
    --data tech_profile="$tech_profile" \
    --data commit_language=fr \
    --data docs_root=.docs \
    --data agents="$agents_json" \
    --data enable_ci_guard="$enable_ci_guard" \
    ${extra_data[@]+"${extra_data[@]}"} \
    "$src_copy" "$out_dir" >"$copy_log" 2>&1; then
    echo "❌ rendu Copier échoué ($profile)" >&2
    sed -n '1,160p' "$copy_log" >&2
    exit 1
  fi
  echo "profile-render: $profile"
}

expect_profile_file() {
  local profile="$1"
  local out_dir="$2"
  local rel="$3"
  if [[ ! -f "$out_dir/$rel" ]]; then
    echo "profile-drift: $profile missing $rel"
    diff_found=1
  fi
}

check_profile_sanity() {
  local profile="$1"
  local out_dir="$2"
  shift 2
  local rel

  for rel in "$@"; do
    expect_profile_file "$profile" "$out_dir" "$rel"
  done

  if ! (cd "$out_dir" && bash .ai/scripts/check-shims.sh >/dev/null 2>&1); then
    echo "profile-drift: $profile check-shims failed"
    diff_found=1
  fi
}

compare_file() {
  local label="$1"
  local src="$2"
  local dst="$3"
  if [[ ! -e "$dst" ]]; then
    echo "missing-runtime: $label ($dst)"
    diff_found=1
  elif ! diff -q "$src" "$dst" >/dev/null 2>&1; then
    echo "drift: $label"
    diff_found=1
  fi
}

compare_tree() {
  local label="$1"
  local src="$2"
  local dst="$3"
  local rel
  if [[ ! -d "$dst" ]]; then
    echo "missing-runtime: $label ($dst)"
    diff_found=1
    return
  fi
  while IFS= read -r rel; do
    dogfood_is_runtime_extra_ignored "$label" "$rel" && continue
    compare_file "$label/$rel" "$src/$rel" "$dst/$rel"
  done < <(cd "$src" && find . -type f | sed 's#^\./##' | sort)

  while IFS= read -r rel; do
    dogfood_is_runtime_extra_ignored "$label" "$rel" && continue
    if [[ ! -e "$src/$rel" ]]; then
      echo "extra-runtime: $label/$rel"
      diff_found=1
    fi
  done < <(cd "$dst" && find . -type f | sed 's#^\./##' | sort)
}

echo "═══ check-dogfood-drift ═══"

out="$out_root/dogfood-minimal"
out_conditional="$out_root/fullstack-cursor"

render_profile "dogfood-minimal" "$out" "minimal" "standard" "generic" '["claude","codex"]' "true"
render_profile "fullstack-cursor" "$out_conditional" "fullstack" "strict" "fullstack-dotnet-react" '["claude","codex","cursor","gemini","copilot"]' "false" "enable_copilot_shim=true"
check_profile_sanity "fullstack-cursor" "$out_conditional" \
  ".cursor/rules/protocol-reminder.mdc" \
  ".cursor/rules/back.mdc" \
  ".cursor/rules/front.mdc" \
  "GEMINI.md" \
  ".github/copilot-instructions.md" \
  ".ai/rules/tech-dotnet.md" \
  ".ai/rules/tech-react.md" \
  ".ai/rules/stack-fullstack-dotnet-react.md"

compare_tree ".ai" "$out/.ai" ".ai"
compare_file ".claude/settings.json" "$out/.claude/settings.json" ".claude/settings.json"
compare_tree ".claude/skills" "$out/.claude/skills" ".claude/skills"
compare_tree ".agents" "$out/.agents" ".agents"
compare_tree ".githooks" "$out/.githooks" ".githooks"
compare_file "AGENTS.md" "$out/AGENTS.md" "AGENTS.md"
compare_file "CLAUDE.md" "$out/CLAUDE.md" "CLAUDE.md"
compare_file "README_AI_CONTEXT.md" "$out/README_AI_CONTEXT.md" "README_AI_CONTEXT.md"
compare_file ".docs/FEATURE_TEMPLATE.md" "$out/.docs/FEATURE_TEMPLATE.md" ".docs/FEATURE_TEMPLATE.md"
compare_tree ".docs/frames" "$out/.docs/frames" ".docs/frames"
compare_tree ".docs/pilots" "$out/.docs/pilots" ".docs/pilots"

echo
dogfood_print_source_only_ignored

if [[ "$diff_found" -eq 0 ]]; then
  echo
  echo "✅ Runtime dogfood aligné avec le rendu Copier minimal ; profil conditionnel fullstack-cursor rendu."
else
  echo
  echo "❌ Drift détecté. Relance : bash .ai/scripts/dogfood-update.sh --apply"
fi

exit "$diff_found"
