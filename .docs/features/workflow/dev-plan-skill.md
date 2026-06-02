---
id: dev-plan-skill
scope: workflow
title: Structurer les développements multi-techno
status: done
depends_on:
  - workflow/intentional-skills
  - workflow/subagent-contract
  - core/template-engine
touches:
  - .ai/workflows/dev-plan.md
  - template/.ai/workflows/dev-plan.md.jinja
  - .agents/skills/aic-dev-plan/**
  - .claude/skills/aic-dev-plan/**
  - template/.agents/skills/aic-dev-plan/**
  - template/.claude/skills/aic-dev-plan/**
  - README.md
  - README_AI_CONTEXT.md
  - template/README_AI_CONTEXT.md.jinja
touches_shared:
  - copier.yml
  - tests/smoke-test.sh
product: {}
external_refs: {}
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: done
  step: ""
  blockers: []
  resume_hint: ""
  updated: 2026-06-02
---

# Structurer les développements multi-techno

## Résumé

Créer un skill public `aic-dev-plan` qui transforme une intention déjà cadrée en plan d'exécution vérifiable avant écriture de code. Le skill couvre les développements impliquant plusieurs surfaces ou technos, sans démarrer l'implémentation.

## Objectif

Combler l'espace entre `aic-frame`, qui décide si une intention mérite une feature, et `aic-review` / `aic-ship`, qui contrôlent un delta existant. Aujourd'hui les règles techno et le contrat subagents existent, mais aucun geste public ne structure l'ordre de développement, les handoffs, les contrats traversants et les checks par techno.

## Périmètre

### Inclus

- Définir un workflow canonique `.ai/workflows/dev-plan.md`.
- Exposer un skill public `aic-dev-plan` côté Claude et Codex.
- Produire un plan d'exécution structuré : surfaces, ordre, contrats, handoffs, checks, risques.
- Charger les règles techno seulement quand elles existent et sont pertinentes.
- Relier la délégation éventuelle au contrat `subagent-contract`.
- Documenter la nouvelle surface utilisateur dans les README.

### Hors périmètre

- Écrire du code applicatif depuis le skill.
- Remplacer `aic-frame`, `aic-review` ou `aic-ship`.
- Ajouter un orchestrateur externe, une file de jobs ou un agent automatique.
- Inventer des règles de stack absentes du projet cible.
- Modifier la stratégie globale des presets `tech_profile`.

### Granularité / nommage

Cette fiche couvre le skill de planification d'exécution. Les presets techno, la politique MCP et les hooks restent dans leurs fiches dédiées car leurs contrats et validations diffèrent.

## Invariants

- `aic-dev-plan` est plan-only : aucune écriture de code applicatif, aucun commit, aucun lancement de chantier implicite.
- Un scope primaire reste actif. Tout passage vers un autre scope doit produire un HANDOFF explicite.
- Le skill privilégie le chargement juste-a-temps : feature doc, règle de scope, règles techno présentes, puis subagent contract seulement si délégation.
- Les règles techno sont consommées comme contraintes de plan, pas comme contexte obligatoire au démarrage.
- L'agent principal reste responsable de l'intégration, même si le plan propose des subagents.

## Décisions

- Nom retenu : `aic-dev-plan`, pas `aic-dev`, pour éviter de suggérer une exécution automatique.
- Le workflow canonique vit sous `.ai/workflows/dev-plan.md`; les wrappers Claude/Codex restent minces.
- Le plan doit produire une matrice par surface plutôt qu'une liste générique de tâches.
- Quand un contrat API, DTO, droits, auth ou données traverse back/front, le plan doit stabiliser le contrat avant le front, sauf exploration UI volontaire.
- Les changements template/CLI seront traités comme propagation downstream et peuvent nécessiter un HANDOFF core.

## Comportement attendu

Quand l'utilisateur demande de préparer ou structurer le développement d'une feature, l'agent invoque `aic-dev-plan` après cadrage ou feature existante. Le skill identifie les technos et surfaces impliquées, propose l'ordre de travail, liste les handoffs nécessaires, associe les checks à chaque étape et signale les inconnues qui empêchent une implémentation fiable.

La sortie attendue est directement exploitable par un agent de développement, mais ne remplace pas une confirmation humaine pour démarrer le code.

## Contrats

- Entrées : intention, feature existante éventuelle, scope primaire, contraintes projet connues, chemins ou technos mentionnés.
- Sortie : plan structuré avec sections fixes `scope`, `surfaces`, `ordre`, `handoffs`, `subagents`, `checks`, `risques`, `prochaine action`.
- Règle de séquencement : contrat/back d'abord si API, DTO, auth, droits, données ou erreurs changent ; front/mock d'abord seulement si exploration assumée.
- Règle de délégation : tout subagent proposé doit avoir un rôle, un write-set, les fichiers interdits et les checks attendus.
- Règle de blocage : si le contrat traversant ou la techno cible est inconnue, le skill doit lister l'inconnue comme bloquante ou hypothèse de travail, pas l'enterrer.

## Validation

- Vérifier que le workflow canonique décrit le chargement JIT, les sorties et les interdits.
- Vérifier que les wrappers Claude/Codex délèguent au workflow sans logique divergente.
- Vérifier que la documentation utilisateur expose `aic-dev-plan` comme étape optionnelle entre frame et implémentation.
- Lancer `check-features`, `check-feature-docs --strict workflow/dev-plan-skill` et `check-shims`.
- Si template touché, lancer `check-dogfood-drift` et `tests/smoke-test.sh`.

## Droits / accès

Non applicable pour les accès runtime du template. Le skill peut toutefois planifier des changements d'auth ou de droits dans un projet cible ; dans ce cas, il doit les traiter comme contrats traversants et demander les checks serveur et front associés.

## Données

Non applicable pour les données propres au template. Le skill peut planifier des migrations ou changements de modèle dans un projet cible ; dans ce cas, il doit les isoler dans une surface dédiée avec rollout, rollback et validation DB explicites.

## UX

L'UX du skill est conversationnelle et structurée. La sortie doit rester compacte pour une feature simple, mais fournir une matrice complète quand plusieurs technos ou scopes sont impliqués.

Le skill ne doit pas afficher une longue checklist neutre : il doit prendre position sur l'ordre recommandé et la prochaine action minimale.

## Observabilité

Non applicable comme instrumentation runtime. La traçabilité repose sur la fiche feature, les worklogs, les handoffs et les checks exécutés.

## Déploiement / rollback

Le déploiement passe par la propagation template/runtime habituelle. Rollback : retirer les wrappers `aic-dev-plan`, le workflow canonique et les références README, puis relancer les checks de shims et de rendu template si les fichiers générés ont été modifiés.

## Risques

- Trop de surface publique : limiter le skill à la planification, sans concurrencer `aic-frame`.
- Plans trop génériques : imposer une matrice par surface et une décision d'ordre.
- Cross-scope implicite : tout passage back/front/core doit être rendu visible par HANDOFF.
- Divergence Claude/Codex/template : wrappers minces et checks de drift obligatoires si propagation template.

## Cross-refs

- `workflow/intentional-skills` : définit la doctrine de skills publics intentionnels.
- `workflow/subagent-contract` : borne la délégation proposée par le plan.
- `core/template-engine` : porte la propagation dans le template Copier et les validations downstream.

## Historique / décisions

- 2026-06-02 : cadrage via `aic-frame`. Décision de créer un skill public `aic-dev-plan` pour structurer les développements multi-techno sans écrire de code.
- 2026-06-02 : audit post-implémentation. Décision de propager le skill dans le template pour résorber le drift dogfood/runtime.
- 2026-06-02 : implémentation runtime — `.ai/workflows/dev-plan.md` (workflow canonique), `.claude/skills/aic-dev-plan/` et `.agents/skills/aic-dev-plan/` (wrappers minces), `README_AI_CONTEXT.md` (ligne workflow quotidien). Template non propagé : HANDOFF `core` requis.
