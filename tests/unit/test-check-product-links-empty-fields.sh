#!/bin/bash
# test-check-product-links-empty-fields.sh — product/product-portfolio-loop.
#
# check-product-links.sh lit ses lignes jq en TSV. Le tab étant un caractère
# blanc d'IFS, `read` fusionne les champs vides consécutifs et rogne ceux de
# tête et de queue : sur une initiative dont les champs produit sont vides,
# chaque valeur remonte d'un cran et `linked_count` finit vide, donc
# `[[ "$linked_count" -eq 0 ]]` est vrai même quand des features dev sont liées.
#
# Ce test est DISCRIMINANT (vérifié : il échoue sur le code d'avant le fix, avec
# les 3 assertions de faux positif/négatif) :
#   - une initiative active aux champs produit vides AVEC feature dev liée ne
#     doit pas être signalée « sans feature dev liée » (faux positif) ;
#   - les warnings des champs réellement vides doivent rester émis, sans être
#     absorbés par le décalage (faux négatif — c'est l'effet de second ordre le
#     plus dangereux : remplir un champ faisait disparaître les warnings d'un
#     autre) ;
#   - la même initiative SANS feature dev liée doit toujours être signalée, avec
#     son decision_state réel dans le message (le check reste utile).

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-product-links-empty.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "✗ $*" >&2; exit 1; }

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/product" "$tmp/.docs/features/core" "$tmp/src"
for script in _lib.sh build-feature-index.sh check-product-links.sh; do
  cp "$repo_root/.ai/scripts/$script" "$tmp/.ai/scripts/$script"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "product-links-empty-test"
YAML
printf 'export const crm = true;\n' > "$tmp/src/crm.ts"

# Initiative LIÉE : champs produit vides (bet, success_metric,
# next_decision_date absents) sauf type et decision_state.
cat > "$tmp/.docs/features/product/crm.md" <<'MD'
---
id: crm
scope: product
title: CRM
status: active
type: feature
depends_on: []
touches:
  - src/crm.ts
product:
  type: initiative
  decision_state: commit
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-08-06"
---

# CRM
MD

# Initiative NON LIÉE : même forme, aucune feature dev ne la référence.
cat > "$tmp/.docs/features/product/etl.md" <<'MD'
---
id: etl
scope: product
title: ETL
status: active
type: feature
depends_on: []
touches:
  - src/etl.ts
product:
  type: initiative
  decision_state: commit
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-08-06"
---

# ETL
MD

cat > "$tmp/.docs/features/core/crm-slice.md" <<'MD'
---
id: crm-slice
scope: core
title: CRM Slice
status: active
type: feature
depends_on: []
touches:
  - src/**
product:
  initiative: product/crm
  contribution: "slice de validation"
  evidence: "test"
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-08-06"
---

# CRM Slice
MD

out="$(cd "$tmp" && bash .ai/scripts/check-product-links.sh 2>&1)"

# --- 1. Faux positif : l'initiative liée ne doit pas être signalée ---
if grep -q "product/crm : active/.* sans feature dev liée" <<< "$out"; then
  echo "$out"
  fail "product/crm a une feature dev liée (product/crm-slice) mais est signalée sans lien"
fi

# --- 2. Faux négatifs : les champs réellement vides restent signalés ---
for missing in "sans product.bet" "sans product.success_metric" "sans product.next_decision_date"; do
  grep -q "product/crm : active $missing" <<< "$out" \
    || { echo "$out"; fail "warning attendu absent : product/crm : active $missing"; }
done

# --- 3. Faux négatif inverse : decision_state est renseigné, pas de warning ---
if grep -q "product/crm : active sans product.decision_state" <<< "$out"; then
  echo "$out"
  fail "product.decision_state=commit est renseigné : ce warning est un faux positif"
fi

# --- 4. Vrai positif : l'initiative sans lien reste signalée, decision_state réel ---
grep -q "product/etl : active/commit sans feature dev liée" <<< "$out" \
  || { echo "$out"; fail "product/etl n'a aucune feature dev liée : le warning doit rester émis"; }

# --- 5. product.type=initiative renseigné : aucun warning de type ---
if grep -q "sans product.type=initiative" <<< "$out"; then
  echo "$out"
  fail "product.type=initiative est renseigné sur les deux initiatives"
fi

echo "✅ test-check-product-links-empty-fields PASS"
