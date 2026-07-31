#!/bin/bash
# aic-release.sh — Checklist RELEASE.md automatisée (étapes mécaniques uniquement).
#
# Source-only : outillage mainteneur du repo ai_context lui-même (release DU
# template), pas rendu aux consommateurs — RELEASE.md et check-release-coherence.sh
# ne le sont pas non plus. Volontairement absent de la surface publique `aic.sh`.
#
# Automatise : tests (§1), rendus Copier critiques (§2), cohérence doc (§4, check
# automatique seulement). Reste volontairement manuel — jamais exécuté ici :
#   - §3 copier update sur un consommateur réel (besoin d'un repo externe) ;
#   - §5 choix SemVer (décision humaine) ;
#   - §6 commit + tag + push (irréversible, jamais automatisé) ;
#   - §7 sanity post-tag (le tag n'existe pas encore à ce stade).
#
# Usage : bash .ai/scripts/aic-release.sh [--skip-smoke] [--skip-renders]

set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
. "$script_dir/_lib.sh"
repo_root="$(vcs_root 2>/dev/null || pwd)"
cd "$repo_root"

skip_smoke=0
skip_renders=0
for arg in "$@"; do
  case "$arg" in
    --skip-smoke) skip_smoke=1 ;;
    --skip-renders) skip_renders=1 ;;
    -h|--help)
      echo "Usage: bash .ai/scripts/aic-release.sh [--skip-smoke] [--skip-renders]"
      exit 0
      ;;
    *)
      echo "Argument inconnu: $arg" >&2
      exit 2
      ;;
  esac
done

fail=0

echo "═══ aic release — checklist RELEASE.md ═══"
echo

echo "── Pré-requis ──"
if command -v git >/dev/null 2>&1 && [[ -d .git ]]; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"
  dirty_count="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "  branche courante : $branch"
  if [[ "$dirty_count" -eq 0 ]]; then
    echo "  ✓ working tree propre"
  else
    echo "  ⚠️  working tree non propre ($dirty_count fichier(s)) — normal si tu es en train d'éditer §4/§5, sinon vérifier avant de tagger"
  fi
else
  echo "  ⚠️  pas de repo git détecté ; vérifie la propreté du working tree manuellement"
fi
echo

echo "── 1. Tests (RELEASE.md §1) ──"
if [[ "$skip_smoke" -eq 1 ]]; then
  echo "  ⏭  ignoré (--skip-smoke)"
else
  smoke_log="$(mktemp "${TMPDIR:-/tmp}/aic-release-smoke.XXXXXX.log")"
  if bash "$repo_root/tests/smoke-test.sh" >"$smoke_log" 2>&1; then
    echo "  ✓ smoke-test PASS"
    rm -f "$smoke_log"
  else
    echo "  ❌ smoke-test FAIL — log complet : $smoke_log"
    tail -30 "$smoke_log"
    fail=1
  fi
fi
echo

echo "── 2. Rendus Copier critiques (RELEASE.md §2) ──"
if [[ "$skip_renders" -eq 1 ]]; then
  echo "  ⏭  ignoré (--skip-renders)"
elif ! command -v copier >/dev/null 2>&1; then
  echo "  ⚠️  copier introuvable ; étape ignorée"
else
  render_root="$(mktemp -d "${TMPDIR:-/tmp}/aic-release-renders.XXXXXX")"

  render_profile() {
    local name="$1"
    shift
    local extra_data=()
    local kv
    for kv in "$@"; do
      extra_data+=(--data "$kv")
    done
    local out_dir="$render_root/$name"
    local log_file="$render_root/$name.log"
    if ! copier copy --defaults --trust --vcs-ref=HEAD \
      --data project_name="smoke-$name" \
      ${extra_data[@]+"${extra_data[@]}"} \
      "$repo_root" "$out_dir" >"$log_file" 2>&1; then
      echo "  ❌ $name — rendu Copier échoué (log : $log_file)"
      tail -20 "$log_file"
      fail=1
      return
    fi
    if [[ ! -f "$out_dir/AGENTS.md" || ! -f "$out_dir/.ai/index.md" ]]; then
      echo "  ❌ $name — fichiers attendus absents (AGENTS.md / .ai/index.md)"
      fail=1
      return
    fi
    echo "  ✓ $name"
  }

  # Miroir exact des invocations documentées dans RELEASE.md §2 — garder les deux
  # listes synchronisées (le profil tfvc a été ajouté au gel v1.0).
  render_profile "standard"
  render_profile "lite" "adoption_mode=lite"
  render_profile "strict" "adoption_mode=strict"
  render_profile "docs" "docs_root=docs"
  render_profile "en" "commit_language=en"
  render_profile "codex" "agents=[codex]"
  render_profile "tfvc" "vcs_provider=tfvc"
  render_profile "fullstack" "scope_profile=fullstack" "tech_profile=fullstack-dotnet-react"

  rm -rf "$render_root"
fi
echo

echo "── 3. copier update sur un consommateur (RELEASE.md §3) ──"
echo "  ⏭  manuel — nécessite un repo consommateur réel, à tester sur une copie jetable :"
echo "     git clone --no-hardlinks <projet-consommateur> /tmp/update-test && cd /tmp/update-test"
echo "     copier update --vcs-ref=HEAD --conflict=rej --defaults --trust"
echo

echo "── 4. Documentation (RELEASE.md §4) ──"
coherence_log="$(mktemp "${TMPDIR:-/tmp}/aic-release-coherence.XXXXXX.log")"
if bash "$script_dir/check-release-coherence.sh" >"$coherence_log" 2>&1; then
  echo "  ✓ check-release-coherence OK"
  rm -f "$coherence_log"
else
  echo "  ❌ check-release-coherence FAIL"
  cat "$coherence_log"
  rm -f "$coherence_log"
  fail=1
fi
echo "  ℹ️  Non automatisable — à vérifier humainement :"
echo "     - CHANGELOG.md : Unreleased finalisé sous le bon numéro de version"
echo "     - PROJECT_STATE.md : « Dernière version publiée » + roadmap à jour"
echo "     - MIGRATION.md : instructions si comportement utilisateur changé"
echo "     - .docs/features/**/*.md impactées : section Historique mise à jour"
echo

cat <<'EOF'
── 5. Versioning (RELEASE.md §5) ──
  ℹ️  Décision humaine — SemVer (vMAJOR.MINOR.PATCH) :
     MAJOR : breaking pour `copier update`
     MINOR : nouvelle option/script/hook additif
     PATCH : correction, doc-drift, sync template/runtime

── 6. Commit + tag (RELEASE.md §6) ──
  ℹ️  Jamais exécuté par ce script (irréversible) — une fois la version décidée :
     git add CHANGELOG.md PROJECT_STATE.md ...
     git commit -m "chore(release): vX.Y.Z"
     git tag vX.Y.Z
     git push origin main
     git push origin vX.Y.Z

── 7. Sanity post-release (RELEASE.md §7) ──
  ℹ️  À lancer une fois le tag poussé :
     copier copy --trust --vcs-ref=vX.Y.Z gh:qhuy/ai_context /tmp/ai-context-released
     bash /tmp/ai-context-released/.ai/scripts/check-shims.sh
     bash /tmp/ai-context-released/.ai/scripts/doctor.sh
EOF

echo
if [[ "$fail" -eq 0 ]]; then
  echo "✅ Étapes automatisables PASS — §3/§5/§6/§7 restent manuels (voir ci-dessus)."
else
  echo "❌ Au moins une étape automatisable a échoué — stop, ne pas tagger avant remédiation."
fi
exit "$fail"
