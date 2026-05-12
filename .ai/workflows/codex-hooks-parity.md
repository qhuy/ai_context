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

## Validation

Avant d'annoncer une parité :

```bash
bash .ai/scripts/check-agent-config.sh
bash .ai/scripts/check-commit-features.sh
bash .ai/scripts/check-features.sh
```

Le résultat reste un pilote tant que les hooks Git et la CI sont nécessaires pour la garantie de non-régression.
