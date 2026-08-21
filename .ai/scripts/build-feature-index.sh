#!/bin/bash
# build-feature-index.sh — Compile le maillage features en JSON (ai_context).
#
# Scanne .docs/features/*/*.md et extrait pour chaque feature :
#   id, scope, status, touches[], touches_shared[], depends_on[], product{}, external_refs{}, path (relatif au repo).
#
# Parsing YAML :
#   - si `yq` (v4) est disponible → parsing propre du frontmatter
#   - sinon → fallback awk/sed (même logique que check-features.sh)
#
# Usage :
#   build-feature-index.sh           # écrit le JSON sur stdout
#   build-feature-index.sh --write   # écrit dans .ai/.feature-index.json (atomique, lock)
#
# Debug : AI_CONTEXT_DEBUG=1 bash build-feature-index.sh --write

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"

require_cmd jq

repo_root="$(cd "$script_dir/../.." && pwd)"
features_dir="$repo_root/$AI_CONTEXT_FEATURES_DIR"
index_file="$repo_root/.ai/.feature-index.json"
freshness_file="$repo_root/.ai/.feature-index.checked"

write=0
[[ "${1:-}" == "--write" ]] && write=1

# ─── Détection yq v4 ───
has_yq=0
if command -v yq >/dev/null 2>&1; then
  if yq --version 2>&1 | grep -qE 'v?4\.'; then
    has_yq=1
  fi
fi
log_debug "yq v4 disponible : $has_yq"

# Extrait le frontmatter YAML (entre la 1ère et la 2ème ligne ---)
extract_frontmatter() {
  awk '/^---$/{c++; next} c==1' "$1"
}

extract_list_awk_raw() {
  local file="$1" key="$2"
  # Borné au 1er bloc frontmatter (---...---) : ne lit JAMAIS le corps markdown
  # (sinon un `key:` dans le body injecte de fausses valeurs). Gère block-style
  # (- item) ET flow-style (key: [a, b]).
  # Limite connue (fallback sans yq) : le strip de commentaire inline ne respecte
  # pas les guillemets — une valeur comme "src/a #1.ts" serait tronquée à "src/a".
  # Accepté : ce parseur n'est utilisé que sans yq, et les valeurs réellement
  # consommées ici (touches/touches_shared/depends_on) ne contiennent pas de `#`
  # dans ce repo. Cf. tests/unit/test-build-feature-index-fallback-frontmatter.sh.
  awk -v k="^${key}:" '
    /^---$/ { fence++; next }
    fence != 1 { next }
    $0 ~ k {
      if ($0 ~ /\[.*\]/) {
        line=$0; sub(/^[^[]*\[/, "", line); sub(/\].*/, "", line)
        n=split(line, arr, ",")
        for (i=1; i<=n; i++) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[i]); if (arr[i] != "") print "- " arr[i] }
        flag=0; next
      }
      flag=1; next
    }
    flag && /^  *-/ {print; next}
    flag && /^[^[:space:]]/ {flag=0}
  ' "$file" \
    | sed -E 's/^[[:space:]]*-[[:space:]]*//' \
    | grep -vE '^$|^\[\]$' || true
}

extract_list_awk() {
  # Variante historique : strip agressif des quotes, réservé aux valeurs
  # techniques (touches/touches_shared/depends_on) sans quote légitime.
  extract_list_awk_raw "$@" \
    | sed -E 's/[[:space:]]+#.*$//; s/["'"'"']//g; s/[[:space:]]+$//' \
    | grep -vE '^$' || true
}

_sanitize_text_value_awk() {
  # Assainit une valeur de texte libre (title, keywords) issue du fallback awk.
  # Contrairement à extract_scalar_awk/extract_list_awk, ne supprime PAS les
  # quotes internes : « Conditions d'exposition » doit garder son apostrophe,
  # sinon la recherche par intention perd le mot. Retire uniquement les quotes
  # ENGLOBANTES ; le strip de commentaire inline (conforme YAML : espace + #)
  # ne s'applique qu'aux valeurs non quotées.
  # \047 = apostrophe, pour garder le script awk sans quote littérale.
  # Limite connue, alignée sur le reste du fallback : une valeur non quotée
  # contenant " #" est tronquée à cet endroit.
  awk '{
    line=$0
    sub(/^[[:space:]]+/, "", line)
    sub(/[[:space:]]+$/, "", line)
    if (line ~ /^".*"$/) {
      line = substr(line, 2, length(line) - 2)
    } else if (line ~ /^\047.*\047$/) {
      line = substr(line, 2, length(line) - 2)
    } else {
      sub(/[[:space:]]+#.*$/, "", line)
      sub(/[[:space:]]+$/, "", line)
    }
    print line
  }'
}

extract_text_scalar_awk() {
  local file="$1" key="$2"
  awk -v k="^${key}:" '
    /^---$/ { fence++; next }
    fence == 1 && $0 ~ k { sub(k, ""); print; exit }
    fence >= 2 { exit }
  ' "$file" | _sanitize_text_value_awk
}

extract_text_list_awk() {
  local file="$1" key="$2"
  extract_list_awk_raw "$file" "$key" | _sanitize_text_value_awk | grep -v '^$' || true
}

extract_scalar_awk() {
  local file="$1" key="$2"
  # Borné au 1er bloc frontmatter (---...---) : ne lit JAMAIS le corps markdown.
  # Même limite connue que extract_list_awk sur le strip de commentaire inline
  # (non quote-aware) ; sans risque ici, id/scope/status/type sont validés par
  # regex kebab-case/énum fermée après extraction (aucun `#` légitime possible).
  awk -v k="^${key}:" '
    /^---$/ { fence++; next }
    fence == 1 && $0 ~ k { sub(k, ""); print; exit }
    fence >= 2 { exit }
  ' "$file" \
    | sed -E 's/^[[:space:]]*//; s/[[:space:]]+#.*$//; s/["'"'"']//g; s/[[:space:]]+$//'
}

extract_product_portfolio_scalar_awk() {
  local file="$1" key="$2"
  awk -v key="$key" '
    /^---$/ { fence++; next }
    fence == 2 { exit }
    fence != 1 { next }
    /^product:[[:space:]]*$/ { in_product=1; next }
    in_product && /^[^[:space:]]/ { in_product=0; in_portfolio=0 }
    in_product && /^  portfolio:[[:space:]]*$/ { in_portfolio=1; next }
    in_portfolio && /^  [A-Za-z0-9_.-]+:/ { in_portfolio=0 }
    in_portfolio && $0 ~ ("^    " key ":[[:space:]]*") {
      line=$0
      sub("^    " key ":[[:space:]]*", "", line)
      print line
      exit
    }
  ' "$file" | sed -E 's/^[[:space:]]*//; s/^"//; s/"$//; s/^'\''//; s/'\''$//; s/[[:space:]]+$//'
}

feature_to_json() {
  local file="$1"
  local rel="${file#"$repo_root/"}"
  local folder_scope
  folder_scope=$(basename "$(dirname "$file")")

  local id scope status type touches_json touches_shared_json deps_json external_refs_json
  local title="" keywords_json="[]"
  local phase="" step="" blockers_json="[]" resume_hint="" updated=""
  local product_json="{}"
  external_refs_json="{}"

  if [[ $has_yq -eq 1 ]]; then
    local fm
    fm=$(extract_frontmatter "$file")
    # Un seul yq (validation + les 16 champs en un objet combiné) au lieu de
    # 16 forks séparés par fiche — mesuré : 1024 forks yq / 69 fiches, ~5s de
    # build (pilotage P11). L'échec de ce yq unique couvre aussi la validation
    # YAML : une fiche malformée est ignorée (warn + return 1) plutôt que de
    # faire planter tout l'index — et en cascade tous les hooks qui l'appellent.
    local combined
    if ! combined=$(printf '%s' "$fm" | yq -o=json -I=0 '{
        "id": (.id // ""),
        "scope": (.scope // ""),
        "title": (.title // ""),
        "status": (.status // ""),
        "type": (.type // ""),
        "phase": (.progress.phase // ""),
        "step": (.progress.step // ""),
        "resume_hint": (.progress.resume_hint // ""),
        "updated": (.progress.updated // ""),
        "touches": (.touches // []),
        "touches_shared": (.touches_shared // []),
        "depends_on": (.depends_on // []),
        "keywords": (.keywords // []),
        "product": (.product // {}),
        "external_refs": (.external_refs // {}),
        "blockers": (.progress.blockers // [])
      }' 2>/dev/null); then
      echo "⚠️  build-feature-index : frontmatter YAML illisible, fiche ignorée : $rel" >&2
      return 1
    fi
    # Un seul jq lit les 9 scalaires et projette keywords validé/normalisé.
    # Découpage par Record Separator (0x1e), non-blanc : contrairement à
    # `IFS=$'\t'`, Bash ne collapse pas deux séparateurs consécutifs, donc les
    # champs vides restent en place. `read -d` préserve aussi un saut de ligne
    # éventuel dans un titre. Le séparateur est généré au runtime pour ne pas
    # embarquer de caractère de contrôle littéral dans le fichier source.
    # Volontairement pas de découpage par tabulation `@tsv` :
    # bash `read` avec `IFS=$'\t'` COLLAPSE les tabulations consécutives même
    # sur un champ vide isolé (bug réel rencontré ici, tab reste classé
    # IFS-whitespace même seul dans IFS) — un `step` vide décalait tous les
    # champs suivants.
    local _lineno=0 _line _field_sep keywords_projection=""
    _field_sep=$(printf '\036')
    while IFS= read -r -d "$_field_sep" _line; do
      case "$_lineno" in
        0) id="$_line" ;;
        1) scope="$_line" ;;
        2) status="$_line" ;;
        3) type="$_line" ;;
        4) phase="$_line" ;;
        5) step="$_line" ;;
        6) resume_hint="$_line" ;;
        7) updated="$_line" ;;
        8) title="$_line" ;;
        9) keywords_projection="$_line" ;;
      esac
      _lineno=$((_lineno + 1))
    done < <(printf '%s' "$combined" | jq -jr '
      .id, "\u001e", .scope, "\u001e", .status, "\u001e", .type, "\u001e",
      .phase, "\u001e", .step, "\u001e", .resume_hint, "\u001e",
      .updated, "\u001e", .title, "\u001e",
      (if ((.keywords | type) == "array"
           and all(.keywords[]; if type == "string" then length > 0 else false end))
       then "1" + (.keywords | tojson)
       else "0" + ((
         if (.keywords | type) == "array"
         then [ .keywords[] | select(type == "string") | select(length > 0) ]
         else []
         end
       ) | tojson)
       end), "\u001e"
    ')
    # Les blobs JSON restent des forks jq séparés, mais sur $combined déjà
    # parsé par yq (pas sur le YAML brut) : simple et correct, sans risque de
    # découpage fragile sur du contenu structuré imbriqué.
    touches_json=$(printf '%s' "$combined" | jq -c '.touches')
    touches_shared_json=$(printf '%s' "$combined" | jq -c '.touches_shared')
    deps_json=$(printf '%s' "$combined" | jq -c '.depends_on')
    # Le premier caractère porte la validité, le reste le tableau JSON.
    # La projection partage le jq des scalaires : aucun fork par fiche ajouté.
    if [[ "${keywords_projection:0:1}" != "1" ]]; then
      echo "⚠️  build-feature-index : keywords invalide (tableau de chaînes non vides attendu), normalisé : $rel" >&2
    fi
    keywords_json="${keywords_projection:1}"
    product_json=$(printf '%s' "$combined" | jq -c '.product')
    external_refs_json=$(printf '%s' "$combined" | jq -c '.external_refs')
    blockers_json=$(printf '%s' "$combined" | jq -c '.blockers')
  else
    id=$(extract_scalar_awk "$file" "id")
    scope=$(extract_scalar_awk "$file" "scope")
    title=$(extract_text_scalar_awk "$file" "title")
    status=$(extract_scalar_awk "$file" "status")
    type=$(extract_scalar_awk "$file" "type")
    touches_json=$(extract_list_awk "$file" "touches" | jq -R . | jq -s .)
    touches_shared_json=$(extract_list_awk "$file" "touches_shared" | jq -R . | jq -s .)
    deps_json=$(extract_list_awk "$file" "depends_on" | jq -R . | jq -s .)
    keywords_inline=$(extract_text_scalar_awk "$file" "keywords")
    if [[ -n "$keywords_inline" && ! "$keywords_inline" =~ ^\[.*\]$ ]] \
      || printf '%s' "$keywords_inline" \
        | grep -Eq '(^|\[|,)[[:space:]]*(-?[0-9]+([.][0-9]+)?|true|false|null|~)[[:space:]]*(,|\])'; then
      echo "⚠️  build-feature-index : keywords invalide (tableau de chaînes non vides attendu), normalisé : $rel" >&2
    fi
    keywords_json=$(extract_text_list_awk "$file" "keywords" | jq -R . | jq -s .)
    external_refs_raw=$(awk '
      /^---$/{fence++; next}
      fence!=1{next}
      /^external_refs:/{flag=1; next}
      flag && /^  [A-Za-z0-9_.-]+:/{print; next}
      flag && /^[^[:space:]]/{flag=0}
    ' "$file" | sed -E 's/^[[:space:]]*//; s/[[:space:]]+$//')
    if [[ -n "$external_refs_raw" ]]; then
      external_refs_json=$(printf '%s\n' "$external_refs_raw" | awk '
        /^[A-Za-z0-9_.-]+:/ {
          key=$0
          sub(/:.*/, "", key)
          val=$0
          sub(/^[^:]+:[[:space:]]*/, "", val)
          gsub(/^"|"$/, "", val)
          if (val != "") print key "\t" val
        }
      ' | jq -Rn '
        reduce inputs as $line ({};
          ($line | split("\t")) as $p
          | if ($p|length) >= 2 then . + {($p[0]): $p[1]} else . end
        )')
    fi
    product_type=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  type:/{sub(/^  type:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_initiative=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  initiative:/{sub(/^  initiative:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_contribution=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  contribution:/{sub(/^  contribution:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_evidence=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  evidence:/{sub(/^  evidence:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_bet=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  bet:/{sub(/^  bet:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_target_user=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  target_user:/{sub(/^  target_user:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_success_metric=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  success_metric:/{sub(/^  success_metric:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_leading_indicator=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  leading_indicator:/{sub(/^  leading_indicator:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_decision_state=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  decision_state:/{sub(/^  decision_state:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_next_decision_date=$(awk '/^---$/{fence++; next} fence!=1{next} /^product:/{flag=1; next} flag && /^  next_decision_date:/{sub(/^  next_decision_date:[[:space:]]*/, ""); print; exit} flag && /^[^[:space:]]/{flag=0}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    product_portfolio_appetite=$(extract_product_portfolio_scalar_awk "$file" "appetite")
    product_portfolio_confidence=$(extract_product_portfolio_scalar_awk "$file" "confidence")
    product_portfolio_expected_impact=$(extract_product_portfolio_scalar_awk "$file" "expected_impact")
    product_portfolio_urgency=$(extract_product_portfolio_scalar_awk "$file" "urgency")
    product_portfolio_strategic_fit=$(extract_product_portfolio_scalar_awk "$file" "strategic_fit")
    product_portfolio_json=$(jq -n \
      --arg appetite "$product_portfolio_appetite" \
      --arg confidence "$product_portfolio_confidence" \
      --arg expected_impact "$product_portfolio_expected_impact" \
      --arg urgency "$product_portfolio_urgency" \
      --arg strategic_fit "$product_portfolio_strategic_fit" \
      '{
        appetite: $appetite, confidence: $confidence, expected_impact: $expected_impact,
        urgency: $urgency, strategic_fit: $strategic_fit
      } | with_entries(select(.value != ""))')
    product_json=$(jq -n \
      --arg type "$product_type" \
      --arg initiative "$product_initiative" \
      --arg contribution "$product_contribution" \
      --arg evidence "$product_evidence" \
      --arg bet "$product_bet" \
      --arg target_user "$product_target_user" \
      --arg success_metric "$product_success_metric" \
      --arg leading_indicator "$product_leading_indicator" \
      --arg decision_state "$product_decision_state" \
      --arg next_decision_date "$product_next_decision_date" \
      --argjson portfolio "$product_portfolio_json" \
      '{
        type: $type, initiative: $initiative, contribution: $contribution, evidence: $evidence,
        bet: $bet, target_user: $target_user, success_metric: $success_metric,
        leading_indicator: $leading_indicator, decision_state: $decision_state,
        next_decision_date: $next_decision_date, portfolio: $portfolio
      } | with_entries(select(if (.value | type) == "object" then (.value | length) > 0 else .value != "" end))')
    # progress.* : parsing best-effort en fallback awk (yq recommandé pour précision)
    phase=$(awk '/^---$/{fence++; next} fence!=1{next} /^progress:/{flag=1; next} flag && /^  phase:/{sub(/^  phase:[[:space:]]*/, ""); print; exit}' "$file" | sed -E 's/["'"'"']//g; s/[[:space:]]+$//')
    step=$(awk '/^---$/{fence++; next} fence!=1{next} /^progress:/{flag=1; next} flag && /^  step:/{sub(/^  step:[[:space:]]*/, ""); print; exit}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    resume_hint=$(awk '/^---$/{fence++; next} fence!=1{next} /^progress:/{flag=1; next} flag && /^  resume_hint:/{sub(/^  resume_hint:[[:space:]]*/, ""); print; exit}' "$file" | sed -E 's/^"//; s/"$//; s/[[:space:]]+$//')
    updated=$(awk '/^---$/{fence++; next} fence!=1{next} /^progress:/{flag=1; next} flag && /^  updated:/{sub(/^  updated:[[:space:]]*/, ""); print; exit}' "$file" | sed -E 's/["'"'"']//g; s/[[:space:]]+$//')
    # progress.blockers : liste sous progress:, items indentés de 4 espaces
    blockers_raw=$(awk '
      /^---$/{fence++; next}
      fence!=1{next}
      /^progress:/{flag=1; next}
      flag && /^  blockers:/{bf=1; next}
      bf && /^    -/{print; next}
      bf && /^  [^ ]/{bf=0}
      flag && /^[^[:space:]]/{flag=0}
    ' "$file" | sed -E 's/^[[:space:]]*-[[:space:]]*//; s/^"//; s/"$//; s/[[:space:]]+$//' | awk 'NF')
    if [[ -n "$blockers_raw" ]]; then
      blockers_json=$(printf '%s\n' "$blockers_raw" | jq -R . | jq -s .)
    else
      blockers_json="[]"
    fi
  fi

  [[ -z "$id" ]] && id=$(basename "$file" .md)
  [[ -z "$scope" ]] && scope="$folder_scope"
  [[ -z "$status" ]] && status="?"

  if [[ ! "$id" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "⚠️  $rel : id='$id' invalide, fiche exclue de l'index" >&2
    return 0
  fi
  if [[ ! "$scope" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    echo "⚠️  $rel : scope='$scope' invalide, fiche exclue de l'index" >&2
    return 0
  fi

  if [[ "$status" != "?" ]] && ! is_valid_status "$status"; then
    echo "⚠️  $rel : status='$status' hors enum ($STATUS_ENUM)" >&2
  fi

  # Profil strict OKF : type par défaut 'feature' si la fiche ne le déclare pas
  # (lecture tolérante pendant la fenêtre de grâce vN ; ajout additif au contrat d'index).
  [[ -z "$type" ]] && type="feature"

  jq -n \
    --arg id "$id" \
    --arg scope "$scope" \
    --arg status "$status" \
    --arg type "$type" \
    --arg title "$title" \
    --arg path "$rel" \
    --argjson touches "$touches_json" \
    --argjson touches_shared "$touches_shared_json" \
    --argjson depends_on "$deps_json" \
    --argjson keywords "$keywords_json" \
    --argjson product "$product_json" \
    --argjson external_refs "$external_refs_json" \
    --arg phase "$phase" \
    --arg step "$step" \
    --argjson blockers "$blockers_json" \
    --arg resume_hint "$resume_hint" \
    --arg updated "$updated" \
    '{
      id: $id, scope: $scope, title: $title, status: $status, type: $type, path: $path,
      touches: $touches, touches_shared: $touches_shared, depends_on: $depends_on,
      keywords: $keywords,
      product: $product, external_refs: $external_refs,
      progress: {
        phase: $phase, step: $step, blockers: $blockers,
        resume_hint: $resume_hint, updated: $updated
      }
    }'
}

# ─── Construction de l'index ───
start_ts=$(date +%s 2>/dev/null || echo 0)
features_json="[]"
count=0
if [[ -d "$features_dir" ]]; then
  files=()
  entries=()
  # find -print0 pour supporter les noms avec espaces/caractères spéciaux
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find_feature_docs "$features_dir")

  # Ordre contractuel stable. Le tri newline-based couvre les chemins usuels
  # du repo, espaces inclus ; les retours ligne dans les noms de fichiers ne
  # sont pas un format supporté par le feature mesh.
  if [[ ${#files[@]} -gt 0 ]]; then
    while IFS= read -r f; do
      # Isolation par fiche : une fiche illisible (return 1 + warn dans
      # feature_to_json) est ignorée sans aborter tout l'index (set -e).
      if entry="$(feature_to_json "$f")"; then
        entries+=("$entry")
        count=$((count + 1))
      fi
    done < <(printf '%s\n' "${files[@]}" | LC_ALL=C sort)
  fi

  if [[ ${#entries[@]} -gt 0 ]]; then
    features_json=$(printf '%s\n' "${entries[@]}" | jq -s .)
  fi
fi

generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
config_file="$repo_root/.ai/config.yml"
project_id="$(read_config 'project_id' "$(basename "$repo_root")" "$config_file")"

# schema_version: contrat stable du JSON émis (élément 5 du contrat public v1.0).
# Politique SemVer, dans les deux sens :
#   - breaking (renommer/supprimer un champ, changer la sémantique d'un type)
#     -> MAJOR côté template ET bump de schema_version ici ;
#   - ajout rétro-compatible d'un champ -> MINOR, SANS bump.
# Le snapshot de clés de tests/unit/test-build-feature-index-contract.sh applique
# cette politique : il échoue sur tout changement de clés pour forcer la décision,
# sans présumer laquelle des deux branches s'applique.
output=$(jq -n \
  --arg schema_version "1" \
  --arg project_id "$project_id" \
  --arg generated_at "$generated_at" \
  --argjson features "$features_json" \
  '{schema_version: $schema_version, project_id: $project_id, generated_at: $generated_at, features: $features}')

log_debug "features scannées : $count"

write_index() {
  mkdir -p "$(dirname "$index_file")"
  if [[ -f "$index_file" ]]; then
    local existing_contract output_contract
    existing_contract=$(jq -S 'del(.generated_at)' "$index_file" 2>/dev/null || true)
    output_contract=$(printf '%s\n' "$output" | jq -S 'del(.generated_at)' 2>/dev/null || true)
    if [[ -n "$existing_contract" && "$existing_contract" == "$output_contract" ]]; then
      touch "$freshness_file"
      log_debug "index inchangé : $index_file"
      log_debug "scan index validé : $freshness_file"
      return 0
    fi
  fi
  local tmp
  tmp=$(mktemp "${index_file}.XXXXXX")
  printf '%s\n' "$output" > "$tmp"
  mv "$tmp" "$index_file"
  touch "$freshness_file"
  log_debug "index écrit : $index_file"
  log_debug "scan index validé : $freshness_file"
}

if [[ $write -eq 1 ]]; then
  with_index_lock write_index
else
  printf '%s\n' "$output"
fi
