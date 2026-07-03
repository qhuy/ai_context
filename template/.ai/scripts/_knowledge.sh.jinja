#!/bin/bash
# _knowledge.sh — Helpers du contrat knowledge source.

KNOWLEDGE_SCHEMA_VERSION="1"
KNOWLEDGE_CONFIDENCE_ENUM="low medium high"
KNOWLEDGE_SENSITIVITY_ENUM="public internal restricted"
KNOWLEDGE_STATUS_ENUM="draft published deprecated retracted"
KNOWLEDGE_FRESHNESS_STATUS_ENUM="verified stale unknown"

knowledge_strip_scalar() {
  sed -E \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]+#.*$//' \
    -e 's/[[:space:]]*$//' \
    -e 's/^"//' \
    -e 's/"$//' \
    -e "s/^'//" \
    -e "s/'$//"
}

knowledge_frontmatter() {
  awk '/^---$/{c++; next} c==1' "$1"
}

knowledge_fm_scalar() {
  local file="$1"
  local key="$2"
  awk -v k="^${key}:[[:space:]]*" '
    /^---$/ { fence++; next }
    fence == 1 && $0 ~ k {
      line=$0
      sub(k, "", line)
      print line
      exit
    }
    fence >= 2 { exit }
  ' "$file" | knowledge_strip_scalar
}

knowledge_fm_nested_scalar() {
  local file="$1"
  local parent="$2"
  local key="$3"
  awk -v parent="^${parent}:[[:space:]]*$" -v key="^[[:space:]]+${key}:[[:space:]]*" '
    /^---$/ { fence++; next }
    fence != 1 { next }
    $0 ~ parent { in_parent=1; next }
    in_parent && /^[^[:space:]]/ { in_parent=0 }
    in_parent && $0 ~ key {
      line=$0
      sub(key, "", line)
      print line
      exit
    }
  ' "$file" | knowledge_strip_scalar
}

knowledge_fm_list() {
  local file="$1"
  local key="$2"
  awk -v k="^${key}:" '
    /^---$/ { fence++; next }
    fence != 1 { next }
    $0 ~ k {
      if ($0 ~ /\[.*\]/) {
        line=$0
        sub(/^[^[]*\[/, "", line)
        sub(/[[:space:]]*#.*$/, "", line)
        sub(/\][[:space:]]*$/, "", line)
        n=split(line, arr, ",")
        for (i=1; i<=n; i++) {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[i])
          if (arr[i] != "") print "- " arr[i]
        }
        flag=0
        next
      }
      flag=1
      next
    }
    flag && /^[[:space:]]*-/ { print; next }
    flag && /^[^[:space:]]/ { flag=0 }
  ' "$file" \
    | sed -E 's/^[[:space:]]*-[[:space:]]*//; s/^"//; s/"$//; s/^'\''//; s/'\''$//; s/[[:space:]]+$//' \
    | grep -vE '^$|^\[\]$' || true
}

knowledge_find_files() {
  local hub_root="$1"
  local knowledge_dir="$hub_root/knowledge"
  [[ -d "$knowledge_dir" ]] || return 0
  find "$knowledge_dir" -mindepth 2 -maxdepth 2 -type f -name '*.md' | LC_ALL=C sort
}

knowledge_in_enum() {
  local value="$1"
  local enum="$2"
  case " $enum " in
    *" $value "*) return 0 ;;
    *) return 1 ;;
  esac
}

knowledge_rel_path() {
  local file="$1"
  local hub_root="$2"
  local rel="${file#"$hub_root"/}"
  printf '%s\n' "$rel"
}

knowledge_validate_file() {
  local file="$1"
  local hub_root="$2"
  local rel source_dir filename file_id
  local fail=0

  rel="$(knowledge_rel_path "$file" "$hub_root")"
  if [[ "$rel" =~ ^knowledge/([^/]+)/([^/]+)\.md$ ]]; then
    source_dir="${BASH_REMATCH[1]}"
    filename="${BASH_REMATCH[2]}"
  else
    echo "$rel : path attendu knowledge/<source_project>/<id>.md"
    return 1
  fi

  if [[ -z "$(knowledge_frontmatter "$file")" ]]; then
    echo "$rel : frontmatter YAML manquant"
    return 1
  fi

  if command -v yq >/dev/null 2>&1; then
    if ! knowledge_frontmatter "$file" | yq -e -o=json '.' >/dev/null 2>&1; then
      echo "$rel : frontmatter YAML invalide"
      return 1
    fi
  fi

  local id type title summary source_project owner confidence checked_at sensitivity status
  id="$(knowledge_fm_scalar "$file" id)"
  type="$(knowledge_fm_scalar "$file" type)"
  title="$(knowledge_fm_scalar "$file" title)"
  summary="$(knowledge_fm_scalar "$file" summary)"
  source_project="$(knowledge_fm_scalar "$file" source_project)"
  owner="$(knowledge_fm_scalar "$file" owner)"
  confidence="$(knowledge_fm_scalar "$file" confidence)"
  checked_at="$(knowledge_fm_nested_scalar "$file" freshness checked_at)"
  sensitivity="$(knowledge_fm_scalar "$file" sensitivity)"
  status="$(knowledge_fm_scalar "$file" status)"

  for key in id type title summary source_project owner confidence sensitivity status; do
    local value
    value="$(knowledge_fm_scalar "$file" "$key")"
    if [[ -z "$value" ]]; then
      echo "$rel : champ obligatoire '$key' manquant"
      fail=1
    fi
  done

  if [[ -z "$checked_at" ]]; then
    echo "$rel : champ obligatoire 'freshness.checked_at' manquant"
    fail=1
  fi

  if [[ -z "$(knowledge_fm_list "$file" source_refs)" ]]; then
    echo "$rel : liste obligatoire 'source_refs' vide ou manquante"
    fail=1
  fi
  if [[ -z "$(knowledge_fm_list "$file" usable_by)" ]]; then
    echo "$rel : liste obligatoire 'usable_by' vide ou manquante"
    fail=1
  fi

  if [[ -n "$id" && ! "$id" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "$rel : id='$id' invalide (kebab-case attendu)"
    fail=1
  fi
  if [[ -n "$type" && ! "$type" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "$rel : type='$type' invalide (snake_case attendu)"
    fail=1
  fi
  if [[ -n "$source_project" && ! "$source_project" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "$rel : source_project='$source_project' invalide (kebab-case attendu)"
    fail=1
  fi
  if [[ -n "$confidence" ]] && ! knowledge_in_enum "$confidence" "$KNOWLEDGE_CONFIDENCE_ENUM"; then
    echo "$rel : confidence='$confidence' hors enum ($KNOWLEDGE_CONFIDENCE_ENUM)"
    fail=1
  fi
  if [[ -n "$sensitivity" ]] && ! knowledge_in_enum "$sensitivity" "$KNOWLEDGE_SENSITIVITY_ENUM"; then
    echo "$rel : sensitivity='$sensitivity' hors enum ($KNOWLEDGE_SENSITIVITY_ENUM)"
    fail=1
  fi
  if [[ -n "$status" ]] && ! knowledge_in_enum "$status" "$KNOWLEDGE_STATUS_ENUM"; then
    echo "$rel : status='$status' hors enum ($KNOWLEDGE_STATUS_ENUM)"
    fail=1
  fi
  if [[ -n "$checked_at" && ! "$checked_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "$rel : freshness.checked_at='$checked_at' invalide (YYYY-MM-DD attendu)"
    fail=1
  fi

  local freshness_status
  freshness_status="$(knowledge_fm_nested_scalar "$file" freshness status)"
  if [[ -n "$freshness_status" ]] && ! knowledge_in_enum "$freshness_status" "$KNOWLEDGE_FRESHNESS_STATUS_ENUM"; then
    echo "$rel : freshness.status='$freshness_status' hors enum ($KNOWLEDGE_FRESHNESS_STATUS_ENUM)"
    fail=1
  fi

  if [[ -n "$id" && "$filename" != "$id" ]]; then
    echo "$rel : nom de fichier '$filename' different de id='$id'"
    fail=1
  fi
  if [[ -n "$source_project" && "$source_dir" != "$source_project" ]]; then
    echo "$rel : dossier source '$source_dir' different de source_project='$source_project'"
    fail=1
  fi

  file_id="$source_project/$id"
  if [[ "$file_id" == "/" ]]; then
    fail=1
  fi

  return "$fail"
}
