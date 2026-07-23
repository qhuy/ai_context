#!/bin/bash
# migrate-all.sh — Orchestrateur read-only/apply des migrations post-Copier.
#
# Usage :
#   bash .ai/scripts/migrate-all.sh             # preview complète
#   bash .ai/scripts/migrate-all.sh --plan      # preview explicite
#   bash .ai/scripts/migrate-all.sh --apply     # préflight puis application

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

apply=0
explicit_plan=0

usage() {
  echo "Usage: bash .ai/scripts/aic.sh migrate <plan | all [--apply]>"
}

for arg in "$@"; do
  case "$arg" in
    --apply) apply=1 ;;
    --plan) explicit_plan=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "❌ argument inconnu : $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$apply" -eq 1 && "$explicit_plan" -eq 1 ]]; then
  echo "❌ 'migrate plan' est strictement read-only ; utilise 'migrate all --apply'." >&2
  exit 2
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-migrate-all.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

migration_ids=("okf-type" "okf-indexes")
migration_labels=(
  "Profil OKF — champ type"
  "Index Markdown progressifs"
)
migration_scripts=(
  "$script_dir/migrate-okf-type.sh"
  "$script_dir/migrate-okf-indexes.sh"
)
migration_statuses=()
migration_outputs=()

blocked=0
pending=0
rej_files=()
rej_count=0

while IFS= read -r -d '' rej; do
  rej_files+=("${rej#./}")
  rej_count=$((rej_count + 1))
done < <(find . -path './.git' -prune -o -type f -name '*.rej' -print0 2>/dev/null)

if [[ "$rej_count" -gt 0 ]]; then
  blocked=$((blocked + 1))
fi

detect_migration_status() {
  local output_file="$1"
  if grep -Eq 'Dry-run:[[:space:]]*[1-9][0-9]*|Dry-run[[:space:]]*:[[:space:]]*[1-9][0-9]*' "$output_file"; then
    echo "à appliquer"
  else
    echo "à jour"
  fi
}

run_preflight() {
  local i script output_file status
  for i in "${!migration_ids[@]}"; do
    script="${migration_scripts[$i]}"
    output_file="$tmp_dir/${migration_ids[$i]}.out"
    migration_outputs[$i]="$output_file"

    if [[ ! -f "$script" ]]; then
      printf '❌ script de migration absent : %s\n' "$script" > "$output_file"
      migration_statuses[$i]="bloqué"
      blocked=$((blocked + 1))
      continue
    fi

    if bash "$script" > "$output_file" 2>&1; then
      status="$(detect_migration_status "$output_file")"
      migration_statuses[$i]="$status"
      if [[ "$status" == "à appliquer" ]]; then
        pending=$((pending + 1))
      fi
    else
      migration_statuses[$i]="bloqué"
      blocked=$((blocked + 1))
    fi
  done
}

overlay_status="optionnel"
overlay_action="init"
if [[ -d .ai/project ]]; then
  overlay_files=()
  overlay_file_count=0
  while IFS= read -r -d '' entry; do
    overlay_files+=("$entry")
    overlay_file_count=$((overlay_file_count + 1))
  done < <(find .ai/project -mindepth 1 -maxdepth 2 -type f -print0 2>/dev/null)

  if [[ -f .ai/project/index.md ]] && grep -qE '^overlay_contract_version:' .ai/project/index.md; then
    overlay_status="à jour"
    overlay_action="sync"
  elif [[ "$overlay_file_count" -eq 1 && "${overlay_files[0]}" == ".ai/project/config.yml" ]]; then
    overlay_status="config-only compatible"
    overlay_action="config-only"
  elif [[ "$overlay_file_count" -gt 0 ]]; then
    overlay_status="action humaine recommandée"
    overlay_action="migrate"
  fi
fi

run_preflight

echo "═══ migrations post-Copier ═══"
echo "mode: $([[ "$apply" -eq 1 ]] && echo apply || echo preview)"
echo
echo "Préflight"

if [[ "$rej_count" -eq 0 ]]; then
  echo "  ✓ aucun fichier .rej non résolu"
else
  echo "  ❌ fichiers .rej à arbitrer avant toute migration :"
  for rej in "${rej_files[@]}"; do
    echo "    - $rej"
  done
fi

if [[ -f .copier-answers.yml ]]; then
  echo "  ✓ métadonnées Copier présentes"
else
  echo "  ⚠️  .copier-answers.yml absent"
  echo "     Action : bash .ai/scripts/aic.sh repair-copier-metadata --apply"
fi

echo
echo "Migrations automatisables"
for i in "${!migration_ids[@]}"; do
  echo "  $((i + 1)). ${migration_labels[$i]} — ${migration_statuses[$i]}"
  sed 's/^/     /' "${migration_outputs[$i]}"
done

echo
echo "Compatibilité legacy — hors batch"
echo "  • 'bash .ai/scripts/aic.sh migrate' reste disponible pour les anciens frontmatters"
echo "  • cette migration historique n'est jamais incluse implicitement dans 'migrate all'"

echo
echo "Étape humaine — overlay projet"
echo "  • état: $overlay_status"
case "$overlay_action" in
  init)
    echo "  • action optionnelle: lancer aic-onboard en mode init si le projet a des règles locales durables"
    ;;
  migrate)
    echo "  • action recommandée: lancer aic-onboard ; il proposera le mode migrate avant toute écriture"
    ;;
  sync)
    echo "  • action optionnelle: relancer aic-onboard en mode sync pour enrichir le registre existant"
    ;;
  config-only)
    echo "  • aucune migration requise: aic-onboard reste optionnel si des scopes doivent être ajoutés"
    ;;
esac
echo "  • l'orchestrateur ne modifie jamais .ai/project/**"

echo
echo "Validations prévues après apply"
echo "  - bash .ai/scripts/check-shims.sh"
echo "  - bash .ai/scripts/check-features.sh --no-write"
echo "  - bash .ai/scripts/check-feature-indexes.sh --strict"

if [[ "$blocked" -gt 0 ]]; then
  echo
  echo "❌ Plan bloqué : $blocked blocage(s) à résoudre ; aucune écriture effectuée." >&2
  exit 1
fi

if [[ "$apply" -eq 0 ]]; then
  echo
  if [[ "$pending" -eq 0 ]]; then
    echo "✓ Aucune migration automatisable en attente."
  else
    echo "ℹ️ $pending migration(s) à appliquer."
    echo "   Action : bash .ai/scripts/aic.sh migrate all --apply"
  fi
  echo "   Rollback futur : committe les migrations séparément, puis utilise le revert de ton VCS."
  exit 0
fi

echo
echo "Application"
for i in "${!migration_ids[@]}"; do
  echo "  → ${migration_labels[$i]}"
  if ! bash "${migration_scripts[$i]}" --apply; then
    echo "❌ Échec pendant '${migration_ids[$i]}'. Les étapes précédentes peuvent déjà être appliquées." >&2
    echo "   Inspecte le diff et restaure la branche de migration avec ton VCS avant de relancer." >&2
    exit 1
  fi
done

echo
echo "Validation"
bash "$script_dir/check-shims.sh"
bash "$script_dir/check-features.sh" --no-write
bash "$script_dir/check-feature-indexes.sh" --strict

echo
echo "✅ Migrations automatisables appliquées et validées."
echo "   Relis le diff, traite l'étape aic-onboard si elle est recommandée, puis crée un commit dédié."
echo "   Rollback après commit : utilise le revert de ton VCS sur ce commit."
