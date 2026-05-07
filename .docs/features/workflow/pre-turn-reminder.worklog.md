
## 2026-05-07 — freshness
- Impact indirect : `template/.ai/scripts/features-for-path.sh.jinja` étendu (ranking
  top-K + matcher path-aware). Le hook PreToolUse Claude bénéficie du ranking sans
  changement de contrat externe.
- Validation : smoke-test PASS, copier copy direct PASS.

## 2026-05-07 01:00 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 01:10 — auto
- Fichiers modifiés :
  - template/.ai/scripts/features-for-path.sh.jinja

## 2026-05-07 — freshness
- Impact direct : `template/.ai/scripts/features-for-path.sh.jinja` étendu pour appeler `context-relevance-log.sh inject` à la fin (livraison Phase 2 #3). Le hook PreToolUse Claude bénéficie du tracker sans changement de contrat externe.
- Validation associée : copier copy direct PASS, 8 cas test-context-relevance PASS.
