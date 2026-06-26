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
- Lancer `check-feature-freshness.sh --worktree --strict` comme garde-fou de fraîcheur documentaire en fin de turn (read-only, code retour explicite ; parité du gate Claude — voir section dédiée).
- Écrire une trace runtime ignorée si le contrat du script le prévoit.

## Interdit comme garantie

- Auto-review.
- Hook LLM ou prompt hook dont le résultat n'est pas déterministe.
- Appel réseau non nécessaire.
- Mutation hors repo.
- Injection de contexte Codex équivalente à Claude tant que le contrat runtime n'est pas validé dans ce dépôt.

## Contrat d'une config future

Une config `.codex/` acceptable doit :

- référencer seulement des scripts versionnés sous `.ai/scripts/` ;
- définir un timeout quand le format le permet ;
- documenter le fallback si Codex n'exécute pas le hook ;
- passer `bash .ai/scripts/check-agent-config.sh`.

## Parité fraîcheur fin de turn (workflow/stop-turn-doc-gate)

Le gate Stop `stop-doc-gate.sh` est Claude-only (câblé dans `.claude/settings.json`, protocole `decision:block`). Pour un agent non-Claude, la parité se fait à deux niveaux.

**1. Toujours actif, universel (aucune config Codex).** Le hook git `commit-msg` (`.githooks/commit-msg` → `check-feature-freshness.sh --staged --strict`) bloque tout commit de code couvert sans sa fiche/worklog, quel que soit l'agent. C'est la garantie stable. Activation par clone : `git config core.hooksPath .githooks`.

**2. Opt-in, plus tôt (signal working-tree avant le commit).** Un projet PEUT brancher un hook Codex de fin de turn sur le **primitive agnostique** :

```bash
bash .ai/scripts/check-feature-freshness.sh --worktree --strict   # code retour 1 = bloquer
```

C'est le même moteur présence-based que le gate Claude, sans dépendre du protocole JSON Claude. `stop-doc-gate.sh` reste réservé au runtime Claude (il émet `decision:block` et lit `stop_hook_active`).

Selon la veille OpenAI (`https://developers.openai.com/codex/hooks`), Codex exposerait un événement `Stop` (fin de turn) configurable via `~/.codex/hooks.json` ou `[hooks]` dans `config.toml`. **À valider contre la surface live avant de s'en remettre** : si son contrat reproduit celui de Claude (`stop_hook_active` en entrée, `{"decision":"block","reason":...}` en sortie), `stop-doc-gate.sh` peut être réutilisé tel quel ; sinon, brancher le primitive `--worktree --strict` ci-dessus.

Exemple (NON livré par défaut — cf. décision « pas de `.codex/` par défaut ») :

```toml
# config.toml — exemple à valider contre la surface Codex live
[hooks.Stop]
command = "bash .ai/scripts/check-feature-freshness.sh --worktree --strict"
timeout = 20
```

Contraintes : opt-in ; `AIC_DOC_GATE=off` reste l'échappatoire ; le hook doit passer `check-agent-config.sh` et documenter le fallback (commit-msg + CI) si Codex ne l'exécute pas.

## Validation

Avant d'annoncer une parité :

```bash
bash .ai/scripts/check-agent-config.sh
bash .ai/scripts/check-commit-features.sh
bash .ai/scripts/check-features.sh
bash .ai/scripts/check-feature-freshness.sh --worktree --warn   # parité fraîcheur (read-only)
```

Le résultat reste un pilote tant que les hooks Git et la CI sont nécessaires pour la garantie de non-régression.
