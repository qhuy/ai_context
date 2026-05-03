#!/bin/bash
# ai-context.sh — CLI unifié pour les scripts .ai/scripts/*.
#
# But : offrir une surface stable (`ai-context <verbe>`) sans casser l'invocation
# directe `bash .ai/scripts/<script>.sh`. Les commandes UX composent les
# scripts existants ; les autres sous-commandes restent des routes directes.
#
# Usage :
#   bash .ai/scripts/ai-context.sh <command> [args...]
#   bash .ai/scripts/ai-context.sh --help
#
# Sous-commandes (toutes les options du script cible sont passées telles quelles) :
#   doctor       → bash .ai/scripts/doctor.sh
#   status       → état humain actionnable du mesh courant
#   brief <path> → contexte feature juste-à-temps pour un fichier
#   mission      → cadrage léger avant une tâche importante
#   repair       → plan de réparation non destructif du mesh
#   document-delta → docs/features à vérifier depuis le delta courant
#   ship-report  → synthèse de sortie avant commit/PR
#   product-status / product-portfolio / product-review → pilotage produit
#   resume       → bash .ai/scripts/resume-features.sh
#   audit        → bash .ai/scripts/audit-features.sh
#   migrate      → bash .ai/scripts/migrate-features.sh
#   pr-report    → bash .ai/scripts/pr-report.sh
#   review       → bash .ai/scripts/review-delta.sh
#   measure      → bash .ai/scripts/measure-context-size.sh
#   check        → bash .ai/scripts/check-features.sh
#   coverage     → bash .ai/scripts/check-feature-coverage.sh
#   shims        → bash .ai/scripts/check-shims.sh
#   index        → bash .ai/scripts/build-feature-index.sh
#   reminder     → bash .ai/scripts/pre-turn-reminder.sh
#
# Exit codes : ceux du script ciblé.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

print_help() {
  cat <<'HELP'
Usage: bash .ai/scripts/ai-context.sh <command> [args...]

CLI ai_context — commandes intentionnelles + accès aux scripts dédiés.

Commandes :
  status       état actionnable : features, delta, hooks, checks, prochaine action
  brief <path> contexte juste-à-temps avant d'éditer un fichier (Codex-friendly)
  mission "<objectif>"
               cadrage léger : scope probable, docs à lire, plan, validations
  repair [--apply]
               plan de réparation du mesh ; --apply reconstruit seulement l'index
  document-delta
               suggestions de documentation à partir du delta courant/staged
  ship-report  rapport de sortie : delta, docs, checks, commit proposé
  product-status
               vue COO des initiatives product et features dev liées
  product-portfolio
               arbitrage portefeuille : impact, confiance, coût, recommandation
  product-review product/<id>
               review décisionnelle d'une initiative product
  doctor       diagnostic non destructif (dépendances, hooks, index, checks)
  resume       buckets EN COURS / BLOQUÉES / STALE / À FAIRE
  audit        audit-features.sh (discover <scope>)
  migrate      migration frontmatter (--apply explicite)
  pr-report    rapport markdown/json d'impact feature depuis un diff git
  review       synthèse review-friendly du delta courant
  measure      taille contexte injecté par les hooks
  check        check-features.sh (frontmatter + scope + depends_on + touches)
  coverage     check-feature-coverage.sh (orphelins)
  shims        check-shims.sh (cohérence shims racine ↔ .ai/index.md)
  index        build-feature-index.sh (rebuild .ai/.feature-index.json)
  reminder     pre-turn-reminder.sh (sortie text ou json)

Aliases : --help, -h, help
HELP
}

status_label() {
  if "$@" >/dev/null 2>&1; then
    printf 'OK'
  else
    printf 'ATTENTION'
  fi
}

inside_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

staged_count() {
  if inside_git_repo; then
    git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' '
  else
    echo 0
  fi
}

changed_files_for_report() {
  if ! inside_git_repo; then
    return 0
  fi
  if [[ "$(staged_count)" -gt 0 ]]; then
    git diff --cached --name-only --diff-filter=AM 2>/dev/null || true
  else
    git status --porcelain 2>/dev/null | sed 's/^...//' | sort -u
  fi
}

review_args_for_current_delta() {
  if [[ "$(staged_count)" -gt 0 ]]; then
    printf '%s\n' "--staged"
  fi
}

infer_scope_from_text() {
  local text
  text="$(printf '%s' "$*" | LC_ALL=C tr '[:upper:]' '[:lower:]')"
  case "$text" in
    *front*|*ui*|*ux*|*react*|*vue*|*css*|*page*|*écran*|*ecran*) echo "front" ;;
    *back*|*api*|*server*|*serveur*|*database*|*db*|*sql*|*endpoint*) echo "back" ;;
    *archi*|*architecture*|*design*|*adr*) echo "architecture" ;;
    *security*|*sécurité*|*securite*|*auth*|*permission*|*droit*) echo "security" ;;
    *test*|*qualit*|*qa*|*ci*|*smoke*) echo "quality" ;;
    *workflow*|*agent*|*skill*|*hook*|*claude*|*codex*) echo "workflow" ;;
    *template*|*copier*|*scaffold*|*runtime*) echo "core" ;;
    *) echo "à confirmer" ;;
  esac
}

print_active_feature_hints() {
  local limit="${1:-6}"
  local index_file="$repo_root/.ai/.feature-index.json"
  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
  if [[ -f "$index_file" ]] && command -v jq >/dev/null 2>&1; then
    jq -r --argjson limit "$limit" '
      [.features[]
        | select(.status == "active" or .status == "draft")
        | "- `" + .path + "` — " + .scope + "/" + .id + ": " + (.title // "sans titre")
      ][0:$limit][]' "$index_file" 2>/dev/null || true
  fi
}

run_status() {
  cd "$repo_root"

  local index_file total draft active blocked done staged modified hooks_path git_hooks claude_hooks

  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
  index_file="$repo_root/.ai/.feature-index.json"

  total=0
  draft=0
  active=0
  blocked=0
  done=0
  if [[ -f "$index_file" ]] && command -v jq >/dev/null 2>&1; then
    total=$(jq '[.features[]] | length' "$index_file" 2>/dev/null || echo 0)
    draft=$(jq '[.features[] | select(.status == "draft")] | length' "$index_file" 2>/dev/null || echo 0)
    active=$(jq '[.features[] | select(.status == "active")] | length' "$index_file" 2>/dev/null || echo 0)
    done=$(jq '[.features[] | select(.status == "done")] | length' "$index_file" 2>/dev/null || echo 0)
    blocked=$(jq '[.features[] | select((.progress.phase // "") == "blocked")] | length' "$index_file" 2>/dev/null || echo 0)
  fi

  staged=0
  modified=0
  hooks_path=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    hooks_path=$(git config --get core.hooksPath 2>/dev/null || true)
  fi

  git_hooks="absents"
  if [[ -d ".githooks" ]]; then
    if [[ "$hooks_path" == ".githooks" && -x ".githooks/pre-commit" && -x ".githooks/commit-msg" ]]; then
      git_hooks="OK"
    else
      git_hooks="à activer"
    fi
  fi

  claude_hooks="absents"
  if [[ -f ".claude/settings.json" ]]; then
    if grep -q "UserPromptSubmit" ".claude/settings.json" && grep -q "PreToolUse" ".claude/settings.json"; then
      claude_hooks="configurés"
    else
      claude_hooks="incomplets"
    fi
  fi

  local check_features check_shims check_product freshness coverage measure_total next_action
  check_features=$(status_label bash "$script_dir/check-features.sh")
  check_shims=$(status_label bash "$script_dir/check-shims.sh")
  check_product=$(status_label bash "$script_dir/check-product-links.sh")
  coverage=$(status_label bash "$script_dir/check-feature-coverage.sh")
  freshness="OK"
  if [[ "$staged" -gt 0 ]]; then
    freshness=$(status_label bash "$script_dir/check-feature-freshness.sh" --staged --strict)
  fi

  measure_total=$(bash "$script_dir/measure-context-size.sh" 2>/dev/null | awk '/total[[:space:]]+chars=/{print $2 " " $3}' | head -1)
  [[ -n "$measure_total" ]] || measure_total="n/a"

  next_action="Travailler normalement ; avant commit, lance: bash .ai/scripts/ai-context.sh review"
  if [[ "$check_features" != "OK" ]]; then
    next_action="Corriger les frontmatter: bash .ai/scripts/check-features.sh"
  elif [[ "$check_shims" != "OK" ]]; then
    next_action="Réparer les shims: bash .ai/scripts/check-shims.sh"
  elif [[ "$check_product" != "OK" ]]; then
    next_action="Relire les liens produit: bash .ai/scripts/ai-context.sh product-status"
  elif [[ "$freshness" != "OK" ]]; then
    next_action="Mettre à jour/stager les fiches feature: bash .ai/scripts/check-feature-freshness.sh --staged --strict"
  elif [[ "$coverage" != "OK" ]]; then
    next_action="Relier les fichiers orphelins à des touches: bash .ai/scripts/check-feature-coverage.sh"
  elif [[ "$staged" -gt 0 ]]; then
    next_action="Relire le delta staged: bash .ai/scripts/ai-context.sh review --staged"
  elif [[ "$modified" -gt 0 ]]; then
    next_action="Stager les docs avec le code, puis lancer: bash .ai/scripts/ai-context.sh review"
  elif [[ "$active" -eq 0 && "$draft" -eq 0 ]]; then
    next_action="Créer ou cadrer la première feature: /aic-frame ou .ai/workflows/feature-new.md"
  fi

  cat <<EOF
AI Context Status

Features
- total   : $total
- active  : $active
- draft   : $draft
- blocked : $blocked
- done    : $done

Delta
- fichiers modifiés : $modified
- fichiers staged   : $staged

Runtime
- git hooks    : $git_hooks
- Claude hooks : $claude_hooks
- reminder     : $measure_total

Checks
- features          : $check_features
- shims             : $check_shims
- product links     : $check_product
- freshness staged  : $freshness
- coverage          : $coverage

Prochaine action minimale
- $next_action
EOF
}

run_brief() {
  local target="${1:-}"
  if [[ -z "$target" ]]; then
    echo "Usage: bash .ai/scripts/ai-context.sh brief <path>" >&2
    exit 2
  fi
  shift || true
  exec bash "$script_dir/features-for-path.sh" --with-docs "$target" "$@"
}

run_mission() {
  cd "$repo_root"
  local objective="$*"
  local scope docs_scope
  if [[ -z "$objective" ]]; then
    echo "Usage: bash .ai/scripts/ai-context.sh mission \"<objectif>\"" >&2
    exit 2
  fi

  scope="$(infer_scope_from_text "$objective")"
  docs_scope=""
  if [[ "$scope" != "à confirmer" && -f ".ai/rules/$scope.md" ]]; then
    docs_scope="- \`.ai/rules/$scope.md\`"
  fi

  cat <<EOF
## Mission Brief

Objectif :
- $objective

Scope primaire probable :
- $scope

Docs à lire maintenant :
- \`.ai/index.md\`
$docs_scope

Features actives candidates :
EOF
  hints="$(print_active_feature_hints 6)"
  if [[ -n "$hints" ]]; then
    printf '%s\n' "$hints"
  else
    echo "- _(aucune feature active/draft détectée)_"
  fi
  cat <<'EOF'

Diagnostic initial :
- Confirmer le scope primaire avant d'éditer.
- Identifier les fichiers touchés puis lancer `brief <path>` avant modification.
- Si plusieurs scopes sont nécessaires, produire un HANDOFF explicite au lieu de mélanger les règles.

Plan recommandé :
1. Reformuler le résultat attendu et les non-goals.
2. Charger uniquement les règles du scope primaire et les features liées aux fichiers visés.
3. Implémenter le plus petit changement cohérent.
4. Mettre à jour la fiche feature/worklog avec l'intention, les fichiers et les validations.
5. Lancer `ai-context.sh ship-report` puis les checks qualité.

Questions de validation :
- Quel est le comportement observable attendu ?
- Quelle contrainte métier ou technique ne doit pas être cassée ?
- Quel test ou preuve rend la tâche terminée ?

Prochaine action minimale :
- Choisir le premier fichier à toucher puis lancer `bash .ai/scripts/ai-context.sh brief <path>`.
EOF
}

run_repair() {
  cd "$repo_root"
  local apply="no"
  for arg in "$@"; do
    case "$arg" in
      --apply) apply="yes" ;;
      -h|--help)
        echo "Usage: bash .ai/scripts/ai-context.sh repair [--apply]"
        exit 0
        ;;
      *)
        echo "Argument inconnu: $arg" >&2
        exit 2
        ;;
    esac
  done

  if [[ "$apply" == "yes" ]]; then
    bash "$script_dir/build-feature-index.sh" --write >/dev/null
  fi

  local check_features check_shims check_product coverage freshness staged
  check_features=$(status_label bash "$script_dir/check-features.sh")
  check_shims=$(status_label bash "$script_dir/check-shims.sh")
  check_product=$(status_label bash "$script_dir/check-product-links.sh")
  coverage=$(status_label bash "$script_dir/check-feature-coverage.sh")
  staged="$(staged_count)"
  freshness="OK"
  if [[ "$staged" -gt 0 ]]; then
    freshness=$(status_label bash "$script_dir/check-feature-freshness.sh" --staged --strict)
  fi

  cat <<EOF
## Repair Plan

Mode :
- apply: $apply
- fichiers staged: $staged

Checks :
- features: $check_features
- shims: $check_shims
- product links: $check_product
- coverage: $coverage
- freshness staged: $freshness

Actions recommandées :
EOF
  [[ "$check_features" != "OK" ]] && echo "- Corriger les frontmatter: \`bash .ai/scripts/check-features.sh\`"
  [[ "$check_shims" != "OK" ]] && echo "- Réparer les shims racine depuis \`.ai/index.md\`: \`bash .ai/scripts/check-shims.sh\`"
  [[ "$check_product" != "OK" ]] && echo "- Corriger les liens produit: \`bash .ai/scripts/check-product-links.sh --strict\`"
  [[ "$coverage" != "OK" ]] && echo "- Ajouter/ajuster les \`touches:\` ou créer une fiche feature pour les orphelins."
  [[ "$freshness" != "OK" ]] && echo "- Stager la fiche/worklog de chaque feature impactée: \`bash .ai/scripts/check-feature-freshness.sh --staged --strict\`"
  if [[ "$check_features$check_shims$check_product$coverage$freshness" == "OKOKOKOKOK" ]]; then
    echo "- Aucun correctif structurel détecté."
  fi

  cat <<'EOF'

Prochaine action minimale :
- Lancer `bash .ai/scripts/ai-context.sh document-delta` pour vérifier la documentation du delta courant.
EOF
}

run_document_delta() {
  cd "$repo_root"
  cat <<'EOF'
## Document Delta

Objectif :
- Identifier les fiches `.docs/features/**` à mettre à jour avant commit.

Delta courant :
EOF
  if inside_git_repo; then
    if [[ "$(staged_count)" -gt 0 ]]; then
      echo "- mode: staged"
    else
      echo "- mode: worktree"
    fi
    changed="$(changed_files_for_report)"
    if [[ -n "$changed" ]]; then
      printf '%s\n' "$changed" | sed 's/^/- /'
    else
      echo "- _(aucun fichier modifié)_"
    fi
  else
    echo "- _(git indisponible dans ce dossier)_"
  fi

  echo
  echo "Analyse feature :"
  if inside_git_repo; then
    args="$(review_args_for_current_delta)"
    if [[ -n "$args" ]]; then
      bash "$script_dir/review-delta.sh" "$args" | sed 's/^/> /' || true
    else
      bash "$script_dir/review-delta.sh" | sed 's/^/> /' || true
    fi
  else
    echo "- Impossible de lire un delta git ; utiliser \`brief <path>\` fichier par fichier."
  fi

  cat <<'EOF'

Prochaine action minimale :
- Mettre à jour puis stager la fiche feature ou son worklog pour chaque feature directe impactée.
EOF
}

run_ship_report() {
  cd "$repo_root"
  local check_features check_shims check_product coverage freshness measure_total staged modified commit_hint
  staged="$(staged_count)"
  modified=0
  if inside_git_repo; then
    modified=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  fi
  check_features=$(status_label bash "$script_dir/check-features.sh")
  check_shims=$(status_label bash "$script_dir/check-shims.sh")
  check_product=$(status_label bash "$script_dir/check-product-links.sh")
  coverage=$(status_label bash "$script_dir/check-feature-coverage.sh")
  freshness="OK"
  if [[ "$staged" -gt 0 ]]; then
    freshness=$(status_label bash "$script_dir/check-feature-freshness.sh" --staged --strict)
  fi
  measure_total=$(bash "$script_dir/measure-context-size.sh" 2>/dev/null | awk '/total[[:space:]]+chars=/{print $2 " " $3}' | head -1)
  [[ -n "$measure_total" ]] || measure_total="n/a"

  commit_hint="chore: mettre à jour ai context"
  if inside_git_repo && git diff --cached --name-only 2>/dev/null | grep -q '^\.docs/features/'; then
    commit_hint="feat: mettre à jour le contexte IA"
  fi

  cat <<EOF
## AI Context Ship Report

Delta :
- fichiers modifiés: $modified
- fichiers staged: $staged
- reminder: $measure_total

Checks :
- features: $check_features
- shims: $check_shims
- product links: $check_product
- coverage: $coverage
- freshness staged: $freshness

Fichiers :
EOF
  files="$(changed_files_for_report)"
  if [[ -n "$files" ]]; then
    printf '%s\n' "$files" | sed 's/^/- /'
  else
    echo "- _(aucun fichier modifié détecté)_"
  fi

  echo
  echo "Review delta :"
  if inside_git_repo; then
    args="$(review_args_for_current_delta)"
    if [[ -n "$args" ]]; then
      bash "$script_dir/review-delta.sh" "$args" | sed 's/^/> /' || true
    else
      bash "$script_dir/review-delta.sh" | sed 's/^/> /' || true
    fi
  else
    echo "- Git indisponible ; rapport limité aux checks locaux."
  fi

  cat <<EOF

Commit proposé :
- \`$commit_hint\`

Prochaine action minimale :
- Si tous les checks sont OK, lancer le commit ; sinon traiter la première ligne ATTENTION ci-dessus.
EOF
}

cmd="${1:-}"
case "$cmd" in
  ""|-h|--help|help)
    print_help
    exit 0
    ;;
esac
shift

case "$cmd" in
  status)     run_status "$@" ;;
  brief)      run_brief "$@" ;;
  mission)    run_mission "$@" ;;
  repair)     run_repair "$@" ;;
  document-delta) run_document_delta "$@" ;;
  ship-report) run_ship_report "$@" ;;
  product-status) exec bash "$script_dir/product-status.sh" "$@" ;;
  product-portfolio) exec bash "$script_dir/product-portfolio.sh" "$@" ;;
  product-review) exec bash "$script_dir/product-review.sh" "$@" ;;
  doctor)     exec bash "$script_dir/doctor.sh" "$@" ;;
  resume)     exec bash "$script_dir/resume-features.sh" "$@" ;;
  audit)      exec bash "$script_dir/audit-features.sh" "$@" ;;
  migrate)    exec bash "$script_dir/migrate-features.sh" "$@" ;;
  pr-report)  exec bash "$script_dir/pr-report.sh" "$@" ;;
  review)     exec bash "$script_dir/review-delta.sh" "$@" ;;
  measure)    exec bash "$script_dir/measure-context-size.sh" "$@" ;;
  check)      exec bash "$script_dir/check-features.sh" "$@" ;;
  coverage)   exec bash "$script_dir/check-feature-coverage.sh" "$@" ;;
  shims)      exec bash "$script_dir/check-shims.sh" "$@" ;;
  index)      exec bash "$script_dir/build-feature-index.sh" "$@" ;;
  reminder)   exec bash "$script_dir/pre-turn-reminder.sh" "$@" ;;
  *)
    echo "Commande inconnue: $cmd" >&2
    print_help >&2
    exit 1
    ;;
esac
