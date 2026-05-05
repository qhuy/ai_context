#!/bin/bash
# Non-regression: .ai/project is optional, project-owned, and reference-safe.

set -euo pipefail

cd "$(dirname "$0")/../.."

if ! command -v copier >/dev/null 2>&1; then
  echo "⚠ copier introuvable, test ignoré"
  exit 0
fi

tmp="$(mktemp -d /tmp/aic-project-overlay-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

src="$tmp/src"
out="$tmp/out"

rsync -a --delete \
  --exclude='.git' \
  --exclude='.ai/.feature-index.json' \
  --exclude='.ai/.progress-history.jsonl' \
  --exclude='.ai/.session-edits.log' \
  --exclude='.ai/.session-edits.flushed' \
  ./ "$src/"

copier copy --defaults --trust \
  --data project_name=overlay-test \
  "$src" "$out" >/dev/null

if [[ -e "$out/.ai/project" ]]; then
  echo "✗ .ai/project ne doit pas être scaffoldé par défaut"
  exit 1
fi

if ! ( cd "$out" && bash .ai/scripts/check-shims.sh ) >/dev/null; then
  echo "✗ check-shims échoue sans .ai/project/index.md"
  exit 1
fi

mkdir -p "$out/.ai/project"
cat > "$out/.ai/project/index.md" <<'MD'
# Project Overlay

Charger [domain](domain.md) seulement pour le vocabulaire métier.
MD
cat > "$out/.ai/project/domain.md" <<'MD'
# Domain Rules

Règle locale de test.
MD

if ! ( cd "$out" && bash .ai/scripts/check-ai-references.sh ) >/dev/null; then
  echo "✗ check-ai-references doit accepter les liens existants sous .ai/project/**"
  ( cd "$out" && bash .ai/scripts/check-ai-references.sh )
  exit 1
fi

cp -R . "$tmp/repo"
(
  cd "$tmp/repo"
  mkdir -p .ai/project
  printf '# Project Overlay\n' > .ai/project/index.md
  printf '# Domain\n' > .ai/project/domain.md
  bash .ai/scripts/check-dogfood-drift.sh >/dev/null
)

echo "✅ test-project-overlay PASS"
