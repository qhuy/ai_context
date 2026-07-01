#!/bin/bash
# test-agents-md-self-sufficient.sh — core/agents-md-native-collapse-path (P2).
#
# Verrou du chemin de collapse : AGENTS.md doit rester AUTO-SUFFISANT (porter les
# hard rules inline), pour que l'indirection .ai/index.md devienne optionnelle si
# un agent lit AGENTS.md nativement (#34235). check-shims doit ÉCHOUER si AGENTS.md
# est réduit à un simple pointeur, et signaler la self-suffisance.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-agents-selfsuff.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/rules" "$tmp/.ai/quality"
cp "$repo_root/.ai/scripts/check-shims.sh" "$tmp/.ai/scripts/check-shims.sh"
# Cibles canoniques + index réels (satisfont les autres assertions de check-shims).
cp "$repo_root/.ai/index.md" "$tmp/.ai/index.md"
cp "$repo_root/.ai/reminder.md" "$tmp/.ai/reminder.md"
cp "$repo_root/.ai/context-ignore.md" "$tmp/.ai/context-ignore.md"
cp "$repo_root/.ai/quality/QUALITY_GATE.md" "$tmp/.ai/quality/QUALITY_GATE.md"
for r in core quality workflow product; do
  cp "$repo_root/.ai/rules/$r.md" "$tmp/.ai/rules/$r.md"
done

# CLAUDE.md minimal valide (pointeur + impératif + lean).
cat > "$tmp/CLAUDE.md" <<'MD'
# CLAUDE.md
> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**
MD

# Cas A — AGENTS.md AUTO-SUFFISANT (hard rules inline) : l'assertion passe.
cat > "$tmp/AGENTS.md" <<'MD'
# AGENTS.md
> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

Hard rules :
- Un scope par tâche ; cross-scope ⇒ HANDOFF.
- Avant `feat:` : fiche feature.

Source unique : `.ai/`.
MD

(
  cd "$tmp"
  out="$(bash .ai/scripts/check-shims.sh 2>&1 || true)"
  echo "$out" | grep -q "AGENTS.md auto-suffisant" \
    || { echo "$out"; fail "cas A : AGENTS.md auto-suffisant devrait être validé"; }
)

# Cas B — AGENTS.md réduit à un simple POINTEUR (pas de hard rules) : échec attendu.
cat > "$tmp/AGENTS.md" <<'MD'
# AGENTS.md
> **Tu DOIS lire [`.ai/index.md`](.ai/index.md) avant toute action.**

Source unique : `.ai/`.
MD

(
  cd "$tmp"
  set +e
  out="$(bash .ai/scripts/check-shims.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || { echo "$out"; fail "cas B : un AGENTS.md sans hard rules devrait faire échouer check-shims"; }
  echo "$out" | grep -q "self-suffisance" \
    || { echo "$out"; fail "cas B : message 'self-suffisance' attendu"; }
)

echo "✅ test-agents-md-self-sufficient PASS"
