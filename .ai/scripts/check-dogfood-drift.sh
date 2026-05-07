#!/bin/bash
# check-dogfood-drift.sh — Compare le runtime source avec un rendu Copier minimal.
#
# Usage:
#   bash .ai/scripts/check-dogfood-drift.sh

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
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
out="$(mktemp -d /tmp/ai-context-dogfood-drift-XXXXXX)"
copy_log="$(mktemp /tmp/ai-context-dogfood-drift-copy.log.XXXXXX)"
trap 'rm -rf "$src_copy" "$out"; rm -f "$copy_log"' EXIT

rsync -a --delete \
  --exclude='.git' \
  --exclude='.ai/.feature-index.json' \
  --exclude='.ai/.progress-history.jsonl' \
  --exclude='.ai/.session-edits.log' \
  --exclude='.ai/.session-edits.flushed' \
  --exclude='.ai/.context-relevance.jsonl' \
  --exclude='.ai/.context-relevance.jsonl.old' \
  "$repo_root/" "$src_copy/"

if ! copier copy --defaults --trust \
  --data project_name=ai_context \
  --data project_description='Template copier pour industrialiser le contexte des agents IA' \
  --data scope_profile=minimal \
  --data adoption_mode=standard \
  --data tech_profile=generic \
  --data commit_language=fr \
  --data docs_root=.docs \
  --data agents='["claude","codex"]' \
  --data enable_ci_guard=true \
  "$src_copy" "$out" >"$copy_log" 2>&1; then
  echo "❌ rendu Copier échoué" >&2
  sed -n '1,160p' "$copy_log" >&2
  exit 1
fi

diff_found=0

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
    is_ignored_runtime_extra "$rel" && continue
    compare_file "$label/$rel" "$src/$rel" "$dst/$rel"
  done < <(cd "$src" && find . -type f | sed 's#^\./##' | sort)

  while IFS= read -r rel; do
    is_ignored_runtime_extra "$rel" && continue
    if [[ ! -e "$src/$rel" ]]; then
      echo "extra-runtime: $label/$rel"
      diff_found=1
    fi
  done < <(cd "$dst" && find . -type f | sed 's#^\./##' | sort)
}

is_ignored_runtime_extra() {
  case "$1" in
    .feature-index.json|.progress-history.jsonl|.session-edits.log|.session-edits.flushed|.context-relevance.jsonl|.context-relevance.jsonl.old|scripts/dogfood-update.sh|scripts/check-dogfood-drift.sh|project|project/*)
      return 0
      ;;
  esac
  return 1
}

echo "═══ check-dogfood-drift ═══"

compare_tree ".ai" "$out/.ai" ".ai"
compare_file ".claude/settings.json" "$out/.claude/settings.json" ".claude/settings.json"
compare_tree ".claude/skills" "$out/.claude/skills" ".claude/skills"
compare_tree ".agents" "$out/.agents" ".agents"
compare_tree ".githooks" "$out/.githooks" ".githooks"
compare_file "AGENTS.md" "$out/AGENTS.md" "AGENTS.md"
compare_file "CLAUDE.md" "$out/CLAUDE.md" "CLAUDE.md"
compare_file "README_AI_CONTEXT.md" "$out/README_AI_CONTEXT.md" "README_AI_CONTEXT.md"
compare_file ".docs/FEATURE_TEMPLATE.md" "$out/.docs/FEATURE_TEMPLATE.md" ".docs/FEATURE_TEMPLATE.md"

echo
echo "source-only ignored:"
echo "- .github/workflows/ai-context-check.yml"
echo "- .github/workflows/template-smoke-test.yml"
echo "- README.md / CHANGELOG.md / PROJECT_STATE.md / MIGRATION.md"
echo "- tests/**"
echo "- template/**"

if [[ "$diff_found" -eq 0 ]]; then
  echo
  echo "✅ Runtime dogfood aligné avec le rendu Copier minimal."
else
  echo
  echo "❌ Drift détecté. Relance : bash .ai/scripts/dogfood-update.sh --apply"
fi

exit "$diff_found"
