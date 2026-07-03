#!/bin/bash
# Grader objectif — tâche 0005. Exécuté DANS le repo de travail après l'agent.
# Exit 0 = succès, 3 = vérité terrain reconstructible hors mesh (cellule invalide),
# tout autre ≠0 = échec.
set -euo pipefail

source_repo="${BENCH_SOURCE_REPO:-}"
[[ -n "$source_repo" && -d "$source_repo/.docs/features" ]] || {
  echo "source feature mesh absent : BENCH_SOURCE_REPO=$source_repo" >&2
  exit 1
}

python3 - "$source_repo" "${BENCH_CONDITION:-}" <<'PY'
import json
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
condition = sys.argv[2]

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
    step = progress.get("step")
    resume_hint = progress.get("resume_hint")
    if not all([scope, feature_id, updated, step, resume_hint]):
        return None
    return {
        "feature": f"{scope}/{feature_id}",
        "step": step,
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
expected_full = sorted(
    (item for item in features if item["updated"] == latest),
    key=lambda item: item["feature"],
)[0]
expected = {k: expected_full[k] for k in ("feature", "step", "next")}

# Garde de fuite : en condition without, la vérité terrain ne doit pas être
# reconstructible depuis la copie de travail (mesh dépouillé). L'output de
# l'agent (BENCH_RESULT/) est exclu : il PEUT légitimement contenir la réponse.
if condition == "without":
    needles = [expected["step"], expected["next"]]
    for path in pathlib.Path(".").rglob("*"):
        if not path.is_file():
            continue
        if "BENCH_RESULT" in path.parts:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for needle in needles:
            if needle and needle in text:
                print(
                    f"BENCH_TASK_INVALID: vérité terrain trouvée hors mesh dans {path}",
                    file=sys.stderr,
                )
                sys.exit(3)

result_path = pathlib.Path("BENCH_RESULT/resume-context.json")
if not result_path.is_file():
    raise SystemExit("BENCH_RESULT/resume-context.json absent")

with result_path.open(encoding="utf-8") as fh:
    actual = json.load(fh)

if set(actual) != {"feature", "step", "next"}:
    raise SystemExit(f"clés inattendues : {sorted(actual)}")

if actual != expected:
    raise SystemExit(f"résultat inattendu\nexpected={expected!r}\nactual={actual!r}")

print("ok")
PY
