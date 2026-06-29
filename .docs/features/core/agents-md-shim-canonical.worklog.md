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
