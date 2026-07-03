# Worklog — workflow/knowledge-publish-search-link

## 2026-07-03 — création

- Feature créée via `.ai/workflows/document-feature.md`
- Scope : workflow
- Intent initial : exposer publish/search/link/import au-dessus du contrat core knowledge.
- Source produit : HANDOFF `product/knowledge-federation` -> `workflow`.
- Dépendance : `core/knowledge-source-contract` livré.
- Décision : publication explicite via `publish --apply`; `link` et `import` non-mutants en MVP.
- Validation prevue : test unitaire cible, routage `aic.sh`, dogfood drift, gate repo.

## 2026-07-03 — implémentation initiale

- Fichiers/surfaces : `.ai/scripts/knowledge.sh`, `template/.ai/scripts/knowledge.sh.jinja`, `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`, `tests/unit/test-knowledge-workflow.sh`.
- Décision : `knowledge.sh` porte la logique workflow ; `aic.sh` route seulement `knowledge`.
- Comportement : `publish` dry-run par defaut, `publish --apply` ecrit la fiche et regenere l'index, `search`/`link`/`import`/`freshness` restent non-mutants.
- Validation partielle : `bash -n` scripts PASS ; `bash tests/unit/test-knowledge-workflow.sh` PASS ; `bash tests/unit/test-template-jinja-raw-braces.sh` PASS ; `bash .ai/scripts/check-dogfood-drift.sh` PASS.
- Gate : `check-feature-freshness --worktree --strict` signale le routage `aic.sh` comme impact core `aic-surface-canonical` et `vcs-provider-abstraction`; worklogs core a documenter dans le meme changement.

## HANDOFF — workflow -> core

- Feature source : `workflow/knowledge-publish-search-link`
- Status : routage `aic.sh knowledge` implemente et teste.
- Contexte : `aic.sh` est une surface core canonique et couverte aussi par `core/vcs-provider-abstraction`; le changement n'ajoute pas de comportement VCS, mais modifie la surface CLI publique.
- Fichiers touchés : `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`.
- Travail restant : documenter l'impact minimal dans les worklogs `core/aic-surface-canonical` et `core/vcs-provider-abstraction`.
- Contrats / décisions : dispatch vers `knowledge.sh`; aucune logique knowledge inlinée dans `aic.sh`.
- Risques : oublier de tracer la surface publique aic ou rouvrir inutilement le scope core.
- Validation attendue : freshness worktree/staged stricte verte après worklogs core.
- Resume hint : ne pas ajouter d'autre changement core ; seulement tracer le routage.

## 2026-07-03 — livraison

- Intent : clôturer le flux `aic knowledge` après validation du MVP CLI.
- Fichiers/surfaces : `.ai/scripts/knowledge.sh`, `template/.ai/scripts/knowledge.sh.jinja`, `.ai/scripts/aic.sh`, `template/.ai/scripts/aic.sh.jinja`, `tests/unit/test-knowledge-workflow.sh`, fiche/worklog workflow, worklogs core du routage.
- Décision : `publish --apply` reste la seule action mutante ; `link` et `import` restent non-mutants et affichent la provenance `knowledge://...`.
- Validation : `bash -n` scripts PASS ; `bash tests/unit/test-knowledge-workflow.sh` PASS ; `bash tests/unit/test-template-jinja-raw-braces.sh` PASS ; `bash .ai/scripts/check-dogfood-drift.sh` PASS ; `bash .ai/scripts/check-feature-docs.sh --strict workflow/knowledge-publish-search-link` PASS ; `bash .ai/scripts/check-feature-freshness.sh --worktree --strict` PASS.
- Cross-scope : impact `aic.sh` documenté dans `core/aic-surface-canonical.worklog.md` et `core/vcs-provider-abstraction.worklog.md`; aucun autre changement core.
- Next : garder `product/knowledge-federation` actif pour la preuve publish/search/link sur deux projets réels ; suite technique possible en `quality/knowledge-freshness-checks`.
