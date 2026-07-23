#!/bin/bash
# test-migration-orchestrator.sh — cockpit post-Copier core/migration-orchestrator.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/aic-migration-orchestrator-test.XXXXXX")"
trap 'rm -rf "$tmp_root"' EXIT

fail() {
  echo "❌ $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  printf '%s\n' "$haystack" | grep -Fq -- "$needle" || fail "$message"
}

new_fixture() {
  local name="$1"
  local fixture="$tmp_root/$name"

  mkdir -p "$fixture/.ai/scripts" "$fixture/.docs/features/core"
  cp "$repo_root/.ai/scripts/_lib.sh" "$fixture/.ai/scripts/_lib.sh"
  cp "$repo_root/.ai/scripts/_vcs.sh" "$fixture/.ai/scripts/_vcs.sh"
  cp "$repo_root/.ai/scripts/aic.sh" "$fixture/.ai/scripts/aic.sh"
  cp "$repo_root/.ai/scripts/migrate-all.sh" "$fixture/.ai/scripts/migrate-all.sh"
  cp "$repo_root/.ai/scripts/migrate-features.sh" "$fixture/.ai/scripts/migrate-features.sh"
  cp "$repo_root/.ai/scripts/migrate-okf-type.sh" "$fixture/.ai/scripts/migrate-okf-type.sh"
  cp "$repo_root/.ai/scripts/migrate-okf-indexes.sh" "$fixture/.ai/scripts/migrate-okf-indexes.sh"
  cp "$repo_root/.ai/config.yml" "$fixture/.ai/config.yml"

  for check in check-shims.sh check-features.sh check-feature-indexes.sh; do
    printf '%s\n' '#!/bin/bash' 'echo "stub validation PASS"' > "$fixture/.ai/scripts/$check"
    chmod +x "$fixture/.ai/scripts/$check"
  done

  chmod +x "$fixture/.ai/scripts/"*.sh
  printf '%s\n' '_src_path: gh:example/ai_context' '_commit: v0.0.0' > "$fixture/.copier-answers.yml"
  cat > "$fixture/.docs/features/core/example.md" <<'FEATURE'
---
id: example
scope: core
title: Example
status: active
depends_on: []
touches: []
---

# Example
FEATURE

  printf '%s\n' "$fixture"
}

docs_snapshot() {
  local fixture="$1"
  (
    cd "$fixture"
    find .docs -type f -exec cksum {} \; | LC_ALL=C sort
  )
}

echo "═══ test-migration-orchestrator ═══"

bash -n "$repo_root/.ai/scripts/migrate-all.sh"
bash -n "$repo_root/template/.ai/scripts/migrate-all.sh.jinja"
cmp -s "$repo_root/.ai/scripts/migrate-all.sh" "$repo_root/template/.ai/scripts/migrate-all.sh.jinja" \
  || fail "le runtime migrate-all et son miroir Jinja divergent"
echo "  ✓ syntaxe Bash et parité runtime/template"

preview_fixture="$(new_fixture preview)"
before_preview="$(docs_snapshot "$preview_fixture")"
plan_out="$(cd "$preview_fixture" && bash .ai/scripts/aic.sh migrate plan)"
after_plan="$(docs_snapshot "$preview_fixture")"
[[ "$before_preview" == "$after_plan" ]] || fail "migrate plan a modifié les fiches"
assert_contains "$plan_out" "Profil OKF — champ type — à appliquer" "le plan ne détecte pas le type OKF manquant"
assert_contains "$plan_out" "Index Markdown progressifs — à appliquer" "le plan ne détecte pas les index manquants"
assert_contains "$plan_out" "2 migration(s) à appliquer" "le résumé du plan est incorrect"
assert_contains "$plan_out" "migration historique n'est jamais incluse" "la séparation de la migration legacy n'est pas expliquée"

all_preview_out="$(cd "$preview_fixture" && bash .ai/scripts/aic.sh migrate all)"
after_all_preview="$(docs_snapshot "$preview_fixture")"
[[ "$before_preview" == "$after_all_preview" ]] || fail "migrate all sans --apply a modifié les fiches"
assert_contains "$all_preview_out" "mode: preview" "migrate all n'est pas read-only par défaut"
echo "  ✓ plan/all preview détectent sans écrire"

apply_out="$(cd "$preview_fixture" && bash .ai/scripts/aic.sh migrate all --apply)"
if grep -q '^schema_version:' "$preview_fixture/.docs/features/core/example.md"; then
  fail "migrate all a appliqué implicitement la migration legacy"
fi
grep -q '^type: feature$' "$preview_fixture/.docs/features/core/example.md" \
  || fail "la migration OKF n'a pas ajouté type"
[[ -f "$preview_fixture/.docs/features/index.md" ]] || fail "l'index racine n'a pas été généré"
[[ -f "$preview_fixture/.docs/features/core/index.md" ]] || fail "l'index de scope n'a pas été généré"
assert_contains "$apply_out" "Migrations automatisables appliquées et validées" "le succès apply n'est pas explicite"

second_apply_out="$(cd "$preview_fixture" && bash .ai/scripts/aic.sh migrate all --apply)"
assert_contains "$second_apply_out" "Profil OKF — champ type — à jour" "le second passage voit encore le type en attente"
assert_contains "$second_apply_out" "Index Markdown progressifs — à jour" "le second passage voit encore les index en attente"
echo "  ✓ apply ordonné et second passage idempotent"

rej_fixture="$(new_fixture rej)"
printf '%s\n' 'conflit Copier' > "$rej_fixture/copier.yml.rej"
rej_before="$(docs_snapshot "$rej_fixture")"
if (cd "$rej_fixture" && bash .ai/scripts/aic.sh migrate all --apply > "$tmp_root/rej.out" 2>&1); then
  fail "un fichier .rej n'a pas bloqué migrate all --apply"
fi
rej_after="$(docs_snapshot "$rej_fixture")"
[[ "$rej_before" == "$rej_after" ]] || fail "le blocage .rej intervient après une écriture"
grep -Fq 'copier.yml.rej' "$tmp_root/rej.out" || fail "le fichier .rej bloquant n'est pas nommé"
echo "  ✓ .rej bloque avant écriture"

collision_fixture="$(new_fixture collision)"
printf '%s\n' '# Index manuel' > "$collision_fixture/.docs/features/index.md"
collision_before="$(docs_snapshot "$collision_fixture")"
if (cd "$collision_fixture" && bash .ai/scripts/aic.sh migrate all --apply > "$tmp_root/collision.out" 2>&1); then
  fail "un index manuel incompatible n'a pas bloqué le préflight"
fi
collision_after="$(docs_snapshot "$collision_fixture")"
[[ "$collision_before" == "$collision_after" ]] || fail "le conflit d'index a été détecté après une écriture"
grep -Fq 'Index Markdown progressifs — bloqué' "$tmp_root/collision.out" \
  || fail "le plan ne classe pas la collision d'index comme bloquée"
echo "  ✓ collision index bloque toutes les migrations"

overlay_fixture="$(new_fixture overlay)"
overlay_init_out="$(cd "$overlay_fixture" && bash .ai/scripts/aic.sh migrate plan)"
assert_contains "$overlay_init_out" "mode init" "un overlay absent ne propose pas init"

mkdir -p "$overlay_fixture/.ai/project"
printf '%s\n' 'project: example' > "$overlay_fixture/.ai/project/config.yml"
overlay_config_out="$(cd "$overlay_fixture" && bash .ai/scripts/aic.sh migrate plan)"
assert_contains "$overlay_config_out" "config-only compatible" "un overlay config-only est présenté comme une migration"
assert_contains "$overlay_config_out" "aucune migration requise" "le quasi no-op config-only n'est pas expliqué"

printf '%s\n' '# Règles legacy' > "$overlay_fixture/.ai/project/legacy.md"
overlay_migrate_out="$(cd "$overlay_fixture" && bash .ai/scripts/aic.sh migrate plan)"
assert_contains "$overlay_migrate_out" "mode migrate" "un overlay legacy ne propose pas migrate"

cat > "$overlay_fixture/.ai/project/index.md" <<'OVERLAY'
---
overlay_contract_version: 1
---
OVERLAY
overlay_sync_out="$(cd "$overlay_fixture" && bash .ai/scripts/aic.sh migrate plan)"
assert_contains "$overlay_sync_out" "mode sync" "un overlay stampé ne propose pas sync"
echo "  ✓ routage aic-onboard init/config-only/migrate/sync sans écriture"

metadata_fixture="$(new_fixture metadata)"
rm -f "$metadata_fixture/.copier-answers.yml"
metadata_out="$(cd "$metadata_fixture" && bash .ai/scripts/aic.sh migrate plan)"
assert_contains "$metadata_out" ".copier-answers.yml absent" "les métadonnées Copier absentes ne sont pas signalées"
assert_contains "$metadata_out" "repair-copier-metadata --apply" "la remédiation Copier n'est pas proposée"

if (cd "$metadata_fixture" && bash .ai/scripts/aic.sh migrate plan --apply > "$tmp_root/plan-apply.out" 2>&1); then
  fail "migrate plan --apply devrait être refusé"
fi
grep -Fq 'strictement read-only' "$tmp_root/plan-apply.out" || fail "le refus plan --apply n'est pas actionnable"

if (cd "$metadata_fixture" && bash .ai/scripts/aic.sh migrate all --inconnu > "$tmp_root/unknown.out" 2>&1); then
  fail "un argument inconnu devrait être refusé"
fi
grep -Fq 'argument inconnu' "$tmp_root/unknown.out" || fail "l'argument inconnu n'est pas expliqué"
echo "  ✓ métadonnées manquantes et arguments invalides"

echo "✅ test-migration-orchestrator PASS"
