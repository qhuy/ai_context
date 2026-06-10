# Revue applicative métier

**Goal** : produire une revue applicative claire, priorisée et vérifiable pour
un delta métier, sans remplacer la quality gate déterministe.

**Role** : reviewer applicatif. Lecture seule. Aucun fix pendant cette
procédure.

## Déclenchement

- Manuel : l'utilisateur demande une review ou invoque `aic-review`.
- Autonome : l'agent peut lancer cette revue quand un delta applicatif est prêt
  à passer en `review`, ou quand il touche une surface risquée : règles métier,
  droits, données, API, migration, performance, UX critique ou sécurité.
- Ship : avant un verdict `GO` sur un changement applicatif non trivial,
  `aic-ship` doit disposer d'une revue applicative récente ou lancer
  `aic-review`.
- Done : la clôture de feature vérifie l'evidence de revue applicative ; elle ne
  relance pas une revue complète.

Ne pas brancher cette revue sur le hook `Stop`. Les hooks doivent rester rapides,
déterministes et peu bavards.

## Entrées

1. Lire `.ai/index.md`.
2. Lire `.ai/quality/QUALITY_GATE.md` pour conserver les checks recommandés et
   le vocabulaire go/no-go du projet.
3. Exécuter `bash .ai/scripts/review-delta.sh --staged` si des fichiers sont
   staged, sinon `bash .ai/scripts/review-delta.sh`.
4. Si une base/head est fournie, exécuter aussi
   `bash .ai/scripts/pr-report.sh --base=<base> --head=<head>`.
5. Pour les fichiers modifiés significatifs, utiliser
   `bash .ai/scripts/features-for-path.sh <path> --with-docs` afin de charger
   les fiches feature directes.
6. Charger seulement les modules pertinents :
   - `.ai/review/common.md` toujours ;
   - `.ai/review/business.md` si une feature ou un comportement utilisateur est
     touché ;
   - `.ai/review/documentation.md` si contrat, API, règle métier, migration,
     configuration ou exploitation changent ;
   - `.ai/review/tech/csharp.md` pour `.cs`, `.cshtml`, `.razor` ;
   - `.ai/review/tech/react.md` pour `.tsx`, `.jsx`, composants React ou routes
     front ;
   - `.ai/review/tech/python.md` pour `.py`.

## Contrat de finding

Un finding valide contient obligatoirement :

- `Sévérité` : `blocker`, `major`, `minor` ou `note`.
- `Preuve` : fichier et ligne quand disponible, ou section de fiche feature.
- `Impact` : conséquence métier, fonctionnelle, technique, sécurité,
  performance, maintenance ou documentation.
- `Correction attendue` : changement concret, pas une intention vague.
- `Validation` : test, check, doc ou inspection à refaire.

Une remarque sans preuve exploitable reste hors findings. Une règle métier non
documentée devient une incertitude, pas un bug certain.

## Décision

- `blocked` si au moins un `blocker`, si un comportement central est non
  vérifiable depuis la fiche feature, ou si une evidence indispensable manque.
- `go avec réserves` si seuls des `major` non bloquants ou des incertitudes
  encadrées restent.
- `go` si aucun risque bloquant et si les checks recommandés sont cohérents avec
  le delta.

## Format de sortie

```markdown
## Review applicative

Risque principal :
- ...

Décision :
- go | go avec réserves | blocked

Features vérifiées :
- ...

Findings bloquants :
- [blocker] <titre>
  Preuve : <fichier:ligne | section feature>
  Impact : ...
  Correction attendue : ...
  Validation : ...

Findings importants :
- [major] ...

Incertitudes fonctionnelles :
- ...

Dette / notes :
- ...

Checks recommandés :
- ...

Prochaine action minimale :
- ...
```

## Compatibilité Claude / Codex

- Les wrappers `.claude/skills/aic-review/**` et `.agents/skills/aic-review/**`
  restent minces et délèguent à ce fichier.
- Les templates doivent rendre les mêmes fichiers sous `template/.ai/review/**`
  et les mêmes wrappers Claude/Codex.
- Aucune règle détaillée ne doit être dupliquée dans un wrapper agent.

## Règles non négociables

- Ne pas corriger pendant la revue.
- Ne pas inventer de besoin métier absent des fiches feature.
- Ne pas lister de best practice générique comme finding.
- Ne pas charger toutes les technos du repo : partir du delta.
- Ne pas rendre `GO` si un comportement central est non vérifiable et que la
  fiche feature devrait le couvrir.
