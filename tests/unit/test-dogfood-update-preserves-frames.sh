#!/bin/bash
# Non-regression: dogfood-update.sh --apply must preserve dated project frames
# and pilots (.docs/{frames,pilots}/AAAA-MM-JJ-*.md). Ils sont project-owned,
# ignorés par le drift
# check ; l'apply ne doit pas les supprimer via rsync --delete.

set -euo pipefail

cd "$(dirname "$0")/../.."

if ! command -v copier >/dev/null 2>&1; then
  echo "⚠ copier introuvable, test ignoré"
  exit 0
fi

tmp="$(mktemp -d /tmp/aic-dogfood-runtime-artifacts-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

rsync -a \
  --exclude='.git' \
  --exclude='.ai/.feature-index.json' \
  --exclude='.ai/.progress-history.jsonl' \
  --exclude='.ai/.session-edits.log' \
  --exclude='.ai/.session-edits.flushed' \
  --exclude='.ai/.context-relevance.jsonl' \
  --exclude='.ai/.context-relevance.jsonl.old' \
  ./ "$tmp/repo/"
cd "$tmp/repo"

# Frame et pilot datés project-owned présents avant l'apply.
frame=".docs/frames/2099-12-31-preserve-test.md"
pilot=".docs/pilots/2099-12-31-preserve-test.md"
mkdir -p .docs/frames
mkdir -p .docs/pilots
printf '# Frame de test à préserver\n' > "$frame"
printf '# Pilot de test à préserver\n' > "$pilot"
printf '# Guardrails source-only à préserver\n' > .ai/guardrails.md
printf 'core/sample\n' > .ai/.session-docs.log

if ! bash .ai/scripts/dogfood-update.sh --apply >/dev/null 2>&1; then
  echo "✗ dogfood-update.sh --apply a échoué"
  exit 1
fi

if [[ ! -f "$frame" ]]; then
  echo "✗ dogfood-update.sh --apply a supprimé le frame daté $frame"
  exit 1
fi
if [[ ! -f "$pilot" ]]; then
  echo "✗ dogfood-update.sh --apply a supprimé le pilot daté $pilot"
  exit 1
fi
if ! grep -q 'Guardrails source-only' .ai/guardrails.md; then
  echo "✗ dogfood-update.sh --apply a écrasé .ai/guardrails.md"
  exit 1
fi
if [[ ! -f .ai/.session-docs.log ]]; then
  echo "✗ dogfood-update.sh --apply a supprimé .ai/.session-docs.log"
  exit 1
fi
if [[ ! -f .ai/scripts/dogfood-runtime-lib.sh ]]; then
  echo "✗ dogfood-update.sh --apply a supprimé le helper source-only dogfood-runtime-lib.sh"
  exit 1
fi

# Les templates non datés restent synchronisés (font partie du runtime).
if [[ ! -f .docs/frames/0000-template.md ]]; then
  echo "✗ .docs/frames/0000-template.md devrait rester présent après --apply"
  exit 1
fi
if [[ ! -f .docs/pilots/0000-template.md ]]; then
  echo "✗ .docs/pilots/0000-template.md devrait rester présent après --apply"
  exit 1
fi

echo "✅ test-dogfood-update-preserves-frames PASS"
