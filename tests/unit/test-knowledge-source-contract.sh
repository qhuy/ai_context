#!/bin/bash
# test-knowledge-source-contract.sh — core/knowledge-source-contract.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-knowledge-contract.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"
}

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/hub/knowledge/legacy-erp"
for s in _lib.sh _vcs.sh _knowledge.sh check-knowledge.sh build-knowledge-index.sh; do
  cp "$repo_root/.ai/scripts/$s" "$tmp/.ai/scripts/$s"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cp "$repo_root/.ai/schema/knowledge.schema.json" "$tmp/.ai/schema/knowledge.schema.json"

cat > "$tmp/hub/knowledge/legacy-erp/legacy-billing-invoice-rules.md" <<'MD'
---
id: legacy-billing-invoice-rules
type: domain_knowledge
title: "Regles de facturation legacy"
summary: "Regles de generation des factures dans le legacy ERP."
source_project: legacy-erp
owner: finance
confidence: high
freshness:
  status: verified
  checked_at: 2026-06-29
sensitivity: internal
source_refs:
  - legacy-erp:/src/billing/InvoiceService.cs
  - legacy-erp:.docs/features/core/invoice-module.md
usable_by:
  - migration-project
status: published
---

# Regles de facturation legacy
MD

(
  cd "$tmp"

  bash .ai/scripts/check-knowledge.sh hub >/dev/null \
    || fail "hub valide rejeté par check-knowledge"

  out="$(bash .ai/scripts/build-knowledge-index.sh hub)"
  printf '%s\n' "$out" | jq -e '
    .schema_version == "1"
    and (.knowledge | length) == 1
    and .knowledge[0].id == "legacy-billing-invoice-rules"
    and .knowledge[0].uri == "knowledge://legacy-erp/legacy-billing-invoice-rules"
    and .knowledge[0].freshness.status == "verified"
    and (.knowledge[0].source_refs | length) == 2
  ' >/dev/null || fail "index stdout invalide"
  [[ ! -f hub/index.json ]] || fail "stdout ne doit pas créer index.json"

  bash .ai/scripts/build-knowledge-index.sh --write hub >/dev/null
  [[ -f hub/index.json ]] || fail "--write n'a pas créé hub/index.json"
  before_mtime="$(mtime hub/index.json)"
  before_contract="$(jq -S 'del(.generated_at)' hub/index.json)"
  sleep 1
  bash .ai/scripts/build-knowledge-index.sh --write hub >/dev/null
  after_mtime="$(mtime hub/index.json)"
  after_contract="$(jq -S 'del(.generated_at)' hub/index.json)"
  [[ "$before_mtime" == "$after_mtime" ]] || fail "--write a réécrit un index contractuellement identique"
  [[ "$before_contract" == "$after_contract" ]] || fail "contrat index instable hors generated_at"

  bash .ai/scripts/check-knowledge.sh hub >/dev/null \
    || fail "hub avec index synchronisé rejeté"

  mkdir -p invalid/knowledge/legacy-erp invalid/knowledge/product-crm
  cp hub/knowledge/legacy-erp/legacy-billing-invoice-rules.md invalid/knowledge/product-crm/legacy-billing-invoice-rules.md
  set +e
  invalid_out="$(bash .ai/scripts/check-knowledge.sh invalid 2>&1)"
  invalid_rc=$?
  set -e
  [[ "$invalid_rc" -ne 0 ]] || fail "source_project incohérent aurait dû échouer"
  echo "$invalid_out" | grep -q "dossier source 'product-crm' different de source_project='legacy-erp'" \
    || { echo "$invalid_out"; fail "message source_project attendu absent"; }

  cp hub/knowledge/legacy-erp/legacy-billing-invoice-rules.md invalid/knowledge/legacy-erp/missing-owner.md
  perl -0pi -e 's/id: legacy-billing-invoice-rules/id: missing-owner/; s/owner: finance\n//' invalid/knowledge/legacy-erp/missing-owner.md
  set +e
  missing_out="$(bash .ai/scripts/check-knowledge.sh invalid 2>&1)"
  missing_rc=$?
  set -e
  [[ "$missing_rc" -ne 0 ]] || fail "owner manquant aurait dû échouer"
  echo "$missing_out" | grep -q "champ obligatoire 'owner' manquant" \
    || { echo "$missing_out"; fail "message owner manquant attendu absent"; }

  mkdir -p empty
  bash .ai/scripts/check-knowledge.sh empty >/dev/null \
    || fail "hub vide devrait passer"
  empty_index="$(bash .ai/scripts/build-knowledge-index.sh empty)"
  printf '%s\n' "$empty_index" | jq -e '.knowledge == []' >/dev/null \
    || fail "index hub vide invalide"
)

echo "✅ test-knowledge-source-contract PASS"
