# Worklog — workflow/aic-release

## 2026-07-24 10:00 — spec / cadrage initial
- Fiche créée depuis le pilotage `workflow/aic-pilot` (item P9b, dépendance P9a levée).
- Cadrage : deux livrables — `aic-release.sh` (checklist RELEASE.md automatisée) et une entrée `_migrations` native dans `copier.yml` câblée sur v0.14.0.
- next : lire RELEASE.md en entier, vérifier `_migrations` (schéma Copier réel via lecture du code source installé, pas mémoire), implémenter, tester empiriquement chaque hypothèse à risque.

## 2026-07-24 10:45 — implement / migration native
- Lu le code source Copier installé (`_template.py`/`_main.py`) pour le schéma `_migrations` réel (format moderne dict `version`/`command`/`when`, extra_vars préfixées `_`).
- Découverte critique via repro empirique : le scénario `v0.11.0 → HEAD` (celui du smoke `[28c/28]`) produit de vrais fichiers `.rej` (7 fichiers) ; `aic migrate plan` sort alors en erreur (exit 1). Sans garde-fou, la migration native aurait fait échouer `copier update` lui-même.
- Décision : commande `bash .ai/scripts/aic.sh migrate plan || true` — lecture seule (respecte l'invariant `core/migration-orchestrator`) et non bloquante.
- `copier.yml` : entrée `_migrations` ajoutée avec commentaire explicite (why : stage after obligatoire, read-only, non-bloquant).

## 2026-07-24 11:15 — implement / aic-release.sh puis correction du faux pas
- `aic-release.sh` écrit, câblé dans `aic.sh` (route `release`), templaté vers `template/.ai/scripts/aic-release.sh.jinja`.
- Bug détecté en testant RELEASE.md §2 empiriquement : `--data agents=codex` (scalaire) rejeté par Copier 9.14.3 (`ValueError: Not a YAML list`). Corrigé dans RELEASE.md et dans le script (`agents=[codex]`).
- `bash .ai/scripts/aic-release.sh` (run complet) a détecté une vraie régression : `test-dogfood-drift-extra.sh` FAIL. Root cause : `aic-release.sh` n'était pas encore mirroré → `check-dogfood-drift.sh` le signalait comme extra-runtime.
- En creusant la remédiation, réalisation d'un problème plus profond : `RELEASE.md` et `check-release-coherence.sh` (dont `aic-release.sh` dépend directement) sont TOUS DEUX source-only, jamais rendus aux consommateurs. Câbler `aic-release.sh` dans `aic.sh` + le templater aurait livré à chaque consommateur une commande qui plante (`check-release-coherence.sh` introuvable chez eux).
- Corrigé : `aic-release.sh` rendu source-only (retiré de `template/`, retiré du dispatch `aic.sh` source ET template, ajouté à l'ignore-list `dogfood-runtime-lib.sh`). Assertion smoke-test correspondante retirée (testait le mauvais artefact au mauvais endroit).
- Smoke-test complet PASS après correction ; assertion `[28c/28]` étendue pour prouver que la migration native est bien jouée (« migrations post-Copier » présent dans le log `copier update`, capturé avant sa suppression).
- next : gates finaux + commit.
