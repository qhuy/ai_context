#!/bin/bash
# test-stop-turn-doc-gate.sh — gate Stop de fin de tour (workflow/stop-turn-doc-gate).
#
# Couvre :
#   - freshness --worktree : code couvert modifie sans fiche/worklog => fail strict
#   - stop-doc-gate.sh : block JSON quand fraicheur non satisfaite
#   - stop-doc-gate.sh : passe (exit 0) quand le worklog de la feature est aussi modifie
#   - anti-boucle stop_hook_active=true => exit 0
#   - echappatoire AIC_DOC_GATE=off => exit 0
#   - orphelin (chemin substantiel sans feature) => warn non bloquant, exit 0
#   - read-only : aucun .ai/.feature-index.json cree

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-stop-doc-gate.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/core" "$tmp/src"
for s in _lib.sh build-feature-index.sh check-feature-freshness.sh stop-doc-gate.sh \
         stop-sequence.sh auto-worklog-flush.sh auto-progress.sh context-relevance-log.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"

cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "stop-doc-gate-test"
coverage:
  roots:
    - src
  extensions:
    - ts
YAML

cat > "$tmp/.docs/features/core/sample.md" <<'MD'
---
id: sample
scope: core
title: Sample
status: active
depends_on: []
touches:
  - src/**
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-06-01"
---
# Sample
MD

cat > "$tmp/.docs/features/core/sample.worklog.md" <<'MD'
# Worklog — core/sample

## 2026-06-01 — création
- seed
MD

printf 'export const x = 1;\n' > "$tmp/src/app.ts"

cd "$tmp"
git init -q
git config user.email "test@example.com"
git config user.name "test"
git config core.hooksPath /dev/null
git add . >/dev/null
git commit -qm "chore: seed"

# ── Cas 0 : working tree propre => pas de block ──
out="$(printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-doc-gate.sh 2>/dev/null)"
echo "$out" | grep -q '"decision":"block"' && fail "tree propre ne devrait pas bloquer"

# ── Cas 1 : code couvert modifie SANS doc => freshness --worktree --strict fail ──
printf 'export const x = 2;\n' > src/app.ts
set +e
fresh="$(bash .ai/scripts/check-feature-freshness.sh --worktree --strict 2>&1)"; frc=$?
set -e
[[ "$frc" -ne 0 ]] || fail "freshness --worktree --strict aurait du echouer (code couvert sans doc)"
echo "$fresh" | grep -q "core/sample" || fail "freshness --worktree devrait nommer core/sample"

# ── Cas 2 : gate bloque (decision:block) + reason mentionne la feature ──
out="$(printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-doc-gate.sh 2>/dev/null)"
echo "$out" | grep -q '"decision":"block"' || fail "gate aurait du bloquer (code couvert sans doc)"
echo "$out" | grep -q "core/sample" || fail "reason du gate devrait nommer core/sample"
[[ ! -e .ai/.feature-index.json ]] || fail "gate (block) a cree l'index (read-only viole)"

# ── Cas 3 : anti-boucle stop_hook_active=true => pas de block ──
out="$(printf '{"stop_hook_active":true}' | bash .ai/scripts/stop-doc-gate.sh 2>/dev/null)"
echo "$out" | grep -q '"decision":"block"' && fail "stop_hook_active=true ne devrait jamais bloquer"

# ── Cas 4 : echappatoire AIC_DOC_GATE=off => pas de block ──
out="$(printf '{"stop_hook_active":false}' | AIC_DOC_GATE=off bash .ai/scripts/stop-doc-gate.sh 2>/dev/null)"
echo "$out" | grep -q '"decision":"block"' && fail "AIC_DOC_GATE=off ne devrait jamais bloquer"

# ── Cas 5 : worklog de la feature aussi modifie => gate passe ──
printf '\n## 2026-06-26 — maj\n- doc a jour\n' >> .docs/features/core/sample.worklog.md
out="$(printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-doc-gate.sh 2>/dev/null)"
echo "$out" | grep -q '"decision":"block"' && fail "gate ne devrait plus bloquer une fois le worklog modifie"
[[ ! -e .ai/.feature-index.json ]] || fail "gate (pass) a cree l'index (read-only viole)"

# ── Cas 6 : orphelin substantiel (couvert par AUCUNE feature) => warn, pas de block ──
# On commit l'etat a jour, puis on ajoute une racine coverage 'pkg' et un fichier
# pkg/lib.ts que le touches: src/** de sample ne couvre pas.
git add -A >/dev/null && git commit -qm "chore: doc a jour" >/dev/null
cat > .ai/config.yml <<'YAML'
docs_root: ".docs"
project_id: "stop-doc-gate-test"
coverage:
  roots:
    - src
    - pkg
  extensions:
    - ts
YAML
mkdir -p pkg
printf 'export const z = 1;\n' > pkg/lib.ts
out="$(printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-doc-gate.sh 2>/dev/null)"
err="$(printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-doc-gate.sh 2>&1 1>/dev/null)"
echo "$out" | grep -q '"decision":"block"' && fail "orphelin seul ne devrait PAS bloquer (warn only)"
echo "$err" | grep -q "pkg/lib.ts" || fail "orphelin devrait etre signale en warn (stderr)"
[[ ! -e .ai/.feature-index.json ]] || fail "gate (orphan) a cree l'index (read-only viole)"

# ── Cas 7 : sequencer (stop-sequence.sh) — block saute l'archivage, pass l'execute ──
git add -A >/dev/null && git commit -qm "chore: clean avant sequencer" >/dev/null
bash .ai/scripts/build-feature-index.sh --write >/dev/null 2>&1
printf 'export const x = 9;\n' > src/app.ts
printf '{"feature":"core/sample","file":"src/app.ts","ts":"2026-06-26T00:00:00Z"}\n' > .ai/.session-edits.log

# 7a : block => archivage saute (worklog non auto-appende, log de session preserve)
out="$(printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-sequence.sh 2>/dev/null)"
echo "$out" | grep -q '"decision":"block"' || fail "sequencer aurait du bloquer (code couvert sans doc)"
grep -q 'auto' .docs/features/core/sample.worklog.md && fail "archivage n'aurait PAS du tourner sur un block"
[[ -f .ai/.session-edits.log ]] || fail "le log de session aurait du etre preserve sur un block"

# 7b : doc touchee => pass => archivage execute (worklog auto-appende)
printf '\n## 2026-06-26 — maj manuelle\n- doc a jour\n' >> .docs/features/core/sample.worklog.md
out="$(printf '{"stop_hook_active":false}' | bash .ai/scripts/stop-sequence.sh 2>/dev/null)"
echo "$out" | grep -q '"decision":"block"' && fail "sequencer ne devrait plus bloquer une fois la doc touchee"
grep -q 'auto' .docs/features/core/sample.worklog.md || fail "l'archivage aurait du tourner sur un pass (worklog auto-appende)"

echo "✅ test-stop-turn-doc-gate PASS"
