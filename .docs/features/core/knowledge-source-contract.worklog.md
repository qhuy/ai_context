# Worklog — core/knowledge-source-contract

## 2026-07-03 — création

- Feature créée via `.ai/workflows/document-feature.md`
- Scope : core
- Intent initial : livrer le contrat executable du hub knowledge Git/Markdown.
- Source produit : HANDOFF `product/knowledge-federation` -> `core`.
- Décision : demarrer par schema + validation + index derive, sans workflow publish/search ni backend central.
- Validation prevue : test unitaire cible, check strict fiche, dogfood drift, gate repo.

## 2026-07-03 — livraison

- Intent : livrer le contrat core minimal pour une knowledge source Git/Markdown.
- Fichiers/surfaces : `.ai/schema/knowledge.schema.json`, `.ai/scripts/_knowledge.sh`, `.ai/scripts/check-knowledge.sh`, `.ai/scripts/build-knowledge-index.sh`, miroir `template/.ai/**`, test `tests/unit/test-knowledge-source-contract.sh`.
- Décision : hub root contenant `knowledge/<source_project>/<id>.md`, `index.json` derive a la racine en mode `--write`, absence de `knowledge/` acceptee comme hub vide.
- Validation : `bash -n` scripts + test ; `jq` schemas ; `bash tests/unit/test-knowledge-source-contract.sh` PASS ; `bash .ai/scripts/check-knowledge.sh` PASS ; `bash .ai/scripts/build-knowledge-index.sh | jq ...` PASS ; `bash tests/unit/test-template-jinja-raw-braces.sh` PASS ; `bash .ai/scripts/check-feature-docs.sh --strict core/knowledge-source-contract` PASS ; `bash .ai/scripts/check-feature-freshness.sh --worktree --strict` PASS ; `bash .ai/scripts/check-dogfood-drift.sh` PASS.
- Next : reprendre le HANDOFF workflow via `workflow/knowledge-publish-search-link` pour exposer `publish`, `search`, `link`, `import` au-dessus de ce contrat.

## 2026-08-21 — helper mtime du contrat rendu portable

- Audit pré-release des variantes de `stat` après deux échecs Ubuntu : le test knowledge essayait encore la syntaxe BSD avant GNU. GNU `stat -f %m` peut réussir avec un rapport multi-ligne, ce que la simple comparaison d'égalité ne révélait pas.
- Correction : priorité à `stat -c %Y`, fallback BSD/macOS `stat -f %m`, avec assertion explicite que les deux timestamps sont numériques.
- Aucun changement du builder knowledge ni de son index ; test ciblé et suite CI portent la validation.
