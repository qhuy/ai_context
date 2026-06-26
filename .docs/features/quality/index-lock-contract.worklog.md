# Worklog — quality/index-lock-contract

## 2026-05-12 — création

- Feature créée via `.ai/workflows/feature-new.md`.
- Scope : quality.
- Intent initial : Corriger le contrat de lock de l'index feature.

## 2026-05-12 — implementation

- Fichiers/surfaces : `.ai/scripts/_lib.sh`, `template/.ai/scripts/_lib.sh.jinja`, `tests/smoke-test.sh`.
- Implementation :
  - suppression de la double affectation de `lock_dir` dans `with_index_lock` ;
  - conservation d'une cle de lock stable par UID avec override `AI_CONTEXT_LOCK_DIR` ;
  - remplacement du fallback "proceder sans lock" par un retour non nul `75` apres timeout ;
  - ajout d'une assertion smoke : si le lock est deja tenu, la commande protegee n'est pas executee.
- Validation intermediaire :
  - `bash .ai/scripts/check-feature-docs.sh quality/index-lock-contract` PASS ;
  - `bash .ai/scripts/check-features.sh` PASS ;
  - `bash .ai/scripts/check-dogfood-drift.sh` PASS ;
  - `git diff --check` PASS ;
  - `bash tests/smoke-test.sh` PASS.

## 2026-05-12 10:09 — DONE

### Evidence

- Build : `bash .ai/scripts/build-feature-index.sh --write` ✅
- Tests : `bash tests/smoke-test.sh` ✅
- Gate : `bash .ai/scripts/check-shims.sh` ✅ ; `bash .ai/scripts/check-ai-references.sh` ✅ ; `bash .ai/scripts/check-features.sh` ✅ ; `bash .ai/scripts/check-feature-docs.sh` ⚠️ legacy warnings only ; `bash .ai/scripts/check-feature-coverage.sh` ✅ ; `bash .ai/scripts/measure-context-size.sh` ✅ ; `bash .ai/scripts/check-feature-docs.sh --strict quality/index-lock-contract` ✅ ; `bash .ai/scripts/check-dogfood-drift.sh` ✅ ; `git diff --check` ✅

### Résumé livré

- `with_index_lock` utilise une seule cle de lock stable par UID.
- Le timeout de lock retourne une erreur au lieu d'executer la commande sans verrou.
- Le template Copier reste aligne avec le runtime dogfood.
- Le smoke test couvre le cas timeout : la commande protegee ne s'execute pas si le lock est tenu.

### Commit suggéré

feat(quality): corriger le contrat de lock index
## 2026-05-12 — impact Q4 régressions ciblées

- Surface : `tests/smoke-test.sh`.
- Impact : le contrat de lock Q1 est maintenant verifie aussi par le test cible Q4 via un timeout qui ne doit pas executer la commande protegee.
- Validation : `bash tests/unit/test-targeted-regressions.sh` PASS ; `bash tests/smoke-test.sh` PASS.

## 2026-05-12 — merge veille Claude/Codex

- Surface : `tests/smoke-test.sh`.
- Impact : resolution de merge conservant la prevalidation lock existante et ajoutant le test agent-config sur une etape separee.
- Validation : freshness stricte et smoke-test relances avant push main.

## 2026-06-01 15:36 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
  - tests/smoke-test.sh

## 2026-06-01 — récupération des locks orphelins (audit U8)

- `with_index_lock` (`_lib.sh` + `.jinja`) : un process tué brutalement (SIGKILL/crash) laissait `$lock_dir` orphelin → tout run ultérieur timeout en 3s (return 75) à perpétuité. Ajout d'une reprise : un lock plus vieux que `AI_CONTEXT_LOCK_STALE_MIN` (défaut 1 min) est considéré orphelin et récupéré une fois (les opérations sous lock sont sub-secondes, via `find -mmin` portable).
- Contrat préservé : un lock frais (réellement tenu) timeout toujours sans exécuter la commande.
- Test : `tests/unit/test-targeted-regressions.sh` étendu (lock orphelin backdaté → récupéré + commande exécutée). PASS.

## 2026-06-01 22:47 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-06-19 14:53 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-19 17:52 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh

## 2026-06-19 18:03 — auto
## 2026-06-25 12:34 — auto
- Fichiers modifiés :
  - template/.ai/scripts/_lib.sh.jinja

## 2026-06-25 — impact OKF (additif, hors comportement)
- `_lib.sh(.jinja)` étendu par `core/okf-strict-profile` : ajout de `TYPE_ENUM` + `is_valid_type` (helpers du profil OKF).
- Aucun impact sur le contrat de lock (`with_index_lock`) : ajout strictement additif, comportement inchangé. Feature reste `done`.

## 2026-06-26 11:17 — auto
- Fichiers modifiés :
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja

## 2026-06-26 11:34 — auto
- Fichiers modifiés :
  - tests/smoke-test.sh
