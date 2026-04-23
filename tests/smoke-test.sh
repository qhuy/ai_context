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
echo "[1/21] copier copy (profil par défaut)"
copier copy --defaults --trust \
  --data project_name=smoke-project \
  "$REPO" "$OUT"

echo
echo "[2/21] check-shims"
bash "$OUT/.ai/scripts/check-shims.sh"

echo
echo "[3/21] pre-turn-reminder (text + json)"
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=text | head -3
bash "$OUT/.ai/scripts/pre-turn-reminder.sh" --format=json | jq -e '.hookSpecificOutput.additionalContext' > /dev/null \
  && echo "  ✓ json valide"

echo
echo "[4/21] check-features (attendu : aucune feature → warn mais PASS)"
bash "$OUT/.ai/scripts/check-features.sh"

echo
echo "[5/21] check-commit-features : Conventional Commits refusent un message invalide"
if CLAUDE_COMMIT_MSG="message invalide sans type" bash "$OUT/.ai/scripts/check-commit-features.sh" 2>/dev/null; then
  echo "  ✗ un message invalide a été accepté"
  exit 1
fi
echo "  ✓ message invalide rejeté"

echo
echo "[6/21] check-commit-features : 'fix: ...' passe sans toucher features/"
if ! CLAUDE_COMMIT_MSG="fix: bug quelconque" bash "$OUT/.ai/scripts/check-commit-features.sh"; then
  echo "  ✗ 'fix:' sans features/ a été rejeté"
  exit 1
fi
echo "  ✓ fix: accepté"

echo
echo "[7/21] features-for-path : silent si aucune feature, matche via touches:"
if ! bash "$OUT/.ai/scripts/features-for-path.sh" src/foo.ts >/dev/null 2>&1; then
  echo "  ✓ aucune feature → exit 1 (attendu)"
fi
mkdir -p "$OUT/.docs/features/back"
cat > "$OUT/.docs/features/back/sample.md" <<'FEAT'
---
id: sample
scope: back
title: Sample
status: active
depends_on: []
touches:
  - src/foo.ts
---
FEAT
mkdir -p "$OUT/src" && echo "// stub" > "$OUT/src/foo.ts"
( cd "$OUT" && bash .ai/scripts/features-for-path.sh src/foo.ts | grep -q 'back/sample' ) \
  && echo "  ✓ path→feature résolu"

echo
echo "[8/21] build-feature-index : index JSON créé par features-for-path"
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

echo
echo "[9/21] build-feature-index : rebuild sur mtime (frontmatter modifié)"
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
echo "[10/21] pre-turn-reminder : dépendances inverses exposées"
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
echo "[11/21] build-feature-index : status hors enum → warn (stderr, pas fail)"
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

echo
echo "[12/21] check-feature-coverage : script exécute et liste orphelins"
mkdir -p "$OUT/src"
echo "// orphan" > "$OUT/src/orphan.ts"
cov_out=$( cd "$OUT" && bash .ai/scripts/check-feature-coverage.sh 2>&1 ) || true
if ! echo "$cov_out" | grep -q "orphelins"; then
  echo "  ✗ sortie coverage inattendue"
  echo "$cov_out"
  exit 1
fi
echo "  ✓ coverage script OK"

echo
echo "[13/21] pre-turn-reminder : status 'done' filtré par défaut + visible via override"
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
echo "[14/21] measure-context-size : produit une sortie parseable"
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
echo "[15/21] progress: build-feature-index extrait progress.phase/step/blockers"
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
echo "[16/21] resume-features : feature EN COURS listée, feature BLOQUÉE séparée"
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
echo "  ✓ resume-features buckets corrects (text + json)"
rm "$OUT/.docs/features/back/inprog.md" "$OUT/.docs/features/back/blocked.md"

echo
echo "[17/21] auto-worklog : log + flush appendent au worklog et bumpent updated"
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
echo "[18/21] skills aic-* présents dans .claude/skills/"
for s in aic-feature-new aic-feature-resume aic-feature-update aic-feature-handoff aic-quality-gate aic-feature-done; do
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
echo "  ✓ 6 skills aic-* présents avec SKILL.md + workflow.md"

echo
echo "[19/21] check-feature-coverage --strict : exit 1 si orphelins"
# /src/orphan.ts (créé étape 12) est toujours orphelin
if ( cd "$OUT" && bash .ai/scripts/check-feature-coverage.sh --strict ) >/dev/null 2>&1; then
  echo "  ✗ --strict a passé malgré des orphelins"
  exit 1
fi
echo "  ✓ --strict échoue avec orphelins"
rm -f "$OUT/src/orphan.ts"

echo
echo "[20/21] check-features : cycle dans depends_on rejeté"
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
echo "[21/21] check-features : 'touches:' morte fait échouer"
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

echo
echo "✅ smoke-test PASS"
