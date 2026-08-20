#!/bin/bash
# test-features-search.sh — core/feature-intent-retrieval.
#
# Couvre le point d'entrée `intent` du contrat .ai/index.md :
#   1. une fiche nommée d'après le code est retrouvée par ses keywords métier ;
#   2. les fiches `done` sont cherchées par défaut (la connaissance capitalisée
#      y vit, et l'inventaire pre-turn les masque) ;
#   3. le repli des diacritiques rend "recuperation" et "récupération" équivalents ;
#   4. aucun résultat ⇒ code 1 (utilisable en garde) ;
#   5. --status filtre, --limit borne, --json sort du JSON ;
#   6. title et keywords sont indexés par le fallback awk (sans yq) ;
#   7. un keywords scalaire est bloqué à l'écriture et dégradé localement à l'index ;
#   8. un acronyme court, seul ou mêlé à des mots longs, matche un mot entier,
#      pas un fragment de "guidé" ou "audit".

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-fsearch.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/back" "$tmp/.docs/features/core" \
  "$tmp/src/legacy" "$tmp/src/crypto" "$tmp/src/ui" "$tmp/src/noise" "$tmp/src/bad"
for s in features-search.sh build-feature-index.sh check-features.sh _lib.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
printf 'docs_root: ".docs"\nproject_id: "fsearch-test"\n' > "$tmp/.ai/config.yml"

# Cas réel visé : fiche nommée d'après le code, sujet redemandé en mots métier.
cat > "$tmp/.docs/features/back/getticketinfo-isdownloadable.md" <<'MD'
---
id: getticketinfo-isdownloadable
scope: back
title: Conditions d'exposition du flag isDownloadable
keywords:
  - téléchargement d'un billet
  - le client ne peut pas télécharger son billet
  - billetterie
status: done
type: feature
depends_on: []
touches:
  - src/legacy/**
---

# Conditions d'exposition du flag isDownloadable
MD

cat > "$tmp/.docs/features/core/unrelated-topic.md" <<'MD'
---
id: unrelated-topic
scope: core
title: Rotation des clés de chiffrement
status: active
type: feature
depends_on: []
touches:
  - src/crypto/**
---

# Rotation des clés de chiffrement
MD

cat > "$tmp/.docs/features/core/ui-library.md" <<'MD'
---
id: ui-library
scope: core
title: "Bibliothèque UI\nmultiligne"
status: done
type: feature
depends_on: []
touches:
  - src/ui/**
---

# Bibliothèque UI
MD

cat > "$tmp/.docs/features/core/guided-audit.md" <<'MD'
---
id: guided-audit
scope: core
title: Parcours guidé pour audit
status: done
type: feature
depends_on: []
touches:
  - src/noise/**
---

# Parcours guidé pour audit
MD

cat > "$tmp/.docs/features/core/bad-keywords.md" <<'MD'
---
id: bad-keywords
scope: core
title: Contrat de rappel corrompu
keywords: billet
status: done
type: feature
depends_on: []
touches:
  - src/bad/**
---

# Contrat de rappel corrompu
MD

(
  cd "$tmp"

  # 7 — l'indexeur reste disponible malgré une fiche mal typée, mais le checker
  # bloque l'erreur pour que son auteur la corrige.
  bash .ai/scripts/build-feature-index.sh --write >/dev/null 2>"$tmp/build.err"
  grep -q "keywords invalide.*bad-keywords.md" "$tmp/build.err" \
    || fail "keywords scalaire : warning de normalisation absent"
  jq -e '.features[] | select(.id == "bad-keywords") | .keywords == []' .ai/.feature-index.json >/dev/null \
    || fail "keywords scalaire : l'index n'a pas normalisé localement en []"
  if bash .ai/scripts/check-features.sh --no-write >"$tmp/check.out" 2>&1; then
    fail "keywords scalaire : check-features aurait dû échouer"
  fi
  grep -q "keywords invalide.*tableau de chaînes" "$tmp/check.out" \
    || fail "keywords scalaire : check-features n'explique pas le contrat attendu"

  # 1 + 2 — vocabulaire métier, fiche `done`, aucun mot du titre ni de l'id.
  out="$(bash .ai/scripts/features-search.sh "téléchargement billet")" \
    || fail "recherche métier : code de sortie non nul alors qu'une fiche matche"
  printf '%s' "$out" | grep -q "back/getticketinfo-isdownloadable" \
    || fail "recherche métier : la fiche done attendue n'est pas retrouvée\n$out"
  printf '%s' "$out" | head -2 | grep -q "getticketinfo-isdownloadable" \
    || fail "recherche métier : la fiche attendue n'est pas en tête de classement\n$out"

  # 3 — repli des diacritiques dans les deux sens.
  bash .ai/scripts/features-search.sh --json "telechargement" \
    | jq -e 'map(select(.id == "getticketinfo-isdownloadable")) | length == 1' >/dev/null \
    || fail "diacritiques : 'telechargement' ne matche pas 'téléchargement'"
  bash .ai/scripts/features-search.sh --json "clés chiffrement" \
    | jq -e 'map(select(.id == "unrelated-topic")) | length == 1' >/dev/null \
    || fail "diacritiques : 'clés' ne matche pas le titre accentué"

  # 8 — "ui" matche le token UI, jamais les fragments de "guidé" / "audit".
  bash .ai/scripts/features-search.sh --json "ui" \
    | jq -e 'length == 1 and .[0].id == "ui-library"' >/dev/null \
    || fail "acronyme UI : faux positif par sous-chaîne"
  bash .ai/scripts/features-search.sh --json "problème ui" \
    | jq -e 'length == 1 and .[0].id == "ui-library" and .[0].matched == 1 and .[0].terms == 2' >/dev/null \
    || fail "acronyme UI : terme court perdu dans une requête mixte"

  # 3bis — mots vides et fragments élidés ne créent pas de faux positif : la
  # phrase complète ne doit remonter que la fiche billetterie, pas la fiche crypto.
  bash .ai/scripts/features-search.sh --json "j'ai un problème sur le téléchargement d'un billet" \
    | jq -e 'length == 1 and .[0].id == "getticketinfo-isdownloadable"' >/dev/null \
    || fail "mots vides : la phrase complète remonte du bruit"

  # 4 — aucun résultat ⇒ code 1, sans faire échouer set -e du script appelant.
  if bash .ai/scripts/features-search.sh "zzzz-terme-absent" >/dev/null; then
    fail "aucun résultat : code de sortie 0 attendu à 1"
  fi

  # 5 — filtres.
  bash .ai/scripts/features-search.sh --json --status active "téléchargement billet" >/dev/null \
    && fail "--status active : la fiche done ne devrait pas matcher"
  bash .ai/scripts/features-search.sh --json --limit 1 "billet chiffrement" \
    | jq -e 'length == 1' >/dev/null || fail "--limit 1 : plus d'un résultat renvoyé"

  # 6 — title/keywords indexés aussi sans yq (parseur fallback awk).
  rm -f .ai/.feature-index.json
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash .ai/scripts/build-feature-index.sh 2>"$tmp/fallback-build.err" \
    | jq -e '
        .features[] | select(.id == "getticketinfo-isdownloadable")
        | (.title == "Conditions d'"'"'exposition du flag isDownloadable")
          and ((.keywords | length) == 3)
      ' >/dev/null || fail "fallback sans yq : title/keywords absents ou tronqués"
  grep -q "keywords invalide.*bad-keywords.md" "$tmp/fallback-build.err" \
    || fail "fallback sans yq : warning du keywords scalaire absent"
  rm -f .ai/.feature-index.json
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash .ai/scripts/features-search.sh --json "ui" \
    | jq -e 'length == 1 and .[0].id == "ui-library"' >/dev/null \
    || fail "fallback sans yq : keywords scalaire ou acronyme UI casse la recherche"
)

echo "✅ test-features-search PASS"
