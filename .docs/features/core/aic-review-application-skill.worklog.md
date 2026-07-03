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

## 2026-07-03 — done

- Intent : clôturer le livrable core de revue applicative modulaire.
- Fichiers/surfaces : `.docs/features/core/aic-review-application-skill.md`, `.docs/features/core/aic-review-application-skill.worklog.md`.
- Décision : statut `done` pour la surface core ; l'intégration stricte dans `aic-ship` et `feature-done` reste le HANDOFF workflow déjà consigné, pas un changement à mélanger ici.
- Validation : `bash .ai/scripts/aic.sh review --help` ; `bash .ai/scripts/check-dogfood-drift.sh` ; `bash .ai/scripts/check-feature-docs.sh --strict core/aic-review-application-skill` ; `bash tests/unit/test-review-delta-shared.sh` ; `bash tests/unit/test-review-delta-uncommitted.sh` ; parité `cmp` runtime/template pour les wrappers `aic-review` et `.ai/review/application-review.md`.
- Next : aucune action core immédiate ; reprendre côté `workflow/intentional-skills` si l'evidence de revue doit devenir bloquante dans ship/done.

## 2026-07-03 — reprise HANDOFF feature-audit
- Intent : traiter le HANDOFF `workflow/feature-audit` sans rouvrir de skill procédural public.
- Fichiers/surfaces : `.agents/skills/aic-review/workflow.md`, `.claude/skills/aic-review/workflow.md`, templates associés, fiche core.
- Décision : `aic-review` charge `.ai/workflows/feature-audit.md` seulement pour router les cas rétro-doc/orphelins/resync ; le skill reste lecture seule et n'exécute pas `--apply`.
- Validation : `bash .ai/scripts/check-feature-docs.sh --strict core/aic-review-application-skill`; `bash .ai/scripts/check-dogfood-drift.sh`; `bash .ai/scripts/check-features.sh --no-write`; `bash .ai/scripts/check-feature-freshness.sh --worktree --strict`.
- Next : revenir au scope `workflow/feature-audit` dans un tour séparé pour lever le blocker et clôturer la fiche.
