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

rsync -a \
  --exclude='.git' \
  --exclude='.ai/.feature-index.json' \
  --exclude='.ai/.progress-history.jsonl' \
  --exclude='.ai/.session-edits.log' \
  --exclude='.ai/.session-edits.flushed' \
  --exclude='.ai/.context-relevance.jsonl' \
  --exclude='.ai/.context-relevance.jsonl.old' \
  ./ "$tmp/repo/"
(
  cd "$tmp/repo"
  mkdir -p .ai/project
  printf '# Project Overlay\n' > .ai/project/index.md
  printf '# Domain\n' > .ai/project/domain.md
  bash .ai/scripts/check-dogfood-drift.sh >/dev/null
)

# ── Registre de scopes : dogfood-drift tolère project/<scope>/index.md ──────
rsync -a \
  --exclude='.git' \
  --exclude='.ai/.feature-index.json' \
  --exclude='.ai/.progress-history.jsonl' \
  --exclude='.ai/.session-edits.log' \
  --exclude='.ai/.session-edits.flushed' \
  --exclude='.ai/.context-relevance.jsonl' \
  --exclude='.ai/.context-relevance.jsonl.old' \
  ./ "$tmp/repo-scope/"
(
  cd "$tmp/repo-scope"
  mkdir -p .ai/project/bo-front .ai/project/sql
  printf -- '---\noverlay_contract_version: 1\n---\n\n# Project Overlay\n' > .ai/project/index.md
  cat > .ai/project/bo-front/index.md <<'MD'
---
scope: bo-front
paths:
  - src/bo-front/**
meta:
  stack: React 18
  test_cmd: pnpm test
---
# Scope bo-front
## Conventions
- Composants dans src/components/.
MD
  printf '# Scope sql\n' > .ai/project/sql/index.md
  if ! bash .ai/scripts/check-dogfood-drift.sh >/dev/null; then
    echo "✗ check-dogfood-drift doit ignorer .ai/project/<scope>/index.md"
    exit 1
  fi
)

# ── Registre de scopes : check-ai-references accepte un lien vers <scope>/index.md ──
(
  cd "$out"
  mkdir -p .ai/project/payments
  printf '# Scope payments\n## Conventions\n- ...\n' > .ai/project/payments/index.md
  cat > .ai/project/index.md <<'MD'
---
overlay_contract_version: 1
---

# Project Overlay

Voir [payments](.ai/project/payments/index.md) pour les règles de paiement.
MD
  if ! bash .ai/scripts/check-ai-references.sh >/dev/null; then
    echo "✗ check-ai-references doit accepter les liens existants sous .ai/project/<scope>/**"
    bash .ai/scripts/check-ai-references.sh
    exit 1
  fi
)

echo "✅ test-project-overlay PASS"
