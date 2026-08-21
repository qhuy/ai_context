---
id: resume-index-freshness
scope: workflow
title: Reprise alignée sur la source du feature mesh
status: done
type: feature
description: "Empêche aic-resume d'afficher une phase périmée lorsque les fiches sont plus récentes que le cache JSON."
depends_on:
  - core/feature-index-cache
touches:
  - .ai/scripts/resume-features.sh
  - template/.ai/scripts/resume-features.sh.jinja
  - tests/unit/test-resume-features-index-freshness.sh
  - .docs/features/workflow/resume-index-freshness.md
  - .docs/features/workflow/resume-index-freshness.worklog.md
touches_shared:
  - tests/smoke-test.sh
product: {}
external_refs: {}
doc:
  level: brief
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: done
  step: ""
  blockers: []
  resume_hint: "feature clôturée le 2026-08-20"
  updated: 2026-08-20
---

# Reprise alignée sur la source du feature mesh

## Résumé

`resume-features.sh` reconstruisait `.ai/.feature-index.json` seulement quand il manquait. Après l'édition d'une fiche, un cache encore présent pouvait donc afficher une ancienne phase, un ancien step ou une ancienne consigne de reprise. Le script applique désormais la même politique de fraîcheur que `features-for-path`, `features-search` et le rappel de début de tour.

## Objectif

Faire de la fiche Markdown la source réellement autoritaire du tableau de reprise, y compris quand aucun checkout ou autre consommateur n'a rafraîchi le cache avant l'appel à `aic resume`.

## Périmètre

### Inclus

- Détecter une fiche canonique plus récente que l'index existant.
- Reconstruire le cache avant de calculer les buckets de reprise.
- Conserver la parité runtime / template Copier.
- Verrouiller le cas par un test discriminant intégré au smoke-test.

### Hors périmètre

- Modifier le schéma ou le contenu de `.ai/.feature-index.json`.
- Changer les buckets, le seuil stale ou le format de sortie de `resume-features`.
- Centraliser tous les blocs `ensure_index` dans un nouveau helper.
- Rendre le rebuild strict : le comportement résilient existant est conservé si le builder échoue.

## Invariants

- Une fiche plus récente que le cache est visible dès l'appel suivant à `resume-features`.
- Une fiche de worklog ou un index Markdown réservé ne déclenche pas le rebuild.
- Le cache reste reconstructible, gitignoré et non autoritaire.
- Le script reste compatible Bash 3.2.
- Runtime dogfoodé et template ont le même comportement.

## Décisions

- Réutiliser `feature_docs_newer_than` au lieu d'introduire un second détecteur de fraîcheur.
- Corriger uniquement le consommateur fautif : le cache et son builder respectaient déjà leur contrat.
- Garder le `best effort` historique (`|| true`) ; si aucun index exploitable n'existe ensuite, l'erreur explicite existante reste inchangée.

## Comportement attendu

Quand l'index manque ou qu'au moins une fiche canonique a un mtime plus récent, `resume-features` tente un rebuild avant toute lecture `jq`. Le tableau et la sortie JSON reflètent alors la phase, le step, la date et le `resume_hint` courants de la fiche.

## Contrats

- Entrées, options, buckets et sortie restent inchangés.
- La politique de fraîcheur devient : index absent **ou** fiche canonique plus récente ⇒ tentative de rebuild.
- Le détecteur ignore les worklogs et les index réservés via `feature_docs_newer_than`.

## Validation

- `bash tests/unit/test-resume-features-index-freshness.sh` reproduit un cache `implement`, rend la fiche `review`, puis exige la valeur `review` dans la sortie et le cache reconstruit.
- `bash .ai/scripts/check-dogfood-drift.sh` vérifie le miroir Copier.
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/resume-index-freshness` passe.
- `bash .ai/scripts/check-features.sh --no-write` passe.
- `bash tests/smoke-test.sh` exécute la régression dans la gate globale.

## Risques

- Une édition fréquente des fiches peut déclencher un rebuild supplémentaire ; c'est le coût déjà accepté par les autres consommateurs interactifs.
- Un filesystem à granularité temporelle insuffisante pourrait ne pas distinguer deux écritures dans la même seconde ; le helper canonique conserve la précision de `find -newer` disponible sur le filesystem.

## Cross-refs

- `core/feature-index-cache` fournit le cache et le helper de fraîcheur sans changement de contrat.
- `workflow/conversational-skills` porte historiquement le mode lecture `/aic-resume`; cette correction en isole la garantie de fraîcheur.

## Historique / décisions

- 2026-08-20 — Bug observé sur le dépôt : la fiche `core/feature-intent-retrieval` était en `review`, tandis que `resume-features` affichait encore `implement` depuis un index présent mais périmé.
- 2026-08-20 — Ownership corrigé après lecture : le cache est sain et sa fiche exclut ses consommateurs ; le correctif appartient au workflow de reprise.
- 2026-08-20 — Passage en `review` après succès du test discriminant, de la parité dogfood, de la couverture 118/118 et des checks feature/freshness ciblés.
- 2026-08-20 — DONE après smoke-test complet, gate structurelle et freshness staged strict verts.
