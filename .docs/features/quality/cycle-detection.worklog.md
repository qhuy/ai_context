# Worklog — quality/cycle-detection


## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - template/.ai/scripts/check-features.sh.jinja

## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/scripts/check-features.sh.jinja

## 2026-06-29 — couverture incidente (C2b : reconciliation id schema/checker)
- Surface partagee touchee (check-features.sh via .ai/** ou touches:, ou tests/unit/**). Aucun changement de comportement propre. (Taxe sur-couverture touches: — cf. quality/touches-breadth-guard.)

## 2026-06-29 — reclassage Signal A check-features
- `template/.ai/scripts/check-features.sh.jinja` passe de `touches:` direct à `touches_shared:` : la détection de cycles reste liée en review sans bloquer la fraîcheur documentaire à chaque évolution du checker.
- Aucun changement de comportement propre à la DFS de cycles.

## 2026-06-29 — DFS exponentielle → tri topologique de Kahn O(V+E) (audit A13)
- La détection de cycles passe d'une DFS récursive (exponentielle sur DAG diamant — mesuré k=20 ≈ 76s, k≥22 timeout) à un tri topologique de Kahn O(V+E) (k=24 instantané). L'invariant `O(V+E)` de la fiche, **faux** auparavant, est désormais vrai. Message d'erreur : liste des features impliquées (au lieu d'un chemin `A → B → A`).
- Code dans `check-features.sh` runtime + `.jinja` (commit `fix(core)` `fd72e14`). Ici : maj fiche + garde anti-régression `tests/unit/test-cycle-detection-diamond.sh` (diamant acyclique → PASS sans faux cycle ; arête retour → cycle détecté). Test ajouté en `touches:` direct de la fiche.

## 2026-07-03 — done
- Intent : clôturer `quality/cycle-detection` après livraison Kahn et stabilisation de la sur-couverture `check-features`.
- Fichiers/surfaces : `.docs/features/quality/cycle-detection.md`, `.docs/features/quality/cycle-detection.worklog.md`.
- Décision : statut `done` ; `check-features.sh` reste en surface partagée et la garde directe est le test diamant.
- Validation : `bash tests/unit/test-cycle-detection-diamond.sh` PASS ; `bash .ai/scripts/check-features.sh --no-write` PASS à relancer dans la gate avant commit.
- Next : aucune action immédiate.
