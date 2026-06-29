#!/bin/bash
# test-build-feature-index-contract.sh — contrat core de build-feature-index.
#
# Couvre :
#   1. stdout ne crée pas .ai/.feature-index.json ;
#   2. l'ordre des features est stable ;
#   3. la représentation contractuelle est stable hors generated_at ;
#   4. --write ne réécrit pas le cache si seul generated_at changerait ;
#   5. --write réécrit si le contenu contractuel change.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-index-contract.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"
}

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/core" "$tmp/.docs/features/quality"
cp "$repo_root/.ai/scripts/build-feature-index.sh" "$tmp/.ai/scripts/build-feature-index.sh"
cp "$repo_root/.ai/scripts/_lib.sh" "$tmp/.ai/scripts/_lib.sh"
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "index-contract-test"
YAML

(
  cd "$tmp"

  empty_out="$(bash .ai/scripts/build-feature-index.sh)"
  [[ ! -e .ai/.feature-index.json ]] || fail "stdout vide a créé .ai/.feature-index.json"
  printf '%s\n' "$empty_out" | jq -e '.features == []' >/dev/null \
    || fail "index stdout vide invalide"

cat > "$tmp/.docs/features/quality/z-last.md" <<'MD'
---
id: z-last
scope: quality
title: Z Last
status: active
depends_on: []
touches:
  - z/**
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-05-14"
---

# Z Last
MD

cat > "$tmp/.docs/features/core/a-first.md" <<'MD'
---
id: a-first
scope: core
title: A First
status: active
depends_on: []
touches:
  - a/**
progress:
  phase: spec
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-05-14"
---

# A First
MD

  out1="$(bash .ai/scripts/build-feature-index.sh)"
  [[ ! -e .ai/.feature-index.json ]] || fail "stdout a créé .ai/.feature-index.json"

  sleep 1
  out2="$(bash .ai/scripts/build-feature-index.sh)"
  contract1="$(printf '%s\n' "$out1" | jq -S 'del(.generated_at)')"
  contract2="$(printf '%s\n' "$out2" | jq -S 'del(.generated_at)')"
  [[ "$contract1" == "$contract2" ]] || fail "contrat stdout instable hors generated_at"

  order="$(printf '%s\n' "$out1" | jq -r '.features[].path' | paste -sd '|' -)"
  [[ "$order" == ".docs/features/core/a-first.md|.docs/features/quality/z-last.md" ]] \
    || fail "ordre feature instable/inattendu : $order"

  # ─── Contrat de CLÉS émises, couplé à schema_version (opérationnalise la version) ───
  # Snapshot du jeu de clés pour le schema_version courant. Si la liste change, ce
  # test ÉCHOUE → décision consciente : bumper schema_version dans build-feature-index.sh
  # ET mettre à jour ce snapshot (clés + version ensemble). Inverse l'incitation : on
  # ne peut plus modifier le contrat d'index sans toucher ce test et bumper la version.
  ver="$(printf '%s\n' "$out1" | jq -r '.schema_version')"
  top_keys="$(printf '%s\n' "$out1" | jq -rS 'keys | join(",")')"
  feat_keys="$(printf '%s\n' "$out1" | jq -rS '.features[0] | keys | join(",")')"
  prog_keys="$(printf '%s\n' "$out1" | jq -rS '.features[0].progress | keys | join(",")')"
  case "$ver" in
    1)
      [[ "$top_keys" == "features,generated_at,project_id,schema_version" ]] \
        || fail "schema_version=1 mais clés top-level modifiées ($top_keys) — bumper la version + MAJ snapshot"
      [[ "$feat_keys" == "depends_on,external_refs,id,path,product,progress,scope,status,touches,touches_shared,type" ]] \
        || fail "schema_version=1 mais clés feature modifiées ($feat_keys) — bumper la version + MAJ snapshot"
      [[ "$prog_keys" == "blockers,phase,resume_hint,step,updated" ]] \
        || fail "schema_version=1 mais clés progress modifiées ($prog_keys) — bumper la version + MAJ snapshot"
      ;;
    *)
      fail "schema_version=$ver inconnu de ce test — ajouter le snapshot de clés correspondant"
      ;;
  esac

  bash .ai/scripts/build-feature-index.sh --write >/dev/null
  [[ -f .ai/.feature-index.json ]] || fail "--write n'a pas créé l'index"
  before_mtime="$(mtime .ai/.feature-index.json)"
  before_hash="$(jq -S 'del(.generated_at)' .ai/.feature-index.json)"

  sleep 1
  bash .ai/scripts/build-feature-index.sh --write >/dev/null
  after_mtime="$(mtime .ai/.feature-index.json)"
  after_hash="$(jq -S 'del(.generated_at)' .ai/.feature-index.json)"
  [[ "$before_mtime" == "$after_mtime" ]] || fail "--write a réécrit un cache contractuellement identique"
  [[ "$before_hash" == "$after_hash" ]] || fail "--write a modifié le contrat sans changement source"

  sleep 1
  perl -0pi -e 's/updated: "2026-05-14"/updated: "2026-05-15"/' .docs/features/core/a-first.md
  bash .ai/scripts/build-feature-index.sh --write >/dev/null
  changed_mtime="$(mtime .ai/.feature-index.json)"
  [[ "$changed_mtime" -gt "$after_mtime" ]] || fail "--write n'a pas réécrit après changement contractuel"
  jq -e '.features[] | select(.id == "a-first" and .progress.updated == "2026-05-15")' .ai/.feature-index.json >/dev/null \
    || fail "changement contractuel absent de l'index"
)

echo "✅ test-build-feature-index-contract PASS"
