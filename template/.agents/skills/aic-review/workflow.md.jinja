# Workflow — aic-review

**Goal** : aider à relire le changement courant avant commit, review ou PR, avec
une revue applicative métier quand le delta touche du code produit.

## Actions

1. Lire `.ai/index.md`.
2. Lire `.ai/quality/QUALITY_GATE.md`.
3. Lire `.ai/review/application-review.md`.
4. Exécuter `bash .ai/scripts/review-delta.sh --staged` si des fichiers sont
   staged, sinon `bash .ai/scripts/review-delta.sh`.
5. Si une base/head est fournie, exécuter aussi
   `bash .ai/scripts/pr-report.sh --base=<base> --head=<head>`.
6. Pour les chemins significatifs du delta, charger les fiches avec
   `bash .ai/scripts/features-for-path.sh <path> --with-docs`.
7. Si la review révèle du code orphelin, une fiche stale, ou une demande
   explicite de rétro-doc/resync, lire `.ai/workflows/feature-audit.md` pour
   router la suite. Rester en lecture seule : pas de `--apply`, pas de création
   de fiche depuis `aic-review`.
8. Charger seulement les modules `.ai/review/*` pertinents selon
   `.ai/review/application-review.md`.
9. Produire un verdict `go`, `go avec réserves` ou `blocked`.

## Déclenchement autonome

- L'agent peut lancer `aic-review` quand un delta applicatif est prêt à passer en
  `review` ou touche une surface risquée.
- Avant `aic-ship`, une revue applicative récente est attendue pour tout
  changement applicatif non trivial.
- Ne jamais déclencher cette revue depuis le hook `Stop`.

## Format

Utiliser le format défini dans `.ai/review/application-review.md`.

Lecture seule. Ne pas corriger dans ce skill.

Discipline de preuve (`.ai/workflows/evidence-discipline.md`) : chaque risque, constat ou fonctionnement affirmé est prouvé (source citée) ou étiqueté Hypothèse / À vérifier ; jamais d'affirmation nue.
