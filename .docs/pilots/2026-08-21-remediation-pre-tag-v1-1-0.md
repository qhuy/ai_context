---
pilot_id: "2026-08-21-remediation-pre-tag-v1-1-0"
status: "done"
source: "audit pré-release v1.0.1..15afc985 et contre-review Codex/Claude du 2026-08-21"
scope_primary: "product"
created_at: "2026-08-21"
updated_at: "2026-08-21"
active_item: ""
active_question: ""
next_hint: "Attendre la confirmation explicite du mainteneur avant de créer les commits ; ne pas taguer ni pousser."
---

# Pilot — Remédiation pré-tag v1.1.0

## Intention

Solder les défauts confirmés par l'audit pré-release sans mélanger les contrats,
les scopes ni les travaux mainteneur, avant toute décision de tag v1.1.0.

## Résultat attendu

- Les items R1, R2, R3 et R4a sont corrigés et validés sur un checkout propre.
- R4b reste explicitement différé tant qu'aucune contention inter-repos n'est mesurée.
- R4c décrit fidèlement le support Copilot à partir de sources officielles datées.
- Le WIP mainteneur, le worktree Claude, le tag et le push restent hors périmètre.

## Carte des sujets

| ID | Sujet | Statut | Scope probable | Route | Preuve attendue |
|---|---|---|---|---|---|
| R1 | Procédure Copier pour consommateurs legacy | done | product | docs | v0.13.0 réparé puis update documenté : sans trust exit 4, avec trust/defaults exit 0 |
| R2 | Self-check benchmark sur clone frais | done | product + handoff core | fix | `run-bench.sh --self-check` puis smoke PASS sur clone frais |
| R3 | Fraîcheur d'index quand la projection ne change pas | done | core | fix + décision de contrat | smoke PASS : 4 consommateurs, un seul scan, mtime JSON et `generated_at` stables |
| R4a | Identifiants de session `.` et `..` | done | core | fix | test discriminant PASS : sous-dossiers `_.` / `_..`, aucun marqueur hors base |
| R4b | Verrou d'index partagé entre dépôts | dropped | quality | diagnose différé | mesure d'une contention réelle avant toute réouverture du contrat |
| R4c | Support natif de Copilot Code Review | done | core | docs | registre et aide alignés sur des sources GitHub officielles datées |

## Question active

Contexte affiché :

- L'ordre R1 → R2 → R3 → R4a puis R4c est validé par le mainteneur.
- Le fichier-témoin séparé est l'option préférée pour R3, sous réserve des tests de consommateurs.

Question à traiter maintenant :

- Aucune : exécution autorisée le 2026-08-21.

## Décisions actées

| Date | Item | Décision | Raison | Suite |
|---|---|---|---|---|
| 2026-08-21 | R1 | Ajouter la réparation des métadonnées avant `--trust` pour les anciens scaffolds | v0.13.0 ne matérialise pas toujours `.copier-answers.yml` | Corriger la procédure et rejouer l'update |
| 2026-08-21 | R2 | Préférer un `.gitkeep` avec exception ciblée | Le self-check reste sans mutation et la garde de chemin est conservée | HANDOFF product → core pour `.gitignore` |
| 2026-08-21 | R3 | Publier `.ai/.feature-index.checked` après chaque scan `--write` réussi | Le JSON garde son mtime et son `generated_at` stables, tandis que le helper commun mémorise le scan sans boucle | Tester les quatre consommateurs dans le smoke Copier |
| 2026-08-21 | R4b | Différer | La clé globale par UID est documentée et aucun timeout inter-repos n'est reproduit | Mesurer avant de rouvrir `quality/index-lock-contract` |
| 2026-08-21 | R4c | Conserver le shim comme option spécifique Copilot | `AGENTS.md` est natif, mais Copilot lit aussi ses instructions dédiées | Sourcer la nuance dans l'édit |

## Handoffs

```text
HANDOFF
  from_scope: product
  to_scope: core
  status: prêt — validé par le mainteneur le 2026-08-21
  files_touched: [.gitignore, docs/benchmarks/runs/.gitkeep]
  pending: [rendre le dossier présent dans un clone frais sans modifier le self-check]
  risks: [réintroduire le versionnement des résultats de benchmark si l'exception gitignore est trop large]
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| R1 | Mise à jour de `docs/upgrading.md` | Codex | fait | v0.13.0 : réparation exit 0, update sans trust exit 4, avec trust/defaults exit 0 |
| R2 | `.gitkeep` + exception ciblée | Codex | fait | clone frais : `.gitkeep` présent, self-check et smoke exit 0 |
| R3 | Témoin de fraîcheur + contrat + tests | Codex | fait | tests ciblés et smoke complet PASS ; étape 9 vérifie les 4 consommateurs |
| R4a | Normalisation des tokens de session | Codex | fait | test session-dedup + ranking + syntaxe PASS ; drift inclus dans la gate finale |
| R4c | Registre et aide Copier | Codex | fait | registre/test ciblé/manifeste PASS ; Claude pending exit 2 attendu |

## Validation de clôture

- Tous les items sont `done`, `dropped`, `handoff` ou explicitement reportés.
- Les fiches couvrantes et leurs worklogs portent les décisions et preuves.
- Les checks ciblés, le drift dogfood et la quality gate sont verts.
- Le test exigeant un environnement propre est rejoué hors du checkout mainteneur.

## Next hint

Attendre la confirmation explicite du mainteneur avant de créer les commits ;
conserver le tag, le push et les quatre actions mainteneur hors périmètre.

## Clôture du pilot — 2026-08-21

- R1, R2, R3, R4a et R4c sont corrigés ; R4b reste différé faute de contention mesurée.
- `bash tests/smoke-test.sh` PASS, y compris upgrade Copier, benchmark, index, sessions et rendu Copilot.
- Quality gate finale PASS : fraîcheur staged stricte, 118/118 fichiers couverts, 0 orphelin, docs strictes et dogfood drift vert.
- Deux advisories historiques restent non bloquants : sur-couverture `touches:` et estimation de tokens faute de `tiktoken` exact.
- Aucun commit, tag, push ni WIP mainteneur modifié pendant le pilot.
