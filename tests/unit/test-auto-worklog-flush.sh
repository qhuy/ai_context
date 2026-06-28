#!/bin/bash
# test-auto-worklog-flush.sh — workflow/auto-worklog (fix churn date).
#
# Le flush Stop append au worklog la trace des éditions MAIS ne bumpe PLUS
# progress.updated dans le frontmatter (sinon "commits juste pour la date").

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-auto-worklog-flush.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/core" "$tmp/src"
for s in _lib.sh build-feature-index.sh auto-worklog-flush.sh auto-worklog-log.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"

cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "auto-worklog-flush-test"
YAML

cat > "$tmp/.docs/features/core/sample.md" <<'MD'
---
id: sample
scope: core
title: Sample
status: active
type: feature
depends_on: []
touches:
  - src/**
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-01-01"
---
# Sample
MD

printf 'export const x = 1;\n' > "$tmp/src/app.ts"

cd "$tmp"
bash .ai/scripts/build-feature-index.sh --write >/dev/null 2>&1
# Trace d'un édit structurel de src/app.ts pour core/sample (comme PostToolUse).
printf '{"feature":"core/sample","file":"src/app.ts","ts":"2026-06-26T00:00:00Z"}\n' > .ai/.session-edits.log

bash .ai/scripts/auto-worklog-flush.sh

# 1. Worklog appendé avec le fichier édité.
[[ -f .docs/features/core/sample.worklog.md ]] || fail "worklog non créé par le flush"
grep -q 'src/app.ts' .docs/features/core/sample.worklog.md || fail "le worklog devrait lister le fichier édité"

# 2. RÉGRESSION fix churn : progress.updated NON modifié par le flush.
grep -q 'updated: "2026-01-01"' .docs/features/core/sample.md \
  || fail "le flush ne doit PAS bumper progress.updated (churn date)"

# 3. Le log de session est consommé (déplacé vers .flushed).
[[ ! -s .ai/.session-edits.log ]] || fail "le log de session aurait dû être vidé/déplacé"

# ── Anti-churn : pas de bloc auto si la feature est documentée manuellement ce tour ──

# 4. auto-worklog-log.sh marque une feature dont la DOC (fiche/worklog) est éditée.
rm -f .ai/.session-docs.log
printf '{"tool_name":"Edit","tool_input":{"file_path":".docs/features/core/sample.worklog.md"}}' \
  | bash .ai/scripts/auto-worklog-log.sh
grep -qx 'core/sample' .ai/.session-docs.log 2>/dev/null \
  || fail "auto-worklog-log devrait marquer core/sample (édit doc) dans .session-docs.log"

# 5. Le flush NE ré-append PAS de bloc auto pour une feature documentée ce tour.
blocks_before=$(grep -c '^## .* — auto$' .docs/features/core/sample.worklog.md)
printf '{"feature":"core/sample","file":"src/app2.ts","ts":"2026-06-26T00:00:00Z"}\n' > .ai/.session-edits.log
printf 'core/sample\n' > .ai/.session-docs.log
bash .ai/scripts/auto-worklog-flush.sh
blocks_after=$(grep -c '^## .* — auto$' .docs/features/core/sample.worklog.md)
[[ "$blocks_after" -eq "$blocks_before" ]] \
  || fail "le flush ne doit PAS ajouter de bloc auto pour une feature documentée ce tour"
grep -q 'src/app2.ts' .docs/features/core/sample.worklog.md \
  && fail "src/app2.ts ne doit PAS apparaître (feature documentée → bloc auto supprimé)" || true

# 6. Le marqueur .session-docs.log est nettoyé après le flush.
[[ ! -f .ai/.session-docs.log ]] || fail ".session-docs.log devrait être nettoyé par le flush"

# 7. Contrôle : une feature NON documentée reçoit toujours son bloc auto (filet de sécurité).
printf '{"feature":"core/sample","file":"src/app3.ts","ts":"2026-06-26T00:00:00Z"}\n' > .ai/.session-edits.log
bash .ai/scripts/auto-worklog-flush.sh
grep -q 'src/app3.ts' .docs/features/core/sample.worklog.md \
  || fail "une feature non documentée doit toujours recevoir son bloc auto (filet de sécurité)"

echo "✅ test-auto-worklog-flush PASS"
