---
id: aic-review-application-skill
scope: core
title: Revue applicative métier modulaire
status: done
depends_on:
  - core/aic-surface-canonical
  - workflow/intentional-skills
touches:
  - .ai/review/**
  - template/.ai/review/**
  - .agents/skills/aic-review/**
  - .claude/skills/aic-review/**
  - template/.agents/skills/aic-review/**
  - template/.claude/skills/aic-review/**
touches_shared:
  - README_AI_CONTEXT.md
  - tests/smoke-test.sh
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: done
  step: "contrat review applicative, modules et wrappers alignés validés"
  blockers: []
  resume_hint: "aucune action core immédiate ; l'intégration stricte dans aic-ship/feature-done reste portée par le HANDOFF workflow/intentional-skills"
  updated: 2026-07-03
type: feature
---

# Revue applicative métier modulaire

## Résumé

Enrichir `aic-review` pour produire une revue applicative claire, priorisée et
vérifiable sur des applications métier. La revue doit s'appuyer sur les fiches
feature associées au développement et charger uniquement les exigences utiles :
socle commun, métier/fonctionnel, documentation et modules technologiques.

## Objectif

Éviter les revues génériques qui empilent des "best practices" non vérifiables.
Chaque finding doit être prouvé et relié à un impact métier, fonctionnel ou
technique concret. Le skill doit aider à décider si un delta est acceptable
avant commit, review ou PR, sans devenir un audit applicatif universel.

## Périmètre

### Inclus

- Garder `aic-review` comme entrée publique canonique.
- Ajouter un mode de revue applicative modulaire derrière `aic-review`.
- Créer les modules de revue nécessaires sous une surface dédiée pendant
  l'implémentation, par exemple `.ai/review/**` et son équivalent template.
- Synchroniser les wrappers Claude et Codex pour qu'ils délèguent au même
  contrat `.ai/review/application-review.md`.
- Définir un contrat strict de finding : sévérité, preuve, impact, correction
  attendue et validation.
- Charger les exigences depuis des modules courts et ciblés.
- Relier la revue fonctionnelle aux fiches `.docs/features/**` associées au
  delta.
- Couvrir les axes métier, fonctionnel, technique, sécurité, performance,
  tests et documentation.
- Fournir les modules technologiques v1 : C#, React et Python.

### Hors périmètre

- Créer une nouvelle commande publique concurrente à `aic-review`.
- Remplacer la quality gate ou les scripts de vérification existants.
- Faire un audit sécurité complet ou un benchmark de performance exhaustif.
- Couvrir toutes les technologies dès la première version.
- Déduire des règles métier absentes de la documentation feature.

### Granularité / nommage

Cette fiche couvre l'évolution du comportement de revue applicative de
`aic-review`. Les modules technologiques futurs peuvent être ajoutés sous le
même contrat tant qu'ils ne changent pas l'objectif, le DONE ou la validation.

## Invariants

- `.ai/` reste la source unique du contexte agentique.
- `aic-review` reste l'entrée utilisateur publique pour la revue.
- Les wrappers Claude et Codex doivent rester minces et alignés.
- La revue doit charger le moins de contexte possible.
- Une remarque de review sans preuve exploitable n'est pas un finding.
- La revue fonctionnelle s'appuie sur les fiches feature disponibles ; si la
  documentation ne permet pas de vérifier un comportement, le skill doit le
  signaler explicitement comme non vérifiable.
- Les exigences technologiques restent dans des fichiers dédiés pour éviter un
  workflow monolithique.

## Décisions

- Préférer une capacité modulaire branchée sur `aic-review` plutôt qu'un nouveau
  skill public.
- Structurer les règles en modules :
  - socle commun ;
  - métier/fonctionnel ;
  - documentation ;
  - technologies.
- Limiter les modules technologiques initiaux à C#, React et Python.
- Ne produire que des findings priorisés ; les conseils secondaires doivent
  rester courts et clairement séparés.
- Ne pas déclencher cette revue depuis le hook `Stop`, car elle est qualitative
  et peut produire des arbitrages.

## Comportement attendu

Quand un utilisateur demande une revue applicative, `aic-review` inspecte le
delta ciblé, identifie les fiches feature concernées, détecte les technologies
touchées et charge seulement les modules nécessaires. La sortie doit permettre
de comprendre rapidement le risque principal, les corrections requises et les
checks à lancer.

Si une fiche feature est absente, obsolète ou insuffisante pour vérifier le
fonctionnel, la revue doit le dire au lieu d'inventer une règle métier.

Déclenchement recommandé :

- manuel quand l'utilisateur demande une review ;
- autonome quand un delta applicatif passe vers `review` ou touche une surface
  risquée ;
- attendu par `aic-ship` avant un verdict `GO` sur un changement applicatif non
  trivial ;
- vérifié comme evidence à la clôture de feature, sans refaire une revue
  complète dans `feature-done`.

## Contrats

- Contrat de finding :
  - sévérité : `blocker`, `major`, `minor` ou `note` ;
  - preuve : fichier et ligne quand disponible ;
  - impact : conséquence métier, fonctionnelle, technique, sécurité,
    performance ou maintenance ;
  - correction attendue : changement concret attendu ;
  - validation : test, check, doc ou inspection nécessaire.
- Contrat de synthèse :
  - risque principal ;
  - findings bloquants ;
  - findings importants ;
  - incertitudes fonctionnelles ;
  - dette ou remarques secondaires ;
  - checks recommandés ;
  - décision `go`, `go avec réserves` ou `blocked`.
- Contrat fonctionnel :
  - comparer le delta avec `Objectif`, `Périmètre`, `Invariants`,
    `Comportement attendu`, `Contrats` et `Validation` des fiches feature ;
  - signaler explicitement `non vérifiable depuis la doc feature` quand la
    preuve manque ;
  - ne pas transformer une hypothèse métier en finding certain.
- Contrat de chargement :
  - charger le socle commun pour toute revue applicative ;
  - charger métier/fonctionnel seulement si une feature ou un comportement
    utilisateur est touché ;
  - charger documentation seulement si contrat, règle métier, migration,
    configuration, API ou exploitation changent ;
  - charger uniquement les modules techno correspondant aux fichiers modifiés.
- Contrat de compatibilité agent :
  - `.agents/skills/aic-review/**` et `.claude/skills/aic-review/**` délèguent
    au même contrat `.ai/review/application-review.md` ;
  - les templates rendent les mêmes fichiers sous `template/.ai/review/**`,
    `template/.agents/**` et `template/.claude/**`.

## Validation

- Revue sur un delta sans fiche feature : la sortie marque les éléments
  fonctionnels non vérifiables.
- Revue sur un delta avec fiche feature : les findings fonctionnels citent les
  sections pertinentes de la fiche.
- Revue multi-techno : seuls les modules des technologies touchées sont pris en
  compte.
- Les findings respectent le contrat sévérité, preuve, impact, correction et
  validation.
- Les recommandations "best practices" génériques sans preuve sont absentes de
  la section findings.
- Checks attendus :
  - `bash .ai/scripts/check-features.sh`
  - `bash .ai/scripts/check-feature-docs.sh core/aic-review-application-skill`
  - `bash .ai/scripts/check-feature-coverage.sh`
  - `bash .ai/scripts/measure-context-size.sh`
  - smoke test si la surface template est modifiée.

## Risques

- Trop de règles peuvent rendre la sortie verbeuse et peu actionnable.
- Une détection technologique trop large peut charger trop de contexte.
- La revue fonctionnelle peut sur-interpréter une fiche feature incomplète.
- Les modules C#, React et Python peuvent eux-mêmes grossir s'ils ne restent pas
  centrés sur les risques observables dans un delta.
- L'intégration stricte dans `aic-ship` et `feature-done` touche le scope
  `workflow`; elle doit être traitée par HANDOFF ou chantier dédié pour éviter
  une feature cross-scope implicite.

## Cross-refs

- `core/aic-surface-canonical` : conserve `aic-review` dans la surface publique
  canonique et évite d'ajouter une commande concurrente.
- `workflow/intentional-skills` : porte la surface intentionnelle Claude/Codex
  existante que les wrappers `aic-review` doivent préserver.
- HANDOFF vers `workflow/intentional-skills` : intégrer formellement l'evidence
  de revue applicative dans `aic-ship` et `feature-done` si le déclenchement doit
  devenir bloquant.

## Historique / décisions

- 2026-06-10 : décision de cadrer une revue applicative métier modulaire plutôt
  qu'un skill de code review fourre-tout.
- 2026-06-10 : ajout du contrat `.ai/review/application-review.md`, des modules
  commun/métier/documentation/C#/React/Python et des wrappers `aic-review`
  Claude/Codex alignés.
- 2026-07-03 : clôture DONE du livrable core après validation de la route
  `aic.sh review`, de la parité runtime/template, du dogfood drift et des tests
  `review-delta` ciblés. L'intégration bloquante dans `aic-ship` /
  `feature-done` reste un HANDOFF workflow séparé.
