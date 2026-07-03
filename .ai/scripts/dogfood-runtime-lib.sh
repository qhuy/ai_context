#!/bin/bash
# dogfood-runtime-lib.sh — Helpers source-only pour dogfood-update/drift.
#
# Ce fichier n'est pas rendu par Copier. Il centralise les exclusions qui
# protègent les fichiers mainteneur et volatils pendant le dogfooding.

DOGFOOD_VOLATILE_AI_FILES=(
  ".feature-index.json"
  ".progress-history.jsonl"
  ".session-edits.log"
  ".session-edits.flushed"
  ".session-docs.log"
  ".context-relevance.jsonl"
  ".context-relevance.jsonl.old"
)

DOGFOOD_SOURCE_COPY_RSYNC_EXCLUDES=(
  --exclude=".git"
)
for dogfood_rel in "${DOGFOOD_VOLATILE_AI_FILES[@]}"; do
  DOGFOOD_SOURCE_COPY_RSYNC_EXCLUDES+=(--exclude=".ai/$dogfood_rel")
done
unset dogfood_rel

DOGFOOD_AI_RUNTIME_RSYNC_EXCLUDES=()
for dogfood_rel in "${DOGFOOD_VOLATILE_AI_FILES[@]}"; do
  DOGFOOD_AI_RUNTIME_RSYNC_EXCLUDES+=(--exclude="$dogfood_rel")
done
unset dogfood_rel
DOGFOOD_AI_RUNTIME_RSYNC_EXCLUDES+=(
  --exclude="guardrails.md"
  --exclude="project"
  --exclude="scripts/dogfood-update.sh"
  --exclude="scripts/check-dogfood-drift.sh"
  --exclude="scripts/dogfood-runtime-lib.sh"
)

DOGFOOD_DATED_DOC_RSYNC_EXCLUDES=(
  --exclude="[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md"
)

dogfood_is_dated_project_doc() {
  local rel="$1"
  case "$rel" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md)
      return 0
      ;;
  esac
  return 1
}

dogfood_is_ai_runtime_extra_ignored() {
  local rel="$1"
  case "$rel" in
    .feature-index.json|.progress-history.jsonl|.session-edits.log|.session-edits.flushed|.session-docs.log|.context-relevance.jsonl|.context-relevance.jsonl.old|guardrails.md|project|project/*|scripts/dogfood-update.sh|scripts/check-dogfood-drift.sh|scripts/dogfood-runtime-lib.sh)
      return 0
      ;;
  esac
  return 1
}

dogfood_is_runtime_extra_ignored() {
  local label="$1"
  local rel="$2"

  if [[ "$label" == ".ai" ]] && dogfood_is_ai_runtime_extra_ignored "$rel"; then
    return 0
  fi
  if [[ "$label" == ".docs/frames" || "$label" == ".docs/pilots" ]] && dogfood_is_dated_project_doc "$rel"; then
    return 0
  fi
  return 1
}

dogfood_print_source_only_ignored() {
  cat <<'NOTE'
source-only ignored:
- .github/workflows/ai-context-check.yml
- .github/workflows/template-smoke-test.yml
- README.md / CHANGELOG.md / PROJECT_STATE.md / MIGRATION.md
- .docs/frames/YYYY-MM-DD-*.md
- .docs/pilots/YYYY-MM-DD-*.md
- .ai/guardrails.md (projet-spécifique, comme .ai/project/**)
- .ai/scripts/dogfood-update.sh / check-dogfood-drift.sh / dogfood-runtime-lib.sh (outillage source-only)
- tests/**
- template/**
NOTE
}
