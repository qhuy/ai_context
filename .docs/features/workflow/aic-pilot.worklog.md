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

## 2026-06-30 15:41 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-06-30-ze-solution.md

## 2026-06-30 16:12 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-06-30-ze-solution.md

## 2026-06-30 16:29 — auto
- Fichiers modifiés :
  - .docs/pilots/2026-06-30-ze-solution.md

## 2026-06-30 — pilotage "ZE SOLUTION" (usage du skill)

- Session de pilotage via `aic-pilot` : registre `.docs/pilots/2026-06-30-ze-solution.md` créé et maintenu (7 axes triés, axe directeur "prouver & positionner").
- Routage exécuté : P1 → `product/agent-efficacy-benchmark`, P3 → `quality/feature-schema-validator`, P2 (hedge) → HANDOFF product→core → `core/agents-md-native-collapse-path`.
- Contrat vérifié en conditions réelles : `aic-pilot` garde l'ownership de `.docs/pilots/**` (`touches:`), donc la freshness staged exige le worklog `aic-pilot` quand le registre change.
