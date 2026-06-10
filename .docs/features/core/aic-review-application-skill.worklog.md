# Worklog — core/aic-review-application-skill

## 2026-06-10 — création

- Feature créée via `.ai/workflows/feature-new.md`
- Scope : core
- Intent initial : Revue applicative métier modulaire
- Décision : enrichir `aic-review` avec des modules de revue ciblés plutôt que
  créer un nouveau skill public.

## 2026-06-10 — implémentation contrat applicatif

- Ajout du contrat canonique `.ai/review/application-review.md`.
- Ajout des modules de revue : socle commun, métier/fonctionnel,
  documentation, C#, React et Python.
- Ajout du miroir template sous `template/.ai/review/**`.
- Alignement des wrappers `aic-review` Claude et Codex, runtime et template,
  pour déléguer au contrat partagé.
- Décision : le déclenchement autonome est autorisé à l'entrée en review et
  attendu avant ship, mais pas branché sur le hook `Stop`.

## 2026-06-10 — HANDOFF vers workflow

- HANDOFF explicite : l'intégration bloquante dans `aic-ship` et
  `feature-done` appartient au scope `workflow/intentional-skills`.
- Besoin transmis : faire vérifier par `aic-ship` qu'une revue applicative
  récente existe ou lancer `aic-review`, puis exiger cette evidence lors de la
  clôture de feature.
- Raison : éviter de mélanger l'évolution modulaire `aic-review` avec la
  procédure de livraison et de clôture.

## 2026-06-10 — dogfooding aic-review

- Revue applicative lancée sur le delta courant avec le nouveau contrat
  `.ai/review/application-review.md`.
- Correction issue de la revue : conserver la lecture de
  `.ai/quality/QUALITY_GATE.md` dans `aic-review` pour éviter une régression de
  recommandations de checks.
- Correction issue de la revue : passer la fiche en `status: active` et déclarer
  `workflow/intentional-skills` dans `depends_on`, car les wrappers Claude/Codex
  existants font partie de cette surface intentionnelle.
