#!/bin/bash
# test-surface-manifest.sh — core/aic-surface-canonical (gouvernance v1.0).
#
# MANIFESTE DE SURFACE : snapshot du contrat public gelé en v1.0. Tout écart fait
# échouer ce test, ce qui transforme une modification du contrat en DÉCISION
# CONSCIENTE au lieu d'un effet de bord.
#
# Politique quand ce test échoue — l'issue dépend de la nature du changement :
#   - AJOUT rétro-compatible à défaut sûr  -> MAJ du snapshot ici, bump MINOR ;
#   - RETRAIT, renommage, resserrement     -> MAJ du snapshot ici, bump MAJOR
#                                             + section MIGRATION.md.
# Le test ne présume pas laquelle : il empêche seulement le changement silencieux.
#
# Dimensions couvertes (les 8 éléments du contrat v1.0) :
#   1. routes CLI par niveau (stable / stable-maintenance / deprecated / interne)
#   2. questions Copier : noms, ordre, type, multiselect, when, validateur, choix
#   3. cycle d'update : _answers_file, _skip_if_exists, _migrations read-only
#   4. schéma fiche : champs requis, enums, patterns
#   5. enveloppe + clés typées de l'index JSON
#   6. clés .ai/config.yml réellement lues
#   7. modèle de shims (agent -> shim attendu, agents dépréciés)
#   8. matrice de capacités : prédicats de rendu conditionnel
#
# Le parsing passe par yq/jq (aucune logique de parsing ajoutée au moteur bash :
# ce fichier vit dans tests/, hors moratoire).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

for bin in yq jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "⏭️  test-surface-manifest SKIP ($bin absent)"; exit 0; }
done

failures=0
fail() { echo "  ✗ $1" >&2; failures=$((failures + 1)); }
ok() { echo "  ✓ $1"; }

# Compare une valeur observée à la valeur gelée, avec un message actionnable.
expect() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    ok "$label"
  else
    fail "$label
      gelé   : $expected
      observé: $actual
      -> MAJ le manifeste ET décider le bump (ajout compatible = MINOR ; retrait/renommage = MAJOR + MIGRATION.md)"
  fi
}

echo "═══ manifeste de surface (contrat public v1.0) ═══"

# ─── 1. Routes CLI par niveau ───
help_out="$(bash .ai/scripts/aic.sh --help)"

routes_in_level() {
  # $1 = en-tête de début, $2 = en-tête de fin (ou vide pour aller jusqu'à "Help :")
  local from="$1" to="${2:-Help :}"
  printf '%s\n' "$help_out" \
    | sed -n "/$from/,/$to/p" \
    | sed -n 's/^  \([a-z][a-z0-9-]*\).*/\1/p' \
    | sort -u | tr '\n' ','
}

expect "routes stable" \
  "dev-plan,diagnose,document-feature,frame,init,onboard,pilot,review,ship,status," \
  "$(routes_in_level '── stable ──' '── stable-maintenance ──')"

expect "routes deprecated" \
  "frame-bootstrap,frame-context,knowledge," \
  "$(routes_in_level '── deprecated ──' '── interne ──')"

expect "routes interne" \
  "reminder,search," \
  "$(routes_in_level '── interne ──')"

# Toute route du dispatch doit être listée dans l'aide (aucune route fantôme).
dispatch_routes="$(
  awk '/^case "\$cmd" in$/{n++} n==2' .ai/scripts/aic.sh \
    | sed -n 's/^  \([a-z][a-z0-9|-]*\)).*/\1/p' \
    | tr '|' '\n' | sort -u | grep -v '^help$' | tr '\n' ','
)"
missing_from_help=""
for r in $(printf '%s' "$dispatch_routes" | tr ',' ' '); do
  printf '%s\n' "$help_out" | grep -qE "^  $r( |\$)" || missing_from_help="$missing_from_help $r"
done
if [[ -z "$missing_from_help" ]]; then
  ok "aucune route du dispatch absente de l'aide"
else
  fail "routes du dispatch non listées dans l'aide :$missing_from_help"
fi

# ─── 2. Questions Copier ───
expect "questions Copier (noms + ordre)" \
  "project_name project_description scope_profile adoption_mode vcs_provider tech_profile commit_language docs_root agents enable_codex_hooks enable_copilot_shim enable_ci_guard scopes" \
  "$(yq -r 'keys | .[] | select(test("^_") | not)' copier.yml | tr '\n' ' ' | sed 's/ $//')"

expect "signature agents (multiselect + choix)" \
  '{"type":"str","multi":true,"choices":["claude","codex","cursor","copilot","gemini"],"default":["claude","codex"]}' \
  "$(yq -o=json -I=0 '{"type": .agents.type, "multi": .agents.multiselect, "choices": .agents.choices, "default": .agents.default}' copier.yml)"

expect "choix vcs_provider" \
  '["git","tfvc","auto","none"]' \
  "$(yq -o=json -I=0 '[.vcs_provider.choices | .[]]' copier.yml)"

expect "choix adoption_mode" \
  '["lite","standard","strict"]' \
  "$(yq -o=json -I=0 '[.adoption_mode.choices | .[]]' copier.yml)"

expect "questions conditionnelles (when)" \
  "enable_codex_hooks enable_copilot_shim scopes" \
  "$(yq -r 'to_entries | .[] | select(.key | test("^_") | not) | select(.value | has("when")) | .key' copier.yml | tr '\n' ' ' | sed 's/ $//')"

expect "questions validées (validator)" \
  "project_name" \
  "$(yq -r 'to_entries | .[] | select(.key | test("^_") | not) | select(.value | has("validator")) | .key' copier.yml | tr '\n' ' ' | sed 's/ $//')"

# codex_hooks=true depuis le 2026-08-07 (chantier restitution, bump MINOR) :
# hooks Codex générés par défaut, opt-out conservé — cf. workflow/codex-hooks-parity.
expect "défauts booléens" \
  "codex_hooks=true copilot_shim=false ci_guard=true" \
  "codex_hooks=$(yq -r '.enable_codex_hooks.default' copier.yml) copilot_shim=$(yq -r '.enable_copilot_shim.default' copier.yml) ci_guard=$(yq -r '.enable_ci_guard.default' copier.yml)"

# ─── 3. Cycle d'update Copier ───
expect "_answers_file" ".copier-answers.yml" "$(yq -r '._answers_file' copier.yml)"
expect "_skip_if_exists (overlay projet protégé)" \
  '[".ai/project",".ai/project/**"]' \
  "$(yq -o=json -I=0 '._skip_if_exists' copier.yml)"
expect "_migrations (read-only, non bloquante)" \
  '[{"version":"v0.14.0","command":"bash .ai/scripts/aic.sh migrate plan || true"}]' \
  "$(yq -o=json -I=0 '._migrations' copier.yml)"

# Invariant fort : aucune migration native ne doit écrire.
if yq -r '._migrations[].command' copier.yml | grep -q -- "--apply"; then
  fail "une migration native contient --apply : Copier ne doit jamais écrire dans le mesh"
else
  ok "aucune migration native n'écrit (pas de --apply)"
fi

# ─── 4. Schéma fiche ───
schema=".ai/schema/feature.schema.json"
expect "champs requis du schéma" \
  '["id","scope","title","status","type","depends_on","touches"]' \
  "$(jq -c '.required' "$schema")"
expect "nombre de sites d'enum" "11" \
  "$(jq '[paths(objects | has("enum"))] | length' "$schema")"
expect "nombre de patterns" "5" \
  "$(jq '[paths(objects | has("pattern"))] | length' "$schema")"
expect "enum status" '["draft","active","done","deprecated","archived"]' \
  "$(jq -c '.properties.status.enum' "$schema")"
expect "enum type" '["feature","contract","workflow","reference"]' \
  "$(jq -c '.properties.type.enum' "$schema")"
expect "politique d'extension (additionalProperties)" "true" \
  "$(jq -c '.additionalProperties' "$schema")"

# ─── 5. Index JSON : enveloppe et clés typées ───
idx_tmp="$(mktemp "${TMPDIR:-/tmp}/aic-manifest-idx.XXXXXX")"
trap 'rm -f "$idx_tmp"' EXIT
bash .ai/scripts/build-feature-index.sh > "$idx_tmp" 2>/dev/null

expect "enveloppe de l'index" "features,generated_at,project_id,schema_version" \
  "$(jq -rS 'keys | join(",")' "$idx_tmp")"
expect "schema_version de l'index" "1" "$(jq -r '.schema_version' "$idx_tmp")"
expect "clés d'une feature" \
  "depends_on,external_refs,id,keywords,path,product,progress,scope,status,title,touches,touches_shared,type" \
  "$(jq -rS '.features[0] | keys | join(",")' "$idx_tmp")"
expect "types des clés de feature" \
  "depends_on=array,external_refs=object,id=string,keywords=array,path=string,product=object,progress=object,scope=string,status=string,title=string,touches=array,touches_shared=array,type=string" \
  "$(jq -r '.features[0] | to_entries | sort_by(.key) | map("\(.key)=\(.value|type)") | join(",")' "$idx_tmp")"
expect "clés de progress" "blockers,phase,resume_hint,step,updated" \
  "$(jq -rS '.features[0].progress | keys | join(",")' "$idx_tmp")"

# Nullabilité : aucune clé émise à null (valeur vide typée à la place).
null_keys="$(jq -r '[.features[] | to_entries[] | select(.value == null) | .key] | unique | join(",")' "$idx_tmp")"
expect "aucune clé de feature émise à null" "" "$null_keys"

# ─── 6. Clés .ai/config.yml réellement lues ───
# Extraites du code : read_config + le lecteur dédié de show_statuses.
config_keys_read="$(
  { grep -rho "read_config '[^']*'" .ai/scripts/*.sh | sed "s/read_config '\([^']*\)'/\1/"
    grep -rho "yq -o=json -I=0 '\.context\.[a-z_]*'" .ai/scripts/*.sh | sed "s/.*'\.\(context\.[a-z_]*\)'/\1/"
  } | sort -u | tr '\n' ','
)"
expect "clés config lues par read_config/yq" \
  "context.default_focus,context.max_tokens_warn,context.show_statuses,progress.auto_transitions.spec_to_implement,progress.history_max_entries,project_id," \
  "$config_keys_read"

# ─── 7. Modèle de shims ───
expect "agents avec shim dédié" "claude,copilot,gemini" \
  "$(sed -n '/^shim_for_agent()/,/^}/p' .ai/scripts/check-shims.sh | sed -n 's/^    \([a-z]*\)) printf.*/\1/p' | sort | tr '\n' ',' | sed 's/,$//')"
expect "agents dépréciés (aucun shim exigé)" "gemini" \
  "$(sed -n '/^agent_deprecated()/,/^}/p' .ai/scripts/check-shims.sh | sed -n 's/^    \([a-z]*\)) return 0 ;;/\1/p' | tr '\n' ',' | sed 's/,$//')"
if grep -q 'add_shim "AGENTS.md"' .ai/scripts/check-shims.sh; then
  ok "AGENTS.md toujours exigé (entrée canonique)"
else
  fail "AGENTS.md n'est plus l'entrée de shim canonique inconditionnelle"
fi

# ─── 8. Matrice de capacités : prédicats de rendu ───
expect "nombre de règles _exclude" "29" "$(yq -r '._exclude | length' copier.yml)"
expect "prédicat CI (lite n'a jamais de CI)" \
  "{% if adoption_mode == 'lite' or (not enable_ci_guard and adoption_mode != 'strict') %}.github/workflows{% endif %}" \
  "$(yq -r '._exclude[] | select(test("github/workflows"))' copier.yml)"
expect "prédicat git hooks (ni lite, ni hors git)" \
  "{% if adoption_mode == 'lite' or vcs_provider != 'git' %}.githooks{% endif %}" \
  "$(yq -r '._exclude[] | select(test("githooks"))' copier.yml)"
# GEMINI.md ne doit plus être un artefact conditionnel : il n'existe plus du tout.
if [[ -e template/GEMINI.md.jinja ]]; then
  fail "template/GEMINI.md.jinja existe encore (gemini déprécié = aucun artefact)"
else
  ok "aucun artefact rendu pour l'agent déprécié"
fi

echo
if [[ "$failures" -gt 0 ]]; then
  echo "❌ manifeste de surface : $failures écart(s) — le contrat public v1.0 a changé." >&2
  echo "   Mets à jour ce manifeste ET tranche le bump SemVer (cf. en-tête du fichier)." >&2
  exit 1
fi
echo "✅ test-surface-manifest PASS"
