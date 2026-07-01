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
