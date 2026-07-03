#!/bin/bash
# test-knowledge-workflow.sh — workflow/knowledge-publish-search-link.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/aic-knowledge-workflow.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "✗ $*" >&2
  exit 1
}

mkdir -p "$tmp/.ai/scripts" "$tmp/.ai/schema" "$tmp/.docs/features/core" "$tmp/hub"
for script in _lib.sh _vcs.sh _knowledge.sh check-knowledge.sh build-knowledge-index.sh knowledge.sh aic.sh build-feature-index.sh check-features.sh check-feature-coverage.sh check-product-links.sh check-shims.sh measure-context-size.sh review-delta.sh pr-report.sh; do
  cp "$repo_root/.ai/scripts/$script" "$tmp/.ai/scripts/$script"
done
cp "$repo_root/.ai/schema/feature.schema.json" "$tmp/.ai/schema/feature.schema.json"
cp "$repo_root/.ai/schema/knowledge.schema.json" "$tmp/.ai/schema/knowledge.schema.json"
cat > "$tmp/.ai/config.yml" <<'YAML'
docs_root: ".docs"
project_id: "knowledge-workflow-test"
YAML
cat > "$tmp/.ai/index.md" <<'MD'
# index
MD
cat > "$tmp/.ai/reminder.md" <<'MD'
# reminder
MD
cat > "$tmp/.docs/features/core/sample.md" <<'MD'
---
id: sample
scope: core
title: Sample
status: active
type: feature
depends_on: []
touches:
  - src/**
external_refs: {}
progress:
  phase: implement
  step: ""
  blockers: []
  resume_hint: ""
  updated: "2026-07-03"
---

# Sample
MD

(
  cd "$tmp"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  git add .
  git commit -qm "chore: seed"
  rm -f .ai/.feature-index.json

  dry_run="$(bash .ai/scripts/aic.sh knowledge publish \
    --hub hub \
    --id legacy-billing-invoice-rules \
    --type domain_knowledge \
    --title "Regles de facturation legacy" \
    --summary "Regles de generation des factures dans le legacy ERP." \
    --source-project legacy-erp \
    --owner finance \
    --confidence high \
    --sensitivity internal \
    --source-ref "legacy-erp:/src/billing/InvoiceService.cs" \
    --usable-by migration-project)"
  echo "$dry_run" | grep -q "Mode: dry-run" || fail "publish dry-run n'affiche pas le mode"
  [[ ! -e hub/knowledge/legacy-erp/legacy-billing-invoice-rules.md ]] \
    || fail "publish dry-run a ecrit une fiche"

  bash .ai/scripts/aic.sh knowledge publish \
    --hub hub \
    --apply \
    --id legacy-billing-invoice-rules \
    --type domain_knowledge \
    --title "Regles de facturation legacy" \
    --summary "Regles de generation des factures dans le legacy ERP." \
    --source-project legacy-erp \
    --owner finance \
    --confidence high \
    --sensitivity internal \
    --source-ref "legacy-erp:/src/billing/InvoiceService.cs" \
    --source-ref "legacy-erp:.docs/features/core/invoice-module.md" \
    --usable-by migration-project >/dev/null

  [[ -f hub/knowledge/legacy-erp/legacy-billing-invoice-rules.md ]] \
    || fail "publish --apply n'a pas cree la fiche"
  [[ -f hub/index.json ]] || fail "publish --apply n'a pas regenere index.json"
  jq -e '.knowledge[0].uri == "knowledge://legacy-erp/legacy-billing-invoice-rules"' hub/index.json >/dev/null \
    || fail "index knowledge invalide"

  search_out="$(bash .ai/scripts/aic.sh knowledge search --hub hub billing)"
  echo "$search_out" | grep -q "knowledge://legacy-erp/legacy-billing-invoice-rules" \
    || fail "search ne retrouve pas la connaissance"

  link_out="$(bash .ai/scripts/aic.sh knowledge link --hub hub --feature core/sample legacy-billing-invoice-rules)"
  echo "$link_out" | grep -q "external_refs:" || fail "link ne produit pas de snippet"
  echo "$link_out" | grep -q "knowledge://legacy-erp/legacy-billing-invoice-rules" \
    || fail "link ne contient pas l'URI canonique"

  import_out="$(bash .ai/scripts/aic.sh knowledge import --hub hub legacy-erp/legacy-billing-invoice-rules)"
  echo "$import_out" | grep -q "Source: \`knowledge://legacy-erp/legacy-billing-invoice-rules\`" \
    || fail "import ne cite pas la provenance"
  echo "$import_out" | grep -q "Sensitivity: \`internal\`" \
    || fail "import ne montre pas la sensibilite"
  echo "$import_out" | grep -q "legacy-erp:/src/billing/InvoiceService.cs" \
    || fail "import ne montre pas les source refs"

  freshness_out="$(bash .ai/scripts/aic.sh knowledge freshness --hub hub)"
  echo "$freshness_out" | grep -q "checked_at=" || fail "freshness ne montre pas checked_at"

  json_out="$(bash .ai/scripts/aic.sh knowledge search --hub hub --json legacy)"
  echo "$json_out" | jq -e 'length == 1 and .[0].owner == "finance"' >/dev/null \
    || fail "search --json invalide"

  set +e
  dup_out="$(bash .ai/scripts/aic.sh knowledge publish \
    --hub hub \
    --apply \
    --id legacy-billing-invoice-rules \
    --type domain_knowledge \
    --title "Regles de facturation legacy" \
    --summary "dup" \
    --source-project legacy-erp \
    --owner finance \
    --confidence high \
    --sensitivity internal \
    --source-ref "legacy-erp:/src/billing/InvoiceService.cs" \
    --usable-by migration-project 2>&1)"
  dup_rc=$?
  set -e
  [[ "$dup_rc" -ne 0 ]] || fail "publish duplicate aurait du echouer"
  echo "$dup_out" | grep -q "existe deja" || fail "message duplicate attendu absent"

  [[ ! -e .ai/.feature-index.json ]] || fail "aic knowledge a cree l'index feature"
)

echo "✅ test-knowledge-workflow PASS"
