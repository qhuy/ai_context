#!/bin/bash
# test-features-for-path-relevance-ranking.sh
#
# Non-regression R2 : features-for-path exploite le tracker pour de-ranker
# une feature injectee plusieurs fois sans intersection, sans modifier le
# ranking de base quand le signal est absent, sous le seuil, ou desactive.

set -euo pipefail

cd "$(dirname "$0")/../.."
repo_root=$(pwd)

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-relevance-ranking.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/.ai/scripts"
cp "$repo_root/.ai/scripts/_lib.sh" "$tmp/.ai/scripts/_lib.sh"
cp "$repo_root/.ai/scripts/features-for-path.sh" "$tmp/.ai/scripts/features-for-path.sh"
cp "$repo_root/.ai/scripts/context-relevance-log.sh" "$tmp/.ai/scripts/context-relevance-log.sh"

cat > "$tmp/.ai/.feature-index.json" <<'JSON'
{
  "features": [
    {
      "scope": "quality",
      "id": "a-noisy",
      "path": ".docs/features/quality/a-noisy.md",
      "status": "active",
      "touches": ["src/foo.ts"],
      "depends_on": [],
      "touches_shared": []
    },
    {
      "scope": "quality",
      "id": "z-clean",
      "path": ".docs/features/quality/z-clean.md",
      "status": "active",
      "touches": ["src/foo.ts"],
      "depends_on": [],
      "touches_shared": []
    },
    {
      "scope": "quality",
      "id": "m-broad",
      "path": ".docs/features/quality/m-broad.md",
      "status": "active",
      "touches": ["src/**"],
      "depends_on": [],
      "touches_shared": []
    }
  ]
}
JSON

first_feature() {
  (
    cd "$tmp"
    AI_CONTEXT_FEATURES_TOP_K=1 "$@" bash .ai/scripts/features-for-path.sh src/foo.ts
  ) | awk '/^  • / {print $2; exit}'
}

assert_first() {
  local desc="$1"
  local expected="$2"
  shift 2
  local got
  got=$(first_feature "$@")
  if [[ "$got" != "$expected" ]]; then
    echo "FAIL: $desc -- attendu $expected, obtenu ${got:-<vide>}" >&2
    exit 1
  fi
  echo "PASS: $desc"
}

# Sans tracker, le tri historique departage par scope/id apres specificite.
assert_first "baseline sans log garde le tie-break scope/id" "quality/a-noisy" env

cat > "$tmp/.ai/.context-relevance.jsonl" <<'JSONL'
{"ts":"2026-07-02T10:00:00Z","event":"summary","injected_features":["quality/a-noisy"],"touched_features":[],"intersection":[]}
{"ts":"2026-07-02T10:01:00Z","event":"summary","injected_features":["quality/a-noisy"],"touched_features":[],"intersection":[]}
{"ts":"2026-07-02T10:02:00Z","event":"summary","injected_features":["quality/a-noisy"],"touched_features":[],"intersection":[]}
JSONL

assert_first "feature injectee sans intersection descend derriere un match equivalent" "quality/z-clean" env
assert_first "seuil plus haut ignore le signal insuffisant" "quality/a-noisy" env AI_CONTEXT_RELEVANCE_RANK_MIN_INJECTED=4
assert_first "opt-out ranking relevance restaure le tri de base" "quality/a-noisy" env AI_CONTEXT_RELEVANCE_RANKING=0

echo '{"tool_name":"Edit","tool_input":{"file_path":"src/foo.ts"}}' \
  | (cd "$tmp" && AI_CONTEXT_FEATURES_TOP_K=1 bash .ai/scripts/features-for-path.sh) >/dev/null
hook_direct=$(jq -rs '[.[] | select(.event == "inject")] | last | .direct_features[0]' "$tmp/.ai/.context-relevance.jsonl" 2>/dev/null)
if [[ "$hook_direct" != "quality/z-clean" ]]; then
  echo "FAIL: hook direct_features doit rester aligne sur les colonnes gardees, obtenu ${hook_direct:-<vide>}" >&2
  exit 1
fi
echo "PASS: hook direct_features reste un vrai scope/id apres ajout de la colonne penalty"

echo "✅ test-features-for-path-relevance-ranking PASS"
