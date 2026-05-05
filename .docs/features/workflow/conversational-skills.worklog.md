# Worklog — workflow/conversational-skills

## 2026-04-24 — création

- Feature créée par /aic-feature-new
- Scope : workflow
- Intent initial : skill ombrelle `/aic` qui accepte une phrase libre et infère intent + cible + champs avant d'invoquer le bon skill `/aic-*` sous le capot
- Déclencheur : friction UX rencontrée par le créateur lui-même pendant le dog-fooding (cf commit c4d504e + discussion qui a suivi)
- Décision : approche A (sucre syntaxique additif), pas de hook auto, pas de TUI
- Prochaine étape : valider la liste exhaustive des intents détectables + écrire SKILL.md + workflow.md sous `template/.claude/skills/aic/`

## 2026-04-24 — re-spec v3 (auto-progression invisible)

- Bascule de design dans la même séance dog-fooding, déclenchée par 2 questions du créateur :
  1. *« quel skill utiliser pour la suite ? »* → révèle que les 5 skills /aic-* (hors resume) sont juste de la **comptabilité d'état** déclenchée à la main
  2. *« je dois pas dire 'c'est livré', tu lances les tests, tu sais ! »* → confirme que ces transitions doivent être **inférées par l'agent**, pas demandées à l'humain
- Itérations explorées :
  - v1 : wrapper additif `/aic` au-dessus des 6 skills (commit 18f4c91) — *trop dense*
  - v2 : remplacement des 6 skills par 1 conversationnel `/aic` — *toujours manuel*
  - v3 : **auto-progression invisible par hook `Stop` ; `/aic` rétrogradé en override** ✅
- Préfixe forcé `/aic` sur tous les prompts envisagé puis rejeté (friction sans gain).
- Renommage de l'`id` rejeté pour stabilité (extension du périmètre, pas changement de fond).
- Garde-fous : règle asymétrique invisible / rapporté / demande explicite selon réversibilité de l'action.
- Snapshot d'état stocké en `.ai/.progress-history.jsonl` pour permettre `/aic undo`.
- next : implémenter le hook Stop d'auto-progression + SKILL.md /aic + assertion smoke-test ; rouvrir workflow/claude-skills pour acter la réduction de périmètre.

## 2026-04-24 12:23 — auto
- Fichiers modifiés :
  - copier.yml
  - template/AGENTS.md.jinja

## 2026-04-24 14:10 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-04-24 18:27 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh

## 2026-04-28 11:23 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh

## 2026-04-28 12:04 — auto
- Fichiers modifiés :
  - copier.yml
  - tests/smoke-test.sh

## 2026-05-04 — freshness
- Impact indirect : le wrapper Codex `aic` reprend la sémantique conversationnelle de l'override `/aic`.
- Validation associée : smoke-test complet PASS.
## 2026-05-05 — freshness
- Impact transversal : le message post-copy guide les règles locales vers `.ai/project/index.md` sans ajouter de skill obligatoire.
- Validation associée : smoke-test PASS.
