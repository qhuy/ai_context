# Worklog — product/knowledge-federation

## 2026-06-29 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : product
- Intent initial : Federation de connaissances ai_context
- Cadrage : initiative produit pour publier, retrouver et reutiliser des connaissances entre projets sans remplacer le `.ai` local.

## 2026-07-03 — décision MVP knowledge source

- Intent : dérouler l'initiative produit jusqu'au choix du contrat minimal et du premier backend MVP.
- Fichiers/surfaces : `.docs/features/product/knowledge-federation.md`, `.docs/features/product/knowledge-federation.worklog.md`.
- Décision : `decision_state=commit`. Le MVP démarre par un hub Git/Markdown : fiches de connaissance versionnées, frontmatter obligatoire, index généré, publication humaine explicite. Git est la source canonique maintainer, pas l'interface non-tech.
- Contrat minimal : `id`, `type`, `title`, `summary`, `source_project`, `source_refs`, `owner`, `confidence`, `freshness.checked_at`, `sensitivity`, `usable_by`, `status`.
- Non-goals confirmés : pas d'API centrale, base de données ou application web en premier livrable ; pas de publication automatique ; pas de hub qui remplace les `.ai/` locaux.
- Validation : checks documentaires et gate repo à lancer dans ce tour avant commit.
- Next : créer des features séparées `core/knowledge-source-contract`, puis `workflow/knowledge-publish-search-link`. Ne pas les mélanger avec R1.

## HANDOFF — product -> core

- Feature source : `product/knowledge-federation`
- Status : MVP produit décidé, backend Git/Markdown retenu.
- Contexte : le contrat doit devenir un schema maintenu et validable, sans embarquer une application ou un backend central.
- Fichiers touchés : aucun fichier `core` dans ce tour.
- Travail restant : cadrer puis livrer `core/knowledge-source-contract` (schema, layout `knowledge/<source_project>/<id>.md`, génération `index.json`, validation frontmatter).
- Contrats / décisions : source canonique Markdown + frontmatter ; index dérivé ; publication explicite.
- Risques : surconcevoir le hub ou réintroduire un feature mesh global.
- Validation attendue : fixture de connaissance valide/invalide, check schema, génération d'index déterministe.
- Resume hint : créer la fiche `core/knowledge-source-contract` avant tout changement runtime.

## HANDOFF — product -> workflow

- Feature source : `product/knowledge-federation`
- Status : MVP produit décidé, backend Git/Markdown retenu.
- Contexte : le flux agent doit exposer `publish`, `search`, `link`, `import` sans forcer l'utilisateur non-tech à manipuler Git.
- Fichiers touchés : aucun fichier `workflow` dans ce tour.
- Travail restant : cadrer puis livrer `workflow/knowledge-publish-search-link` après le contrat `core`.
- Contrats / décisions : publication humaine explicite ; les fiches locales lient la connaissance via `external_refs.knowledge`.
- Risques : import silencieux sans provenance ou publication de contenu sensible.
- Validation attendue : scénario source -> publish candidate -> search depuis repo consommateur -> link local avec provenance visible.
- Resume hint : attendre le contrat `core/knowledge-source-contract`, puis créer la fiche workflow dédiée.
