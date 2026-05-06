# Worklog — workflow/auto-progress-file-filter

## 2026-05-06 23:25 — création
- Feature créée en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`.
- Scope : workflow.
- Intent initial : restaurer la sémantique de `progress.phase` en filtrant la transition `spec→implement` par type de fichier édité.
- Bug identifié : aujourd'hui, n'importe quelle édition (README, test, commentaire, fiche feature) bumpe la phase. Conséquence : `phase: implement` ne signifie plus « code en cours », juste « activité dans le périmètre ».
- Décision Phase 2 : positionnée en #4. Indépendant des fiches #1–#3 mais devient calibré après matcher correct (`#2`).
- Approche par défaut envisagée : filtre déterministe combinant matche `touches:` direct (pas `touches_shared:`) ET extension ∈ liste « structurelle » (par défaut exclure `.md`, `.txt`, `.lock`).
- Question ouverte : comportement sur fichiers de tests. Préférence par défaut : structurel (TDD valide la phase implement).
- Next : à reprendre dans un turn dédié pour passer en `status: active`, lire `auto-progress.sh`, définir précisément la liste d'extensions exclues, implémenter, ajouter tests reproductibles 1-4 décrits dans la fiche.
