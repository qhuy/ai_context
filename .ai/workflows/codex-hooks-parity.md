# Procédure interne — codex-hooks-parity

**Goal** : cadrer les hooks Codex comme garde-fous opt-in, déterministes et non LLM, sans remplacer les hooks Git ni les checks du mesh.

**Role** : Contrat de pilote. À utiliser avant d'ajouter ou modifier une configuration `.codex/`.

## Principes

- Les hooks Codex sont optionnels.
- Les hooks Git restent la convergence universelle entre Claude, Codex, autres agents et humains.
- Un hook Codex doit appeler une commande versionnée, testable et non interactive.
- Aucun hook Codex ne doit injecter du contexte lourd ou non borné par défaut.

## Autorisé

- Vérifier une commande `git commit` avec `.ai/scripts/check-commit-features.sh`.
- Alerter sur une commande destructive (`rm -rf`, reset, clean) avec un script local.
- Lancer un check lecture seule avec timeout explicite.
- Lancer le gate de fraîcheur documentaire en fin de turn (read-only ; voir section dédiée).
- Injecter le reminder borné par tour via `pre-turn-reminder.sh --format=text` sur `UserPromptSubmit` (contrat documenté par la doc officielle : le texte stdout est ajouté comme contexte développeur).
- Écrire une trace runtime ignorée si le contrat du script le prévoit.

## Interdit comme garantie

- Auto-review.
- Hook LLM ou prompt hook dont le résultat n'est pas déterministe.
- Appel réseau non nécessaire.
- Mutation hors repo.
- Injection de contexte par édition (équivalent `features-for-path.sh` en `PreToolUse`) : la sortie documentée de PreToolUse côté Codex ne prévoit aucun canal `additionalContext`, et l'outil d'édition Codex est `apply_patch`. Seule l'injection bornée du reminder par tour est autorisée.

## Config générée (`.codex/hooks.json`, opt-in)

Depuis 2026-07-06, le template génère `.codex/hooks.json` si `codex` est sélectionné ET `enable_codex_hooks=true` (défaut : `false` — jamais par défaut) :

- `UserPromptSubmit` → `bash .ai/scripts/pre-turn-reminder.sh --format=text`, timeout 5 s. Même contenu borné que le hook Claude, en texte brut.
- `Stop` → `bash .ai/scripts/stop-doc-gate.sh`, timeout 20 s. Même gate que Claude (échappatoire `AIC_DOC_GATE=off` et anti-boucle `stop_hook_active` inclus).

Trust model (doc officielle) : Codex ne charge les hooks projet que si la couche `.codex/` du repo est trustée — chaque utilisateur approuve au premier lancement. Fallback si Codex n'exécute pas les hooks : `commit-msg` (`check-feature-freshness.sh --staged --strict`) + CI, inchangés.

Toute config `.codex/` (générée ou locale) doit :

- référencer seulement des scripts versionnés sous `.ai/scripts/` ;
- définir un timeout explicite par hook (le défaut Codex est 600 s, trop laxiste) ;
- documenter le fallback si Codex n'exécute pas le hook ;
- passer `bash .ai/scripts/check-agent-config.sh` (validation stricte des `.codex/*.json` à objet `hooks`).

## Parité fraîcheur fin de turn (workflow/stop-turn-doc-gate)

Le gate Stop `stop-doc-gate.sh` parle le protocole `decision:block` + `stop_hook_active`, partagé par Claude Code et Codex (vérifié le 2026-07-06 sur la doc officielle). Il est câblé pour Claude via `stop-sequence.sh` dans `.claude/settings.json`, et pour Codex, opt-in, via la config générée `.codex/hooks.json`. Pour un agent sans hooks, la parité se fait à deux niveaux.

**1. Toujours actif, universel (aucune config Codex).** Le hook git `commit-msg` (`.githooks/commit-msg` → `check-feature-freshness.sh --staged --strict`) bloque tout commit de code couvert sans sa fiche/worklog, quel que soit l'agent. C'est la garantie stable. Activation par clone : `git config core.hooksPath .githooks`.

**2. Opt-in, plus tôt (signal working-tree avant le commit).** Un projet PEUT brancher un hook Codex de fin de turn sur le **primitive agnostique** :

```bash
bash .ai/scripts/check-feature-freshness.sh --worktree --strict   # code retour 1 = bloquer
```

C'est le même moteur présence-based que le gate Claude, sans dépendre du protocole JSON Claude. `stop-doc-gate.sh` reste réservé au runtime Claude (il émet `decision:block` et lit `stop_hook_active`).

Vérifié le 2026-07-06 (doc officielle `https://developers.openai.com/codex/hooks`) : l'événement `Stop` de Codex reproduit le contrat de Claude — `stop_hook_active` dans le JSON d'entrée, `{"decision":"block","reason":...}` sur stdout pour bloquer. `stop-doc-gate.sh` est donc réutilisé tel quel : c'est lui que `.codex/hooks.json` branche sur `Stop`.

⚠️ Ne PAS brancher le primitive brut sur l'événement `Stop` :

```toml
# ANTI-EXEMPLE — non bloquant sur Stop
[hooks.Stop]
command = "bash .ai/scripts/check-feature-freshness.sh --worktree --strict"
timeout = 20
```

Sur `Stop`, un code retour non nul est traité comme une erreur de hook signalée puis ignorée (Codex continue) ; le blocage passe par le JSON `decision:block`. Le primitive `--worktree --strict` reste l'outil agnostique pour la CI, les scripts et les agents sans protocole de hook.

Contraintes : opt-in ; hooks projet chargés seulement si la couche `.codex/` est trustée ; `AIC_DOC_GATE=off` reste l'échappatoire ; fallback documenté (commit-msg + CI) si Codex n'exécute pas le hook ; la config doit passer `check-agent-config.sh`.

## Validation

Avant d'annoncer une parité :

```bash
bash .ai/scripts/check-agent-config.sh
bash .ai/scripts/check-commit-features.sh
bash .ai/scripts/check-features.sh
bash .ai/scripts/check-feature-freshness.sh --worktree --warn   # parité fraîcheur (read-only)
bash tests/unit/test-check-agent-config.sh                      # cas hooks.json Codex
bash tests/smoke-test.sh                                        # étape génération opt-in .codex/
```

Le résultat reste un pilote : la génération et sa validation statique sont testées, mais aucune exécution live par le CLI Codex n'est intégrée à la CI. Les hooks Git et la CI restent la garantie de non-régression.
