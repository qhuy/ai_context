# Worklog — workflow/aic-frame-external-reference

## 2026-05-11 — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : workflow
- Intent initial : Rendre aic-frame exploitable comme cadrage durable référençable
- Contraintes initiales : ne pas modifier AI Debate, ne pas importer ses workflows, préserver la confirmation humaine avant création de feature.

## 2026-05-11 — implémentation
- Rédaction `aic-frame` resserrée sur les workflows Claude/Codex runtime et templates.
- Ajout du challenge IA, du routage `feature|doc|adr|manual|diagnose|dropped`, des critères terminé/bloqué et du mode durable `execution_ref`.
- Garde-fous conservés : pas de code, pas de feature sans confirmation humaine, pas d'import de workflow externe.
- Validation : `check-features`, `check-feature-docs workflow/aic-frame-external-reference`, `check-dogfood-drift`, `git diff --check` PASS.
- Smoke complet : PASS sur copie temporaire avec index Git propre.
- Note : le smoke complet lancé directement depuis le repo courant échoue au test `[6/28]` parce que l'index Git contient déjà des fichiers staged hors de cette feature ; je n'ai pas unstaged ces changements.

## 2026-05-11 — questions de cadrage
- Correction post-review : une intention trop vague doit déclencher toutes les questions nécessaires au cadrage, pas une seule question bloquante.
- Les questions sont bornées aux décisions utiles, groupées par thème et séparées entre `Bloquant maintenant` et `À valider plus tard`.
