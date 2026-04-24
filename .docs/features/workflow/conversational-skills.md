---
id: conversational-skills
scope: workflow
title: Skill ombrelle /aic — invocation par phrase libre
status: draft
depends_on:
  - workflow/claude-skills
  - core/feature-index-cache
touches:
  - template/AGENTS.md.jinja
  - copier.yml
  - tests/smoke-test.sh
# NB : `template/.claude/skills/aic/**` sera ajouté à `touches` dès la phase=implement
# (le validateur check-features.sh refuse les globs ne résolvant aucun chemin existant).
# Friction observée — candidate à une amélioration future du validateur.
progress:
  phase: spec
  step: "spec initiale — cadrage UX et règles d'inférence"
  blockers: []
  resume_hint: "valider la liste des intents détectables + heuristique extension/création avant d'écrire le SKILL.md"
  updated: 2026-04-24
---

# Skill ombrelle `/aic` — invocation par phrase libre

## Objectif

Réduire la friction d'invocation des 6 skills `/aic-*`. Aujourd'hui l'utilisateur doit connaître :
- le bon skill (parmi `feature-new`, `feature-update`, `feature-handoff`, `feature-resume`, `feature-done`, `quality-gate`),
- l'`id` exact de la fiche cible,
- les champs structurés (`phase`, `step`, `resume_hint`, `blockers`).

→ Asymétrie : 1 phrase de pensée humaine, 6 champs YAML à fournir. Même le créateur ne maîtrise pas la syntaxe.

Le skill `/aic` accepte une phrase en français libre, **infère** intent + cible + champs, **propose un plan**, et **n'agit qu'après confirmation**.

## Comportement attendu

### Invocation

```
/aic <phrase libre en français>
```

Exemples :
- `/aic je veux ajouter un nouveau status 'stable' pour les features` → réouverture `core/feature-mesh`
- `/aic je rouvre feature-mesh pour ajouter le status stable` → idem (formulation directe)
- `/aic j'ai fini l'implem du focus graph` → clôture `core/graph-aware-injection` (si match unique)
- `/aic je passe la main au scope front pour intégrer le payment-intent` → handoff
- `/aic je démarre le rate-limiting côté back` → `/aic-feature-new back/rate-limiting` (fuzzy id depuis vocabulaire)

### Sortie standard

Toujours afficher le **plan** AVANT d'agir :

```
🎯 Intent : <réouverture | clôture | handoff | création | reprise>
🎯 Cible  : <scope/id> (existe phase=X | à créer)
🎯 Geste  : <skill sous-jacent qui sera invoqué>

Plan proposé :
1. /aic-feature-<X> <args inférés>
   • <champ> : <valeur>
   ...

⚠️  Cross-scope si applicable : <liste handoff anticipés>

ok ?
```

L'humain répond `oui` (ou `non, fais X`). Aucune action silencieuse.

## Contrats

### Règles d'inférence d'intent (sur la phrase libre)

| Vocabulaire détecté | Intent | Skill sous-jacent |
|---|---|---|
| « ajouter / enrichir / étendre / rouvrir / je reprends » + cible existante | réouverture | `/aic-feature-update` (status→active, phase→implement) |
| « je démarre / je crée / nouvelle feature » | création | `/aic-feature-new` |
| « j'ai fini / je clôture / done / livré » | clôture | `/aic-quality-gate` puis `/aic-feature-done` |
| « je passe la main / handoff / bascule scope » | passation | `/aic-feature-handoff` |
| « où j'en étais / qu'est-ce qui traîne / reprends » (sans cible) | reprise | `/aic-feature-resume` |
| « pause / sauve / blocker / je continue plus tard » | snapshot | `/aic-feature-update` (sans changement de status) |

### Résolution de cible (fuzzy match)

1. Extraire substrings/mots-clés de la phrase.
2. Matcher contre `.feature-index.json` : `id`, `title`, `touches`, mots-clés du corps.
3. Score → top 1 si > seuil ; sinon poser **1 question de clarif** (pas 6).
4. Si aucune match et intent = création → deviner `scope` depuis vocabulaire métier (`back`, `front`, `auth`, `paiement` → `back`, etc.).

### Arbitrage extension vs création

Encoder l'heuristique :

| Situation détectée | Décision |
|---|---|
| Phrase mentionne « ajouter / nouveau X » + X est un sous-élément de fiche existante (status, flag, option) | extension de la fiche existante |
| Phrase décrit une capacité orthogonale | nouvelle fiche + `depends_on` |
| Phrase décrit un changement breaking de contrat | nouvelle fiche + ancienne → `deprecated` |

### Détection cross-scope

Croiser les `touches` candidats avec les scopes courants. Lister les handoff anticipés dans le plan (n'exécute pas, signale).

### Garde-fous

- Toujours **proposer le plan**, jamais agir sans confirmation.
- Si intent ambigu (2 verbes contradictoires détectés) → 1 question de clarif.
- Si aucune fiche match et intent ≠ création → demander `id` cible explicite.
- Skills `/aic-*` directs **restent disponibles** (power-users, scripts, CI).

## Cross-refs

- **`workflow/claude-skills`** : `/aic` est un wrapper au-dessus, ne remplace pas — l'utilisateur garde l'accès direct.
- **`core/feature-index-cache`** : source pour la résolution fuzzy de cible.
- **`workflow/auto-worklog`** : aucun changement, le worklog continue d'être peuplé par les hooks PostToolUse/Stop.

## Historique / décisions

- **2026-04-24** — Découverte du problème UX par dog-fooding (le créateur lui-même a buté sur la syntaxe d'invocation de `/aic-feature-update`).
- Choix d'un **skill ombrelle** plutôt que :
  - hook `UserPromptSubmit` qui détecte automatiquement (sur-engineering, faux positifs)
  - skill conversationnel à 3 questions guidées (B) — gardé en option v1 si la phrase libre se révèle trop ouverte
- `/aic-*` directs **non dépréciés** : zéro régression, sucre syntaxique additif uniquement.
