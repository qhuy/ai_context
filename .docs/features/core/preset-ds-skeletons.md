---
id: preset-ds-skeletons
scope: core
title: Squelettes bootstrap pour DS registry et atomic map
status: active
depends_on:
  - core/template-engine
touches:
  - template/docs/design-system-registry.md.jinja
  - template/docs/atomic-design-map.md.jinja
  - copier.yml
progress:
  phase: review
  step: "V1 livrée — 2 squelettes + exclusion + smoke-test étendu ; freshness template renforcé"
  blockers: []
  resume_hint: "créer 2 fichiers .jinja dans template/docs/ rendus uniquement si tech_profile ∈ {react-next, fullstack-dotnet-react} ; structure par catégorie + 1 composant commenté d'exemple"
  updated: 2026-04-28
---

# Squelettes bootstrap pour DS registry et atomic map

## Objectif

Le preset `tech-react` rend obligatoire un `docs/design-system-registry.md` maintenu à jour dans le même commit que l'ajout de composant, et un `docs/atomic-design-map.md` dès 30 composants. Sur un projet neuf, ces fichiers n'existent pas → l'agent part d'une page blanche à la première création de composant, ou oublie carrément la règle.

Objectif : moissonner deux squelettes minimalistes dès `copier copy` quand le `tech_profile` implique React, pour que la convention soit **vivante dès le bootstrap** — une entrée d'exemple commentée + structure par catégorie prête à remplir.

## Comportement attendu

- `copier copy` rend `docs/design-system-registry.md` et `docs/atomic-design-map.md` **uniquement** quand `tech_profile ∈ {react-next, fullstack-dotnet-react}`.
- Le squelette `design-system-registry.md` contient :
  - Intro + règle mandatory (« consulter avant de créer »).
  - Sections vides par catégorie : Layout & Shell, Forms & Inputs, Lists & Tables, Navigation, Feedback, Partials.
  - Un composant d'exemple commenté dans chaque catégorie, avec la forme attendue (nom + rôle + règle de comportement).
- Le squelette `atomic-design-map.md` contient :
  - Intro + légende (atom / molecule / organism / template / page + tags).
  - Section compteurs à tenir à jour.
  - Un exemple de tableau vide prêt à remplir.

## Contrats

- Exclusion `_exclude` dans `copier.yml` : `{% if tech_profile not in ['react-next', 'fullstack-dotnet-react'] %}docs/design-system-registry.md{% endif %}` (idem pour atomic-design-map).
- Pas de nouvelle variable copier.
- `docs_root` n'affecte pas ces fichiers — ils vivent dans `docs/` racine (convention front), pas dans `.docs/`.

## Cross-refs

- `core/template-engine` : ce travail enrichit la moisson de fichiers rendus selon `tech_profile`. Aucune dérive de profil ni de variable copier, uniquement 2 fichiers conditionnels en plus.

## Historique / décisions

- 2026-04-24 : fiche créée après enrichissement des presets techno. Règle `tech-react` « registry obligatoire dans le même commit » sans squelette = friction UX au bootstrap. Décision : rendre les squelettes via copier conditionnellement.
- 2026-04-24 : implémentation V1. Ajout `template/docs/design-system-registry.md.jinja` (structure par catégorie Layout/Forms/Lists/Navigation/Feedback/Partials + entrée d'exemple commentée par catégorie) et `template/docs/atomic-design-map.md.jinja` (légende atomic + summary compteurs + 3 tableaux vides UI/Feature/Routes). Exclusion conditionnelle dans `copier.yml` (`tech_profile not in ['react-next', 'fullstack-dotnet-react']`). Extension du smoke-test [28/28] avec 6 assertions : absents en profil dotnet-only, présents en react-next et fullstack. Smoke-test PASS.
- 2026-05-03 : le template du freshness check valide désormais chaque feature candidate individuellement quand un fichier partagé matche plusieurs fiches. Pas de changement sur les squelettes DS, mais `template/**` reste couvert par cette feature et la doc est alignée.
- 2026-05-03 : réduction du bruit `touches:` : remplacement de `template/**` par les deux squelettes réellement possédés (`template/docs/design-system-registry.md.jinja`, `template/docs/atomic-design-map.md.jinja`). Les modifications génériques du template restent couvertes par `core/template-engine`.
- 2026-05-03 : `copier.yml` modifié pour la surface skills intentionnelle. Aucun changement sur les squelettes DS ; entrée ajoutée car la fiche conserve historiquement `copier.yml` dans `touches`.
- 2026-05-03 : `copier.yml` modifié pour le retrait des skills procéduraux exposés. Aucun changement sur les squelettes DS.
- 2026-05-03 : `copier.yml` ajoute `product` au socle des profils. Aucun changement sur les squelettes DS ; entrée ajoutée car la fiche conserve historiquement `copier.yml` dans `touches`.
