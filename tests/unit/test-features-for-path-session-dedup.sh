#!/bin/bash
# test-features-for-path-session-dedup.sh
#
# Dedup d'injection par session : en hook, le corps d'une fiche ne part qu'une
# fois par session_id ; les appels suivants n'emettent qu'un rappel court.
# Couvre aussi les sorties de secours : session differente, fiche modifiee
# (mtime), opt-out par variable, et mode CLI (jamais dedupliqué).

set -euo pipefail

cd "$(dirname "$0")/../.."
repo_root=$(pwd)

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-session-dedup.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/.ai/scripts" "$tmp/.docs/features/quality"
cp "$repo_root/.ai/scripts/_lib.sh" "$tmp/.ai/scripts/_lib.sh"
cp "$repo_root/.ai/scripts/features-for-path.sh" "$tmp/.ai/scripts/features-for-path.sh"
cp "$repo_root/.ai/scripts/context-relevance-log.sh" "$tmp/.ai/scripts/context-relevance-log.sh"

# Fiche d'abord, index ensuite : l'index doit rester plus recent que les fiches
# pour que ensure_index ne tente pas un rebuild (build-feature-index.sh absent).
cat > "$tmp/.docs/features/quality/solo.md" <<'MD'
---
id: solo
scope: quality
title: Fiche temoin
status: active
touches:
  - src/foo.ts
---

# Fiche temoin

CORPS_SENTINELLE_UNIQUE
MD

cat > "$tmp/.ai/.feature-index.json" <<'JSON'
{
  "features": [
    {
      "scope": "quality",
      "id": "solo",
      "path": ".docs/features/quality/solo.md",
      "status": "active",
      "touches": ["src/foo.ts"],
      "depends_on": [],
      "touches_shared": []
    }
  ]
}
JSON
touch "$tmp/.ai/.feature-index.json"

hook_ctx() {
  local session="$1"
  shift
  printf '{"session_id":"%s","tool_name":"Edit","tool_input":{"file_path":"src/foo.ts"}}' "$session" \
    | (cd "$tmp" && "$@" bash .ai/scripts/features-for-path.sh) \
    | jq -r '.hookSpecificOutput.additionalContext // ""'
}

assert_body() {
  local desc="$1" out="$2"
  if ! printf '%s' "$out" | grep -q 'CORPS_SENTINELLE_UNIQUE'; then
    echo "FAIL: $desc -- le corps de la fiche est absent" >&2
    exit 1
  fi
  echo "PASS: $desc"
}

assert_reminder_only() {
  local desc="$1" out="$2"
  if printf '%s' "$out" | grep -q 'CORPS_SENTINELLE_UNIQUE'; then
    echo "FAIL: $desc -- le corps a ete reinjecte alors qu'il devait etre dedupliqué" >&2
    exit 1
  fi
  if ! printf '%s' "$out" | grep -q 'quality/solo'; then
    echo "FAIL: $desc -- la fiche a disparu de la sortie (rappel attendu)" >&2
    exit 1
  fi
  if ! printf '%s' "$out" | grep -q 'déjà injectée'; then
    echo "FAIL: $desc -- rappel court absent" >&2
    exit 1
  fi
  echo "PASS: $desc"
}

assert_no_marker() {
  local desc="$1" dir="$2"
  if find "$dir" -maxdepth 1 -type f -name 'quality_solo.*' -print 2>/dev/null | grep -q .; then
    echo "FAIL: $desc -- un marqueur est sorti du sous-dossier de session" >&2
    exit 1
  fi
  echo "PASS: $desc"
}

# 1-2. Coeur du contrat : premier appel = corps, second appel = rappel court.
assert_body "premier appel de la session injecte le corps" "$(hook_ctx sess-A env)"
assert_reminder_only "second appel de la meme session n'injecte qu'un rappel" "$(hook_ctx sess-A env)"

# 3. Isolation : une autre session repart d'un etat vierge.
assert_body "une session differente reinjecte le corps" "$(hook_ctx sess-B env)"

# 4. Invalidation par mtime : fiche modifiee => corps reinjecte dans la meme session.
sleep 1
touch "$tmp/.docs/features/quality/solo.md"
touch "$tmp/.ai/.feature-index.json"
assert_body "fiche modifiee (mtime) reinjecte le corps dans la meme session" "$(hook_ctx sess-A env)"
assert_reminder_only "apres reinjection, le nouveau marqueur redevient un rappel" "$(hook_ctx sess-A env)"

# 5. Opt-out explicite : la borne existante reste pilotable.
assert_body "AI_CONTEXT_FEATURE_DOC_SESSION_DEDUP=0 restaure l'injection complete" \
  "$(hook_ctx sess-A env AI_CONTEXT_FEATURE_DOC_SESSION_DEDUP=0)"

# 6. Mode CLI : pas de session_id, jamais de dedup (non-regression --with-docs).
cli_out=$(cd "$tmp" && bash .ai/scripts/features-for-path.sh --with-docs src/foo.ts)
assert_body "le mode CLI --with-docs n'est jamais dedupliqué" "$cli_out"
cli_out2=$(cd "$tmp" && bash .ai/scripts/features-for-path.sh --with-docs src/foo.ts)
assert_body "le mode CLI reste stable au second appel" "$cli_out2"

# 7. Etat illisible : fallback silencieux sur l'injection complete, exit 0.
chmod 500 "$tmp/.ai/.session-injected-docs"
ro_out=$(hook_ctx sess-C env)
chmod 700 "$tmp/.ai/.session-injected-docs"
assert_body "etat non inscriptible => fallback injection complete sans erreur" "$ro_out"

# 8. Les composants réservés ne doivent ni fusionner avec la racine d'état (`.`),
# ni remonter dans `.ai/` (`..`). Ils restent deux sessions distinctes.
assert_body "session point reste isolee au premier appel" "$(hook_ctx . env)"
assert_body "session point-point reste isolee au premier appel" "$(hook_ctx .. env)"
assert_reminder_only "session point se deduplique dans son sous-dossier" "$(hook_ctx . env)"
assert_reminder_only "session point-point se deduplique dans son sous-dossier" "$(hook_ctx .. env)"
[[ -d "$tmp/.ai/.session-injected-docs/_." ]] \
  || { echo "FAIL: sous-dossier attendu pour la session . absent" >&2; exit 1; }
[[ -d "$tmp/.ai/.session-injected-docs/_.." ]] \
  || { echo "FAIL: sous-dossier attendu pour la session .. absent" >&2; exit 1; }
assert_no_marker "aucun marqueur a la racine de session-injected-docs" "$tmp/.ai/.session-injected-docs"
assert_no_marker "aucun marqueur remonte dans .ai" "$tmp/.ai"

echo "✅ test-features-for-path-session-dedup PASS"
