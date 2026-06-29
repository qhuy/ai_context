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

## 2026-05-12 — arbitrage AI Debate 0015 appliqué
- Décision humaine : validation du cahier des charges et du plan A1-A5.
- Ajout du cadrage adaptatif automatique `low|standard|high`, avec justification visible et override humain explicite.
- Ajout de la table d'incertitudes pour distinguer blocage immédiat, hypothèse de travail, risque accepté et validation différée.
- Création du template durable `.docs/frames/0000-template.md` et de sa version Copier.
- Vérification du schéma : `external_refs.frame` est déjà autorisé par `.ai/schema/feature.schema.json`.
- Repositionnement de `aic.sh frame` comme bootstrap de contexte, avec alias explicites `frame-bootstrap` et `frame-context`.
- Documentation utilisateur clarifiée dans `README.md`, `README_AI_CONTEXT.md` et le template README.
- Validations PASS : `bash -n .ai/scripts/aic.sh`, `bash -n template/.ai/scripts/aic.sh.jinja`, `bash .ai/scripts/aic.sh frame "test cadrage"`, `check-features`, `check-feature-docs --strict workflow/aic-frame-external-reference`, `check-dogfood-drift`, `check-agent-config`, `check-ai-references`, `check-feature-coverage`, `check-shims`, `measure-context-size`, `tests/smoke-test.sh`.

## 2026-06-19 11:47 — auto
- Fichiers modifiés :
  - .docs/frames/2026-06-19-project-overlay-scope-registry.md
## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/scripts/aic.sh.jinja

## 2026-06-25 — impact OKF (additif, hors comportement)
- `aic.sh(.jinja)` étendu par `core/okf-strict-profile` : sous-dispatch `migrate okf-type` ; le défaut `migrate` et la commande `frame` restent inchangés.
- Aucun impact sur le cadrage `aic frame` / `execution_ref` : extension rétro-compatible. Feature reste `done`.

## 2026-06-28 — couverture incidente (frame remédiation : avancement A1/A2)
- `.docs/frames/2026-06-28-audit-strategique-remediation.md` mis à jour (avancement Phase 1). Aucun changement de comportement.

## 2026-06-28 — couverture incidente (frame remédiation : avancement 2e vague + A9)
- `.docs/frames/2026-06-28-audit-strategique-remediation.md` mis à jour. Aucun changement de comportement.

## 2026-06-28 23:10 — auto
- Fichiers modifiés :
  - .docs/frames/2026-06-28-audit-strategique-remediation.md

## 2026-06-28 — couverture incidente (frame remédiation : C1 cadré + fiche)
- `.docs/frames/2026-06-28-audit-strategique-remediation.md` mis à jour (C1 cadré, fiche créée). Aucun changement de comportement.

## 2026-06-29 — couverture incidente (frame remediation : C1 core livre)
- Frame mis a jour (C1 implemente). Aucun changement de comportement.

## 2026-06-29 11:39 — auto
- Fichiers modifiés :
  - .docs/frames/2026-06-28-audit-strategique-remediation.md

## 2026-06-29 — couverture incidente (frame remediation : C2c livre)
- Frame mis a jour (C2c fait, C2a/b routes vers feature-mesh). Aucun changement de comportement.

## 2026-06-29 — couverture incidente (frame remediation : C2b livre)
- Frame mis a jour (C2b fait, C2a = enhancement a cadrer). Aucun changement de comportement.
