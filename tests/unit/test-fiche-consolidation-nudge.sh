#!/bin/bash
# test-fiche-consolidation-nudge.sh — workflow/feature-consolidation-nudge.
#
# Le hook PreToolUse réinjecte une question de consolidation + les fiches sœurs
# UNIQUEMENT à l'édition d'une fiche existante (pas worklog, pas code, pas création).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-fiche-nudge.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.docs/features/sales" "$tmp/src"
cp "$repo_root/.ai/scripts/fiche-consolidation-nudge.sh" "$tmp/.ai/scripts/"

for f in reports reports-rights imports; do
  printf -- '---\nid: %s\nscope: sales\ntitle: %s\nstatus: active\n---\n# %s\n' "$f" "$f" "$f" > "$tmp/.docs/features/sales/$f.md"
done
printf '# Worklog — sales/reports\n' > "$tmp/.docs/features/sales/reports.worklog.md"
printf 'export const x = 1;\n' > "$tmp/src/app.ts"

cd "$tmp"
git init -q && git config user.email t@e.x && git config user.name t && git add . && git commit -qm seed

nudge() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1" | bash .ai/scripts/fiche-consolidation-nudge.sh; }

# Cas 1 : édition d'une fiche existante → nudge avec sœurs + famille d'id.
out="$(nudge "$tmp/.docs/features/sales/reports.md")"
echo "$out" | grep -q 'raison' || fail "nudge devrait poser la question de raison d'être"
echo "$out" | grep -q 'sales/reports-rights' || fail "devrait lister la sœur reports-rights"
echo "$out" | grep -q 'famille' || fail "reports-rights devrait être marquée famille d'id"
echo "$out" | grep -q 'sales/imports' || fail "devrait lister la sœur imports"
echo "$out" | grep -q 'reports.worklog' && fail "ne devrait PAS lister le worklog"

# Cas 2 : édition d'un worklog → rien.
out="$(nudge "$tmp/.docs/features/sales/reports.worklog.md")"
[[ -z "$out" ]] || fail "édition de worklog ne doit rien émettre"

# Cas 3 : édition de code → rien.
out="$(nudge "$tmp/src/app.ts")"
[[ -z "$out" ]] || fail "édition de code ne doit rien émettre"

# Cas 4 : création d'une NOUVELLE fiche (fichier absent) → rien (feature-new gère).
out="$(nudge "$tmp/.docs/features/sales/brand-new.md")"
[[ -z "$out" ]] || fail "création d'une nouvelle fiche ne doit pas nudger"

echo "✅ test-fiche-consolidation-nudge PASS"
