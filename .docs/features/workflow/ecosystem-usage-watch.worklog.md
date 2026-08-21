# Worklog — workflow/ecosystem-usage-watch

## 2026-08-20 — création et implémentation du contrat

- Origine : la veille Claude/Codex était techniquement pertinente mais ne challengait pas les trous d'usage ni les nouveaux workflows IA dans les fonctions de l'entreprise.
- Décision : conserver le socle technique et ajouter une quatrième piste obligatoire couvrant tâches, décisions, handoffs, adoption et gouvernance métier.
- Discipline de preuve : séparation explicite entre capacité technique, workflow observé et gain mesuré ; une case study fournisseur reste un signal.
- Contractualisation : matrice de couverture métiers, fiche structurée par cas d'usage, expérience falsifiable, plafond global de douze items et routage `aic-frame` / `aic-pilot`.
- Profondeur maîtrisée : balayage de toutes les fonctions, puis au plus deux approfondissements tournants selon signal, risque ou ancienneté ; populations terrain, contributeur, expert, manager et direction rendues visibles.
- Limite : aucun rapport réel n'est produit dans ce chantier ; la feature reste en phase `review` jusqu'à une exécution web sourcée et challengée.

## 2026-08-20 — HANDOFF workflow → product

- Surface partagée : `README.md`, possédée par `product/readme-positioning`.
- Demande : exposer les deux routines mainteneur versionnées — audit interne et veille externe — sans modifier la promesse ni le quickstart.
- Décision : ajout documentaire minimal dans la section Documentation ; la feature produit reste `done` et le workflow `ecosystem-usage-watch` porte le nouveau contrat.
- Validation attendue : liens valides, freshness des deux fiches et checks documentaires.

## 2026-08-20 — validation structurelle

- `check-feature-docs --strict workflow/ecosystem-usage-watch` et `check-features --no-write` : PASS.
- `check-feature-coverage --strict` : 118/118 fichiers couverts après les deux lots.
- `check-feature-freshness --worktree --strict` et `check-ai-references` : PASS.
- La feature reste en `review` : la preuve manquante est volontairement un premier rapport réel, sourcé avec accès web, pas un check statique supplémentaire.

## 2026-08-20 — correction après revue applicative

- Finding mineur : le prompt demandait de réparer ses points d'entrée externes déplacés, mais la section Non-goals semblait limiter toute écriture hors rapport au seul registre TSV.
- Correction : liste exhaustive des trois écritures autorisées — rapport, registre TSV, et prompt uniquement pour réparer un point d'entrée.
- Aucun changement du périmètre de veille ni des critères de sélection.
