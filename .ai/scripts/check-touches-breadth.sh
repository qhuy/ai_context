#!/bin/bash
# check-touches-breadth.sh — Garde-fou ADVISORY contre la sur-couverture touches:.
#
# Réduit au fil de l'eau la "taxe" du gate freshness --staged : un édit d'infra
# partagée (ex. tests/smoke-test.sh) listée en `touches:` DIRECT par des dizaines
# de features force à toucher toutes leurs docs au commit. Ce check signale les
# candidats à reclasser en `touches_shared:` (qui apparaît dans les rapports mais
# ne déclenche PAS l'obligation fiche/worklog --staged, cf. FEATURE_TEMPLATE).
#
# Deux signaux (warn) :
#   A. Fichier exact présent dans le `touches:` DIRECT de PLUS de K features
#      (K via AIC_TOUCHES_BREADTH_K, défaut 4) → probablement de l'infra partagée.
#   B. Glob catch-all top-level en `touches:` (préfixe non-glob ≤ 1 segment :
#      .ai/**, template/**, tests/**, …) → vérifier qu'il doit déclencher l'obligation.
#
# NON bloquant (exit 0 toujours) : honore workflow/feature-granularity (« pas de
# gate fragile/bloquant dans les scripts »). Informatif, à traiter incrémentalement.
#
# Read-only : index temporaire via mktemp, jamais d'écriture de .ai/.feature-index.json.

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"
require_cmd jq
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

K="${AIC_TOUCHES_BREADTH_K:-4}"

index_file=".ai/.feature-index.json"
index_tmp="$(mktemp "${TMPDIR:-/tmp}/aic-touches-breadth.XXXXXX")"
trap 'rm -f "$index_tmp"' EXIT
if bash "$script_dir/build-feature-index.sh" > "$index_tmp" 2>/dev/null; then
  index_file="$index_tmp"
elif [[ -f "$index_file" ]]; then
  :
else
  echo "  ⚠️  pas d'index feature, rien à vérifier" >&2
  exit 0
fi

echo "═══ check-touches-breadth (advisory) ═══"

# Signal A : fichier exact (non-glob) partagé par > K features en touches: direct.
shared="$(jq -r --argjson k "$K" '
  [ .features[] | {sid: (.scope + "/" + .id), t: (.touches[]? // empty)} ]
  | map(select(.t | test("[*?[]") | not))
  | group_by(.t)
  | map(select(length > $k))
  | sort_by(-length)
  | .[] | (.[0].t) + "\t" + (length | tostring) + "\t" + ([.[].sid] | join(", "))
' "$index_file" 2>/dev/null || true)"

# Signal B : glob catch-all top-level (préfixe non-glob ≤ 1 segment) en touches: direct.
broad="$(jq -r '
  [ .features[] | {sid: (.scope + "/" + .id), t: (.touches[]? // empty)} ]
  | map(select(.t | test("[*?]")))
  | map(. + {depth: (.t | split("*")[0] | split("/") | map(select(length > 0)) | length)})
  | map(select(.depth <= 1))
  | .[] | .sid + "\t" + .t
' "$index_file" 2>/dev/null || true)"

found=0
if [[ -n "$shared" ]]; then
  found=1
  echo
  echo "  A. Fichiers en touches: DIRECT de > $K features (→ envisager touches_shared:) :"
  printf '%s\n' "$shared" | while IFS=$'\t' read -r path n feats; do
    [[ -z "$path" ]] && continue
    echo "    - $path  ($n features : $feats)"
  done
fi
if [[ -n "$broad" ]]; then
  found=1
  echo
  echo "  B. Globs catch-all top-level en touches: (vérifier l'obligation doc) :"
  printf '%s\n' "$broad" | while IFS=$'\t' read -r feat path; do
    [[ -z "$feat" ]] && continue
    echo "    - $feat  →  $path"
  done
fi

echo
if [[ "$found" -eq 0 ]]; then
  echo "✅ aucune sur-couverture touches: détectée (K=$K)"
else
  echo "ℹ️  Advisory : reclasser ces touches: en touches_shared: (ou affiner le glob) réduit la taxe du gate freshness --staged. Non bloquant."
fi
exit 0
