#!/bin/bash
# test-context-config-keys.sh — workflow/pre-turn-reminder.
#
# Verrouille B9 (chantier v1.0) : `context.show_statuses` et
# `context.default_focus` de .ai/config.yml sont RÉELLEMENT lues. Avant v1.0
# elles étaient scaffoldées mais aucun script ne les consommait (roadmap
# PROJECT_STATE « 🚧 Consommer context.show_statuses / default_focus ») — le
# contrat v1.0 exigeant que les clés gelées soient lues, elles sont implémentées
# plutôt que retirées.
#
# Précédence testée : env var > config > défaut codé.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

command -v yq >/dev/null 2>&1 || { echo "⏭️  test-context-config-keys SKIP (yq absent)"; exit 0; }

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-context-keys.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $1"; exit 1; }

mkdir -p "$tmp/.ai"

run_visible() {
  # $1 = chemin config (peut ne pas exister) ; $2 = valeur AI_CONTEXT_SHOW_ALL_STATUS
  AI_CONTEXT_CONFIG_FILE="$1" AI_CONTEXT_SHOW_ALL_STATUS="${2:-0}" \
    bash -c "cd '$repo_root' && . .ai/scripts/_lib.sh && visible_statuses_jq"
}

# ─── show_statuses ───

cfg="$tmp/.ai/config.yml"

# 1. Config custom respectée
printf 'context:\n  show_statuses:\n    - done\n    - archived\n' > "$cfg"
out="$(run_visible "$cfg")"
[[ "$out" == '["done","archived"]' ]] \
  || fail "config show_statuses non respectée : $out"
echo "  ✓ show_statuses : valeur de config appliquée"

# 2. L'env var garde la priorité sur la config
out="$(run_visible "$cfg" 1)"
echo "$out" | grep -q '"deprecated"' \
  || fail "AI_CONTEXT_SHOW_ALL_STATUS=1 doit primer sur la config : $out"
echo "  ✓ show_statuses : env var prime sur la config"

# 3. Config absente -> défaut codé
out="$(run_visible "$tmp/.ai/absent.yml")"
[[ "$out" == '["active","draft","?"]' ]] \
  || fail "config absente devrait donner le défaut : $out"
echo "  ✓ show_statuses : défaut quand la config est absente"

# 4. Liste vide -> défaut (garde anti-masquage total du mesh)
printf 'context:\n  show_statuses: []\n' > "$cfg"
out="$(run_visible "$cfg")"
[[ "$out" == '["active","draft","?"]' ]] \
  || fail "liste vide devrait retomber sur le défaut, pas masquer tout : $out"
echo "  ✓ show_statuses : liste vide ne masque pas tout le mesh"

# 5. Clé absente de la section context -> défaut
printf 'context:\n  max_tokens_warn: 0\n' > "$cfg"
out="$(run_visible "$cfg")"
[[ "$out" == '["active","draft","?"]' ]] \
  || fail "clé absente devrait donner le défaut : $out"
echo "  ✓ show_statuses : clé absente -> défaut"

# ─── default_focus ───
# Preuve indirecte mais discriminante : un focus invalide déclenche un warn
# stderr explicite. S'il apparaît, la valeur a bien été lue depuis la config.

proj="$tmp/proj"
mkdir -p "$proj/.ai/scripts" "$proj/.docs/features/back"
cp -R "$repo_root/.ai/scripts/." "$proj/.ai/scripts/"
cp "$repo_root/.ai/reminder.md" "$proj/.ai/" 2>/dev/null || true
printf 'docs_root: ".docs"\nproject_id: "focus-test"\ncontext:\n  default_focus: "scope-inexistant"\n' \
  > "$proj/.ai/config.yml"
cat > "$proj/.docs/features/back/f.md" <<'FEAT'
---
id: f
scope: back
title: Feature de test
status: active
type: feature
depends_on: []
touches: []
---
# Feature de test
FEAT

err="$( cd "$proj" && bash .ai/scripts/pre-turn-reminder.sh 2>&1 >/dev/null || true )"
echo "$err" | grep -q "focus=scope-inexistant" \
  || { echo "$err"; fail "context.default_focus non lu depuis .ai/config.yml"; }
echo "  ✓ default_focus : valeur de config lue par pre-turn-reminder"

# AI_CONTEXT_FOCUS doit primer sur la config
err="$( cd "$proj" && AI_CONTEXT_FOCUS="autre-bidon" bash .ai/scripts/pre-turn-reminder.sh 2>&1 >/dev/null || true )"
echo "$err" | grep -q "focus=autre-bidon" \
  || { echo "$err"; fail "AI_CONTEXT_FOCUS doit primer sur context.default_focus"; }
echo "  ✓ default_focus : env var prime sur la config"

echo "✅ test-context-config-keys PASS"
