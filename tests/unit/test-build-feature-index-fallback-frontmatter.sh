#!/bin/bash
# test-build-feature-index-fallback-frontmatter.sh — core/feature-index-cache.
#
# Le parseur fallback (sans yq) doit lire UNIQUEMENT le frontmatter, jamais le
# corps markdown. Régression historique : un `status:`/`depends_on:` présent dans
# le corps fuitait dans l'index (fausses valeurs, bien formées, sans signal).
# Couvre aussi le flow-style YAML (`touches: [a, b]`) que l'ancien awk vidait.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-bfi-fm.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/test"
cp "$repo_root/.ai/scripts/build-feature-index.sh" "$tmp/.ai/scripts/build-feature-index.sh"
cp "$repo_root/.ai/scripts/_lib.sh" "$tmp/.ai/scripts/_lib.sh"
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "bfi-fm-test"\n' > "$tmp/.ai/config.yml"

# Fiche piège : frontmatter SANS status, depends_on vide, mais le corps imite du
# frontmatter (status:/depends_on: en colonne 0). Ne doit JAMAIS fuiter.
cat > "$tmp/.docs/features/test/bodyleak.md" <<'MD'
---
id: bodyleak
scope: test
title: Body leak guard
depends_on: []
touches:
  - src/real.ts
---
# Corps markdown

Une ligne piège qui imite le frontmatter :
status: done-in-body
depends_on:
  - leaked/dep
touches:
  - leaked/file.ts
MD

# Fiche flow-style : touches au format inline [a, b].
cat > "$tmp/.docs/features/test/flowstyle.md" <<'MD'
---
id: flowstyle
scope: test
title: Flow style touches
status: active
touches: [src/a.ts, src/b.ts]
depends_on: []
---
# Flow
MD

# Fiche piège objets : le frontmatter ne déclare NI product, NI external_refs, NI
# progress, mais le corps markdown les imite en colonne 0 (cas réaliste : une fiche
# qui documente ces blocs). Aucune valeur ne doit fuiter dans l'index en fallback.
cat > "$tmp/.docs/features/test/objleak.md" <<'MD'
---
id: objleak
scope: test
title: Object body leak guard
status: active
touches:
  - src/real.ts
---
# Corps markdown

Une doc qui imite des blocs frontmatter :

product:
  type: leaked-type
  initiative: leaked-init
external_refs:
  ticket: LEAKED-123
progress:
  phase: leaked-phase
  step: leaked-step
  blockers:
    - leaked blocker
MD

(
  cd "$tmp"
  # PATH minimal = pas de yq → force le parseur fallback awk/sed.
  out="$(PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash .ai/scripts/build-feature-index.sh)"

  printf '%s\n' "$out" | jq -e . >/dev/null 2>&1 || fail "index fallback : JSON invalide"

  # — Body-leak : aucune valeur du corps ne doit apparaître —
  printf '%s\n' "$out" | jq -e '
    .features[] | select(.id == "bodyleak")
    | (.status != "done-in-body")
      and (.depends_on | index("leaked/dep") | not)
      and (.touches | index("leaked/file.ts") | not)
      and (.touches == ["src/real.ts"])
  ' >/dev/null || fail "body-leak : le corps markdown a fuité dans l'index (status/depends_on/touches)"

  # status absent du frontmatter → défaut '?', surtout pas la valeur du corps
  printf '%s\n' "$out" | jq -e '.features[] | select(.id == "bodyleak") | .status == "?"' >/dev/null \
    || fail "body-leak : status aurait dû retomber sur le défaut '?'"

  # — Flow-style : touches inline correctement extraits —
  printf '%s\n' "$out" | jq -e '
    .features[] | select(.id == "flowstyle")
    | (.touches | index("src/a.ts")) and (.touches | index("src/b.ts"))
      and (.touches | length) == 2
  ' >/dev/null || fail "flow-style : touches: [a, b] non extrait en fallback"

  # — Object body-leak : product / external_refs / progress du corps ne fuient pas —
  printf '%s\n' "$out" | jq -e '
    .features[] | select(.id == "objleak")
    | (.product == {})
      and (.external_refs == {})
      and (.progress.phase == "")
      and (.progress.step == "")
      and (.progress.blockers == [])
  ' >/dev/null || fail "object body-leak : product/external_refs/progress du corps ont fuité dans l'\''index"

  # — Read-only : stdout ne crée pas l'index —
  [[ ! -e .ai/.feature-index.json ]] || fail "fallback stdout a créé l'index (read-only violé)"
)

echo "✅ test-build-feature-index-fallback-frontmatter PASS"
