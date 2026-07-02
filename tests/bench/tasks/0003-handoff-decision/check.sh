#!/bin/bash
# Grader objectif — tâche 0003. Exécuté DANS le repo de travail après l'agent.
# Exit 0 = succès, ≠0 = échec.
set -euo pipefail

result="BENCH_RESULT/handoff-decision.txt"
[[ -f "$result" ]] || { echo "$result absent" >&2; exit 1; }

expected="$(mktemp)"
trap 'rm -f "$expected"' EXIT
cat > "$expected" <<'EOF'
decision=HANDOFF_REQUIRED
source=product/agent-efficacy-benchmark
target=quality/smoke-test
EOF

if ! diff -u "$expected" "$result"; then
  echo "décision de handoff inattendue" >&2
  exit 1
fi

echo "ok"
