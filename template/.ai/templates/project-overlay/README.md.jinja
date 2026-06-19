# Project Overlay

Ce fichier est un exemple. Ne le déplace pas automatiquement : `.ai/project/**` doit rester créé et maintenu par le projet consommateur.

## Entrée projet

`.ai/project/index.md` est le seul point d'entrée. L'agent le lit après les règles générales et avant les règles de scope — uniquement s'il existe.

Exemple avec registre de scopes :

```md
---
overlay_contract_version: 1
---

# Project Overlay

## Routage par scope

- `src/bo-front/**`  -> `.ai/project/bo-front/index.md`
- `src/bo-back/**`   -> `.ai/project/bo-back/index.md`
- `db/**`            -> `.ai/project/sql/index.md`
- `infra/**`         -> `.ai/project/infra/index.md`
```

## Registre de scopes

Chaque scope du projet (app, couche, préoccupation) possède son propre dossier :

```
.ai/project/
  index.md              ← entrée unique, route path → scope
  <scope>/
    index.md            ← routeur + manifeste du scope
    conventions.md      ← (optionnel) conventions longues extraites de l'index
```

### Contrat de forme — `.ai/project/<scope>/index.md`

```md
---
scope: <nom-du-scope>          # doit matcher le nom du dossier
paths:                         # globs que ce scope possède
  - src/bo-front/**
meta:
  stack: React 18              # technologie principale
  test_cmd: pnpm test
  build_cmd: pnpm build
  owner: team-front            # optionnel
---

# Scope bo-front

## Conventions

Règles durables : nommage, structure, patterns qui ne changent pas d'un sprint à l'autre.

- Composants dans `src/components/<domaine>/`.
- Toute nouvelle page déclare sa route dans `src/router/index.ts`.

## Derived

Pointeurs vers éléments volatils à dériver au moment de l'action — ne pas figer en prose.

- Script SQL du sprint courant : dernier fichier dans `db/sprints/` par ordre alphabétique.

## Selon les chemins touchés

Sous-routage intra-scope vers feuilles (charger uniquement sur match de path).

- `src/bo-front/payments/**` -> `conventions.md#section-paiements`
```

> Le stamp `overlay_contract_version` vit **une seule fois**, dans le front-matter de `.ai/project/index.md` : il versionne l'overlay entier, pas chaque scope. C'est le pivot d'idempotence d'une future migration. Les index de scope n'en portent pas.

### Règle durable vs volatile

| Durable | Volatile |
|---|---|
| Nommage, structure, patterns, règles invariantes | Sprint courant, environnement actif, version déployée |
| → Écrit en prose dans `conventions` | → Dérivé à la demande (`derived`) ou valeur unique dans `.ai/project/config.yml` |

Jamais figer de l'état volatile en prose : il serait périmé au prochain sprint.

## Règles de chargement

- `.ai/project/index.md` est la seule entrée projet.
- Sur match de path, l'agent charge `.ai/project/<scope>/index.md` — descente d'**un niveau**, par pointeur explicite, jamais de récursion aveugle.
- Les feuilles internes au scope (`conventions.md`, etc.) ne sont chargées que si l'index scope les pointe explicitement.
- `.ai/project/**` est project-owned : `copier update` ne doit ni supprimer ni écraser ce dossier.
- Un repo sans overlay garde le comportement actuel — aucune erreur, aucun bruit.

## Migration

Si des règles locales vivent dans un ancien fichier template (`.ai/rules/<scope>.md` ou legacy `L1_*`), déplacer la partie spécifique au projet vers `.ai/project/<scope>/`.

Si l'overlay existant est plat (`.ai/project/payments.md`) : relocaliser vers `.ai/project/payments/index.md` et ajuster le pointeur dans `.ai/project/index.md`. Le skill `aic-onboard` (mode `migrate`) peut prendre en charge cette relocation.

Garder dans les fichiers upstream-managed uniquement :

- les règles génériques utiles à tous les repos ;
- aucune copie longue de contexte métier.
