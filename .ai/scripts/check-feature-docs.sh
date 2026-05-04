#!/bin/bash
# check-feature-docs.sh — Vérifie la complétude documentaire des fiches feature.
#
# Objectif : faire de chaque fiche feature une source de vérité utile sans
# rendre tout le legacy bloquant par défaut.
#
# Mode par défaut : warnings seulement.
# Mode strict      : missing/empty/TODO deviennent bloquants.
#
# Usage :
#   bash .ai/scripts/check-feature-docs.sh
#   bash .ai/scripts/check-feature-docs.sh --strict
#   bash .ai/scripts/check-feature-docs.sh --strict core/feature-mesh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

cd "$script_dir/../.."

FEATURES_DIR="$AI_CONTEXT_FEATURES_DIR"
STRICT=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help)
      sed -n '1,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$arg"
      else
        echo "Argument inconnu: $arg" >&2
        exit 2
      fi
      ;;
  esac
done

fail=0
warn_count=0

ok() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1" >&2; warn_count=$((warn_count + 1)); }
ko() { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; fail=1; }

report_issue() {
  local blocking="$1"
  local message="$2"
  if [[ "$blocking" -eq 1 ]]; then
    ko "$message"
  else
    warn "$message"
  fi
}

frontmatter() {
  awk '/^---$/{c++;next} c==1' "$1"
}

fm_scalar() {
  local file="$1"
  local key="$2"
  frontmatter "$file" \
    | awk -F': *' -v key="$key" '$1 == key { print $2; found=1; exit } END { exit found ? 0 : 1 }' \
    | sed 's/^["'\'']//' | sed 's/["'\'']$//' | tr -d '[:space:]'
}

doc_level() {
  local file="$1"
  awk '
    /^---$/ { fence++; next }
    fence == 2 { exit }
    fence == 1 && /^doc:[[:space:]]*$/ { in_doc=1; next }
    in_doc && /^[^[:space:]]/ { in_doc=0 }
    in_doc && /^[[:space:]]*level:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*level:[[:space:]]*/, "", line)
      gsub(/["'\''[:space:]]/, "", line)
      print line
      exit
    }
  ' "$file"
}

doc_requires() {
  local file="$1"
  local flag="$2"
  awk -v flag="$flag" '
    /^---$/ { fence++; next }
    fence == 2 { exit }
    fence == 1 && /^doc:[[:space:]]*$/ { in_doc=1; next }
    in_doc && /^[^[:space:]]/ { in_doc=0; in_requires=0 }
    in_doc && /^[[:space:]]*requires:[[:space:]]*$/ { in_requires=1; next }
    in_requires && /^[[:space:]]{2}[A-Za-z0-9_-]+:/ { in_requires=0 }
    in_requires && $0 ~ "^[[:space:]]*" flag ":[[:space:]]*" {
      line=$0
      sub("^[[:space:]]*" flag ":[[:space:]]*", "", line)
      gsub(/["'\''[:space:]]/, "", line)
      print line
      exit
    }
  ' "$file"
}

has_section() {
  local file="$1"
  local section="$2"
  grep -qx "## $section" "$file"
}

section_body() {
  local file="$1"
  local section="$2"
  awk -v section="## $section" '
    $0 == section { capture=1; next }
    capture && /^## / { exit }
    capture { print }
  ' "$file"
}

section_has_content() {
  local file="$1"
  local section="$2"
  section_body "$file" "$section" \
    | sed '/^[[:space:]]*$/d' \
    | sed '/^[[:space:]]*À renseigner si /d' \
    | sed '/^[[:space:]]*A renseigner si /d' \
    | sed '/^[[:space:]]*Synthèse courte :/d' \
    | sed '/^[[:space:]]*Pourquoi cette feature existe/d' \
    | sed '/^[[:space:]]*Description fonctionnelle/d' \
    | sed '/^[[:space:]]*Choix marquants/d' \
    | grep -q '[[:alnum:]]'
}

has_placeholder() {
  local file="$1"
  grep -qiE 'TODO|TBD|à compléter|a completer|<[^>]+>|À renseigner|A renseigner' "$file"
}

validate_section() {
  local file="$1"
  local section="$2"
  local blocking="$3"
  if ! has_section "$file" "$section"; then
    report_issue "$blocking" "$file : section '$section' manquante"
    return
  fi
  if ! section_has_content "$file" "$section"; then
    report_issue "$blocking" "$file : section '$section' vide ou placeholder"
  fi
}

echo "═══ check-feature-docs ═══"

if [[ ! -d "$FEATURES_DIR" ]]; then
  echo "  ⚠️  $FEATURES_DIR absent (aucune feature documentée)"
  exit 0
fi

files=()
if [[ -n "$TARGET" ]]; then
  target_file="$TARGET"
  if [[ "$target_file" != *.md ]]; then
    target_file="$FEATURES_DIR/$target_file.md"
  fi
  if [[ "$target_file" != "$FEATURES_DIR/"* && ! -f "$target_file" ]]; then
    target_file="$FEATURES_DIR/$TARGET"
  fi
  if [[ ! -f "$target_file" ]]; then
    echo "  ✗ feature introuvable: $TARGET" >&2
    exit 1
  fi
  files+=("$target_file")
else
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$FEATURES_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.md' ! -name '*.worklog.md' -print0 2>/dev/null)
fi

if [[ -z "${files[*]-}" ]]; then
  echo "  ⚠️  aucune feature sous $FEATURES_DIR"
  exit 0
fi

for f in "${files[@]}"; do
  status="$(fm_scalar "$f" status 2>/dev/null || true)"
  level="$(doc_level "$f")"
  [[ -n "$level" ]] || level="standard"

  blocking=0
  if [[ "$STRICT" -eq 1 || "$status" == "done" ]]; then
    blocking=1
  fi

  case "$level" in
    brief|standard|full) ;;
    *)
      report_issue "$blocking" "$f : doc.level='$level' invalide (brief|standard|full)"
      level="standard"
      ;;
  esac

  if [[ "$level" == "brief" ]]; then
    required_sections=( "Résumé" "Objectif" "Décisions" "Validation" "Historique / décisions" )
  else
    required_sections=( "Résumé" "Objectif" "Périmètre" "Invariants" "Décisions" "Comportement attendu" "Contrats" "Validation" "Historique / décisions" )
  fi

  for section in "${required_sections[@]}"; do
    validate_section "$f" "$section" "$blocking"
  done

  # Modules conditionnels. Le flag explicite active le module ; doc.level=full
  # demande aussi tous les modules pour les fiches à fort enjeu.
  for spec in \
    "auth:Droits / accès" \
    "data:Données" \
    "ux:UX" \
    "api_contract:Contrats" \
    "rollout:Déploiement / rollback" \
    "observability:Observabilité"; do
    flag="${spec%%:*}"
    section="${spec#*:}"
    required="$(doc_requires "$f" "$flag")"
    if [[ "$required" == "true" || "$level" == "full" ]]; then
      validate_section "$f" "$section" "$blocking"
    fi
  done

  if [[ "$status" == "done" ]] && has_placeholder "$f"; then
    ko "$f : status=done contient encore TODO/TBD/placeholder"
  elif [[ "$STRICT" -eq 1 ]] && has_placeholder "$f"; then
    ko "$f : contient encore TODO/TBD/placeholder"
  fi

  ok "$f"
done

echo
if [[ "$fail" -eq 0 ]]; then
  if [[ "$warn_count" -gt 0 ]]; then
    echo "⚠️  PASS avec $warn_count warning(s)"
  else
    echo "✅ PASS"
  fi
  exit 0
else
  echo "❌ FAIL"
  exit 1
fi
