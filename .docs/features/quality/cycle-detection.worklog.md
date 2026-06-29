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
