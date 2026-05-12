#!/bin/bash
# dogfood-update.sh — Applique le rendu courant du template au repo source.
#
# Usage:
#   bash .ai/scripts/dogfood-update.sh          # dry-run
#   bash .ai/scripts/dogfood-update.sh --apply  # synchronise les fichiers runtime
#
# Source-only: ce script n'est pas rendu dans template/.ai/scripts/.

set -euo pipefail

mode="dry-run"
if [[ "${1:-}" == "--apply" ]]; then
  mode="apply"
elif [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '1,12p' "$0"
  exit 0
elif [[ -n "${1:-}" ]]; then
  echo "Usage: bash .ai/scripts/dogfood-update.sh [--apply]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

if [[ "$mode" == "dry-run" ]]; then
  exec bash "$script_dir/check-dogfood-drift.sh"
fi

if [[ ! -f "copier.yml" || ! -d "template" ]]; then
  echo "❌ dogfood-update doit être lancé depuis le repo source ai_context" >&2
  exit 1
fi
if ! command -v copier >/dev/null 2>&1; then
  echo "❌ copier introuvable" >&2
  exit 1
fi

src_copy="$(mktemp -d /tmp/ai-context-dogfood-src-XXXXXX)"
out="$(mktemp -d /tmp/ai-context-dogfood-XXXXXX)"
copy_log="$(mktemp /tmp/ai-context-dogfood-copy.log.XXXXXX)"
trap 'rm -rf "$src_copy" "$out"; rm -f "$copy_log"' EXIT

rsync -a --delete \
  --exclude='.git' \
  --exclude='.ai/.feature-index.json' \
  --exclude='.ai/.progress-history.jsonl' \
  --exclude='.ai/.session-edits.log' \
  --exclude='.ai/.session-edits.flushed' \
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

sync_args=(-a --checksum --delete)

echo "═══ dogfood-update ($mode) ═══"
echo "Rendu temporaire : $out"
echo

run_rsync() {
  local src="$1"
  local dst="$2"
  shift 2
  echo "→ $dst"
  rsync "${sync_args[@]}" "$@" "$src" "$dst"
}

run_rsync "$out/.ai/" ".ai/" \
  --exclude='.feature-index.json' \
  --exclude='.progress-history.jsonl' \
  --exclude='.session-edits.log' \
  --exclude='.session-edits.flushed' \
  --exclude='project' \
  --exclude='scripts/dogfood-update.sh' \
  --exclude='scripts/check-dogfood-drift.sh'
run_rsync "$out/.claude/settings.json" ".claude/settings.json"
run_rsync "$out/.claude/skills/" ".claude/skills/"
run_rsync "$out/.agents/" ".agents/"
run_rsync "$out/.githooks/" ".githooks/"
run_rsync "$out/AGENTS.md" "AGENTS.md"
run_rsync "$out/CLAUDE.md" "CLAUDE.md"
run_rsync "$out/README_AI_CONTEXT.md" "README_AI_CONTEXT.md"
run_rsync "$out/.docs/FEATURE_TEMPLATE.md" ".docs/FEATURE_TEMPLATE.md"
run_rsync "$out/.docs/frames/" ".docs/frames/"

cat <<'NOTE'

Source-only conservé volontairement :
- .github/workflows/ai-context-check.yml (plus strict que le rendu downstream)
- .github/workflows/template-smoke-test.yml
- README.md / CHANGELOG.md / PROJECT_STATE.md / MIGRATION.md
- tests/**
- template/**
NOTE

if [[ "$mode" == "apply" ]]; then
  chmod +x .ai/scripts/*.sh
  for hook in .githooks/commit-msg .githooks/pre-commit .githooks/post-checkout; do
    [[ -f "$hook" ]] && chmod +x "$hook"
  done
  echo
  echo "✅ Runtime dogfood synchronisé. Lance ensuite :"
  echo "   bash .ai/scripts/check-dogfood-drift.sh"
  echo "   bash .ai/scripts/check-shims.sh && bash .ai/scripts/check-features.sh"
else
  echo
  echo "Dry-run uniquement. Relance avec --apply pour écrire."
fi
