# Worklog — core/agents-md-shim-canonical

## 2026-06-28 — création (aic-frame, item C1)
- Fiche créée suite au cadrage `aic-frame` de l'item C1 (frame de remédiation 2026-06-28).
- Arbitrages tranchés par l'utilisateur : (a) nouvelle fiche dédiée (vs extension de `aic-surface-canonical`) ; (b) modèle **import `@AGENTS.md` + fallback tailored** (symlink rejeté).
- Phase `spec` : cadrée, non implémentée. Gate d'implémentation explicite = vérifier empiriquement le support `@import` par agent (Claude d'abord, puis Cursor/Gemini/Copilot) AVANT tout code.
- HANDOFF : pitch → `product/readme-positioning` ; génération Copier → `core/template-engine`.

## 2026-06-29 — gate @import PASSE
- Verif 4 plateformes (Claude via claude-code-guide, autres web). Claude @path OK + AGENTS.md natif (a confirmer) ; Gemini @path OK ; Cursor/Copilot pas d'import fiable MAIS lisent AGENTS.md nativement.
- Modele retenu : AGENTS.md base neutre ; CLAUDE.md/GEMINI.md = @AGENTS.md + lignes agent ; Cursor/Copilot = lecture native (pas de shim requis) ou tailored minimal.
- Phase spec -> implement. Etape suivante : rendre AGENTS.md neutre + convertir shims + etendre check-shims.

## 2026-06-29 — import model livre
- AGENTS.md neutralise (base) ; CLAUDE.md = MUST-read + @AGENTS.md + pointeur Claude ; template/GEMINI.md.jinja = @AGENTS.md. Cursor/Copilot laisses tailored (fallback).
- Checks verts : check-shims (AGENTS 15 l. / CLAUDE 7 l.), check-dogfood-drift (parite), smoke-test.
- Reste avant DONE : note migration CHANGELOG/docs/upgrading (forme des shims change a copier update) ; check-shims dynamique par agents actives ; confirmer #34235.
- Fichiers : AGENTS.md, CLAUDE.md, template/AGENTS.md.jinja, template/CLAUDE.md.jinja, template/GEMINI.md.jinja

## 2026-06-30 — check-shims : verrou de self-suffisance d'AGENTS.md (init. core/agents-md-native-collapse-path, P2)
- `check-shims.sh` (surface possédée ici) : nouvelle assertion exigeant les hard rules inline dans `AGENTS.md` — échoue si le shim est réduit à un simple pointeur. Verrouille la précondition du chemin de collapse (AGENTS.md seul suffit aux règles).
- Runtime + `.jinja` (parité). Test dédié `tests/unit/test-agents-md-self-sufficient.sh`. check-shims réel PASS (nouvelle ligne « AGENTS.md auto-suffisant »), dogfood-drift aligné.
- Initiative portée par `core/agents-md-native-collapse-path` (P2, pilot `2026-06-30-ze-solution`) ; recoupe le follow-up « check-shims dynamique par agents activés » listé ci-dessus (non traité ici).

## 2026-07-03 — check-shims dynamique par agents activés
- Intent : fermer le follow-up C1 restant — `check-shims.sh` ne doit plus vérifier seulement `AGENTS.md` + `CLAUDE.md` en dur.
- Fichiers/surfaces : `.ai/scripts/check-shims.sh`, `template/.ai/scripts/check-shims.sh.jinja`, `tests/unit/test-check-shims-dynamic-agents.sh`.
- Décision : lire `agents` depuis `.copier-answers.yml` quand il existe ; fallback dogfood/anciens scaffolds sur les shims présents ; `codex` et `cursor` n'ajoutent pas de root shim dédié.
- Validation : `bash -n` runtime/template, `shellcheck -S error`, `bash tests/unit/test-check-shims-dynamic-agents.sh`, `bash .ai/scripts/check-shims.sh`, rendu Copier ciblé `claude+gemini+copilot`, `bash .ai/scripts/check-dogfood-drift.sh`, `bash .ai/scripts/check-features.sh --no-write`, freshness worktree strict et `bash tests/smoke-test.sh` PASS.
- Next : confirmer séparément la lecture native d'`AGENTS.md` par Claude (#34235) pour décider si `CLAUDE.md` devient optionnel.

## 2026-07-03 — follow-up #34235 transféré au registre natif
- `core/agents-md-native-collapse-path` porte désormais `.ai/native-context-support.tsv` et `check-agent-native-context.sh --require-confirmed <agent>`.
- Impact ici : `check-shims` reste propriétaire des shims activés ; la décision de rendre `CLAUDE.md` optionnel ne vit plus dans cette fiche mais dans le registre natif.

## 2026-07-03 — DONE : clôture du modèle de shims dérivés
- Intent : fermer la fiche C1 après livraison du modèle `AGENTS.md` base + shims dérivés et transfert du kill criterion Claude.
- Fichiers/surfaces : fiche/worklog `core/agents-md-shim-canonical`.
- Evidence : `check-feature-docs --strict core/agents-md-shim-canonical` PASS, `check-shims` PASS, `check-dogfood-drift` PASS ; smoke complet déjà passé dans le commit `9affa45` qui a branché le registre natif.
- Décision : Doc Impact Decision C — fiche feature mise à jour, aucun changement runtime dans ce commit de clôture.
- Risques : pas de breaking change, pas de migration de données, pas d'impact sécurité/auth/tenancy ; compatibilité arrière inchangée.
- Next : aucune action immédiate ; rouvrir seulement si le modèle de shims ou le contrat `.copier-answers.yml` change.

## 2026-07-06 — couverture incidente (workflow/evidence-discipline)
- `AGENTS.md` (+ `template/AGENTS.md.jinja`) : hard rule « Aucune supposition : prouver (code lu, commande, doc) ou marquer Hypothèse » ; « Shim lean » condensé en 1 ligne — AGENTS.md reste à 15 lignes (limite MAX_LINES), auto-suffisance préservée (test PASS). Validation portée par `workflow/evidence-discipline`.
