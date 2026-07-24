#!/bin/bash
# check-runtime-template-mirror.sh — Avertit si un fichier runtime dogfoodé est
# staged sans son miroir template.jinja (ou l'inverse). Script source-only,
# mainteneur ai_context uniquement (pilotage P7, 2026-07-24).
#
# Portée volontairement restreinte aux deux classes en correspondance 1:1
# exacte : `.ai/scripts/*.sh` et `.ai/workflows/*.md`. `.ai/rules/*.md` n'est
# PAS 1:1 (les règles scopées back/front/architecture/security/handoff/tech-*
# n'existent que côté template — ce repo dogfoode scope_profile=minimal) ;
# les inclure produirait des faux positifs systématiques.
#
# Advisory uniquement (comme check-touches-breadth.sh) : un changement peut
# légitimement ne toucher qu'un côté (ex: fix cosmétique dogfood-only, ou
# script source-only déjà exclu). Ne bloque jamais un commit.
#
# Usage :
#   bash .ai/scripts/check-runtime-template-mirror.sh                 # staged (local)
#   bash .ai/scripts/check-runtime-template-mirror.sh --base=X --head=Y  # diff CI (aucun index staged en checkout)

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"
# shellcheck source=dogfood-runtime-lib.sh
. "$script_dir/dogfood-runtime-lib.sh"
cd "$repo_root"

base_ref="" head_ref=""
for arg in "$@"; do
  case "$arg" in
    --base=*) base_ref="${arg#--base=}" ;;
    --head=*) head_ref="${arg#--head=}" ;;
  esac
done

if [[ -n "$base_ref" && -n "$head_ref" ]]; then
  changed="$(vcs_diff_paths "$base_ref" "$head_ref" 2>/dev/null || true)"
  mode_label="diff $base_ref...$head_ref"
else
  changed="$(vcs_staged_paths 2>/dev/null || true)"
  mode_label="staged"
fi
[[ -z "$changed" ]] && { echo "═══ check-runtime-template-mirror (advisory) ═══"; echo "  (rien à comparer : $mode_label vide)"; exit 0; }

is_staged() { printf '%s\n' "$changed" | grep -Fxq "$1"; }

notices=()

check_pair() {
  local runtime_rel="$1" template_rel="$2"
  local runtime_staged=0 template_staged=0
  is_staged "$runtime_rel" && runtime_staged=1
  is_staged "$template_rel" && template_staged=1
  if [[ "$runtime_staged" -eq 1 && "$template_staged" -eq 0 ]]; then
    notices+=("$runtime_rel staged sans $template_rel")
  elif [[ "$runtime_staged" -eq 0 && "$template_staged" -eq 1 ]]; then
    notices+=("$template_rel staged sans $runtime_rel")
  fi
}

while IFS= read -r rel; do
  [[ "$rel" == .ai/scripts/*.sh ]] || continue
  name="${rel#.ai/scripts/}"
  dogfood_is_ai_runtime_extra_ignored "scripts/$name" && continue
  check_pair ".ai/scripts/$name" "template/.ai/scripts/$name.jinja"
done < <(printf '%s\n' "$changed" | grep -E '^\.ai/scripts/.*\.sh$|^template/\.ai/scripts/.*\.sh\.jinja$' | sed -E 's#^template/\.ai/scripts/(.*)\.jinja$#.ai/scripts/\1#' | sort -u)

while IFS= read -r rel; do
  [[ "$rel" == .ai/workflows/*.md ]] || continue
  name="${rel#.ai/workflows/}"
  check_pair ".ai/workflows/$name" "template/.ai/workflows/$name.jinja"
done < <(printf '%s\n' "$changed" | grep -E '^\.ai/workflows/.*\.md$|^template/\.ai/workflows/.*\.md\.jinja$' | sed -E 's#^template/\.ai/workflows/(.*)\.jinja$#.ai/workflows/\1#' | sort -u)

echo "═══ check-runtime-template-mirror (advisory) ═══"
if [[ "${#notices[@]}" -eq 0 ]]; then
  echo "  ✓ Aucune paire runtime/template déséquilibrée ($mode_label)."
else
  for n in "${notices[@]}"; do
    echo "  ℹ️  $n — vérifier si l'autre côté doit aussi changer."
  done
fi
exit 0
