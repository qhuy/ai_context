---
id: aic-release
scope: workflow
title: Automatisation de la checklist RELEASE.md + migration native v0.14.0
status: done
depends_on:
  - core/migration-orchestrator
  - core/template-engine
  - core/aic-surface-canonical
touches:
  - .ai/scripts/aic-release.sh
  - copier.yml
touches_shared:
  - .ai/scripts/dogfood-runtime-lib.sh
  - RELEASE.md
  - tests/smoke-test.sh
  - .docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: true
    observability: false
progress:
  phase: done
  step: "aic-release.sh livré (source-only) + migration native v0.14.0 câblée dans copier.yml, jouée dans le smoke"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir seulement si un futur breaking (v0.15+) doit gagner sa propre entrée _migrations, ou si RELEASE.md gagne une étape supplémentaire à automatiser"
  updated: 2026-07-24
type: feature
---

# Automatisation de la checklist RELEASE.md + migration native v0.14.0

## Résumé

Deux livrables distincts mais couplés, issus du même item de pilotage (P12 → P9b) :
1. `.ai/scripts/aic-release.sh` — script source-only qui exécute les étapes
   mécaniques de `RELEASE.md` (tests, rendus Copier critiques, cohérence doc) en
   une commande, et rappelle explicitement les étapes qui restent humaines.
2. Une entrée `_migrations` native dans `copier.yml`, câblée sur le tag `v0.14.0`,
   qui surface automatiquement `aic migrate plan` (lecture seule) chez tout
   consommateur qui traverse cette borne de version via `copier update`.

## Objectif

`RELEASE.md` documentait une checklist en 7 étapes, entièrement manuelle. Deux
bugs latents y dormaient (§2 `--data agents=codex` rejeté par Copier 9.14.3 —
`ValueError: Not a YAML list` — et §3 documentant un faux positional
`copier update <chemin>` qui n'existe pas). Par ailleurs, les migrations project-owned
(`aic migrate plan/all`) livrées par `core/migration-orchestrator` restaient une
démarche que le consommateur devait se rappeler de lancer lui-même après
`copier update` — rien ne le lui rappelait au moment précis où ça devient
pertinent.

## Périmètre

### Inclus

- `aic-release.sh` : Pré-requis (branche + propreté working tree, informatif),
  §1 tests (smoke-test complet), §2 rendus des 7 profils Copier critiques
  (miroir exact de `RELEASE.md` §2, avec le bug `agents=codex` corrigé en
  `agents=[codex]`), §4 `check-release-coherence.sh`. §3/§5/§6/§7 restent
  imprimés comme rappels, jamais exécutés (voir Invariants).
- Correction du bug `--data agents=codex` dans `RELEASE.md` §2 lui-même.
- Une entrée `_migrations` dans `copier.yml`, `version: v0.14.0`, stage `after`
  (défaut), commande `bash .ai/scripts/aic.sh migrate plan || true`.

### Hors périmètre

- Automatiser §3 (`copier update` sur un consommateur réel) : nécessite un repo
  externe, reste une action manuelle documentée.
- Automatiser §5 (choix SemVer) : décision humaine, non automatisable par nature.
- Automatiser §6 (commit + tag + push) : irréversible, jamais scripté — cf.
  Invariants.
- Exposer `aic release` dans la surface publique `aic.sh` (Claude/Codex/consommateurs) :
  `RELEASE.md` lui-même n'est pas templaté (c'est la checklist de release DU
  template, pas un outil consommateur) ; `aic-release.sh` suit la même règle que
  `check-release-coherence.sh` et `check-dogfood-drift.sh`.
- Faire échouer `copier update` sur un blocage de migration détecté (`.rej`
  préexistants) : la commande native reste non bloquante (`|| true`), cf.
  Invariants et Risques.

### Granularité / nommage

Cette fiche couvre l'automatisation de la checklist de release et le câblage
natif Copier. La logique des migrateurs eux-mêmes (`okf-type`, `okf-indexes`,
l'orchestrateur `migrate plan/all`) reste portée par `core/migration-orchestrator`
et les fiches d'origine de chaque migrateur.

## Invariants

- `aic-release.sh` ne remplace jamais le jugement humain sur §5/§6 : il n'exécute
  jamais `git tag`/`git push`, quels que soient ses arguments.
- `aic-release.sh` est source-only : jamais rendu dans `template/`, jamais câblé
  dans `aic.sh` (source ou template) — cohérent avec le fait que `RELEASE.md` et
  `check-release-coherence.sh` sont eux-mêmes source-only. Un consommateur n'a
  aucune raison de voir cette commande : il ne release pas le template `ai_context`.
- La migration native `_migrations` reste strictement en lecture seule
  (`migrate plan`, jamais `--apply`) : Copier n'a jamais le droit d'écrire
  silencieusement dans le mesh/l'overlay d'un consommateur — invariant hérité
  directement de `core/migration-orchestrator`.
- La migration native reste non bloquante (`|| true`) : un `.rej` préexistant ou
  un blocage détecté par `migrate plan` ne doit jamais faire échouer `copier
  update` lui-même — vérifié empiriquement (voir Validation).
- Le stage de la migration native reste `after` (défaut) : en `before`, le script
  `aic.sh` de la version d'origine n'a pas encore la commande `migrate`.

## Décisions

- Un seul script `aic-release.sh` plutôt qu'une extension de `aic.sh` : suit le
  précédent déjà acté pour `migrate-all.sh` (« script séparé plutôt que d'ajouter
  la logique dans le dispatcher déjà volumineux »), et est de toute façon requis
  puisque le script est source-only (voir ci-dessous).
- Découverte tardive mais décisive : `aic-release.sh` avait été initialement
  câblé dans `aic.sh` + templaté par erreur. Corrigé après avoir vérifié que
  `RELEASE.md` et `check-release-coherence.sh` ne le sont pas non plus — un
  consommateur n'a pas de `RELEASE.md` à checklister. Le script reste dans
  `.ai/scripts/` (dogfoodé) mais est ajouté à l'ignore-list source-only de
  `dogfood-runtime-lib.sh`, exactement comme `check-release-coherence.sh`.
- La migration native appelle `aic migrate plan` (le cockpit), pas les scripts
  individuels `migrate-okf-type.sh`/`migrate-okf-indexes.sh` : signal strictement
  supérieur (couvre aussi `.rej`, `.copier-answers.yml`, overlay) pour le même
  coût, et c'est l'entrée recommandée par `core/migration-orchestrator` lui-même.
- Pas de mode `--apply` sur la migration native, même optionnel : re-donnerait à
  Copier, via une porte dérobée, le droit d'écriture silencieuse que
  `migration-orchestrator` interdit explicitement dans son Objectif.

## Comportement attendu

Un mainteneur du repo `ai_context` lance, avant de préparer un tag :
```bash
bash .ai/scripts/aic-release.sh
```
Il obtient un rapport section par section (§1 à §7), avec PASS/FAIL explicite sur
les étapes automatisables et un rappel imprimé pour les étapes humaines. Un
consommateur qui traverse la borne v0.14.0 via `copier update` voit, dans la
sortie de la commande elle-même, le plan `aic migrate plan` s'afficher
automatiquement — sans qu'aucun fichier ne soit modifié par cet affichage.

## Contrats

- `aic-release.sh [--skip-smoke] [--skip-renders]` : exit 0 si toutes les étapes
  automatisables passent (ou sont explicitement skippées), exit 1 sinon.
- `aic-release.sh` n'exécute jamais `git commit`/`git tag`/`git push`.
- La migration native `_migrations` de `copier.yml` : `version: v0.14.0`, se
  déclenche une seule fois par consommateur (franchissement `from < 0.14.0 <=
  to`), commande toujours terminée par `|| true` (exit 0 quel que soit le
  verdict du plan).

## Validation

- `bash .ai/scripts/aic-release.sh` (run complet) : §1 et §2 PASS sur le repo
  sain ; a détecté une vraie régression (`test-dogfood-drift-extra.sh`, causée
  par l'oubli initial du miroir template — corrigé, voir Décisions).
- Bug `--data agents=codex` reproduit puis corrigé (`agents=[codex]`), vérifié
  par rendu réel avant et après.
- Migration native : reproduit manuellement le scénario `v0.11.0 → HEAD` (celui
  du smoke `[28c/28]`) — confirme que ce scénario produit de vrais fichiers
  `.rej` (7 fichiers) et que `aic migrate plan` sans `|| true` sortirait en
  erreur (exit 1), ce qui aurait fait échouer `copier update` lui-même. Le
  garde-fou `|| true` est donc requis, pas seulement prudent.
- `tests/smoke-test.sh` `[28c/28]` étendu : capture la sortie de `copier update`
  avant sa suppression et vérifie la présence de « migrations post-Copier »
  (preuve d'invocation, indépendante du verdict bloqué/débloqué).
- `bash .ai/scripts/check-dogfood-drift.sh`, `check-runtime-template-mirror.sh`,
  smoke-test complet : PASS après correction du faux pas template.

## Droits / accès

Non requis : outillage local, exécuté avec les droits du mainteneur.

## Données

Non requis : `aic-release.sh` ne modifie aucune donnée ; la migration native ne
fait qu'afficher un plan en lecture seule.

## UX

Non requis au sens interface graphique. La sortie doit distinguer clairement les
étapes automatisées (PASS/FAIL) des étapes qui restent des rappels humains.

## Observabilité

Non requise : sortie déterministe stdout/stderr, code de retour, logs temporaires
nommés explicitement en cas d'échec (`aic-release-smoke.XXXXXX.log`, etc.).

## Déploiement / rollback

- `aic-release.sh` et l'entrée `_migrations` sont additifs, non bloquants pour
  l'existant.
- Rollback `aic-release.sh` : suppression du fichier, aucun consommateur affecté
  (jamais rendu).
- Rollback migration native : retirer l'entrée de `copier.yml` ; les
  consommateurs déjà passés par v0.14.0 ne sont de toute façon plus concernés
  (la borne ne se rejoue pas).

## Risques

- Un `.rej` préexistant sans rapport avec cette release ferait quand même
  s'afficher un plan « bloqué » lors du passage de la borne v0.14.0 — mitigé par
  le `|| true` (n'affecte que l'affichage, jamais l'issue de `copier update`).
- Si `core/migration-orchestrator` ajoute un jour un troisième migrateur, la
  migration native n'a rien à changer (elle délègue à `migrate plan`, pas aux
  scripts individuels) — mais un futur breaking (v0.15+, v1.0) nécessitera sa
  propre entrée `_migrations` versionnée séparément.

## Cross-refs

- `core/migration-orchestrator` : porte l'invariant « Copier n'écrit jamais
  silencieusement » que cette fiche respecte strictement côté câblage natif.
- `core/template-engine` : propriétaire général de `copier.yml` et du cycle
  `copier update`.
- `core/aic-surface-canonical` : justifie pourquoi `release` reste hors de la
  surface publique `aic`.
- `workflow/aic-pilot` : pilotage P9b de l'audit fonctionnel général du
  2026-07-23.

## Historique / décisions

- 2026-07-24 : création + implémentation. Faux pas initial détecté et corrigé en
  cours de route : `aic-release.sh` avait été câblé dans `aic.sh` et templaté
  avant de réaliser que `RELEASE.md`/`check-release-coherence.sh` (dont il
  dépend) sont eux-mêmes source-only — un consommateur ne peut pas exécuter une
  checklist de release du template qu'il ne possède pas. Corrigé : script
  source-only, non câblé dans `aic.sh`, ajouté à l'ignore-list dogfood.
