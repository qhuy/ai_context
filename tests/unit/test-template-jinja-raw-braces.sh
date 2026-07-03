#!/bin/bash
# test-template-jinja-raw-braces.sh — core/dogfood-runtime-sync.
#
# Empêche les expansions Bash de longueur `${#var}` non protégées dans les
# fichiers Jinja. Sans bloc `{% raw %}`, Jinja peut interpréter `{#` comme début
# de commentaire et casser le rendu Copier avant les tests runtime.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
failures="$(mktemp "${TMPDIR:-/tmp}/aic-jinja-raw.XXXXXX")"
trap 'rm -f "$failures"' EXIT

while IFS= read -r file; do
  awk -v file="$file" '
    /\{%-?[[:space:]]*raw[[:space:]]*-?%\}/ { raw = 1 }
    !raw && index($0, "${#") {
      printf "%s:%d:%s\n", file, FNR, $0
    }
    /\{%-?[[:space:]]*endraw[[:space:]]*-?%\}/ { raw = 0 }
  ' "$file" >> "$failures"
done < <(find "$repo_root/template" -type f -name "*.jinja" -print)

if [[ -s "$failures" ]]; then
  echo "FAIL: expansions Bash \${#...} non protégées par {% raw %} :" >&2
  cat "$failures" >&2
  exit 1
fi

echo "test-template-jinja-raw-braces PASS"
