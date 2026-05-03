#!/bin/bash
# smoke-test.sh — Génère un projet de test et vérifie qu'il est cohérent.
#
# Usage : bash tests/smoke-test.sh
# Requiert : copier installé dans le PATH.

set -euo pipefail

cd "$(dirname "$0")/.."
REPO="$PWD"
OUT="/tmp/ai-context-smoke-$$"

trap 'rm -rf "$OUT"' EXIT

echo "═══ smoke-test ═══"
echo "repo  = $REPO"
echo "out   = $OUT"

if ! command -v copier >/dev/null 2>&1; then
  echo "❌ copier introuvable. Installer : pip install --user copier" >&2
  exit 1
fi

echo
echo "[0a/28] tests unitaires (path_matches_touch)"
bash tests/unit/test-path-matches-touch.sh
echo

echo "[0b/28] tests unitaires (is_path_within_repo)"
bash tests/unit/test-is-path-within-repo.sh
echo

echo "[0c/28] tests unitaires (freshness multi-feature)"
bash tests/unit/test-check-feature-freshness.sh
echo

echo "[0d/28] tests unitaires (dogfood drift destination-only)"
bash tests/unit/test-dogfood-drift-extra.sh
echo

echo "[0e/28] tests unitaires (review delta + touches_shared)"
bash tests/unit/test-review-delta-shared.sh
echo

echo "[1/28] copier copy (profil par défaut)"
copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-project \
  "$REPO" "$OUT"

echo
echo "[2/28] check-shims"
bash "$OUT/.ai/scripts/check-shims.sh"
if [[ ! -f "$OUT/.ai/schema/feature.schema.json" ]]; then
  echo "  ✗ .ai/schema/feature.schema.json absent"
  exit 1
fi
echo "  ✓ schema feature présent"
if ! ( cd "$OUT" && bash .ai/scripts/doctor.sh ) >/dev/null 2>&1; then
  echo "  ✗ doctor.sh échoue sur un scaffold sain"
  exit 1
fi
echo "  ✓ doctor.sh OK"
if ! ( cd "$OUT" && bash .ai/scripts/pr-report.sh --help ) | grep -q "Usage:"; then
  echo "  ✗ pr-report.sh --help invalide"
  exit 1
fi
echo "  ✓ pr-report.sh --help OK"
if grep -q "mapfile" "$OUT/.ai/scripts/pr-report.sh"; then
  echo "  ✗ pr-report.sh utilise mapfile (incompatible Bash 3.2)"
  exit 1
fi
echo "  ✓ pr-report.sh compatible Bash 3.2 (sans mapfile)"
if ! ( cd "$OUT" && bash .ai/scripts/review-delta.sh --help ) | grep -q "Review Delta"; then
  echo "  ✗ review-delta.sh --help invalide"
  exit 1
fi
echo "  ✓ review-delta.sh --help OK"
# pr-report.sh : format JSON valide + exclusions par défaut + --include-docs
(
  cd "$OUT"
  git init -q 2>/dev/null || true
  git config user.email "smoke@test"
  git config user.name "smoke"
  mkdir -p src
  echo "// initial" > src/sample.ts
  git add -A >/dev/null 2>&1
  git -c core.hooksPath=/dev/null commit -q -m "chore: init"  >/dev/null 2>&1 || true
  # Modifie un README (doc) + un fichier code
  echo "// changed" > src/sample.ts
  echo "doc change" >> README.md 2>/dev/null || echo "doc change" > README.md
  git add -A >/dev/null 2>&1
  git -c core.hooksPath=/dev/null commit -q -m "chore: changes" >/dev/null 2>&1 || true
)
report_json=$( cd "$OUT" && bash .ai/scripts/pr-report.sh --format=json --base=HEAD~1 --head=HEAD 2>&1 ) || true
if ! echo "$report_json" | jq -e '.base' >/dev/null 2>&1; then
  echo "  ✗ pr-report.sh --format=json ne produit pas de JSON valide"
  echo "$report_json"
  exit 1
fi
# README.md doit être exclu par défaut (docs_excluded > 0)
docs_count=$(echo "$report_json" | jq '.docs_excluded')
if [[ "$docs_count" -lt 1 ]]; then
  echo "  ✗ pr-report.sh n'exclut pas README.md par défaut"
  echo "$report_json"
  exit 1
fi
# --include-docs doit lever l'exclusion
report_inc=$( cd "$OUT" && bash .ai/scripts/pr-report.sh --format=json --include-docs --base=HEAD~1 --head=HEAD 2>&1 ) || true
inc_count=$(echo "$report_inc" | jq '.docs_excluded')
if [[ "$inc_count" -ne 0 ]]; then
  echo "  ✗ --include-docs n'inclut pas les docs (docs_excluded=$inc_count)"
  exit 1
fi
echo "  ✓ pr-report.sh format=json + exclusions par défaut + --include-docs OK"
rm -rf "$OUT/.git" "$OUT/README.md" "$OUT/src/sample.ts"
# Wrapper ai-context.sh : --help liste les sous-commandes ; routage vers shims.
if ! ( cd "$OUT" && bash .ai/scripts/ai-context.sh --help ) | grep -q "Commandes :"; then
  echo "  ✗ ai-context.sh --help ne liste pas les commandes"
  exit 1
fi
if ! ( cd "$OUT" && bash .ai/scripts/ai-context.sh --help ) | grep -q "brief <path>"; then
  echo "  ✗ ai-context.sh --help ne présente pas brief <path>"
  exit 1
fi
if ! ( cd "$OUT" && bash .ai/scripts/ai-context.sh --help ) | grep -q 'mission "<objectif>"'; then
  echo "  ✗ ai-context.sh --help ne présente pas mission"
  exit 1
fi
if ! ( cd "$OUT" && bash .ai/scripts/ai-context.sh --help ) | grep -q "ship-report"; then
  echo "  ✗ ai-context.sh --help ne présente pas ship-report"
  exit 1
fi
if ! ( cd "$OUT" && bash .ai/scripts/ai-context.sh status ) | grep -q "Prochaine action minimale"; then
  echo "  ✗ ai-context.sh status ne produit pas un état actionnable"
  exit 1
fi
mission_out=$( cd "$OUT" && bash .ai/scripts/ai-context.sh mission "préparer une feature back" )
if ! printf '%s' "$mission_out" | grep -q "## Mission Brief"; then
  echo "  ✗ ai-context.sh mission ne produit pas de brief"
  exit 1
fi
repair_out=$( cd "$OUT" && bash .ai/scripts/ai-context.sh repair )
if ! printf '%s' "$repair_out" | grep -q "## Repair Plan"; then
  echo "  ✗ ai-context.sh repair ne produit pas de plan"
  exit 1
fi
document_delta_out=$( cd "$OUT" && bash .ai/scripts/ai-context.sh document-delta )
if ! printf '%s' "$document_delta_out" | grep -q "## Document Delta"; then
  echo "  ✗ ai-context.sh document-delta ne produit pas de rapport"
  exit 1
fi
ship_report_out=$( cd "$OUT" && bash .ai/scripts/ai-context.sh ship-report )
if ! printf '%s' "$ship_report_out" | grep -q "## AI Context Ship Report"; then
  echo "  ✗ ai-context.sh ship-report ne produit pas de rapport"
  exit 1
fi
if ! ( cd "$OUT" && bash .ai/scripts/ai-context.sh shims ) >/dev/null 2>&1; then
  echo "  ✗ ai-context.sh shims (alias check-shims) échoue"
  exit 1
fi
if ! ( cd "$OUT" && bash .ai/scripts/ai-context.sh review --help ) | grep -q "Review Delta"; then
  echo "  ✗ ai-context.sh review ne route pas vers review-delta"
  exit 1
fi
if ( cd "$OUT" && bash .ai/scripts/ai-context.sh inexistant ) >/dev/null 2>&1; then
  echo "  ✗ ai-context.sh accepte une commande inconnue"
  exit 1
fi
echo "  ✓ ai-context.sh wrapper OK"

echo
echo "[3/28] pre-turn-reminder (text + json)"
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=text | head -3
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=json | jq -e '.hookSpecificOutput.additionalContext' > /dev/null \
  && echo "  ✓ json valide"

echo
echo "[4/28] check-features (attendu : aucune feature → warn mais PASS)"
bash "$OUT/.ai/scripts/check-features.sh"

echo
echo "[5/28] check-commit-features : Conventional Commits refusent un message invalide"
if CLAUDE_COMMIT_MSG="message invalide sans type" bash "$OUT/.ai/scripts/check-commit-features.sh" 2>/dev/null; then
  echo "  ✗ un message invalide a été accepté"
  exit 1
fi
echo "  ✓ message invalide rejeté"

echo
echo "[6/28] check-commit-features : 'fix: ...' passe sans toucher features/"
if ! CLAUDE_COMMIT_MSG="fix: bug quelconque" bash "$OUT/.ai/scripts/check-commit-features.sh"; then
  echo "  ✗ 'fix:' sans features/ a été rejeté"
  exit 1
fi
echo "  ✓ fix: accepté"

echo
echo "[7/28] features-for-path : silent si aucune feature, matche via touches:"
if ! bash "$OUT/.ai/scripts/features-for-path.sh" src/foo.ts >/dev/null 2>&1; then
  echo "  ✓ aucune feature → exit 1 (attendu)"
fi
mkdir -p "$OUT/.docs/features/back" "$OUT/.docs/features/core"
cat > "$OUT/.docs/features/core/base.md" <<'FEAT'
---
id: base
scope: core
title: Base
status: active
depends_on: []
touches: []
---

# Base

Contexte partagé attendu dans l'injection juste-à-temps.
FEAT
cat > "$OUT/.docs/features/back/sample.md" <<'FEAT'
---
id: sample
scope: back
title: Sample
status: active
depends_on:
  - core/base
touches:
  - src/foo.ts
---

# Sample

Contexte direct attendu dans l'injection juste-à-temps.
FEAT
mkdir -p "$OUT/src" && echo "// stub" > "$OUT/src/foo.ts"
( cd "$OUT" && bash .ai/scripts/features-for-path.sh src/foo.ts | grep -q 'back/sample' ) \
  && echo "  ✓ path→feature résolu"
hook_ctx=$(
  cd "$OUT"
  printf '%s' '{"tool_name":"Edit","tool_input":{"file_path":"src/foo.ts"}}' \
    | bash .ai/scripts/features-for-path.sh \
    | jq -r '.hookSpecificOutput.additionalContext'
)
if ! printf '%s' "$hook_ctx" | grep -q 'Contexte feature injecté juste-à-temps'; then
  echo "  ✗ hook features-for-path n'injecte pas les fiches"
  exit 1
fi
if ! printf '%s' "$hook_ctx" | grep -q 'Contexte direct attendu'; then
  echo "  ✗ hook features-for-path n'injecte pas la fiche directe"
  exit 1
fi
if ! printf '%s' "$hook_ctx" | grep -q 'Contexte partagé attendu'; then
  echo "  ✗ hook features-for-path n'injecte pas depends_on"
  exit 1
fi
echo "  ✓ hook injecte fiche directe + depends_on"
brief_ctx=$( cd "$OUT" && bash .ai/scripts/ai-context.sh brief src/foo.ts )
if ! printf '%s' "$brief_ctx" | grep -q 'Contexte direct attendu'; then
  echo "  ✗ ai-context.sh brief n'expose pas le contexte feature"
  exit 1
fi
echo "  ✓ ai-context.sh brief expose le contexte feature"

echo
echo "[8/28] build-feature-index : index JSON créé par features-for-path"
idx="$OUT/.ai/.feature-index.json"
if [[ ! -f "$idx" ]]; then
  echo "  ✗ $idx absent après features-for-path.sh"
  exit 1
fi
if ! jq -e '.features[] | select(.id == "sample" and .scope == "back")' "$idx" >/dev/null; then
  echo "  ✗ index ne contient pas sample/back"
  exit 1
fi
echo "  ✓ index contient sample/back"
if ! jq -e '.schema_version == "1"' "$idx" >/dev/null; then
  echo "  ✗ index manque schema_version: \"1\""
  exit 1
fi
echo "  ✓ index expose schema_version"
if ! jq -e '.project_id == "smoke-project"' "$idx" >/dev/null; then
  echo "  ✗ index manque project_id (attendu: smoke-project)"
  exit 1
fi
echo "  ✓ index expose project_id"

echo
echo "[9/28] build-feature-index : rebuild sur mtime (frontmatter modifié)"
before_marker=$(mktemp)
touch -r "$idx" "$before_marker"
sleep 1
touch "$OUT/.docs/features/back/sample.md"
( cd "$OUT" && bash .ai/scripts/features-for-path.sh src/foo.ts >/dev/null ) || true
if [[ ! "$idx" -nt "$before_marker" ]]; then
  echo "  ✗ index pas rebuilt (pas plus récent que marker)"
  rm -f "$before_marker"
  exit 1
fi
rm -f "$before_marker"
echo "  ✓ index rebuilt après touch"

echo
echo "[9b/28] build-feature-index : concurrence (lock atomique)"
(
  cd "$OUT"
  for _ in 1 2 3 4 5; do
    bash .ai/scripts/build-feature-index.sh --write >/dev/null 2>&1 &
  done
  wait
)
if ! jq -e . "$idx" >/dev/null 2>&1; then
  echo "  ✗ index corrompu après 5 builds parallèles"
  head -5 "$idx"
  exit 1
fi
# mktemp utilise ${index_file}.XXXXXX — un orphelin = mv non joué = lock cassé
orphans=$(find "$OUT/.ai" -maxdepth 1 -name '.feature-index.json.*' 2>/dev/null | head -1)
if [[ -n "$orphans" ]]; then
  echo "  ✗ fichier tmp .feature-index.json.* orphelin : $orphans"
  exit 1
fi
echo "  ✓ 5 builds parallèles : JSON valide, pas de tmp orphelin"

echo
echo "[10/28] pre-turn-reminder : dépendances inverses exposées"
cat > "$OUT/.docs/features/back/base.md" <<'FEAT'
---
id: base
scope: back
title: Base feature
status: active
depends_on: []
touches:
  - src/foo.ts
---
FEAT
cat > "$OUT/.docs/features/back/child.md" <<'FEAT'
---
id: child
scope: back
title: Child feature
status: active
depends_on:
  - back/base
touches:
  - src/foo.ts
---
FEAT
( cd "$OUT" && bash .ai/scripts/build-feature-index.sh --write )
if ! ( cd "$OUT" && bash .ai/scripts/pre-turn-reminder.sh ) | grep -q "back/base ← back/child"; then
  echo "  ✗ reverse deps absent du reminder"
  exit 1
fi
echo "  ✓ reverse deps présentes"

echo
echo "[11/28] build-feature-index : status hors enum → warn (stderr, pas fail)"
cat > "$OUT/.docs/features/back/bogus.md" <<'FEAT'
---
id: bogus
scope: back
title: Bogus status
status: typo
depends_on: []
touches:
  - src/foo.ts
---
FEAT
warn_out=$( cd "$OUT" && bash .ai/scripts/build-feature-index.sh 2>&1 >/dev/null )
if ! echo "$warn_out" | grep -q "status='typo'"; then
  echo "  ✗ warn enum absent"
  exit 1
fi
echo "  ✓ warn enum présent"
rm "$OUT/.docs/features/back/bogus.md"

cat > "$OUT/.docs/features/back/phase-typo.md" <<'FEAT'
---
id: phase-typo
scope: back
title: Bogus phase
status: active
depends_on: []
touches:
  - src/foo.ts
progress:
  phase: typo
---
FEAT
phase_warn_out=$( cd "$OUT" && bash .ai/scripts/check-features.sh 2>&1 >/dev/null || true )
if ! echo "$phase_warn_out" | grep -q "progress.phase='typo'"; then
  echo "  ✗ warn progress.phase absent"
  exit 1
fi
echo "  ✓ warn progress.phase présent"
rm "$OUT/.docs/features/back/phase-typo.md"

# depends_on / touches sont obligatoires (peuvent valoir [] mais doivent être déclarées)
cat > "$OUT/.docs/features/back/missing-deps.md" <<'FEAT'
---
id: missing-deps
scope: back
title: Missing depends_on / touches
status: active
---
FEAT
miss_out=$( cd "$OUT" && bash .ai/scripts/check-features.sh 2>&1 || true )
if ! echo "$miss_out" | grep -q "clé frontmatter 'depends_on' manquante"; then
  echo "  ✗ check-features n'exige pas depends_on"
  echo "$miss_out"
  exit 1
fi
if ! echo "$miss_out" | grep -q "clé frontmatter 'touches' manquante"; then
  echo "  ✗ check-features n'exige pas touches"
  echo "$miss_out"
  exit 1
fi
if ( cd "$OUT" && bash .ai/scripts/check-features.sh ) >/dev/null 2>&1; then
  echo "  ✗ check-features passe alors que depends_on/touches sont manquants"
  exit 1
fi
echo "  ✓ check-features exige depends_on et touches"
rm "$OUT/.docs/features/back/missing-deps.md"

# Mais [] doit rester accepté
cat > "$OUT/.docs/features/back/empty-arrays.md" <<'FEAT'
---
id: empty-arrays
scope: back
title: Empty depends_on/touches arrays
status: draft
depends_on: []
touches: []
---
FEAT
if ! ( cd "$OUT" && bash .ai/scripts/check-features.sh ) >/dev/null 2>&1; then
  echo "  ✗ check-features refuse depends_on: [] / touches: []"
  exit 1
fi
echo "  ✓ depends_on: [] et touches: [] acceptés"
rm "$OUT/.docs/features/back/empty-arrays.md"

# Validation touches: rejette les chemins hors repo (absolu, .., ~)
for bad_touch in "/etc/passwd" "../../escape.ts" "~/secret.ts" "src/../../boom.ts"; do
  cat > "$OUT/.docs/features/back/bad-touch.md" <<FEAT
---
id: bad-touch
scope: back
title: Bad touch
status: draft
depends_on: []
touches:
  - $bad_touch
---
FEAT
  bad_out=$( cd "$OUT" && bash .ai/scripts/check-features.sh 2>&1 || true )
  if ! echo "$bad_out" | grep -q "hors repo"; then
    echo "  ✗ check-features accepte un touches hors repo : '$bad_touch'"
    echo "$bad_out"
    exit 1
  fi
done
rm "$OUT/.docs/features/back/bad-touch.md"
echo "  ✓ check-features rejette touches hors repo (absolu, .., ~)"

cat > "$OUT/.docs/features/back/legacy-migrate.md" <<'FEAT'
---
id: legacy-migrate
scope: back
title: Legacy migration target
status: in_progress
---
FEAT
mig_out=$( cd "$OUT" && bash .ai/scripts/migrate-features.sh 2>&1 )
if ! echo "$mig_out" | grep -q "legacy-migrate.md"; then
  echo "  ✗ migrate-features dry-run ne détecte pas le fichier legacy"
  exit 1
fi
if ! echo "$mig_out" | grep -q "normalize status: in_progress -> active"; then
  echo "  ✗ migrate-features dry-run ne propose pas la normalisation attendue"
  exit 1
fi
( cd "$OUT" && bash .ai/scripts/migrate-features.sh --apply >/dev/null )
if ! grep -q "^schema_version: 1$" "$OUT/.docs/features/back/legacy-migrate.md"; then
  echo "  ✗ migrate-features --apply n'ajoute pas schema_version"
  exit 1
fi
if ! grep -q "^status: active$" "$OUT/.docs/features/back/legacy-migrate.md"; then
  echo "  ✗ migrate-features --apply n'applique pas status normalisé"
  exit 1
fi
echo "  ✓ migrate-features dry-run/apply OK"
rm "$OUT/.docs/features/back/legacy-migrate.md"

# enum source-of-truth : ajouter un status au schema → check-features ne warn plus
schema_bak="$OUT/.ai/schema/feature.schema.json.bak"
cp "$OUT/.ai/schema/feature.schema.json" "$schema_bak"
jq '.properties.status.enum += ["paused"]' "$schema_bak" > "$OUT/.ai/schema/feature.schema.json"
cat > "$OUT/.docs/features/back/paused-feat.md" <<'FEAT'
---
id: paused-feat
scope: back
title: Feature paused via schema-derived enum
status: paused
depends_on: []
touches:
  - src/foo.ts
---
FEAT
schema_warn_out=$( cd "$OUT" && bash .ai/scripts/build-feature-index.sh 2>&1 >/dev/null )
if echo "$schema_warn_out" | grep -q "status='paused'"; then
  echo "  ✗ status 'paused' ajouté au schema mais toujours considéré hors enum"
  exit 1
fi
echo "  ✓ enum dérivé du schema (status 'paused' reconnu)"
mv "$schema_bak" "$OUT/.ai/schema/feature.schema.json"
rm "$OUT/.docs/features/back/paused-feat.md"

echo
echo "[12/28] check-feature-coverage : script exécute et liste orphelins"
mkdir -p "$OUT/src"
echo "// orphan" > "$OUT/src/orphan.ts"
cov_out=$( cd "$OUT" && bash .ai/scripts/check-feature-coverage.sh 2>&1 ) || true
if ! echo "$cov_out" | grep -q "orphelins"; then
  echo "  ✗ sortie coverage inattendue"
  echo "$cov_out"
  exit 1
fi
echo "  ✓ coverage script OK"
audit_out=$( cd "$OUT" && bash .ai/scripts/audit-features.sh discover back 2>&1 ) || true
if ! echo "$audit_out" | grep -q "audit-features discover <back>"; then
  echo "  ✗ audit-features discover ne produit pas d'en-tête attendu"
  exit 1
fi
if ! echo "$audit_out" | grep -q "dry-run: yes"; then
  echo "  ✗ audit-features devrait être en dry-run par défaut"
  exit 1
fi
if ! echo "$audit_out" | grep -q "src/orphan.ts"; then
  echo "  ✗ audit-features discover n'identifie pas orphan.ts"
  exit 1
fi
# --help doit lister 'MVP discover only'
help_out=$( cd "$OUT" && bash .ai/scripts/audit-features.sh --help 2>&1 ) || true
if ! echo "$help_out" | grep -q "MVP discover only"; then
  echo "  ✗ audit-features --help n'annonce pas son périmètre MVP"
  exit 1
fi
# Robustesse aux chemins avec espaces : un fichier dans un dossier 'src/with space/'
# doit être listé (le script groupe par dossier ; on utilise un dossier unique
# pour qu'il devienne visible dans la sortie).
mkdir -p "$OUT/src/with space"
echo "// space orphan" > "$OUT/src/with space/file.ts"
audit_space_out=$( cd "$OUT" && bash .ai/scripts/audit-features.sh discover back 2>&1 ) || true
if ! echo "$audit_space_out" | grep -q "src/with space/file.ts"; then
  echo "  ✗ audit-features ne gère pas les chemins avec espaces"
  echo "$audit_space_out"
  exit 1
fi
rm -rf "$OUT/src/with space"
echo "  ✓ audit-features discover (dry-run + --help + paths-with-spaces) OK"

echo
echo "[13/28] pre-turn-reminder : status 'done' filtré par défaut + visible via override"
cat > "$OUT/.docs/features/back/legacy.md" <<'FEAT'
---
id: legacy
scope: back
title: Legacy closed feature
status: done
depends_on: []
touches:
  - src/foo.ts
---
FEAT
( cd "$OUT" && bash .ai/scripts/build-feature-index.sh --write )
default_out=$( cd "$OUT" && bash .ai/scripts/pre-turn-reminder.sh )
if echo "$default_out" | grep -q "legacy(done)"; then
  echo "  ✗ feature done visible par défaut"
  exit 1
fi
if ! echo "$default_out" | grep -q "masquée"; then
  echo "  ✗ hint 'masquée' absent"
  exit 1
fi
override_out=$( cd "$OUT" && AI_CONTEXT_SHOW_ALL_STATUS=1 bash .ai/scripts/pre-turn-reminder.sh )
if ! echo "$override_out" | grep -q "legacy(done)"; then
  echo "  ✗ feature done absente avec override"
  exit 1
fi
echo "  ✓ filtre par status OK + override OK"
rm "$OUT/.docs/features/back/legacy.md"

echo
echo "[14/28] measure-context-size : produit une sortie parseable"
meas_out=$( cd "$OUT" && bash .ai/scripts/measure-context-size.sh 2>&1 )
if ! echo "$meas_out" | grep -q "tokens~="; then
  echo "  ✗ pas de tokens~= dans la sortie"
  echo "$meas_out"
  exit 1
fi
if ! echo "$meas_out" | grep -q "static"; then
  echo "  ✗ breakdown static absent"
  exit 1
fi
echo "  ✓ measure-context-size OK"

echo
echo "[15/28] progress: build-feature-index extrait progress.phase/step/blockers"
cat > "$OUT/.docs/features/back/inprog.md" <<'FEAT'
---
id: inprog
scope: back
title: In progress feature
status: active
depends_on: []
touches:
  - src/foo.ts
progress:
  phase: implement
  step: "3/5 service layer"
  blockers: []
  resume_hint: "reprendre sur service/foo.ts tests unitaires"
  updated: 2026-04-23
---
FEAT
( cd "$OUT" && bash .ai/scripts/build-feature-index.sh --write )
if ! jq -e '.features[] | select(.id == "inprog") | .progress.phase == "implement"' "$idx" >/dev/null; then
  echo "  ✗ progress.phase pas extrait"
  exit 1
fi
if ! jq -e '.features[] | select(.id == "inprog") | .progress.step | contains("service layer")' "$idx" >/dev/null; then
  echo "  ✗ progress.step pas extrait"
  exit 1
fi
echo "  ✓ progress.* extrait dans l'index"

echo
echo "[16/28] resume-features : feature EN COURS listée, feature BLOQUÉE séparée"
cat > "$OUT/.docs/features/back/blocked.md" <<'FEAT'
---
id: blocked
scope: back
title: Blocked feature
status: active
depends_on: []
touches:
  - src/foo.ts
progress:
  phase: spec
  step: "en attente spec API"
  blockers:
    - "API spec TBD côté partenaire"
  resume_hint: ""
  updated: 2026-04-23
---
FEAT
( cd "$OUT" && bash .ai/scripts/build-feature-index.sh --write )
resume_out=$( cd "$OUT" && bash .ai/scripts/resume-features.sh )
if ! echo "$resume_out" | grep -q "EN COURS"; then
  echo "  ✗ bucket EN COURS absent"
  echo "$resume_out"
  exit 1
fi
if ! echo "$resume_out" | grep -q "back/inprog"; then
  echo "  ✗ inprog absent d'EN COURS"
  exit 1
fi
if ! echo "$resume_out" | grep -q "BLOQUÉES"; then
  echo "  ✗ bucket BLOQUÉES absent"
  exit 1
fi
if ! echo "$resume_out" | grep -q "back/blocked"; then
  echo "  ✗ blocked absent de BLOQUÉES"
  exit 1
fi
json_out=$( cd "$OUT" && bash .ai/scripts/resume-features.sh --format=json )
if ! echo "$json_out" | jq -e '.en_cours | length >= 1' >/dev/null; then
  echo "  ✗ json en_cours vide"
  exit 1
fi
# Override config : forcer stale_after_days=0, inprog doit apparaître en STALE
cat > "$OUT/.ai/config.yml" <<'YAML'
progress:
  stale_after_days: 0
YAML
resume_cfg_out=$( cd "$OUT" && bash .ai/scripts/resume-features.sh )
if ! echo "$resume_cfg_out" | grep -q "STALE (>0j sans update)"; then
  echo "  ✗ libellé STALE n'utilise pas stale_after_days depuis .ai/config.yml"
  exit 1
fi
if ! echo "$resume_cfg_out" | grep -q "back/inprog"; then
  echo "  ✗ inprog absent du bucket STALE avec stale_after_days=0"
  exit 1
fi
git -C "$OUT" checkout -- .ai/config.yml >/dev/null 2>&1 || true
echo "  ✓ resume-features buckets corrects (text + json)"
rm "$OUT/.docs/features/back/inprog.md" "$OUT/.docs/features/back/blocked.md"

echo
echo "[17/28] auto-worklog : log + flush appendent au worklog et bumpent updated"
mkdir -p "$OUT/.docs/features/back" "$OUT/src"
echo "// foo" > "$OUT/src/foo.ts"
cat > "$OUT/.docs/features/back/autofeat.md" <<'FEAT'
---
id: autofeat
scope: back
title: Auto worklog test
status: active
depends_on: []
touches:
  - src/foo.ts
progress:
  phase: implement
  step: "pre-auto"
  blockers: []
  resume_hint: ""
  updated: 2020-01-01
---
FEAT
( cd "$OUT" && bash .ai/scripts/build-feature-index.sh --write )
# Simule un PostToolUse Write
echo '{"tool_input":{"file_path":"src/foo.ts"}}' | ( cd "$OUT" && bash .ai/scripts/auto-worklog-log.sh )
if [[ ! -s "$OUT/.ai/.session-edits.log" ]]; then
  echo "  ✗ session-edits.log vide après PostToolUse"
  exit 1
fi
if ! grep -q '"feature":"back/autofeat"' "$OUT/.ai/.session-edits.log"; then
  echo "  ✗ feature autofeat pas loggée"
  exit 1
fi
# Flush via Stop
( cd "$OUT" && bash .ai/scripts/auto-worklog-flush.sh )
if [[ -s "$OUT/.ai/.session-edits.log" ]]; then
  echo "  ✗ log pas clearé après flush"
  exit 1
fi
if [[ ! -f "$OUT/.docs/features/back/autofeat.worklog.md" ]]; then
  echo "  ✗ worklog pas créé"
  exit 1
fi
if ! grep -q "Fichiers modifiés" "$OUT/.docs/features/back/autofeat.worklog.md"; then
  echo "  ✗ worklog sans entrée 'Fichiers modifiés'"
  cat "$OUT/.docs/features/back/autofeat.worklog.md"
  exit 1
fi
today=$(date +%Y-%m-%d)
if ! grep -qE "^  updated: $today" "$OUT/.docs/features/back/autofeat.md"; then
  echo "  ✗ progress.updated pas bumpé à $today"
  grep -E "^  updated:" "$OUT/.docs/features/back/autofeat.md"
  exit 1
fi
echo "  ✓ auto-worklog log+flush OK"
rm "$OUT/.docs/features/back/autofeat.md" "$OUT/.docs/features/back/autofeat.worklog.md"

echo
echo "[18/28] auto-progress : pre-commit bascule spec → implement + snapshot history"
# Crée une feature en phase=spec avec un fichier couvert par touches:
mkdir -p "$OUT/.docs/features/back" "$OUT/src"
echo "// bar" > "$OUT/src/bar.ts"
cat > "$OUT/.docs/features/back/specfeat.md" <<'FEAT'
---
id: specfeat
scope: back
title: Spec feature test
status: draft
depends_on: []
touches:
  - src/bar.ts
progress:
  phase: spec
  step: "pre-progress"
  blockers: []
  resume_hint: ""
  updated: 2020-01-01
---
FEAT
(
  cd "$OUT"
  bash .ai/scripts/build-feature-index.sh --write >/dev/null
  git init -q >/dev/null 2>&1 || true
  git config user.email "smoke@test" >/dev/null
  git config user.name "smoke" >/dev/null
  git config core.hooksPath .githooks >/dev/null
  chmod +x .githooks/* 2>/dev/null || true
  git add -A >/dev/null
  # Le pre-commit doit détecter src/bar.ts couvert par specfeat (phase=spec)
  # et basculer en phase=implement. Non-bloquant même si commit-msg passe.
  git commit -q -m "feat(back): add bar.ts

Touche specfeat pour déclencher la bascule." >/dev/null 2>&1 || true
)
# Vérifier la bascule
if ! grep -qE "^  phase: implement[[:space:]]*$" "$OUT/.docs/features/back/specfeat.md"; then
  echo "  ✗ phase pas bumpée à implement"
  grep -E "^  phase:" "$OUT/.docs/features/back/specfeat.md"
  exit 1
fi
# Vérifier le snapshot
if [[ ! -s "$OUT/.ai/.progress-history.jsonl" ]]; then
  echo "  ✗ snapshot pas créé dans .progress-history.jsonl"
  exit 1
fi
if ! grep -q '"feature":"back/specfeat"' "$OUT/.ai/.progress-history.jsonl"; then
  echo "  ✗ snapshot ne référence pas back/specfeat"
  cat "$OUT/.ai/.progress-history.jsonl"
  exit 1
fi
if ! grep -q '"to":{"phase":"implement"' "$OUT/.ai/.progress-history.jsonl"; then
  echo "  ✗ snapshot ne transitionne pas vers implement"
  cat "$OUT/.ai/.progress-history.jsonl"
  exit 1
fi
# Snapshot doit aussi capturer l'état AVANT (sinon /aic undo ne peut pas restaurer)
if ! grep -q '"from":{"phase":"spec"' "$OUT/.ai/.progress-history.jsonl"; then
  echo "  ✗ snapshot n'enregistre pas le from.phase (undo cassé)"
  cat "$OUT/.ai/.progress-history.jsonl"
  exit 1
fi
echo "  ✓ snapshot complet (from + to) — /aic undo plumbing OK"
# Vérifier entrée worklog auto-progress
if [[ ! -f "$OUT/.docs/features/back/specfeat.worklog.md" ]] || \
   ! grep -q "auto-progress" "$OUT/.docs/features/back/specfeat.worklog.md"; then
  echo "  ✗ worklog sans ligne auto-progress"
  exit 1
fi
# Vérifier idempotence : second commit sans edit de spec → pas de nouveau snapshot
snap_count_before=$(wc -l < "$OUT/.ai/.progress-history.jsonl")
(
  cd "$OUT"
  echo "// bar 2" >> "$OUT/src/bar.ts"
  git add -A >/dev/null
  git commit -q -m "chore(back): tweak bar" >/dev/null 2>&1 || true
)
snap_count_after=$(wc -l < "$OUT/.ai/.progress-history.jsonl")
if [[ "$snap_count_before" != "$snap_count_after" ]]; then
  echo "  ✗ snapshot rejoué sur phase déjà en implement (non idempotent)"
  exit 1
fi
echo "  ✓ auto-progress spec→implement + snapshot + idempotence OK"

# Test E2E /aic undo via aic-undo.sh (réutilise l'état post-bascule ci-dessus)
(
  cd "$OUT"
  bash .ai/scripts/aic-undo.sh --apply >/dev/null
)
if ! grep -qE "^  phase: spec[[:space:]]*$" "$OUT/.docs/features/back/specfeat.md"; then
  echo "  ✗ aic-undo n'a pas restauré phase=spec"
  grep -E "^  phase:" "$OUT/.docs/features/back/specfeat.md"
  exit 1
fi
if ! grep -q "/aic undo" "$OUT/.docs/features/back/specfeat.worklog.md"; then
  echo "  ✗ worklog sans ligne '/aic undo' après undo"
  exit 1
fi
if [[ -s "$OUT/.ai/.progress-history.jsonl" ]]; then
  echo "  ✗ history pas vidé après undo de l'unique snapshot"
  cat "$OUT/.ai/.progress-history.jsonl"
  exit 1
fi
# Idempotence : second --apply sur history vide doit être no-op
if ! ( cd "$OUT" && bash .ai/scripts/aic-undo.sh --apply 2>&1 ) | grep -q "Rien à annuler"; then
  echo "  ✗ aic-undo --apply sur history vide ne dit pas 'Rien à annuler'"
  exit 1
fi
echo "  ✓ aic-undo : restaure spec + append worklog + vide history + idempotent"

rm -rf "$OUT/.git" "$OUT/.docs/features/back/specfeat.md" "$OUT/.docs/features/back/specfeat.worklog.md" "$OUT/.ai/.progress-history.jsonl" "$OUT/.ai/.session-edits.flushed" 2>/dev/null || true

echo
echo "[19/28] skills publics + workflows internes présents"
for s in aic aic-frame aic-status aic-diagnose aic-review aic-ship; do
  if [[ ! -f "$OUT/.claude/skills/$s/SKILL.md" ]]; then
    echo "  ✗ $s/SKILL.md absent"
    exit 1
  fi
  if [[ ! -f "$OUT/.claude/skills/$s/workflow.md" ]]; then
    echo "  ✗ $s/workflow.md absent"
    exit 1
  fi
  if ! grep -q "^name: $s$" "$OUT/.claude/skills/$s/SKILL.md"; then
    echo "  ✗ $s frontmatter 'name' incorrect"
    exit 1
  fi
done
for s in feature-new feature-resume feature-update feature-handoff feature-audit quality-gate feature-done project-guardrails; do
  if [[ ! -f "$OUT/.ai/workflows/$s.md" ]]; then
    echo "  ✗ .ai/workflows/$s.md absent"
    exit 1
  fi
done
if find "$OUT/.claude/skills" -maxdepth 1 -type d -name 'aic-feature-*' | grep -q .; then
  echo "  ✗ skills procéduraux aic-feature-* encore exposés"
  find "$OUT/.claude/skills" -maxdepth 1 -type d -name 'aic-feature-*'
  exit 1
fi
for s in aic-quality-gate aic-project-guardrails; do
  if [[ -d "$OUT/.claude/skills/$s" ]]; then
    echo "  ✗ $s encore exposé comme skill Claude"
    exit 1
  fi
done
echo "  ✓ 6 skills publics + 8 workflows internes présents"
# .ai/index.md référence .ai/guardrails.md dans Pack A
if ! grep -q "guardrails.md" "$OUT/.ai/index.md"; then
  echo "  ✗ .ai/index.md ne référence pas .ai/guardrails.md (Pack A)"
  exit 1
fi
echo "  ✓ .ai/index.md référence guardrails.md (Pack A)"

echo
echo "[20/28] check-feature-coverage --strict : exit 1 si orphelins"
# /src/orphan.ts (créé étape 12) est toujours orphelin
if ( cd "$OUT" && bash .ai/scripts/check-feature-coverage.sh --strict ) >/dev/null 2>&1; then
  echo "  ✗ --strict a passé malgré des orphelins"
  exit 1
fi
echo "  ✓ --strict échoue avec orphelins"
rm -f "$OUT/src/orphan.ts"

# Override simple via .ai/config.yml : ne scanner que app/**/*.ts
cat > "$OUT/.ai/config.yml" <<'YAML'
coverage:
  roots:
    - app
  extensions:
    - ts
  exclude_dirs:
    - node_modules
YAML
if ! ( cd "$OUT" && bash .ai/scripts/check-feature-coverage.sh --strict ) >/dev/null 2>&1; then
  echo "  ✗ override .ai/config.yml non pris en charge par check-feature-coverage"
  exit 1
fi
echo "  ✓ override .ai/config.yml pris en charge"
git -C "$OUT" checkout -- .ai/config.yml >/dev/null 2>&1 || true

echo
echo "[21/28] check-features : cycle dans depends_on rejeté"
cat > "$OUT/.docs/features/back/cycle_a.md" <<'FEAT'
---
id: cycle_a
scope: back
title: Cycle A
status: active
depends_on:
  - back/cycle_b
touches:
  - src/foo.ts
---
FEAT
cat > "$OUT/.docs/features/back/cycle_b.md" <<'FEAT'
---
id: cycle_b
scope: back
title: Cycle B
status: active
depends_on:
  - back/cycle_a
touches:
  - src/foo.ts
---
FEAT
if ( cd "$OUT" && bash .ai/scripts/check-features.sh ) >/dev/null 2>&1; then
  echo "  ✗ cycle depends_on accepté"
  exit 1
fi
echo "  ✓ cycle rejeté"
rm "$OUT/.docs/features/back/cycle_a.md" "$OUT/.docs/features/back/cycle_b.md"

echo
echo "[22/28] check-features : warn si active dépend d'une feature deprecated"
cat > "$OUT/.docs/features/back/old_api.md" <<'FEAT'
---
id: old_api
scope: back
title: Old API
status: deprecated
depends_on: []
touches:
  - src/foo.ts
---
FEAT
cat > "$OUT/.docs/features/back/new_api.md" <<'FEAT'
---
id: new_api
scope: back
title: New API
status: active
depends_on:
  - back/old_api
touches:
  - src/foo.ts
---
FEAT
dep_out=$( cd "$OUT" && bash .ai/scripts/check-features.sh 2>&1 ) || true
if ! echo "$dep_out" | grep -q "depends_on 'back/old_api' est 'deprecated'"; then
  echo "  ✗ warn deprecated absent"
  echo "$dep_out"
  exit 1
fi
echo "  ✓ deprecated warn OK"
rm "$OUT/.docs/features/back/old_api.md" "$OUT/.docs/features/back/new_api.md"

echo
echo "[23/28] reminder i18n : commit_language=en génère un reminder EN"
OUT_EN="/tmp/ai-context-smoke-en-$$"
copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-en \
  --data commit_language=en \
  "$REPO" "$OUT_EN" >/dev/null
if ! grep -q "Read \`.ai/index.md\` BEFORE" "$OUT_EN/.ai/reminder.md"; then
  echo "  ✗ reminder pas en anglais"
  cat "$OUT_EN/.ai/reminder.md"
  rm -rf "$OUT_EN"
  exit 1
fi
if grep -q "Lire \`.ai/index.md\`" "$OUT_EN/.ai/reminder.md"; then
  echo "  ✗ reminder contient encore du français"
  rm -rf "$OUT_EN"
  exit 1
fi
rm -rf "$OUT_EN"
echo "  ✓ reminder EN OK"

echo
echo "[24/28] pre-turn-reminder --focus : scope + 1-hop, exclut le reste"
mkdir -p "$OUT/.docs/features/back" "$OUT/.docs/features/front" "$OUT/.docs/features/architecture"
cat > "$OUT/.docs/features/back/api.md" <<'FEAT'
---
id: api
scope: back
title: API layer
status: active
depends_on: []
touches:
  - src/foo.ts
---
FEAT
cat > "$OUT/.docs/features/front/ui.md" <<'FEAT'
---
id: ui
scope: front
title: UI consuming API
status: active
depends_on:
  - back/api
touches:
  - src/foo.ts
---
FEAT
cat > "$OUT/.docs/features/architecture/unrelated.md" <<'FEAT'
---
id: unrelated
scope: architecture
title: Unrelated concern
status: active
depends_on: []
touches:
  - src/foo.ts
---
FEAT
( cd "$OUT" && bash .ai/scripts/build-feature-index.sh --write )
focus_out=$( cd "$OUT" && bash .ai/scripts/pre-turn-reminder.sh --focus=back )
if ! echo "$focus_out" | grep -q "focus=back"; then
  echo "  ✗ header focus absent"
  echo "$focus_out"
  exit 1
fi
if ! echo "$focus_out" | grep -q "api(active)"; then
  echo "  ✗ feature focus absente"
  exit 1
fi
if ! echo "$focus_out" | grep -q "ui(active)"; then
  echo "  ✗ voisin 1-hop front/ui absent"
  exit 1
fi
if echo "$focus_out" | grep -q "unrelated(active)"; then
  echo "  ✗ architecture/unrelated présent malgré focus=back"
  exit 1
fi
# Env var équivalente
env_out=$( cd "$OUT" && AI_CONTEXT_FOCUS=back bash .ai/scripts/pre-turn-reminder.sh )
if ! echo "$env_out" | grep -q "focus=back"; then
  echo "  ✗ AI_CONTEXT_FOCUS ignoré"
  exit 1
fi
# Focus invalide → warn + fallback
bad_out=$( cd "$OUT" && bash .ai/scripts/pre-turn-reminder.sh --focus=nonexistent 2>&1 >/dev/null )
if ! echo "$bad_out" | grep -q "focus ignoré"; then
  echo "  ✗ warn sur focus invalide absent"
  exit 1
fi
echo "  ✓ focus filter OK (scope + 1-hop + env + fallback)"
rm "$OUT/.docs/features/back/api.md" "$OUT/.docs/features/front/ui.md" "$OUT/.docs/features/architecture/unrelated.md"

echo
echo "[25/28] check-features : 'touches:' morte fait échouer"
cat > "$OUT/.docs/features/back/dead.md" <<'FEAT'
---
id: dead
scope: back
title: Dead touches
status: active
depends_on: []
touches:
  - this/path/does/not/exist
---
FEAT
if ( cd "$OUT" && bash .ai/scripts/check-features.sh ) >/dev/null 2>&1; then
  echo "  ✗ touches morte acceptée"
  exit 1
fi
echo "  ✓ touches morte rejetée"
rm "$OUT/.docs/features/back/dead.md"

echo
echo "[26/28] _lib.sh : matching touches centralisé"
if ! (
  cd "$OUT"
  . .ai/scripts/_lib.sh
  path_matches_touch "src/foo.ts" "src/foo.ts"
  path_matches_touch "src/auth/service.ts" "src/auth"
  path_matches_touch "src/auth/service.ts" "src/auth/**"
  path_matches_touch "src/auth/service.ts" "src/**/*.ts"
  ! path_matches_touch "src/auth/service.ts" "src/other"
  ! path_matches_touch "src/auth/service.ts" "src/auth-other"
); then
  echo "  ✗ matching touches incohérent"
  exit 1
fi
echo "  ✓ matching exact/dossier/glob/** OK"

echo
echo "[27/28] docs_root=docs : scripts runtime suivent le dossier configuré"
OUT_DOCS="/tmp/ai-context-smoke-docs-root-$$"
copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-docs-root \
  --data docs_root=docs \
  "$REPO" "$OUT_DOCS" >/dev/null
mkdir -p "$OUT_DOCS/docs/features/back" "$OUT_DOCS/src"
cat > "$OUT_DOCS/docs/features/back/sample.md" <<'FEAT'
---
id: sample
scope: back
title: Docs root sample
status: active
depends_on: []
touches:
  - src/foo.ts
---
FEAT
echo "// docs-root" > "$OUT_DOCS/src/foo.ts"
( cd "$OUT_DOCS" && bash .ai/scripts/check-features.sh >/dev/null )
if ! ( cd "$OUT_DOCS" && bash .ai/scripts/features-for-path.sh src/foo.ts ) | grep -q "back/sample"; then
  echo "  ✗ features-for-path ne lit pas docs/features"
  rm -rf "$OUT_DOCS"
  exit 1
fi
if ! grep -q "docs/features/back/sample.md" "$OUT_DOCS/.ai/.feature-index.json"; then
  echo "  ✗ index ne référence pas docs/features"
  rm -rf "$OUT_DOCS"
  exit 1
fi
rm -rf "$OUT_DOCS"
echo "  ✓ docs_root=docs OK"

echo
echo "[28/28] tech_profile + adoption_mode : rendus conditionnels"
OUT_DOTNET="/tmp/ai-context-smoke-dotnet-$$"
OUT_REACT="/tmp/ai-context-smoke-react-$$"
OUT_FULLSTACK="/tmp/ai-context-smoke-fullstack-$$"
OUT_LITE="/tmp/ai-context-smoke-lite-$$"
OUT_STRICT="/tmp/ai-context-smoke-strict-$$"

copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-dotnet \
  --data tech_profile=dotnet-clean-cqrs \
  "$REPO" "$OUT_DOTNET" >/dev/null
if [[ ! -f "$OUT_DOTNET/.ai/rules/tech-dotnet.md" ]]; then
  echo "  ✗ tech-dotnet.md absent pour dotnet-clean-cqrs"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
  exit 1
fi
if [[ -f "$OUT_DOTNET/.ai/rules/tech-react.md" ]] || [[ -f "$OUT_DOTNET/.ai/rules/stack-fullstack-dotnet-react.md" ]]; then
  echo "  ✗ règles React/fullstack générées pour dotnet-clean-cqrs"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
  exit 1
fi
if [[ -f "$OUT_DOTNET/docs/design-system-registry.md" ]] || [[ -f "$OUT_DOTNET/docs/atomic-design-map.md" ]]; then
  echo "  ✗ squelettes DS générés pour dotnet-clean-cqrs (front uniquement)"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
  exit 1
fi
if ! grep -q "tech-dotnet.md" "$OUT_DOTNET/.ai/index.md"; then
  echo "  ✗ index ne référence pas tech-dotnet.md"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
  exit 1
fi

copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-react \
  --data tech_profile=react-next \
  "$REPO" "$OUT_REACT" >/dev/null
if [[ ! -f "$OUT_REACT/.ai/rules/tech-react.md" ]]; then
  echo "  ✗ tech-react.md absent pour react-next"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
  exit 1
fi
if [[ -f "$OUT_REACT/.ai/rules/tech-dotnet.md" ]] || [[ -f "$OUT_REACT/.ai/rules/stack-fullstack-dotnet-react.md" ]]; then
  echo "  ✗ règles .NET/fullstack générées pour react-next"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
  exit 1
fi
for f in design-system-registry.md atomic-design-map.md; do
  if [[ ! -f "$OUT_REACT/docs/$f" ]]; then
    echo "  ✗ squelette docs/$f absent pour react-next"
    rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
    exit 1
  fi
done
if ! grep -q "tech-react.md" "$OUT_REACT/.ai/index.md"; then
  echo "  ✗ index ne référence pas tech-react.md"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
  exit 1
fi

copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-fullstack \
  --data scope_profile=fullstack \
  --data tech_profile=fullstack-dotnet-react \
  "$REPO" "$OUT_FULLSTACK" >/dev/null
for f in design-system-registry.md atomic-design-map.md; do
  if [[ ! -f "$OUT_FULLSTACK/docs/$f" ]]; then
    echo "  ✗ squelette docs/$f absent pour fullstack-dotnet-react"
    rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
    exit 1
  fi
done
for f in tech-dotnet.md tech-react.md stack-fullstack-dotnet-react.md; do
  if [[ ! -f "$OUT_FULLSTACK/.ai/rules/$f" ]]; then
    echo "  ✗ $f absent pour fullstack-dotnet-react"
    rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
    exit 1
  fi
  if ! grep -q "$f" "$OUT_FULLSTACK/.ai/index.md"; then
    echo "  ✗ index ne référence pas $f"
    rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK"
    exit 1
  fi
done

copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-lite \
  --data adoption_mode=lite \
  "$REPO" "$OUT_LITE" >/dev/null
if [[ -d "$OUT_LITE/.githooks" ]]; then
  echo "  ✗ mode lite ne doit pas générer .githooks"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK" "$OUT_LITE" "$OUT_STRICT"
  exit 1
fi
if [[ -d "$OUT_LITE/.github/workflows" ]]; then
  echo "  ✗ mode lite ne doit pas générer les workflows CI"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK" "$OUT_LITE" "$OUT_STRICT"
  exit 1
fi

copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-strict \
  --data adoption_mode=strict \
  --data enable_ci_guard=false \
  "$REPO" "$OUT_STRICT" >/dev/null
if [[ ! -d "$OUT_STRICT/.github/workflows" ]]; then
  echo "  ✗ mode strict doit conserver les workflows CI même avec enable_ci_guard=false"
  rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK" "$OUT_LITE" "$OUT_STRICT"
  exit 1
fi

rm -rf "$OUT_DOTNET" "$OUT_REACT" "$OUT_FULLSTACK" "$OUT_LITE" "$OUT_STRICT"
echo "  ✓ profils dotnet/react/fullstack + modes adoption lite/strict OK"

echo
echo "[28b/28] combinaisons scope_profile × tech_profile (couverture matrice)"
# Couvre 4 combinaisons additionnelles (au-delà des 4 déjà couvertes via fullstack×*) :
#   minimal × generic        : aucun back/front/architecture/security
#   backend × dotnet         : back+architecture+security (pas front), tech-dotnet
#   minimal × react-next     : pas de scope métier, tech-react présent
#   custom × generic         : minimal scopes, pas de tech profile
combos=(
  "minimal:generic"
  "backend:dotnet-clean-cqrs"
  "minimal:react-next"
  "custom:generic"
)
for combo in "${combos[@]}"; do
  scope="${combo%%:*}"
  tech="${combo##*:}"
  combo_out="/tmp/ai-context-smoke-${scope}-${tech}-$$"
  copier copy --defaults --trust --vcs-ref=HEAD \
    --data project_name="smoke-${scope}-${tech}" \
    --data scope_profile="$scope" \
    --data tech_profile="$tech" \
    "$REPO" "$combo_out" >/dev/null

  # Tous les profils ont core+quality+workflow
  for required in core.md quality.md workflow.md; do
    if [[ ! -f "$combo_out/.ai/rules/$required" ]]; then
      echo "  ✗ $combo : $required absent (toujours requis)"
      rm -rf "$combo_out"
      exit 1
    fi
  done

  # check-shims doit passer sur chaque combo (sanity)
  if ! ( cd "$combo_out" && bash .ai/scripts/check-shims.sh >/dev/null 2>&1 ); then
    echo "  ✗ $combo : check-shims fail"
    ( cd "$combo_out" && bash .ai/scripts/check-shims.sh )
    rm -rf "$combo_out"
    exit 1
  fi

  # minimal et custom : pas de scopes métier (back/front/architecture/security/handoff)
  if [[ "$scope" == "minimal" || "$scope" == "custom" ]]; then
    for forbidden in back.md front.md architecture.md security.md handoff.md; do
      if [[ -f "$combo_out/.ai/rules/$forbidden" ]]; then
        echo "  ✗ $combo : $forbidden ne devrait pas être généré"
        rm -rf "$combo_out"
        exit 1
      fi
    done
  fi

  # backend : back+architecture+security+handoff oui, front non
  if [[ "$scope" == "backend" ]]; then
    for required in back.md architecture.md security.md handoff.md; do
      if [[ ! -f "$combo_out/.ai/rules/$required" ]]; then
        echo "  ✗ $combo : $required absent"
        rm -rf "$combo_out"
        exit 1
      fi
    done
    if [[ -f "$combo_out/.ai/rules/front.md" ]]; then
      echo "  ✗ $combo : front.md ne devrait pas être généré (backend uniquement)"
      rm -rf "$combo_out"
      exit 1
    fi
  fi

  # tech-dotnet uniquement si tech_profile inclut dotnet
  if [[ "$tech" == "dotnet-clean-cqrs" || "$tech" == "fullstack-dotnet-react" ]]; then
    if [[ ! -f "$combo_out/.ai/rules/tech-dotnet.md" ]]; then
      echo "  ✗ $combo : tech-dotnet.md absent"
      rm -rf "$combo_out"
      exit 1
    fi
  else
    if [[ -f "$combo_out/.ai/rules/tech-dotnet.md" ]]; then
      echo "  ✗ $combo : tech-dotnet.md ne devrait pas être généré"
      rm -rf "$combo_out"
      exit 1
    fi
  fi

  # tech-react uniquement si tech_profile inclut react
  if [[ "$tech" == "react-next" || "$tech" == "fullstack-dotnet-react" ]]; then
    if [[ ! -f "$combo_out/.ai/rules/tech-react.md" ]]; then
      echo "  ✗ $combo : tech-react.md absent"
      rm -rf "$combo_out"
      exit 1
    fi
  else
    if [[ -f "$combo_out/.ai/rules/tech-react.md" ]]; then
      echo "  ✗ $combo : tech-react.md ne devrait pas être généré"
      rm -rf "$combo_out"
      exit 1
    fi
  fi

  rm -rf "$combo_out"
done
echo "  ✓ 4 combinaisons (minimal×generic, backend×dotnet, minimal×react, custom×generic) OK"
echo "  ℹ couverture matrice : 8/16 combinaisons exercées (incluant les 4 via fullstack×*)"

# Cursor MDC scopés : back.mdc et front.mdc rendus si cursor + scope présent
combo_cursor="/tmp/ai-context-smoke-cursor-$$"
copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-cursor \
  --data scope_profile=fullstack \
  --data agents='["claude","cursor"]' \
  "$REPO" "$combo_cursor" >/dev/null
for mdc in protocol-reminder.mdc back.mdc front.mdc; do
  if [[ ! -f "$combo_cursor/.cursor/rules/$mdc" ]]; then
    echo "  ✗ .cursor/rules/$mdc absent (cursor + fullstack)"
    rm -rf "$combo_cursor"
    exit 1
  fi
done
# back.mdc et front.mdc doivent avoir un frontmatter globs:
for mdc in back.mdc front.mdc; do
  if ! grep -q "^globs:" "$combo_cursor/.cursor/rules/$mdc"; then
    echo "  ✗ .cursor/rules/$mdc sans frontmatter globs:"
    rm -rf "$combo_cursor"
    exit 1
  fi
done
rm -rf "$combo_cursor"

# Sans cursor dans agents : pas de .cursor/ du tout
combo_nocursor="/tmp/ai-context-smoke-nocursor-$$"
copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-nocursor \
  --data agents='["claude"]' \
  "$REPO" "$combo_nocursor" >/dev/null
if [[ -d "$combo_nocursor/.cursor" ]]; then
  echo "  ✗ .cursor/ généré alors que cursor pas dans agents"
  rm -rf "$combo_nocursor"
  exit 1
fi
rm -rf "$combo_nocursor"

# cursor + minimal (sans back/front) : protocol-reminder oui, back/front MDC non
combo_minimal="/tmp/ai-context-smoke-cursor-minimal-$$"
copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-cursor-minimal \
  --data scope_profile=minimal \
  --data agents='["claude","cursor"]' \
  "$REPO" "$combo_minimal" >/dev/null
if [[ ! -f "$combo_minimal/.cursor/rules/protocol-reminder.mdc" ]]; then
  echo "  ✗ protocol-reminder.mdc absent (cursor + minimal)"
  rm -rf "$combo_minimal"
  exit 1
fi
for mdc in back.mdc front.mdc; do
  if [[ -f "$combo_minimal/.cursor/rules/$mdc" ]]; then
    echo "  ✗ .cursor/rules/$mdc rendu alors que scope absent (minimal)"
    rm -rf "$combo_minimal"
    exit 1
  fi
done
rm -rf "$combo_minimal"
echo "  ✓ Cursor MDC scopés : protocol-reminder + back/front conditionnels au scope"

echo
echo "[28c/28] copier update : propagation v0.11.0 → HEAD préserve fichiers custom"
UPD_OUT="/tmp/ai-context-smoke-update-$$"

# Scaffold initial sur v0.11.0 (avant les corrections P0+P1+P2 + R1)
if ! copier copy --defaults --trust --vcs-ref=v0.11.0 \
    --data project_name=smoke-update \
    "$REPO" "$UPD_OUT" >/dev/null 2>&1; then
  echo "  ⚠ copier copy v0.11.0 indisponible (tag manquant ?), étape skippée"
else
  # Sanity v0.11.0 : aic-undo.sh n'existe pas encore (introduit dans R2)
  pre_undo_exists=0
  [[ -f "$UPD_OUT/.ai/scripts/aic-undo.sh" ]] && pre_undo_exists=1

  # Fichier user hors périmètre template — doit survivre au update.
  # Il est versionné car Copier refuse d'updater un sous-projet dirty.
  echo "# Custom user file (test copier update)" > "$UPD_OUT/MY_CUSTOM.md"

  # copier update ne fonctionne que dans un sous-projet git-tracké. Certaines
  # versions de Copier ne matérialisent pas l'answers file sur ce scénario local ;
  # on le rend explicite pour tester l'upgrade, pas le mécanisme de réponses.
  if [[ ! -f "$UPD_OUT/.copier-answers.yml" ]]; then
    cat > "$UPD_OUT/.copier-answers.yml" <<EOF
# Changes here will be overwritten by Copier
_commit: v0.11.0
_src_path: $REPO
project_name: smoke-update
EOF
  fi
  if [[ ! -d "$UPD_OUT/.git" ]]; then
    git -C "$UPD_OUT" init >/dev/null
  fi
  git -C "$UPD_OUT" add . >/dev/null
  git -C "$UPD_OUT" commit -m "test: scaffold v0.11.0" >/dev/null

  # Update vers HEAD (apporte P0+P1+P2 + R1 + R2 working tree)
  update_log="/tmp/ai-context-copier-update-$$.log"
  if ! ( cd "$UPD_OUT" && copier update --defaults --trust --vcs-ref=HEAD -A >"$update_log" 2>&1 ); then
    echo "  ✗ copier update v0.11.0 → HEAD a échoué"
    sed -n '1,160p' "$update_log"
    rm -rf "$UPD_OUT"
    exit 1
  fi
  rm -f "$update_log"

  if [[ ! -f "$UPD_OUT/MY_CUSTOM.md" ]]; then
    echo "  ✗ MY_CUSTOM.md (fichier user) disparu après copier update"
    rm -rf "$UPD_OUT"
    exit 1
  fi
  if [[ "$(cat "$UPD_OUT/MY_CUSTOM.md")" != "# Custom user file (test copier update)" ]]; then
    echo "  ✗ MY_CUSTOM.md modifié alors qu'il est hors template"
    cat "$UPD_OUT/MY_CUSTOM.md"
    rm -rf "$UPD_OUT"
    exit 1
  fi

  # Sanity : check-shims passe encore après update
  if ! ( cd "$UPD_OUT" && bash .ai/scripts/check-shims.sh >/dev/null 2>&1 ); then
    echo "  ✗ check-shims fail après copier update"
    ( cd "$UPD_OUT" && bash .ai/scripts/check-shims.sh )
    rm -rf "$UPD_OUT"
    exit 1
  fi

  # Si HEAD contient aic-undo.sh, vérifier qu'il a été propagé (test conditionné
  # à la disponibilité du script dans le commit testé — utile sur HEAD post-R2)
  if [[ "$pre_undo_exists" -eq 0 ]] && [[ -f "$REPO/.ai/scripts/aic-undo.sh" ]]; then
    if [[ ! -f "$UPD_OUT/.ai/scripts/aic-undo.sh" ]]; then
      echo "  ✗ aic-undo.sh présent dans le repo mais pas propagé via copier update"
      rm -rf "$UPD_OUT"
      exit 1
    fi
  fi

  rm -rf "$UPD_OUT"
  echo "  ✓ copier update v0.11.0 → HEAD : fichier user préservé + check-shims OK"
fi

echo
echo "[bonus] big-mesh : budget tokens + focus graph-aware"
# Génère 30 features back + 30 features front + dépendances pour stresser
# l'inventaire et la section reverse_deps. Borne haute pragmatique : 30k chars
# (~7500 tokens borne basse) — au-delà, le coût par tour devient sensible.
OUT_BIG="/tmp/ai-context-smoke-big-$$"
copier copy --defaults --trust --vcs-ref=HEAD \
  --data project_name=smoke-big \
  --data scope_profile=fullstack \
  "$REPO" "$OUT_BIG" >/dev/null
mkdir -p "$OUT_BIG/.docs/features/back" "$OUT_BIG/.docs/features/front"
for i in $(seq 1 30); do
  front_depends_on=" []"
  if [[ "$i" -le 10 ]]; then
    front_depends_on="
  - back/big-back-$i"
  fi
  cat > "$OUT_BIG/.docs/features/back/big-back-$i.md" <<FEAT
---
id: big-back-$i
scope: back
title: Big back $i
status: active
depends_on: []
touches:
  - src/back-$i/**
---
FEAT
  cat > "$OUT_BIG/.docs/features/front/big-front-$i.md" <<FEAT
---
id: big-front-$i
scope: front
title: Big front $i
status: active
depends_on:$front_depends_on
touches:
  - app/front-$i/**
---
FEAT
done
( cd "$OUT_BIG" && bash .ai/scripts/build-feature-index.sh --write >/dev/null )

big_full=$( cd "$OUT_BIG" && bash .ai/scripts/pre-turn-reminder.sh 2>/dev/null | wc -c )
big_focused=$( cd "$OUT_BIG" && AI_CONTEXT_FOCUS=back bash .ai/scripts/pre-turn-reminder.sh 2>/dev/null | wc -c )

if [[ "$big_full" -gt 30000 ]]; then
  echo "  ✗ pre-turn-reminder full=$big_full chars > 30000 (budget pragmatique cassé)"
  rm -rf "$OUT_BIG"
  exit 1
fi
echo "  ✓ pre-turn-reminder full = $big_full chars (≤30000)"

if [[ "$big_focused" -ge "$big_full" ]]; then
  echo "  ✗ AI_CONTEXT_FOCUS=back ne réduit pas l'inventaire (focused=$big_focused, full=$big_full)"
  rm -rf "$OUT_BIG"
  exit 1
fi
echo "  ✓ AI_CONTEXT_FOCUS réduit la taille (full=$big_full → focus=$big_focused)"

# Vérifie que max_tokens_warn déclenche bien le warning stderr
warn_out=$( cd "$OUT_BIG" \
  && yq -i '.context.max_tokens_warn = 100' .ai/config.yml \
  && bash .ai/scripts/pre-turn-reminder.sh >/dev/null 2>&1; \
  cd "$OUT_BIG" && bash .ai/scripts/pre-turn-reminder.sh 2>&1 >/dev/null )
if ! echo "$warn_out" | grep -q "max_tokens_warn"; then
  echo "  ✗ max_tokens_warn ne déclenche pas le warning"
  echo "$warn_out"
  rm -rf "$OUT_BIG"
  exit 1
fi
echo "  ✓ context.max_tokens_warn déclenche le warning attendu"

rm -rf "$OUT_BIG"

echo
echo "✅ smoke-test PASS"
