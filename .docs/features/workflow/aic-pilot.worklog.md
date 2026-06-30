# Worklog — workflow/aic-pilot

## 2026-06-29 — création

- Feature créée via cadrage conversationnel validé par l'utilisateur.
- Scope : workflow.
- Intent initial : ajouter `aic-pilot` comme couche de pilotage transverse et faire débrayer `aic-frame` quand une demande est trop large.

## 2026-06-30 — implémentation + reclassification freshness

- Ajout du skill public `aic-pilot` côté Claude/Codex et templates Copier.
- Ajout du template durable `.docs/pilots/0000-template.md` + rendu `{{docs_root}}/pilots`.
- `aic-frame` route désormais vers `pilot` pour audits larges, suivis transverses et paquets de bugs/features/décisions.
- `aic.sh` expose seulement un bootstrap `pilot` informatif : le pilotage reste skill-only et conversationnel.
- Dogfood update/drift préservent les registres pilot datés comme les frames datés.
- Reclassification associée au contrat freshness `(a')` : `aic-pilot` garde l'ownership exact de ses skills et registres ; les surfaces partagées (`aic.sh`, README, Copier, dogfood, smoke, frame) restent reliées en `touches_shared`.
