---
id: ecosystem-usage-watch
scope: workflow
title: Veille écosystème et radar des usages IA
status: active
type: workflow
description: "Cadre une veille hebdomadaire qui relie évolutions techniques, trous d'usage métiers, preuves et expérimentation mesurable."
depends_on:
  - workflow/aic-pilot
  - workflow/evidence-discipline
touches:
  - docs/veille/**
  - .docs/features/workflow/ecosystem-usage-watch.md
  - .docs/features/workflow/ecosystem-usage-watch.worklog.md
touches_shared:
  - README.md
  - .ai/native-context-support.tsv
product: {}
external_refs: {}
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
  phase: review
  step: "prompt étendu et documenté ; première exécution réelle à challenger"
  blockers: []
  resume_hint: "Exécuter WATCH_PROMPT.md avec accès web, puis vérifier la qualité du delta technique, de la matrice métiers et des expériences proposées."
  updated: 2026-08-20
---

# Veille écosystème et radar des usages IA

## Résumé

Cette feature transforme une veille initialement centrée sur Claude, Codex et les standards agents en une routine hebdomadaire à deux regards : suivre les changements techniques externes et détecter les usages IA ou les métiers que le produit sert encore mal. Le rapport doit convertir chaque signal crédible en impact prouvé, limite explicite ou expérience mesurable, sans devenir une revue d'actualité ni une roadmap parallèle.

## Objectif

Éviter deux angles morts symétriques : maintenir une architecture techniquement à jour mais déconnectée des tâches réelles, ou accumuler des idées d'usage séduisantes sans preuve, métrique ni surface d'implémentation. La routine doit aider le mainteneur à adapter `ai_context` à l'évolution des agents et des pratiques d'entreprise tout en conservant son noyau générique.

## Périmètre

### Inclus

- Veille datée sur Claude/Anthropic, Codex/OpenAI et les standards transverses consommés par le dépôt.
- Radar des tâches, décisions et handoffs dans les principales fonctions de l'entreprise.
- Matrice de couverture qui rend visibles métiers, populations, niveau de recherche, signaux absents et trous persistants.
- Balayage hebdomadaire de toutes les fonctions et rotation de deux approfondissements au maximum.
- Discipline de preuve distincte pour la capacité technique, le workflow réel et le gain mesuré.
- Fiche courte par candidat d'usage : acteur, contexte, humain dans la boucle, risque, métrique et expérience falsifiable.
- Routage des constats retenus vers `aic-frame` ou `aic-pilot`.

### Hors périmètre

- Auditer le code interne ; cette responsabilité reste à `docs/audit/REVIEW_PROMPT.md`.
- Implémenter les constats ou créer leurs fiches feature pendant la veille.
- Garantir une opportunité par métier ou promouvoir un cas d'usage sans signal crédible.
- Spécialiser le noyau `ai_context` pour une seule fonction de l'entreprise.
- Produire le premier rapport sans accès web et sans sources datées.

### Granularité / nommage

La fiche couvre le contrat récurrent de veille et son format de sortie. Chaque évolution issue d'un rapport conserve sa propre route et, si nécessaire, sa propre fiche dans le scope qui la possède.

## Invariants

- Les quatre pistes Claude, Codex, standards et usages métiers sont toutes parcourues ; `RAS` ou `AUCUN SIGNAL` est une conclusion valide.
- Toutes les fonctions sont balayées, mais seules deux au maximum sont approfondies par semaine ; le rapport distingue explicitement ces deux niveaux de preuve.
- Une capacité de modèle ne prouve ni un besoin métier ni un gain de performance.
- Tout finding technique s'appuie sur une source primaire datée et une surface du dépôt réellement lue.
- Tout candidat d'usage nomme une tâche ou décision réelle, le contexte requis, le contrôle humain, le risque et une métrique.
- Le rapport ne crée pas de roadmap parallèle : les actions passent par le routage existant.
- Une semaine calme produit un rapport court au lieu d'items artificiels.

## Décisions

- Conserver un seul prompt de veille : la piste usages est obligatoire et non un appendice optionnel.
- Couvrir les fonctions par matrice, sans quota de findings, afin de distinguer recherche effectuée et remplissage artificiel.
- Faire tourner les approfondissements selon l'ancienneté, le signal ou le risque afin de conserver de la profondeur sans abandonner la largeur.
- Séparer preuve du workflow et preuve du gain ; une étude de cas fournisseur reste un signal tant que son bénéfice n'est pas mesuré ou corroboré.
- Exiger une expérience minimale falsifiable avant toute généralisation produit.
- Garder la veille non implémentante ; `aic-frame` traite une intention et `aic-pilot` un paquet transverse.

## Comportement attendu

À chaque exécution hebdomadaire, l'agent lit le dernier rapport, fixe sa fenêtre de recherche, inspecte les quatre pistes, balaie toutes les fonctions puis en approfondit au plus deux. Il produit au plus douze items retenus et montre le delta technique, le radar des usages, la couverture des fonctions et populations, les trous transverses et un top trois actionnable. Un item non prouvé est écarté ou explicitement étiqueté comme hypothèse ; un item applicable reçoit une première action et une route, jamais une implémentation silencieuse.

## Contrats

- **Entrée autoritaire** : `docs/veille/WATCH_PROMPT.md`.
- **Baseline** : dernier fichier daté sous `docs/veille/reports/`; à défaut, fenêtre annoncée de sept jours.
- **Sortie** : `docs/veille/reports/VEILLE-AAAA-MM-JJ.md`.
- **Écriture directe supplémentaire** : `.ai/native-context-support.tsv` seulement lorsque la vérification change ou rafraîchit une preuve ; appliquer la parité template si un miroir existe.
- **Classes** : `APPLIQUER`, `INSTRUMENTER`, `SURVEILLER`, `RETIRER`.
- **Preuve technique** : URL canonique, date de publication, date de consultation et impact `fichier:ligne` ou absence prouvée par recherche ciblée.
- **Preuve d'usage** : acteur et population, tâche/décision, déclencheur, entrées, sortie, fréquence, systèmes, mode d'intervention, validation humaine, risque, métrique et expérience minimale.
- **Routage** : `aic-frame` pour une intention cohérente ; `aic-pilot` pour plusieurs constats ou scopes.

## Validation

- Le prompt contient les quatre pistes obligatoires et une matrice couvrant toutes les fonctions nommées, avec distinction balayage / approfondissement.
- Le format distingue le delta technique, le radar d'usages, les trous transverses et le triage.
- Les règles distinguent explicitement capacité, usage et preuve de gain.
- `bash .ai/scripts/check-feature-docs.sh --strict workflow/ecosystem-usage-watch` passe.
- `bash .ai/scripts/check-features.sh --no-write` passe.
- `bash .ai/scripts/check-feature-coverage.sh --strict` associe `docs/veille/**` à cette fiche.
- Critère de sortie de `review` : un premier rapport réel, sourcé avec accès web, respecte le contrat et fait l'objet d'une revue critique de sa couverture technique et métier.

## Risques

- La largeur du périmètre peut produire une recherche superficielle ; la matrice et le plafond de douze items rendent ce compromis visible.
- Les retours fournisseurs peuvent surévaluer les gains ; ils restent des signaux jusqu'à mesure ou corroboration.
- Une liste de métiers peut devenir décorative ; `AUCUN SIGNAL` est préféré à une hypothèse déguisée.
- Un usage très spécifique peut gonfler le noyau ; la transférabilité du pattern et la limite produit doivent être explicites.
- Le prompt seul ne prouve pas la qualité de la routine ; la feature reste en `review` jusqu'au premier rapport réel.

## Cross-refs

- `workflow/aic-pilot` : reçoit les paquets de constats transverses sans créer de feature globale.
- `workflow/evidence-discipline` : impose la distinction entre preuve, hypothèse et point à vérifier.
- `product/readme-positioning` : reste propriétaire de `README.md`; le lien vers la routine est un HANDOFF documentaire, pas un changement de positionnement.

## Historique / décisions

- 2026-08-20 — Création après challenge de la veille technique : le cas d'usage « détecter les trous et nouveaux usages IA dans tous les métiers » n'était pas couvert par le prompt initial.
- 2026-08-20 — Prompt étendu aux fonctions d'entreprise, aux handoffs, à la preuve de gain et aux expériences mesurables. Phase `review` conservée jusqu'à une première exécution réelle.
