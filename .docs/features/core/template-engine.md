---
id: template-engine
scope: core
title: Moteur de template copier (profils + scopes conditionnels)
status: active
depends_on: []
touches:
  - copier.yml
  - README.md
  - template/**
progress:
  phase: review
  step: "enrichir les presets techno (V1 tech-dotnet + tech-react + stack-fullstack)"
  blockers: []
  resume_hint: "3 presets enrichis ; smoke-test OK ; prêt pour commit + DONE"
  updated: 2026-04-24
---

# Moteur de template copier

## Objectif

Industrialiser la génération du contexte AI dans n'importe quel projet via `copier copy gh:huyqdt/ai_context .`. Quatre profils (`minimal`, `backend`, `fullstack`, `custom`) déterminent les scopes générés.

## Comportement attendu

- `copier copy` rend les fichiers `.jinja` et exclut conditionnellement les shims/règles selon `agents` et `scopes`.
- `_message_after_copy` guide les prochaines étapes (activation hooks, scripts à lancer).
- `copier update` re-applique les diffs sans casser les ajouts utilisateur.

## Contrats

- `project_name` requis ; validateur bloque si vide.
- `scope_profile` ∈ {minimal, backend, fullstack, custom} → dérive `scopes` (variable calculée).
- `agents` multiselect ∈ {claude, codex, cursor, gemini, copilot} → conditionne shims.
- `docs_root` (default `.docs`) configure le dossier feature mesh.
- `tech_profile` ∈ {generic, dotnet-clean-cqrs, react-next, fullstack-dotnet-react} → génère des règles stack optionnelles sans modifier les scopes métier.

## Cross-refs

Ce moteur produit le squelette consommé par `feature-mesh`, `feature-index-cache`, `claude-skills`, `git-hooks`. Toute évolution structurelle (nouveau scope, nouveau hook) passe par `copier.yml` + `template/`.

## Historique / décisions

- v0.1 : profil unique fullstack.
- v0.4 : introduction des 4 profils + agents multiselect.
- v0.7.2 : `_envops.keep_trailing_newline` pour préserver les `\n` finaux après rendu jinja.
- 2026-04-24 : ajout du script `template/.ai/scripts/auto-progress.sh.jinja` + entrée Stop dans `template/.claude/settings.json.jinja` + entrées `.session-edits.flushed` / `.progress-history.jsonl` dans `template/.ai/.gitignore`. Édité dans le cadre du HANDOFF workflow → core émis pendant l'implémentation de `workflow/conversational-skills` (v3, auto-progression invisible). Aucune dérive de profil ni de variable copier ; uniquement enrichissement de la moisson de fichiers rendus.
- 2026-04-24 : ajout de `template/.githooks/pre-commit.jinja` (hook universel d'auto-progression) + update `template/.githooks/README.md.jinja` pour le documenter. Édition cross-scope mineure depuis `workflow/git-hooks` (mini-chantier 1.5, parité agent-agnostic pour Codex/Cursor/Gemini/Copilot). Le template utilise la variable `{{ agents }}` pour lister les bénéficiaires dans le commentaire. Pas d'impact sur `copier.yml` ni sur la dérivation des scopes — simple fichier supplémentaire moissonné systématiquement (pas de condition jinja).
- 2026-04-24 : update `_message_after_copy` dans `copier.yml` + réécriture de `template/AGENTS.md.jinja` pour acter l'UX « 0 skill par défaut » (auto-progression invisible via hooks Stop + pre-commit, skills `/aic` et `/aic-feature-resume` en override/lecture seulement). HANDOFF reçu depuis `workflow/conversational-skills` (chantier 3). Aucune variable copier nouvelle, aucune dérive de profil — modification éditoriale des messages/docs.
- 2026-04-24 : patch `template/.ai/scripts/auto-progress.sh.jinja` — le script crée désormais le worklog s'il n'existe pas (au lieu de skipper). Bug révélé par le smoke-test [18/27] : pour les agents non-Claude (pre-commit sans hook Stop préalable), le worklog n'avait jamais été créé par `auto-worklog-flush.sh`, donc l'auto-progression ne laissait aucune trace lisible. Correctif miroir sur `.ai/scripts/auto-progress.sh`. Ajout section `## Auto-progression` dans `template/.ai/index.md.jinja`.
- 2026-04-24 : ajout des helpers de matching `touches:` dans `template/.ai/scripts/_lib.sh.jinja`. Objectif : éviter les divergences entre hook `PreToolUse`, auto-worklog, pre-commit et coverage.
- 2026-04-24 : les scripts template consomment désormais `AI_CONTEXT_DOCS_ROOT={{ docs_root }}` depuis `_lib.sh.jinja` pour supporter `docs_root=docs` sur les chemins runtime (`check-features`, index, reminder, commit guard).
- 2026-04-24 : README racine synchronisé avec le runtime actuel (`docs_root` configurable, matching `touches:` centralisé, pre-commit/auto-progress dans l'arbre généré).
- 2026-04-24 : ajout du preset `tech_profile` dans `copier.yml` + règles conditionnelles `tech-dotnet`, `tech-react`, `stack-fullstack-dotnet-react`. Les règles reprennent des patterns génériques observés sur `ticketing.apps` (Clean Architecture/CQRS, feature-sliced React, contrat back/front), sans copier les conventions métier/projet.
- 2026-04-24 : README enrichi avec une procédure de migration pour projet existant déjà équipé d'un contexte AI : preview hors repo, inventaire des fichiers à copier vs fusionner, migration progressive des features à plat vers `.docs/features/<scope>/`.
- 2026-04-24 : retour d'installation sur projet réel — correction du newline littéral dans `pre-turn-reminder.sh` et exclusion des dossiers générés (`node_modules`, `bin`, `obj`, `dist`, `wwwroot`, etc.) dans `check-feature-coverage.sh`, avec extension du coverage aux fichiers C#.
- 2026-04-24 : ajout de 2 squelettes conditionnels `template/docs/design-system-registry.md.jinja` et `template/docs/atomic-design-map.md.jinja` + 2 entrées `_exclude` dans `copier.yml` (rendus uniquement si `tech_profile ∈ {react-next, fullstack-dotnet-react}`). Travail porté par la fiche [core/preset-ds-skeletons](core/preset-ds-skeletons.md). Aucune nouvelle variable copier ; les squelettes sont moissonnés dans `docs/` (racine), pas `{{ docs_root }}/` (convention front).
- 2026-04-24 : enrichissement V1 du preset `stack-fullstack-dotnet-react` (24 → ~100 lignes). Structure 5 blocs : `Stack déclarée` / `Contrat API` / `Séquencement & handoff` / `Interdits explicites` / `Validation croisée`. Ajouts clés : source de vérité du contrat tranchée (OpenAPI généré recommandé, ou DTO partagés), changement de contrat = acte gouverné (endpoint/DTO/auth/droits/erreurs), nommage cohérent DTO↔client↔schéma Zod↔UI, hiérarchie d'URL miroir UI/menu, client HTTP centralisé obligatoire côté front, mapping droits↔endpoint documenté, 6 interdits explicites (deviner un DTO non documenté, `fetch` brut dispersé, renommer sans propager, endpoints hors hiérarchie, changements silencieux de droits/nullabilité, adapters de noms entre back et front). Validation croisée : diff OpenAPI si contrat change, régénération client front + typecheck, vérification guards front si droits modifiés.
- 2026-04-24 : enrichissement V1 du preset `tech-react` (41 → ~165 lignes). Structure 7 blocs : `Stack déclarée` / `Architecture & nommage` / `Design System & composants partagés` / `Data, formulaires, état` / `UX, accessibilité, i18n` / `Interdits explicites` / `Validation`. Ajouts clés inspirés de `ticketing.apps` : arborescence hiérarchisée (`ui/primitives` → `ui/common` → `ui/partials`), **registry obligatoire** (`docs/design-system-registry.md` tenu à jour dans le même commit que l'ajout de composant), **atomic map obligatoire dès 30 composants**, isolation stricte des libs tierces lourdes via `ui/adapters/<lib>/`, Storybook recommandé dès 10 composants, TanStack Query v5 cookbook (`queryKey`, invalidation via `queryClient`, pas de bus d'événement), RHF + Zod (schéma = source unique de validation, messages = clés i18n), 10 interdits explicites (duplication sans scan, imports directs libs tierces, `dispatchEvent` pour invalidation, callbacks `refreshXxx`, regex hors schéma…). États UI minimums imposés (loading/empty/error/success).
- 2026-04-24 : enrichissement V1 du preset `tech-dotnet` (40 → 92 lignes). Passage à une structure en 5 blocs standardisés : `Stack déclarée` / `Architecture & nommage` / `Erreurs, données & sécurité` / `Interdits explicites` / `Validation`. Ajouts clés inspirés de `ticketing.apps/.ai/workflow/backend/L1_BACKEND_CSHARP.md` : suffixes de nommage obligatoires (`UseCaseCommand`/`Request`), visibilité `internal` par défaut, `Result<T>` + failures typés au niveau des ports, contraintes domain non-anémique, SQL safety précise (`QUOTENAME()`/allowlist), check DI wiring, seuil de tests chiffré (1 happy + 1 error par handler). **3 points d'entrée documentés** (HTTP contrôleur / `Applications/Workers` / `Applications/MessageHandlers`) avec un interdit explicite « worker ou message handler sans use case ». `tech-react` et `stack-fullstack-dotnet-react` restent en attente d'un tour dédié.
- 2026-04-27 : ajout de `adoption_mode` dans `copier.yml` (`lite`, `standard`, `strict`). `lite` exclut `.githooks` et workflows CI ; `strict` conserve les workflows même avec `enable_ci_guard=false`. Smoke-test enrichi pour valider ces rendus.
- 2026-04-27 : correction UX du message post-scaffold en `adoption_mode=lite` : suppression de l'instruction trompeuse d'activation `.githooks` quand ce dossier n'est pas généré ; message guidant explicitement vers `standard`/`strict` pour activer l'enforcement local.
- 2026-04-27 : correction UX complémentaire du message post-scaffold en `adoption_mode=lite` : l'étape `/hooks` est désormais explicitement marquée inutile en mode lite (évite une action sans effet).
- 2026-04-27 : README aligné sur ce comportement `lite` avec une note explicite : activation hooks locaux et `/hooks` côté Claude sans effet tant que `.githooks` n'est pas scaffoldé.
- 2026-04-27 : correction de la syntaxe `_message_after_copy` dans `copier.yml` : suppression des blocs Jinja `{% if %}` bruts dans le YAML (source de `yaml.scanner.ScannerError` au parsing Copier), remplacés par des expressions inline `{{ ... if ... else ... }}`.
