
## 2026-05-07 — freshness
- Impact indirect : `template/.ai/scripts/features-for-path.sh.jinja` étendu (ranking
  top-K + matcher path-aware). Le hook PreToolUse Claude bénéficie du ranking sans
  changement de contrat externe.
- Validation : smoke-test PASS, copier copy direct PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 — freshness
- Impact direct : `template/.ai/scripts/features-for-path.sh.jinja` étendu pour appeler `context-relevance-log.sh inject` à la fin (livraison Phase 2 #3). Le hook PreToolUse Claude bénéficie du tracker sans changement de contrat externe.
- Validation associée : copier copy direct PASS, 8 cas test-context-relevance PASS.

## 2026-05-07 14:20 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 14:45 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 14:53 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-07-02 — R1 : reverse deps sorties du UserPromptSubmit

- Changement : `pre-turn-reminder.sh` et son miroir `.jinja` n'injectent plus la section « Dépendances inverses » à chaque prompt utilisateur.
- Justification : la baseline `measure-context-size.sh` montrait `5326 chars` dont `3285` de reverse deps. Cette section croît avec les arêtes du mesh et dominait le coût par tour.
- Contrat conservé : l'injection JIT par `features-for-path.sh --with-docs` charge toujours la fiche directe liée au path et ses `depends_on`.
- Cross-scope documenté : runtime dogfoodé (`core/dogfood-runtime-sync`), co-owner template focus (`core/graph-aware-injection`) et smoke E2E (`quality/smoke-test`).

## 2026-07-02 — R1 validation

- Preuve coût : `measure-context-size.sh` passe de `5326 chars` (`reverse_deps=3285`) à `2039 chars` (`reverse_deps=0`), soit `tokens~=(509..679)`.
- Preuve runtime/template : `check-dogfood-drift.sh` PASS après miroir `template/*.jinja`.
- Preuve comportement : `tests/smoke-test.sh` PASS ; l'étape `[10/28]` vérifie absence de reverse deps dans le reminder et injection JIT de la fiche directe + `depends_on`.

## 2026-07-02 — couverture incidente R2 ranking tracker

- Surface partagée : `template/.ai/scripts/features-for-path.sh.jinja`, utilisée par le hook PreToolUse complémentaire du reminder.
- Changement porté par `quality/features-for-path-ranking-and-matcher-correctness` : pénalité de ranking issue du tracker local.
- Impact contrat pre-turn : aucun changement du hook `UserPromptSubmit`; le JIT conserve l'injection fiches directes + `depends_on`.

## 2026-07-03 — done
- Intent : clôturer R1 `workflow/pre-turn-reminder`.
- Fichiers/surfaces : `.docs/features/workflow/pre-turn-reminder.md`, `.docs/features/workflow/pre-turn-reminder.worklog.md`.
- Décision : statut `done`; l'implémentation `db79921` a déjà retiré les dépendances inverses du hook par tour et le JIT `features-for-path.sh --with-docs` reste le report du graphe quand un path est connu.
- Validation : `bash .ai/scripts/measure-context-size.sh` → `reverse_deps chars=0`, total courant `1516 chars`, tokens estimés `(379..505)` ; `bash tests/smoke-test.sh` PASS dans le tour courant, incluant l'étape `[10/28]` reminder sans reverse deps + JIT `depends_on`.
- Next : aucune action immédiate ; passer à R2 côté `quality/features-for-path-ranking-and-matcher-correctness`.

## 2026-07-06 — couverture incidente (workflow/evidence-discipline)
- `template/.ai/reminder.md.jinja` (+ rendu racine) : hard rule « aucune supposition » ajoutée aux variantes FR et EN. Aucun changement du mécanisme d'injection. Reminder statique mesuré à 560 chars. Validation portée par `workflow/evidence-discipline`.
