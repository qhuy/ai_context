---
id: index-lock-contract
scope: quality
title: Corriger le contrat de lock de l'index feature
status: done
depends_on: []
touches:
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
  - tests/smoke-test.sh
touches_shared: []
product: {}
external_refs:
  ai_debate: "/Users/huy/Documents/Perso/ai_debate/.ai-debate/discussions/0013-qualite-code-ai-context.md#q1"
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: false
    observability: false
progress:
  phase: done
  step: ""
  blockers: []
  resume_hint: "feature clôturée le 2026-05-12"
  updated: 2026-05-12
---

# Corriger le contrat de lock de l'index feature

## Résumé

Cette feature corrige le contrat de `with_index_lock`, utilise par la generation de l'index feature. Le lock doit etre stable, portable et verifiable en concurrence, sans ligne morte ni execution silencieuse sans protection.

## Objectif

Eviter que plusieurs processus reconstruisent `.ai/.feature-index.json` en meme temps apres un timeout de lock. Le code actuel contient une double affectation de `lock_dir`, dont une ligne morte, et autorise un fallback "on procede sans" qui affaiblit le contrat annonce.

## Périmètre

### Inclus

- Supprimer la double affectation de `lock_dir` dans `.ai/scripts/_lib.sh`.
- Definir une cle de lock stable pour l'index feature.
- Remplacer le fallback sans lock par un echec explicite apres timeout.
- Renforcer la validation concurrente existante dans `tests/smoke-test.sh`.

### Hors périmètre

- Revoir tous les locks du projet.
- Changer le format de `.ai/.feature-index.json`.
- Modifier la strategie de cache ou de rebuild de l'index.
- Introduire une dependance a `flock`.

### Granularité / nommage

La feature couvre uniquement le contrat de lock de l'index feature. Les autres sujets qualite identifies par `0013` restent portes par les items Q2+.

## Invariants

- Le lock reste compatible macOS sans dependance a `flock`.
- L'ecriture de `.ai/.feature-index.json` reste atomique.
- Un timeout d'acquisition du lock ne doit pas lancer l'ecriture sans protection.
- Le lock doit etre nettoye apres execution normale ou interruption geree.

## Décisions

- La cle par defaut du lock est basee sur l'UID utilisateur, pas sur le PID, pour que les processus concurrents d'un meme utilisateur partagent bien le meme verrou.
- `AI_CONTEXT_LOCK_DIR` reste l'override explicite pour les tests ou cas avances.
- En cas de timeout, la commande protegee n'est pas executee et la fonction retourne une erreur.

## Comportement attendu

`with_index_lock` recoit une commande shell et tente de creer un repertoire de lock atomique. Si le lock est acquis, la commande est executee puis le lock est supprime. Si le lock ne peut pas etre acquis dans le delai configure, la commande n'est pas lancee et l'appel echoue.

## Contrats

- Interface shell : `with_index_lock` suivi de la commande a proteger.
- Override : `AI_CONTEXT_LOCK_DIR` pointe vers le repertoire de lock a utiliser.
- Timeout actuel : 30 tentatives espacees de 0.1 seconde.
- Erreur timeout : retour non nul sans execution de la commande.

## Validation

- Le test de concurrence de `tests/smoke-test.sh` doit rester vert.
- Ajouter une assertion qui prouve qu'un timeout de lock n'execute pas la commande protegee.
- Lancer :

  ```bash
  bash .ai/scripts/check-features.sh
  bash .ai/scripts/check-feature-docs.sh quality/index-lock-contract
  bash tests/smoke-test.sh
  git diff --check
  ```

## Droits / accès

Ce changement ne modifie aucun droit ni controle d'acces.

## Données

Ce changement ne modifie aucun modele de donnees ; il protege uniquement l'ecriture atomique de l'index local.

## UX

Ce changement n'expose pas de parcours utilisateur.

## Observabilité

Le comportement reste observable via le code retour non nul et les logs debug quand `AI_CONTEXT_DEBUG=1`.

## Déploiement / rollback

Aucun deploiement progressif n'est requis. Le rollback consiste a restaurer le comportement precedent de `with_index_lock`, mais ce rollback recreerait le risque d'ecriture sans verrou.

## Risques

- Un lock orphelin peut bloquer l'index jusqu'au timeout. Le comportement attendu est alors un echec explicite, preferable a une ecriture concurrente non protegee.
- Un timeout trop court peut exposer des echecs sur machines lentes. Ce point reste a surveiller via le smoke test.

## Cross-refs

- Discussion source : `/Users/huy/Documents/Perso/ai_debate/.ai-debate/discussions/0013-qualite-code-ai-context.md`, item Q1.

## Historique / décisions

- 2026-05-12 : creation depuis l'item Q1 du plan AI Debate `0013`.
