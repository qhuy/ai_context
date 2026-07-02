#!/bin/bash
# Grader objectif — tâche 0002. Exécuté DANS le repo de travail après l'agent.
# Exit 0 = succès, ≠0 = échec.
set -euo pipefail

source_repo="${BENCH_SOURCE_REPO:-}"
[[ -n "$source_repo" && -d "$source_repo/.docs/features" ]] || {
  echo "source feature mesh absent : BENCH_SOURCE_REPO=$source_repo" >&2
  exit 1
}

[[ -f BENCH_RESULT/feature-resume.json ]] || {
  echo "BENCH_RESULT/feature-resume.json absent" >&2
  exit 1
}

python3 - "$source_repo" BENCH_RESULT/feature-resume.json <<'PY'
import json
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
result_path = pathlib.Path(sys.argv[2])

def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value

def parse_feature(path: pathlib.Path):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None
    fm = text[4:end].splitlines()
    data = {}
    progress = {}
    in_progress = False
    for line in fm:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if re.match(r"^[A-Za-z0-9_.-]+:", line):
            in_progress = False
            key, value = line.split(":", 1)
            if key == "progress":
                in_progress = True
                continue
            data[key] = unquote(value)
            continue
        if in_progress and line.startswith("  ") and ":" in line:
            key, value = line.strip().split(":", 1)
            progress[key] = unquote(value)
    if data.get("status") != "active":
        return None
    scope = data.get("scope")
    feature_id = data.get("id")
    updated = progress.get("updated")
    phase = progress.get("phase")
    resume_hint = progress.get("resume_hint")
    if not all([scope, feature_id, updated, phase, resume_hint]):
        return None
    return {
        "feature": f"{scope}/{feature_id}",
        "phase": phase,
        "updated": updated,
        "next": resume_hint,
    }

features = []
for path in sorted((source / ".docs/features").glob("*/*.md")):
    if path.name.endswith(".worklog.md"):
        continue
    parsed = parse_feature(path)
    if parsed:
        features.append(parsed)

if not features:
    raise SystemExit("aucune feature active complète dans le source")

latest = max(item["updated"] for item in features)
expected = sorted(
    (item for item in features if item["updated"] == latest),
    key=lambda item: item["feature"],
)[0]

with result_path.open(encoding="utf-8") as fh:
    actual = json.load(fh)

if set(actual) != {"feature", "phase", "updated", "next"}:
    raise SystemExit(f"clés inattendues : {sorted(actual)}")

if actual != expected:
    raise SystemExit(f"résultat inattendu\nexpected={expected!r}\nactual={actual!r}")

print("ok")
PY
