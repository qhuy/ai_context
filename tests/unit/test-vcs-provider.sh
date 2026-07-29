#!/bin/bash
# Non-regression: abstraction VCS Git/TFVC.

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

# shellcheck source=../../.ai/scripts/_vcs.sh
. "$repo_root/.ai/scripts/_vcs.sh"

tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'vcs-provider-test')
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

workspace="$tmp_dir/workspace"
fake_bin="$tmp_dir/bin"
mkdir -p "$workspace/.ai" "$workspace/src" "$workspace/docs" "$fake_bin"
printf '# test index\n' > "$workspace/.ai/index.md"
printf 'content\n' > "$workspace/src/app.cs"
printf 'content\n' > "$workspace/docs/feature spec.md"

cat > "$fake_bin/tf" <<'FAKE_TF'
#!/bin/sh
case "$1" in
  status)
    root="$AI_CONTEXT_FAKE_TFVC_ROOT"
    cat <<EOF
$/Project/src/app.cs
  Change: edit
  Local item: $root/src/app.cs

$/Project/docs/feature spec.md
  Change: add
  Local item: $root/docs/feature spec.md
EOF
    ;;
  *) exit 1 ;;
esac
FAKE_TF
chmod +x "$fake_bin/tf"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

PATH="$fake_bin:$PATH"
export PATH
export AI_CONTEXT_REPO_ROOT="$workspace"
export AI_CONTEXT_FAKE_TFVC_ROOT="$workspace"

cd "$workspace" || exit 1

unset AI_CONTEXT_VCS_PROVIDER
cat > .ai/config.yml <<'YAML'
vcs:
  provider: tfvc
YAML

if [[ "$(vcs_provider)" == "tfvc" ]]; then
  pass "config.yml selectionne tfvc"
else
  fail "provider attendu=tfvc, obtenu=$(vcs_provider)"
fi

if [[ "$(vcs_root)" == "$workspace" ]]; then
  pass "racine TFVC resolue"
else
  fail "racine TFVC incorrecte: $(vcs_root)"
fi

if vcs_has_staging_area; then
  fail "tfvc ne doit pas declarer de staging area"
else
  pass "tfvc sans staging area"
fi

pending="$(vcs_pending_paths)"
if printf '%s\n' "$pending" | grep -Fxq "src/app.cs"; then
  pass "pending TFVC: fichier code"
else
  fail "src/app.cs absent des pending: $pending"
fi

if printf '%s\n' "$pending" | grep -Fxq "docs/feature spec.md"; then
  pass "pending TFVC: chemin avec espace"
else
  fail "docs/feature spec.md absent des pending: $pending"
fi

staged="$(vcs_staged_paths)"
if [[ "$staged" == "$pending" && "$(vcs_staged_label)" == "pending" ]]; then
  pass "staged alias pending en TFVC"
else
  fail "alias staged TFVC incorrect: label=$(vcs_staged_label), staged=$staged"
fi

export AI_CONTEXT_VCS_PROVIDER=none
if [[ "$(vcs_provider)" == "none" && -z "$(vcs_pending_paths)" ]]; then
  pass "provider none silencieux"
else
  fail "provider none devrait etre silencieux"
fi

# ─── Locale : le parseur ne doit PAS dépendre de libellés anglais ───
# Le client TEE est traduit selon la locale (celui du mainteneur est en FR).
# Matcher `Local item:` renverrait zéro chemin sur un client FR -> aucun touches:
# ne matcherait -> gate de fraîcheur PASSANT au lieu de bloquant (fail-open).
# La détection est donc structurelle : chemin absolu se relativisant sous la racine.
loc_ws="$tmp_dir/locale-ws"
mkdir -p "$loc_ws/src"
loc_tf="$tmp_dir/locale-bin"
mkdir -p "$loc_tf"

make_fake_tf() {
  cat > "$loc_tf/tf" <<EOF
#!/bin/sh
[ "\$1" = status ] || exit 1
cat <<'TFOUT'
$1
TFOUT
EOF
  chmod +x "$loc_tf/tf"
}

run_pending() {
  ( cd "$loc_ws" && PATH="$loc_tf:$PATH" AI_CONTEXT_REPO_ROOT="$loc_ws" \
      AI_CONTEXT_VCS_PROVIDER=tfvc bash -c ". '$repo_root/.ai/scripts/_vcs.sh'; vcs_pending_paths" )
}

make_fake_tf "\$/Projet/src/app.cs
  Change: edit
  Local item: $loc_ws/src/app.cs"
if [[ "$(run_pending)" == "src/app.cs" ]]; then
  pass "pending changes détectés avec libellés EN"
else
  fail "libellés EN : attendu src/app.cs, obtenu '$(run_pending)'"
fi

make_fake_tf "\$/Projet/src/app.cs
  Modification : modifier
  Élément local : $loc_ws/src/app.cs
  Verrou : aucun"
if [[ "$(run_pending)" == "src/app.cs" ]]; then
  pass "pending changes détectés avec libellés FR (locale-agnostique)"
else
  fail "libellés FR : attendu src/app.cs, obtenu '$(run_pending)' — fail-open sur client traduit"
fi

make_fake_tf "\$/Projet/autre/x.cs
  Local item: /ailleurs/hors-workspace/x.cs
  Utilisateur : Huy
  Verrou : aucun
  Date : 2026-07-28"
if [[ -z "$(run_pending)" ]]; then
  pass "aucun faux positif (hors workspace, valeurs non-chemin, chemin serveur)"
else
  fail "faux positif : '$(run_pending)' ne devrait rien produire"
fi

# ─── Régression : normalisation des chemins (fail-open TFVC, trouvé par l'E2E) ───
# `_vcs_normalize_path` collapsait les slashes répétés via une substitution bash
# qui INSÉRAIT un backslash littéral (`/a/b//c` -> `/a/b\/c`). Conséquence : la
# relativisation échouait, `vcs_pending_paths` renvoyait un chemin ABSOLU, aucun
# `touches:` ne matchait, et `check-feature-freshness --staged --strict` PASSAIT
# au lieu de bloquer — un fail-open silencieux du gate cœur en TFVC.
norm_cases="
/a/b/proj|/a/b//proj/src/x.cs|src/x.cs
/a/b//proj|/a/b/proj/src/x.cs|src/x.cs
/a/b/proj|/a/b///proj/src/x.cs|src/x.cs
/a/b/proj|\\a\\b\\proj\\src\\x.cs|src/x.cs
/a/b/proj|/a/b/proj/src/x.cs|src/x.cs
"
# NB : process substitution et non pipe — un `... | while` tourne dans un
# sous-shell et perdrait les incréments de $failures (le test afficherait FAIL
# mais sortirait 0, donc ne gaterait rien).
while IFS='|' read -r nroot npath nexp; do
  [[ -n "$nroot" ]] || continue
  ngot="$(_vcs_relativize_path "$nroot" "$npath")"
  if [[ "$ngot" == "$nexp" ]]; then
    pass "relativize($nroot, $npath) = $nexp"
  else
    fail "relativize($nroot, $npath) = '$ngot' au lieu de '$nexp' (fail-open possible)"
  fi
  case "$ngot" in
    *'\\'*) fail "relativize a produit un backslash littéral : $ngot" ;;
    /*) fail "relativize a renvoyé un chemin absolu ($ngot) : aucun touches: ne matcherait" ;;
  esac
done < <(printf '%s\n' "$norm_cases")

if [[ "$failures" -gt 0 ]]; then
  echo "$failures échec(s)" >&2
  exit 1
fi

echo "OK"
