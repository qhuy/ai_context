# Worklog — quality/features-for-path-ranking-and-matcher-correctness

## 2026-05-06 23:05 — création
- Feature créée en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`.
- Scope : quality.
- Intent initial : ranker l'injection PreToolUse par spécificité du glob (top-K) ET corriger le matcher globstar pour bash 3.2 sur les patterns multi-niveaux.
- Bug matcher confirmé en local :
  - `_lib.sh:82-84` : `enable_globstar()` est `shopt -s globstar 2>/dev/null || true`, no-op silencieux sur bash 3.2 macOS.
  - `_lib.sh:118-121` : branche spéciale couvre uniquement `prefix/**` simple. Les patterns `src/**/*.ts`, `foo-*/**`, etc. retombent sur le glob Bash standard ligne 116, qui sur 3.2 traite `**` comme `*` (un seul niveau).
  - Bash local : `/bin/bash 3.2.57(1)-release arm64-apple-darwin25`. Critère P1 satisfait.
- Bug ranking confirmé : aucun tri, aucun top-K, aucune métrique de spécificité dans `features-for-path.sh`. Une feature avec `touches: src/**` matche tout fichier sous src/ et est injectée comme une feature avec `touches: src/auth/payment/intent.ts`.
- Décision Phase 2 : positionnée en #2 selon convergence Claude/Codex round 4, après `quality/review-delta-uncommitted-coverage` (#1).
- Approche par défaut : Option B (Codex round 3) — fix matcher comme prérequis interne du ranking, acceptance bloque livraison.
- Top-K par défaut envisagé : 3, configurable via `AI_CONTEXT_FEATURES_TOP_K`.
- Critère de spécificité par défaut envisagé : longueur du préfixe non-glob (decroissante), puis nombre de wildcards (croissant) en départage.
- Next : à reprendre dans un turn dédié pour passer en `status: active`, lire le code complet de `features-for-path.sh` + `_lib.sh`, arbitrer entre fix matcher A/B/C, implémenter ranking + acceptance, ajouter tests reproductibles.

## 2026-05-07 — correction post-review Codex
- Codex post-review du commit `736b5e0` : risque pointé sur le contrat exit code.
- Vérification factuelle :
  - [.claude/settings.json:26-35](.claude/settings.json:26) : PreToolUse Write|Edit|MultiEdit invoque `bash .ai/scripts/features-for-path.sh` avec timeout 3.
  - Consommateurs identifiés (5) : `aic.sh`, `auto-worklog-log.sh` (via `features_matching_path`), `measure-context-size.sh`, hook PreToolUse direct, hook PostToolUse via `auto-worklog-log.sh`.
  - Selon la doc Claude Code, un hook PreToolUse exit code 2 bloque l'opération. Sans clause explicite, l'auteur de l'implémentation pourrait choisir exit 2 sur pattern cassé et casser tous les hooks.
- Fix : ajout du **contrat dual exit code** dans la fiche.
  - Mode strict (CLI/doctor) : exit ≠ 0 autorisé, fail hard utile pour debug.
  - Mode hook (défaut) : warning stderr + exit 0 toujours. Un pattern cassé dans une fiche ne doit JAMAIS bloquer l'agent.
  - Détection : flag `--strict` ou env var `AI_CONTEXT_FEATURES_STRICT=1`.
- Sections impactées : Invariants, Comportement attendu (point 4), Contrats (nouvelle sous-section dual exit code), Historique.

## 2026-05-07 — re-review Codex : contrat à 4 niveaux
- Codex re-review du commit `84cfbe9` : contrat dual encore trop étroit, mélange `features-for-path.sh` et `_lib.sh::features_matching_path`. 5 consommateurs directs de la fonction (pas du script) confirmés en local : `auto-worklog-log.sh`, `check-feature-freshness.sh`, `pr-report.sh`, `review-delta.sh`, `features-for-path.sh` lui-même.
- Ambiguïté résiduelle : "CLI direct = strict" contredisait "défaut = best-effort".
- Fix : section "Contrats" reformulée en 4 niveaux explicites :
  - Niveau 1 : matcher `_lib.sh::features_matching_path` (fonction interne, ne décide pas de la politique exit).
  - Niveau 2 : wrapper `features-for-path.sh` (best-effort par défaut, strict opt-in via `--strict` ou env var).
  - Niveau 3 : hooks Claude (best-effort imposé, jamais `--strict`).
  - Niveau 4 : checks/CI/doctor (strict requis, passent explicitement `--strict`).
- Décision tranchée : `bash features-for-path.sh <path>` sans flag = best-effort. Pas d'auto-détection CLI/hook qui pourrait mal classer. Strict = opt-in pur.
- Question ouverte (à arbitrer en phase implement) : `review-delta.sh` reste-t-il en best-effort (compat utilisateur) ou bascule strict pour traçabilité ?
