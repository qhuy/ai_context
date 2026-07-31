#!/bin/bash
# test-upgrade-v014-to-v1.sh — core/template-engine.
#
# Chantier B10 du gel v1.0 : prouver que `copier update` v0.14.0 -> candidate v1.0
# est sûr sur des réponses REPRÉSENTATIVES, dont le cas le plus risqué —
# un consommateur portant la réponse `gemini`, dépréciée en v1.0.
#
# Le cas gemini est ici pour une raison précise, découverte empiriquement : quand
# une réponse stockée sort de `choices`, Copier jette la réponse ENTIÈRE et
# applique le défaut. Un projet en `agents: [cursor, gemini]` devenait
# `[claude, codex]` — perte silencieuse de cursor, ajout non demandé de claude.
# D'où la dépréciation (valeur conservée, aucun artefact rendu) plutôt que le
# retrait. Ce test verrouille l'absence de régression sur ce point.
#
# Non couvert ici : les scénarios déjà tenus par le smoke `[28c/28]` (fichier user
# préservé, fiche project-owned intacte, index opt-in, rollback).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

command -v copier >/dev/null 2>&1 || { echo "⏭️  test-upgrade-v014-to-v1 SKIP (copier absent)"; exit 0; }
git -C "$repo_root" show-ref --tags --verify --quiet refs/tags/v0.14.0 \
  || { echo "⏭️  test-upgrade-v014-to-v1 SKIP (tag v0.14.0 absent — fetch-depth: 0 requis en CI)"; exit 0; }

tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-upg-v1.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $1"; exit 1; }

# Scénarios : nom | agents à la v0.14 | scope_profile
scenarios="
git-defaut|[\"claude\",\"codex\"]|minimal
gemini-legacy|[\"cursor\",\"gemini\"]|fullstack
"

while IFS='|' read -r name agents scope; do
  [[ -n "$name" ]] || continue
  ws="$tmp/$name"

  copier copy --defaults --trust --vcs-ref=v0.14.0 \
    --data project_name="upg-$name" \
    --data agents="$agents" \
    --data scope_profile="$scope" \
    "$repo_root" "$ws" >"$tmp/$name.copy.log" 2>&1 \
    || { sed -n '1,30p' "$tmp/$name.copy.log"; fail "$name : scaffold v0.14.0 échoué"; }

  # `_src_path` est relatif quand la source est `.` : l'absolutiser, sinon
  # `copier update` cherche le tag dans le projet cible au lieu du template.
  python3 - "$ws/.copier-answers.yml" "$repo_root" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
p.write_text(s.replace("_src_path: .", f"_src_path: {sys.argv[2]}"))
PY

  ( cd "$ws" && git init -q && git add -A \
      && git -c user.email=t@t -c user.name=t commit -qm "scaffold v0.14.0" >/dev/null )

  # État AVANT, pour comparer ce que l'update préserve.
  before_agents="$(grep -A6 '^agents:' "$ws/.copier-answers.yml" | grep '^- ' | tr -d ' -' | sort | tr '\n' ',')"
  before_cursor=0; [[ -d "$ws/.cursor" ]] && before_cursor=1
  printf '// code metier\n' > "$ws/mycode.txt"
  ( cd "$ws" && git add -A && git -c user.email=t@t -c user.name=t commit -qm "code local" >/dev/null )

  ( cd "$ws" && copier update --defaults --trust --vcs-ref=HEAD --conflict=rej ) \
    >"$tmp/$name.upd.log" 2>&1 || {
      # Copier 9.x + py3.14 peut crasher dans son _cleanup APRÈS un update réussi.
      if grep -q "Updating to template version" "$tmp/$name.upd.log" \
         && grep -qE "_cleanup|Directory not empty|copier\._vcs\.clone" "$tmp/$name.upd.log"; then
        :
      else
        sed -n '1,40p' "$tmp/$name.upd.log"
        fail "$name : copier update v0.14.0 -> HEAD échoué"
      fi
    }

  # ─── Invariants communs ───
  [[ -f "$ws/mycode.txt" ]] || fail "$name : fichier user perdu par l'update"
  rej="$(find "$ws" -name '*.rej' -not -path '*/.git/*' | wc -l | tr -d ' ')"
  [[ "$rej" -eq 0 ]] || fail "$name : $rej fichier(s) .rej après update"

  after_agents="$(grep -A6 '^agents:' "$ws/.copier-answers.yml" | grep '^- ' | tr -d ' -' | sort | tr '\n' ',')"
  [[ "$after_agents" == "$before_agents" ]] \
    || fail "$name : réponse agents modifiée par l'update ('$before_agents' -> '$after_agents')"

  # Surfaces v1.0 effectivement livrées par l'update.
  for expected in .ai/scripts/aic-init.sh .ai/scripts/check-skills-parity.sh GLOSSARY.md; do
    [[ -e "$ws/$expected" ]] || fail "$name : $expected non livré par l'update"
  done
  ( cd "$ws" && bash .ai/scripts/aic.sh --help 2>/dev/null | grep -Fq '── stable ──' ) \
    || fail "$name : l'aide classifiée v1.0 n'est pas livrée"

  ( cd "$ws" && bash .ai/scripts/check-shims.sh >/dev/null 2>&1 ) \
    || { ( cd "$ws" && bash .ai/scripts/check-shims.sh ); fail "$name : check-shims échoue après update"; }

  # ─── Invariants propres au cas gemini ───
  if [[ "$name" == "gemini-legacy" ]]; then
    [[ ! -f "$ws/GEMINI.md" ]] \
      || fail "$name : GEMINI.md devrait être supprimé par l'update (agent déprécié)"
    [[ ! -f "$ws/CLAUDE.md" ]] \
      || fail "$name : CLAUDE.md créé alors que claude n'a jamais été sélectionné (réponse réinitialisée ?)"
    if [[ "$before_cursor" -eq 1 ]]; then
      [[ -d "$ws/.cursor" ]] \
        || fail "$name : .cursor perdu — la réponse agents a été réinitialisée au défaut"
    fi
    echo "  ✓ gemini legacy : réponse conservée, cursor préservé, GEMINI.md retiré, pas de claude imposé"
  else
    echo "  ✓ $name : update propre (réponse, fichier user, surfaces v1.0, check-shims)"
  fi
done < <(printf '%s\n' "$scenarios")

echo "✅ test-upgrade-v014-to-v1 PASS"
