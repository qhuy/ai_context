#!/bin/bash
# check-ai-references.sh — Vérifie l'intégrité des liens markdown vers .ai/* et .docs/*.
#
# Usage : bash .ai/scripts/check-ai-references.sh

set -euo pipefail

cd "$(dirname "$0")/../.."

fail=0
ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1"; fail=1; }

echo "═══ check-ai-references ═══"

# Scan tous les .md / shims à la racine + .ai/, cherche les refs relatives
# vers .ai/... ou .docs/... et vérifie que la cible existe.

shopt -s nullglob
files=(
  AGENTS.md CLAUDE.md GEMINI.md .github/copilot-instructions.md
  .ai/**/*.md
)

missing=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  # grep des liens markdown : [label](path)
  while IFS= read -r path; do
    # Ignore URL externe
    [[ "$path" =~ ^https?:// ]] && continue
    [[ "$path" =~ ^mailto: ]] && continue
    # Résout les chemins relatifs depuis le fichier source
    dir="$(dirname "$f")"
    resolved="$dir/$path"
    # Normalise (enlève ./ et ../)
    resolved=$(cd "$(dirname "$resolved")" 2>/dev/null && echo "$PWD/$(basename "$resolved")" || echo "$resolved")
    resolved=${resolved#$PWD/}
    if [[ ! -e "$resolved" && ! -e "$path" ]]; then
      ko "$f → $path (introuvable)"
      missing=$((missing+1))
    fi
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\(([^)]+)\)$/\1/' | grep -vE '^#')
done

if [[ "$missing" -eq 0 ]]; then
  ok "Toutes les références markdown pointent vers des fichiers existants."
  echo "✅ PASS"
  exit 0
else
  echo "❌ FAIL — $missing référence(s) cassée(s)"
  exit 1
fi
