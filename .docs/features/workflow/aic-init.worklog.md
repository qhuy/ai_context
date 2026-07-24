# Worklog — workflow/aic-init

## 2026-07-24 09:00 — spec / cadrage initial
- Fiche créée depuis le pilotage `workflow/aic-pilot` (item P12 de l'audit fonctionnel général du 2026-07-23).
- Cadrage : successeur de `ai-context.sh first-run` (retiré v0.13 sans remplacement), doit rester non bloquant et idempotent.
- next : implémenter `aic-init.sh`, wirer la route `init` dans `aic.sh`, mirrorer template, étendre smoke-test.

## 2026-07-24 09:20 — implement / script + wiring
- `.ai/scripts/aic-init.sh` créé : doctor.sh (informatif) → hooks git idempotents → état mesh bref → pointeur prochaine étape.
- Route `init` ajoutée à `.ai/scripts/aic.sh` (dispatch + aide), vérifiée en exécution réelle sur le dogfood repo.
- Mirroré vers `template/.ai/scripts/aic-init.sh.jinja` (identique, aucune variable Jinja nécessaire) et `template/.ai/scripts/aic.sh.jinja`.
- Décision : pas de fiche d'exemple non vide (sous-périmètre initial de P12) — `FEATURE_TEMPLATE.md` + pointeur affiché suffisent.
- next : étendre `tests/smoke-test.sh`, rebuild index, gates, commit.
