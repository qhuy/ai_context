#!/bin/bash
# test-tfvc-e2e.sh — core/vcs-provider-abstraction.
#
# Chantier B4 du gel v1.0 : jusqu'ici `vcs_provider=tfvc` n'était exercé qu'au
# niveau de `_vcs.sh` en isolation (test-vcs-provider.sh, faux binaire `tf`),
# ce que copier.yml avouait lui-même — « best-effort, non testé end-to-end ».
# TFVC étant le provider principal de l'organisation utilisatrice, ce test
# ferme l'écart : scaffold Copier réel + pending change réel + CHAÎNE
# D'ENFORCEMENT complète, pas seulement le parsing de `tf status`.
#
# Ce qui est vérifié :
#   1. scaffold tfvc : pas de .githooks (contrat de la matrice de capacités) ;
#   2. doctor : passe et annonce le provider tfvc ;
#   3. review : rapporte le pending change TFVC ;
#   4. check-feature-freshness --staged --strict BLOQUE quand du code couvert
#      change sans sa fiche/worklog — le gate cœur, via pending changes ;
#   5. le même gate PASSE quand la fiche et le worklog sont dans le pending set.
#
# Non couvert ici (gate mainteneur, hors CI) : le `tf` réel de l'organisation,
# sa version et sa langue. Voir la fiche core/vcs-provider-abstraction.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

command -v copier >/dev/null 2>&1 || { echo "⏭️  test-tfvc-e2e SKIP (copier absent)"; exit 0; }
command -v jq >/dev/null 2>&1 || { echo "⏭️  test-tfvc-e2e SKIP (jq absent)"; exit 0; }

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-tfvc-e2e.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $1"; exit 1; }

src="$tmp/src"
out="$tmp/proj"
fake_bin="$tmp/bin"
mkdir -p "$fake_bin"

# Copier rend depuis HEAD quand la source est un repo git : on passe par une
# copie rsync pour tester le WORKING TREE (même raison que $SRC dans smoke-test).
rsync -a --exclude='.git' "$repo_root/" "$src/"

copier copy --defaults --trust \
  --data project_name=tfvc-e2e \
  --data vcs_provider=tfvc \
  --data scope_profile=backend \
  "$src" "$out" >"$tmp/copy.log" 2>&1 \
  || { sed -n '1,40p' "$tmp/copy.log"; fail "scaffold vcs_provider=tfvc échoué"; }

# ─── 1. Matrice de capacités : pas de git hooks en TFVC ───
[[ ! -d "$out/.githooks" ]] \
  || fail ".githooks rendu alors que vcs_provider=tfvc (contrat de la matrice)"
[[ -f "$out/.ai/scripts/_vcs.sh" ]] \
  || fail "_vcs.sh absent du scaffold tfvc"
grep -q 'provider: "tfvc"' "$out/.ai/config.yml" \
  || grep -q 'vcs_provider: tfvc' "$out/.copier-answers.yml" \
  || fail "provider tfvc non persisté dans la config du scaffold"
echo "  ✓ scaffold tfvc : pas de .githooks, provider persisté"

# ─── Faux `tf` : rapporte un pending change piloté par un fichier de contrôle ───
# Le format imite `tf status /format:detailed` (« Local item: <chemin absolu »),
# seul contrat que _vcs_tfvc_pending_paths sait lire.
cat > "$fake_bin/tf" <<'FAKE_TF'
#!/bin/sh
case "$1" in
  status)
    root="$AI_CONTEXT_FAKE_TFVC_ROOT"
    list="$AI_CONTEXT_FAKE_TFVC_PENDING"
    [ -f "$list" ] || exit 0
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      printf '$/Project/%s\n' "$rel"
      printf '  Change: edit\n'
      printf '  Local item: %s/%s\n\n' "$root" "$rel"
    done < "$list"
    ;;
  *) exit 1 ;;
esac
FAKE_TF
chmod +x "$fake_bin/tf"

pending_list="$tmp/pending.txt"
export PATH="$fake_bin:$PATH"
export AI_CONTEXT_FAKE_TFVC_ROOT="$out"
export AI_CONTEXT_FAKE_TFVC_PENDING="$pending_list"

# Une feature qui couvre src/service.cs, pour que le gate ait quelque chose à exiger.
mkdir -p "$out/.docs/features/back" "$out/src"
cat > "$out/.docs/features/back/service.md" <<'FEAT'
---
id: service
scope: back
title: Service métier
status: active
type: feature
depends_on: []
touches:
  - src/service.cs
---

# Service métier

## Résumé
Feature de test pour le gate de fraîcheur en TFVC.
FEAT
printf '# worklog\n' > "$out/.docs/features/back/service.worklog.md"
printf '// code\n' > "$out/src/service.cs"
( cd "$out" && bash .ai/scripts/build-feature-index.sh --write >/dev/null 2>&1 )

# ─── 2. doctor : passe et voit le provider tfvc ───
doctor_out="$( cd "$out" && bash .ai/scripts/doctor.sh 2>&1 )" \
  || { printf '%s\n' "$doctor_out"; fail "doctor échoue sur un scaffold tfvc sain"; }
printf '%s' "$doctor_out" | grep -qi "tfvc" \
  || { printf '%s\n' "$doctor_out"; fail "doctor n'annonce pas le provider tfvc"; }
echo "  ✓ doctor : PASS et provider tfvc détecté"

# ─── 3. review : rapporte le pending change TFVC ───
printf 'src/service.cs\n' > "$pending_list"
review_out="$( cd "$out" && bash .ai/scripts/review-delta.sh 2>&1 || true )"
printf '%s' "$review_out" | grep -q "src/service.cs" \
  || { printf '%s\n' "$review_out"; fail "review-delta ne voit pas le pending change TFVC"; }
echo "  ✓ review : pending change TFVC visible dans le rapport"

# ─── 4. Le gate de fraîcheur BLOQUE : code couvert sans fiche/worklog ───
if ( cd "$out" && bash .ai/scripts/check-feature-freshness.sh --staged --strict ) >"$tmp/fresh1.log" 2>&1; then
  cat "$tmp/fresh1.log"
  fail "freshness --staged --strict devrait BLOQUER (code couvert, fiche absente du pending)"
fi
grep -q "back/service" "$tmp/fresh1.log" \
  || { cat "$tmp/fresh1.log"; fail "le gate ne nomme pas la feature à documenter"; }
echo "  ✓ freshness strict : BLOQUE via les pending changes TFVC (chaîne d'enforcement)"

# ─── 5. Le même gate PASSE quand fiche + worklog sont dans le pending set ───
printf 'src/service.cs\n.docs/features/back/service.md\n.docs/features/back/service.worklog.md\n' \
  > "$pending_list"
( cd "$out" && bash .ai/scripts/check-feature-freshness.sh --staged --strict ) >"$tmp/fresh2.log" 2>&1 \
  || { cat "$tmp/fresh2.log"; fail "freshness devrait PASSER quand la fiche est dans le pending set"; }
echo "  ✓ freshness strict : PASSE quand la doc accompagne le code"

echo "✅ test-tfvc-e2e PASS"
