#!/bin/bash
# Grader objectif — tâche 0001. Exécuté DANS le repo de travail après l'agent.
# Exit 0 = succès, ≠0 = échec. Aucun jugement subjectif.
set -euo pipefail
[[ -f HELLO.txt ]] || { echo "HELLO.txt absent" >&2; exit 1; }
content="$(cat HELLO.txt)"
[[ "$content" == "hello ai_context" ]] || { echo "contenu inattendu : '$content'" >&2; exit 1; }
echo "ok"
