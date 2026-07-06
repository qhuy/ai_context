# Procédure interne — evidence-discipline

**Goal** : éliminer les suppositions des sorties d'agent — toute affirmation de fonctionnement porte sa preuve ou son étiquette d'incertitude.

**Role** : Contrat transverse. S'applique à toute analyse, review, diagnostic, cadrage ou affirmation sur le comportement d'un système (code, outil, API, doc).

## Règle

Une affirmation de fonctionnement (« X fait Y », « le hook bloque », « cette lib supporte Z ») n'est recevable que sous l'une de ces trois formes :

| Étiquette | Exigence |
|---|---|
| **Prouvé** | source vérifiable citée : fichier:ligne lu, commande exécutée avec sa sortie, doc officielle (URL), mesure |
| **Hypothèse** | marquée explicitement comme telle, avec ce qui la confirmerait ou l'infirmerait |
| **À vérifier** | inconnue nommée ; BLOQUANTE si elle peut changer la décision, la route ou le DONE |

Interdit : l'affirmation nue — un fonctionnement énoncé comme un fait sans source ni étiquette.

## Application

- Le niveau de preuve suit l'enjeu : une exploration tolère des hypothèses étiquetées ; une décision d'architecture, un contrat ou un DONE exigent du **Prouvé**.
- Une hypothèse ne peut pas rester une hypothèse si elle a une probabilité crédible de changer le scope, la route, le DONE ou la validation (règle d'`aic-frame`, généralisée ici).
- Vérifier coûte moins cher que corriger : lire le fichier, lancer la commande, fetcher la doc AVANT d'affirmer.
- Les artefacts durables portent leurs preuves : section Validation des fiches (sorties de commandes datées), colonne `evidence` des registres, `evidence` des frames.

## Précédents internes (la règle généralise l'existant)

- `aic-frame` : table des incertitudes (Bloquant maintenant / Hypothèse de travail / Risque accepté / À valider plus tard).
- Registre natif `.ai/native-context-support.tsv` : statut `confirmed` impossible sans colonne `evidence`.
- Quality gate : evidence (build/tests) exigée avant DONE.

## Enforcement

- **Comportemental** : hard rule injectée à chaque tour (`.ai/reminder.md`) et portée par `AGENTS.md` (tous agents).
- **Structurel** : les skills d'analyse (`aic-review`, `aic-diagnose`, `aic-pilot`, `aic-frame`) exigent l'étiquetage dans leurs règles non négociables.
- **Limite assumée** : la véracité d'une affirmation n'est pas vérifiable mécaniquement — aucun gate bash ne le prétend, et les hooks LLM-juges restent interdits (`codex-hooks-parity`). Ce contrat est une discipline outillée, pas une garantie machine.
