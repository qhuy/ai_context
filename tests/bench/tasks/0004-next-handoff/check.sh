#!/bin/bash
# Grader objectif — tâche 0004. Exécuté DANS le repo de travail après l'agent.
# Exit 0 = succès, ≠0 = échec.
set -euo pipefail

source_repo="${BENCH_SOURCE_REPO:-}"
source_feature=".docs/features/product/agent-efficacy-benchmark.md"

[[ -n "$source_repo" && -f "$source_repo/$source_feature" ]] || {
  echo "feature source absente : BENCH_SOURCE_REPO=$source_repo" >&2
  exit 1
}

[[ -f BENCH_RESULT/next-handoff.json ]] || {
  echo "BENCH_RESULT/next-handoff.json absent" >&2
  exit 1
}

python3 - "$source_repo/$source_feature" BENCH_RESULT/next-handoff.json <<'PY'
import json
import pathlib
import re
import sys

feature_path = pathlib.Path(sys.argv[1])
result_path = pathlib.Path(sys.argv[2])

def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value

def progress_resume_hint(path: pathlib.Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit("frontmatter absent")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("frontmatter non terminé")
    in_progress = False
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if re.match(r"^[A-Za-z0-9_.-]+:", line):
            in_progress = False
            key, value = line.split(":", 1)
            if key == "progress":
                in_progress = True
            continue
        if in_progress and line.startswith("  ") and ":" in line:
            key, value = line.strip().split(":", 1)
            if key == "resume_hint":
                return unquote(value)
    raise SystemExit("progress.resume_hint absent")

resume_hint = progress_resume_hint(feature_path)
match = re.search(r"\bHANDOFF\s+([a-z0-9-]+/[a-z0-9-]+)\s+restant\s*=\s*(.+)$", resume_hint)
if not match:
    raise SystemExit(f"handoff restant introuvable dans resume_hint={resume_hint!r}")

target = match.group(1)
next_action = match.group(2).strip()
expected = {
    "source": "product/agent-efficacy-benchmark",
    "target": target,
    "next": next_action,
    "evidence": ".docs/features/product/agent-efficacy-benchmark.md",
}

with result_path.open(encoding="utf-8") as fh:
    actual = json.load(fh)

if set(actual) != set(expected):
    raise SystemExit(f"clés inattendues : {sorted(actual)}")

if actual != expected:
    raise SystemExit(f"résultat inattendu\nexpected={expected!r}\nactual={actual!r}")

print("ok")
PY
