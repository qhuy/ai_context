#!/bin/bash
# aic.sh — surface canonique aic pour agents hookés et non-hookés.
#
# But : exposer une taxonomie unique alignée avec les skills publics :
# frame / status / diagnose / document-feature / review / ship.
# Les commandes techniques restent disponibles pour maintenance, sans remplacer
# la surface utilisateur aic-*.
#
# Usage :
#   bash .ai/scripts/aic.sh <command> [args...]
#   bash .ai/scripts/aic.sh --help
#
# Exit codes : ceux du script ciblé.

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

print_help() {
  cat <<'HELP'
Usage: bash .ai/scripts/aic.sh <command> [args...]

CLI aic — surface canonique alignée avec les skills aic-*.

Commandes utilisateur :
  frame "<objectif>"
               cadrage avant action : scope, docs à lire, plan, validation
  status       état actionnable : features, delta, hooks, checks, prochaine action
  diagnose ["symptôme"]
               diagnostic court du goulot probable et prochaine action
  document-feature [path]
               sans path : docs/features à vérifier depuis le delta courant ;
               avec path : contexte feature juste-à-temps pour ce fichier
  review       synthèse review-friendly du delta courant
  ship         rapport de sortie : delta, docs, checks, commit proposé

Commandes maintenance :
  repair [--apply]
               plan de réparation du mesh ; --apply reconstruit seulement l'index
  product-status
               vue des initiatives product et features dev liées
  product-portfolio
               comparaison read-only : impact, confiance, coût, recommandation
  product-review product/<id>
               review décisionnelle d'une initiative product
  doctor       diagnostic non destructif (dépendances, hooks, index, checks)
  resume       buckets EN COURS / BLOQUÉES / STALE / À FAIRE
  audit        audit-features.sh (discover <scope>)
  migrate      migration frontmatter (--apply explicite)
  pr-report    rapport markdown/json d'impact feature depuis un diff git
  measure      taille contexte injecté par les hooks
  check        check-features.sh (frontmatter + scope + depends_on + touches)
  check-docs   check-feature-docs.sh (sections feature ; --strict <scope/id> avant DONE)
  coverage     check-feature-coverage.sh (orphelins)
  shims        check-shims.sh (cohérence shims racine ↔ .ai/index.md)
  index        build-feature-index.sh (rebuild .ai/.feature-index.json)
  reminder     pre-turn-reminder.sh (sortie text ou json)
  repair-copier-metadata [--apply] [--src-path <src>] [--commit <ref>]
               recrée .copier-answers.yml si absent ou incomplet
  template-diff [--src-path <src>] [--vcs-ref <ref>]
               rend le template dans /tmp et liste les écarts sans toucher au repo

Help : --help, -h, help
HELP
}

status_label() {
  if "$@" >/dev/null 2>&1; then
    printf 'OK'
  else
    printf 'ATTENTION'
  fi
}

yaml_scalar() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 1
  awk -F': *' -v key="$key" '$1 == key { print $2; found=1; exit } END { exit found ? 0 : 1 }' "$file" \
    | sed 's/^["'\'']//' | sed 's/["'\'']$//'
}

infer_project_name() {
  yaml_scalar "$repo_root/.ai/config.yml" project_id 2>/dev/null \
    || yaml_scalar "$repo_root/.copier-answers.yml" project_name 2>/dev/null \
    || basename "$repo_root"
}

infer_docs_root() {
  yaml_scalar "$repo_root/.ai/config.yml" docs_root 2>/dev/null \
    || yaml_scalar "$repo_root/.copier-answers.yml" docs_root 2>/dev/null \
    || echo ".docs"
}

infer_scope_profile() {
  local docs_root has_back has_front has_arch has_security
  docs_root="$(infer_docs_root)"
  has_back=0
  has_front=0
  has_arch=0
  has_security=0
  [[ -d "$repo_root/$docs_root/features/back" ]] && has_back=1
  [[ -d "$repo_root/$docs_root/features/front" ]] && has_front=1
  [[ -d "$repo_root/$docs_root/features/architecture" ]] && has_arch=1
  [[ -d "$repo_root/$docs_root/features/security" ]] && has_security=1
  if [[ "$has_back$has_front" == "11" ]]; then
    echo "fullstack"
  elif [[ "$has_back$has_arch$has_security" == "111" ]]; then
    echo "backend"
  else
    echo "minimal"
  fi
}

infer_agents_yaml() {
  local found=0
  [[ -f "$repo_root/.claude/settings.json" || -f "$repo_root/CLAUDE.md" ]] && { echo "  - claude"; found=1; }
  [[ -f "$repo_root/AGENTS.md" ]] && { echo "  - codex"; found=1; }
  [[ -d "$repo_root/.cursor" ]] && { echo "  - cursor"; found=1; }
  [[ -f "$repo_root/GEMINI.md" ]] && { echo "  - gemini"; found=1; }
  [[ -f "$repo_root/.github/copilot-instructions.md" ]] && { echo "  - copilot"; found=1; }
  [[ "$found" -eq 0 ]] && printf '%s\n%s\n' "  - claude" "  - codex"
}

infer_adoption_mode() {
  if [[ ! -d "$repo_root/.githooks" ]]; then
    echo "lite"
  elif [[ -f "$repo_root/.github/workflows/ai-context-check.yml" ]]; then
    echo "standard"
  else
    echo "standard"
  fi
}

write_repaired_answers() {
  local target="$1"
  local src_path="$2"
  local commit_ref="$3"
  local project_name docs_root scope_profile adoption_mode
  project_name="$(infer_project_name)"
  docs_root="$(infer_docs_root)"
  scope_profile="$(infer_scope_profile)"
  adoption_mode="$(infer_adoption_mode)"
  cat >"$target" <<EOF
# Changes here will be overwritten by Copier
_src_path: $src_path
_commit: $commit_ref
project_name: $project_name
project_description: ""
scope_profile: $scope_profile
adoption_mode: $adoption_mode
tech_profile: generic
commit_language: fr
docs_root: $docs_root
agents:
$(infer_agents_yaml)
enable_ci_guard: true
EOF
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
    git diff --cached --name-only --no-renames 2>/dev/null || true
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
    *product*|*produit*|*roadmap*|*portfolio*|*initiative*|*priorit*) echo "product" ;;
    *core*|*noyau*|*runtime*|*template*|*copier*|*scaffold*|*aic*) echo "core" ;;
    *front*|*ui*|*ux*|*react*|*vue*|*css*|*page*|*écran*|*ecran*) echo "front" ;;
    *back*|*api*|*server*|*serveur*|*database*|*db*|*sql*|*endpoint*) echo "back" ;;
    *archi*|*architecture*|*design*) echo "architecture" ;;
    *security*|*sécurité*|*securite*|*auth*|*permission*|*droit*) echo "security" ;;
    *test*|*qualit*|*qa*|*ci*|*smoke*) echo "quality" ;;
    *workflow*|*agent*|*skill*|*hook*|*claude*|*codex*|*cadrage*|*frame*) echo "workflow" ;;
    *) echo "à confirmer" ;;
  esac
}

print_active_feature_hints() {
  local limit="${1:-6}"
  local scope_filter="${2:-}"
  local index_file="$repo_root/.ai/.feature-index.json"
  bash "$script_dir/build-feature-index.sh" --write >/dev/null 2>&1 || true
  if [[ -f "$index_file" ]] && command -v jq >/dev/null 2>&1; then
    jq -r --argjson limit "$limit" --arg scope_filter "$scope_filter" '
      [.features[]
        | select(.status == "active" or .status == "draft")
        | select($scope_filter == "" or .scope == $scope_filter)
        | "- `" + .path + "` — " + .scope + "/" + .id + ": " + (.title // "sans titre")
      ][0:$limit][]' "$index_file" 2>/dev/null || true
  fi
}

run_frame() {
  cd "$repo_root"
  local objective scope docs_scope docs_root hooks_line claude_line product_line first_dev_scope doc_feature_scope hints

  objective="$*"
  [[ -n "$objective" ]] || objective="cadrer la prochaine tâche"
  scope="$(infer_scope_from_text "$objective")"
  docs_scope=""
  if [[ "$scope" != "à confirmer" && -f ".ai/rules/$scope.md" ]]; then
    docs_scope="- \`.ai/rules/$scope.md\`"
  fi

  docs_root=".docs"
  if [[ -f ".ai/config.yml" ]]; then
    docs_root="$(awk -F': *' '/^docs_root:/{print $2; exit}' .ai/config.yml 2>/dev/null | tr -d '"' || true)"
    [[ -n "$docs_root" ]] || docs_root=".docs"
  fi

  hooks_line="git hooks absents"
  if [[ -d ".githooks" ]]; then
    hooks_line="git config core.hooksPath .githooks && chmod +x .githooks/*"
  fi

  claude_line="Claude non scaffoldé"
  if [[ -f ".claude/settings.json" ]]; then
    claude_line="Dans Claude Code: lancer /hooks et activer les hooks proposés"
  fi

  product_line="Créer une initiative product si le projet a un enjeu produit à tracer."
  if [[ -d "$docs_root/features/product" ]]; then
    product_line="Créer une initiative product dans \`$docs_root/features/product/<id>.md\` si la tâche porte un pari produit."
  fi

  first_dev_scope="core"
  [[ -d "$docs_root/features/front" ]] && first_dev_scope="front"
  [[ -d "$docs_root/features/back" ]] && first_dev_scope="back"
  doc_feature_scope="$first_dev_scope"
  if [[ "$scope" != "à confirmer" && -d "$docs_root/features/$scope" ]]; then
    doc_feature_scope="$scope"
  fi

  cat <<EOF
## AIC Frame

Objectif :
- $objective

Position recommandée :
- Utiliser la surface \`aic\` comme langage public unique.
- Cadrer avant écriture, puis créer ou mettre à jour la fiche feature avant tout \`feat:\`.

Scope primaire probable :
- $scope

Docs à lire maintenant :
- \`.ai/index.md\`
$docs_scope

Features actives candidates :
EOF
  if [[ "$scope" != "à confirmer" ]]; then
    hints="$(print_active_feature_hints 6 "$scope")"
  else
    hints="$(print_active_feature_hints 6)"
  fi
  if [[ -n "$hints" ]]; then
    printf '%s\n' "$hints"
  else
    echo "- _(aucune feature active/draft détectée)_"
  fi

  cat <<EOF

Garde-fous locaux :
- \`$hooks_line\`
- $claude_line

Plan recommandé :
1. Reformuler le résultat attendu, les non-goals et le goulot probable.
2. Confirmer le scope primaire ; si plusieurs scopes sont nécessaires, préparer un HANDOFF.
3. Charger uniquement les règles et fiches liées au scope ou aux fichiers ciblés.
4. Documenter la feature dans \`$docs_root/features/$doc_feature_scope/<id>.md\` si le changement ajoute/modifie du comportement.
5. Lancer les checks adaptés avant sortie.

Validation :
- Acceptance : comportement observable nommé avant écriture.
- Checks : \`bash .ai/scripts/aic.sh review\`, puis \`bash .ai/scripts/aic.sh ship\`.
- Doc impact : fiche feature \`$docs_root/features/$doc_feature_scope/<id>.md\` si comportement modifié ; $product_line

Prochaine action minimale :
- Si le cadrage est clair, créer ou mettre à jour la fiche feature ; sinon lancer \`bash .ai/scripts/aic.sh diagnose "$objective"\`.
EOF
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

  next_action="Travailler normalement ; avant commit, lance: bash .ai/scripts/aic.sh review"
  if [[ "$check_features" != "OK" ]]; then
    next_action="Corriger les frontmatter: bash .ai/scripts/check-features.sh"
  elif [[ "$check_shims" != "OK" ]]; then
    next_action="Réparer les shims: bash .ai/scripts/check-shims.sh"
  elif [[ "$check_product" != "OK" ]]; then
    next_action="Relire les liens produit: bash .ai/scripts/aic.sh product-status"
  elif [[ "$freshness" != "OK" ]]; then
    next_action="Mettre à jour/stager les fiches feature: bash .ai/scripts/check-feature-freshness.sh --staged --strict"
  elif [[ "$coverage" != "OK" ]]; then
    next_action="Relier les fichiers orphelins à des touches: bash .ai/scripts/check-feature-coverage.sh"
  elif [[ "$staged" -gt 0 ]]; then
    next_action="Relire le delta staged: bash .ai/scripts/aic.sh review --staged"
  elif [[ "$modified" -gt 0 ]]; then
    next_action="Stager les docs avec le code, puis lancer: bash .ai/scripts/aic.sh review"
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

run_diagnose() {
  cd "$repo_root"
  local symptom scope docs_scope
  symptom="$*"
  [[ -n "$symptom" ]] || symptom="blocage non précisé"

  scope="$(infer_scope_from_text "$symptom")"
  docs_scope=""
  if [[ "$scope" != "à confirmer" && -f ".ai/rules/$scope.md" ]]; then
    docs_scope="- \`.ai/rules/$scope.md\`"
  fi

  cat <<EOF
## AIC Diagnose

Symptôme :
- $symptom

Goulot probable :
- À confirmer par les données locales avant d'éditer.

Scope primaire probable :
- $scope

Docs à lire maintenant :
- \`.ai/index.md\`
$docs_scope

Features actives candidates :
EOF
  if [[ "$scope" != "à confirmer" ]]; then
    hints="$(print_active_feature_hints 6 "$scope")"
  else
    hints="$(print_active_feature_hints 6)"
  fi
  if [[ -n "$hints" ]]; then
    printf '%s\n' "$hints"
  else
    echo "- _(aucune feature active/draft détectée)_"
  fi
  cat <<'EOF'

Diagnostic initial :
- Vérifier si la demande est une feature, un bug, une dette, une doc drift ou un symptôme.
- Ne pas valider l'auto-diagnostic sans preuve locale.
- Si le vrai problème est documentaire, utiliser `document-feature`.
- Si le vrai problème est dans le delta, utiliser `review`.
- Si la sortie est proche, utiliser `ship`.

Questions de validation :
- Quel est le comportement observable attendu ?
- Quelle contrainte métier ou technique ne doit pas être cassée ?
- Quel test ou preuve rend la tâche terminée ?

Prochaine action minimale :
- Nommer le premier fichier ou la première fiche concernée, puis relancer `bash .ai/scripts/aic.sh document-feature <path>`.
EOF
}

run_document_feature() {
  cd "$repo_root"
  local target="${1:-}"
  if [[ -n "$target" ]]; then
    shift || true
    exec bash "$script_dir/features-for-path.sh" --with-docs "$target" "$@"
  fi

  cat <<'EOF'
## AIC Document Feature

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
    echo "- Git indisponible ; utiliser \`bash .ai/scripts/aic.sh document-feature <path>\` fichier par fichier."
  fi

  cat <<'EOF'

Prochaine action minimale :
- Mettre à jour puis stager la fiche feature ou son worklog pour chaque feature directe impactée.
EOF
}

run_repair() {
  cd "$repo_root"
  local apply="no"
  for arg in "$@"; do
    case "$arg" in
      --apply) apply="yes" ;;
      -h|--help)
        echo "Usage: bash .ai/scripts/aic.sh repair [--apply]"
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
- Lancer `bash .ai/scripts/aic.sh document-feature` pour vérifier la documentation du delta courant.
EOF
}

run_ship() {
  cd "$repo_root"
  local check_features check_shims check_product coverage freshness measure_total staged modified commit_hint staged_paths
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
  if inside_git_repo; then
    staged_paths="$(git diff --cached --name-only --no-renames 2>/dev/null || true)"
  else
    staged_paths=""
  fi
  if [[ -n "$staged_paths" ]] && ! printf '%s\n' "$staged_paths" | grep -Evq '^(README\.md|README_AI_CONTEXT\.md|CHANGELOG\.md|MIGRATION\.md|CONTRIBUTING\.md|PROJECT_STATE\.md|AUDIT_[^/]+\.md|docs/|\.docs/features/|template/README\.md\.jinja|template/README_AI_CONTEXT\.md\.jinja|template/\{\{docs_root\}\}/)'; then
    commit_hint="docs: mettre à jour la documentation ai context"
  fi

  cat <<EOF
## AIC Ship

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

run_repair_copier_metadata() {
  cd "$repo_root"
  local apply="no"
  local src_path="gh:qhuy/ai_context"
  local commit_ref="HEAD"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) apply="yes"; shift ;;
      --src-path) src_path="${2:?--src-path requiert une valeur}"; shift 2 ;;
      --commit|--vcs-ref) commit_ref="${2:?--commit requiert une valeur}"; shift 2 ;;
      -h|--help)
        echo "Usage: bash .ai/scripts/aic.sh repair-copier-metadata [--apply] [--src-path <src>] [--commit <ref>]"
        exit 0
        ;;
      *)
        echo "Argument inconnu: $1" >&2
        exit 2
        ;;
    esac
  done

  local answers_file="$repo_root/.copier-answers.yml"
  local status="absent"
  if [[ -f "$answers_file" ]]; then
    if grep -q '^_src_path:' "$answers_file" && grep -q '^_commit:' "$answers_file"; then
      status="complet"
    else
      status="incomplet"
    fi
  fi

  local tmp_answers
  tmp_answers="$(mktemp "${TMPDIR:-/tmp}/ai-context-copier-answers.XXXXXX.yml")"
  write_repaired_answers "$tmp_answers" "$src_path" "$commit_ref"

  cat <<EOF
## Copier Metadata Repair

État :
- .copier-answers.yml: $status
- src: $src_path
- commit/ref: $commit_ref
- apply: $apply

Metadata proposée :
\`\`\`yaml
EOF
  sed -n '1,120p' "$tmp_answers"
  cat <<'EOF'
```
EOF

  if [[ "$apply" == "yes" ]]; then
    if [[ "$status" == "complet" ]]; then
      echo
      echo "Aucune écriture : .copier-answers.yml contient déjà _src_path et _commit."
    else
      cp "$tmp_answers" "$answers_file"
      echo
      echo "Écrit : .copier-answers.yml"
    fi
  else
    cat <<'EOF'

Prochaine action minimale :
- Relire la metadata ci-dessus puis relancer avec `--apply` si elle correspond au scaffold réel.
- Ensuite tester sans downgrade : `copier update --vcs-ref=HEAD --dry-run` ou `bash .ai/scripts/aic.sh template-diff`.
EOF
  fi
  rm -f "$tmp_answers"
}

run_template_diff() {
  cd "$repo_root"
  local src_path="gh:qhuy/ai_context"
  local vcs_ref="HEAD"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --src-path) src_path="${2:?--src-path requiert une valeur}"; shift 2 ;;
      --vcs-ref|--commit) vcs_ref="${2:?--vcs-ref requiert une valeur}"; shift 2 ;;
      -h|--help)
        echo "Usage: bash .ai/scripts/aic.sh template-diff [--src-path <src>] [--vcs-ref <ref>]"
        exit 0
        ;;
      *)
        echo "Argument inconnu: $1" >&2
        exit 2
        ;;
    esac
  done

  if ! command -v copier >/dev/null 2>&1; then
    echo "copier introuvable. Installer Copier puis relancer: pipx install copier" >&2
    exit 127
  fi

  local render_dir answers_tmp copy_log project_name docs_root scope_profile adoption_mode
  render_dir="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-template-diff.XXXXXX")"
  answers_tmp="$(mktemp "${TMPDIR:-/tmp}/ai-context-template-data.XXXXXX.yml")"
  copy_log="$(mktemp "${TMPDIR:-/tmp}/ai-context-template-copy.XXXXXX.log")"
  project_name="$(infer_project_name)"
  docs_root="$(infer_docs_root)"
  scope_profile="$(infer_scope_profile)"
  adoption_mode="$(infer_adoption_mode)"
  write_repaired_answers "$answers_tmp" "$src_path" "$vcs_ref"

  if ! copier copy --defaults --trust --vcs-ref="$vcs_ref" \
      --data project_name="$project_name" \
      --data docs_root="$docs_root" \
      --data scope_profile="$scope_profile" \
      --data adoption_mode="$adoption_mode" \
      "$src_path" "$render_dir" >"$copy_log" 2>&1; then
    sed -n '1,120p' "$copy_log" >&2
    rm -rf "$render_dir" "$answers_tmp" "$copy_log"
    echo "Rendu template impossible depuis $src_path@$vcs_ref" >&2
    exit 1
  fi

  cat <<EOF
## Template Diff

Rendu externe :
- src: $src_path
- ref: $vcs_ref
- tmp: $render_dir
- repo courant modifié: non

Fichiers template différents ou absents :
EOF

  local found=0 rel
  while IFS= read -r rel; do
    [[ "$rel" == ".copier-answers.yml" ]] && continue
    if [[ ! -e "$repo_root/$rel" ]]; then
      echo "- ADD $rel"
      found=1
    elif ! diff -q "$render_dir/$rel" "$repo_root/$rel" >/dev/null 2>&1; then
      echo "- CHANGE $rel"
      found=1
    fi
  done < <(cd "$render_dir" && find . -type f | sed 's#^\./##' | sort)

  if [[ "$found" -eq 0 ]]; then
    echo "- Aucun écart détecté sur les fichiers rendus."
  fi

  cat <<EOF

Prochaine action minimale :
- Inspecter un fichier précis avec : diff -u "$repo_root/<path>" "$render_dir/<path>"
- Supprimer le rendu temporaire quand il n'est plus utile : rm -rf "$render_dir"
EOF

  rm -f "$answers_tmp" "$copy_log"
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
  frame)      run_frame "$@" ;;
  status)     run_status "$@" ;;
  diagnose)   run_diagnose "$@" ;;
  document-feature) run_document_feature "$@" ;;
  repair)     run_repair "$@" ;;
  repair-copier-metadata) run_repair_copier_metadata "$@" ;;
  template-diff) run_template_diff "$@" ;;
  ship)       run_ship "$@" ;;
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
  check-docs) exec bash "$script_dir/check-feature-docs.sh" "$@" ;;
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
