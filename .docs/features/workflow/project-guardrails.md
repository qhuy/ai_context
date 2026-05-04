---
id: project-guardrails
scope: workflow
title: Procédure project-guardrails — non-goals + glossaire métier pour orienter l'agent
status: active
depends_on:
  - workflow/claude-skills
  - core/feature-mesh
touches:
  - .ai/workflows/project-guardrails.md
  - .ai/index.md
  - README_AI_CONTEXT.md
  - template/.ai/workflows/project-guardrails.md.jinja
  - template/.ai/index.md.jinja
  - template/README_AI_CONTEXT.md.jinja
  - copier.yml
touches_shared:
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "guardrails conservé hors Pack A"
  blockers: []
  resume_hint: "vérifier que project-guardrails reste on-demand dans index, workflow et smoke-test"
  updated: 2026-05-04
---

# Procédure project-guardrails

## Objectif

Combler le trou identifié dans le contexte général projet : la `project_description` (copier) se réduit à 1 ligne en blockquote, et les 8 skills `/aic-*` existants sont 100 % feature-centric. Aucun mécanisme ne capture **les non-goals** (ce que l'agent ne doit *pas* proposer) ni le **glossaire métier** (acronymes, vocabulaire spécifique).

La procédure cible spécifiquement ce qui n'est *pas* déjà dans le README — pour orienter l'agent, pas pour décrire le produit. Vision et utilisateurs cibles restent intentionnellement délégués au README pour éviter la duplication.

## Comportement attendu

### Surface

| Entrée | Statut | Quand l'utiliser |
|---|---|---|
| `/aic-frame` | recommandé | Cadrage complet ; peut matérialiser les guardrails si le besoin concerne les non-goals ou le glossaire |
| `.ai/workflows/project-guardrails.md` | procédure interne | Écriture déterministe de `.ai/guardrails.md` après confirmation |

### Workflow

1. **Cadrage** : détecter `.ai/guardrails.md`. Si présent → proposer `update` / `replace` / `cancel`.
2. **Non-goals** : dialogue. 3-7 items typiques. Pour chacun, raison courte si non-évidente. **Minimum 1 item obligatoire** (sans ça le skill perd sa valeur).
3. **Glossaire** (optionnel) : « Y a-t-il du vocabulaire métier spécifique ? Acronymes ? » — si non, section omise.
4. **Récapitulatif** + confirmation utilisateur.
5. **Écriture** de `.ai/guardrails.md`.
6. **Référence on-demand** : vérifier que `.ai/index.md` ne force pas `guardrails.md` dans Pack A ; proposer seulement un pointeur hors Pack A si utile.

### Livrable utilisateur

`.ai/guardrails.md` (sous `.ai/`, pas `{{ docs_root }}/`, parce que c'est de l'orientation agent et non de la doc produit). Sections :

- **Non-goals (explicitement hors-scope)** — items que l'agent ne doit pas proposer/implémenter.
- **Glossaire métier** (optionnel) — vocabulaire à utiliser tel quel.

## Contrats

- La procédure est conservée sous `.ai/workflows/`. La surface utilisateur recommandée est `/aic-frame`.
- Non référencé dans Pack A. `.ai/guardrails.md` se charge seulement pour cadrage, non-goals ou glossaire métier.
- Pas d'injection runtime dans `pre-turn-reminder.sh` → coût tokens nul par défaut.
- Idempotent : ré-exécution = mode update sans perte de contenu.
- Pas de `feat:` commit déclenché par cette procédure (livrable doc).
- Vision / Users / Roadmap **explicitement absents** du fichier généré (délégué au README).

## Cross-refs

- **`workflow/claude-skills`** : catalogue parent. La procédure n'est plus exposée comme skill Claude.
- **`core/feature-mesh`** : la procédure reste documentée sans ajouter de charge obligatoire au démarrage agent.

## Historique / décisions

- **2026-04-28** — Création. Première itération envisageait un skill 4-sections (Vision + Users + Non-goals + Glossaire) sous le nom `/aic-project-bootstrap`. Audit honnête : Vision et Users sont redondants avec README et `project_description`. Resserrage aux **Non-goals + Glossaire** seuls (la valeur unique non couverte ailleurs), renommage en `/aic-project-guardrails` (intent : orienter l'agent, éviter la dérive — distinct d'un README marketing). Le fichier produit vit sous `.ai/` (orientation agent) et non sous `{{ docs_root }}/` (doc métier).
- **2026-05-03** — Dogfooding appliqué au repo source : le skill rendu `.claude/skills/aic-project-guardrails/*`, la référence Pack A dans `.ai/index.md` et l'étape recommandée dans `README_AI_CONTEXT.md` sont synchronisés.
- **2026-05-03** — `tests/smoke-test.sh` intègre les tests unitaires de régression review. Aucun changement sur le skill guardrails, mais le smoke partagé de cette feature reste aligné.
- **2026-05-03** — `tests/smoke-test.sh` passe en `touches_shared` pour conserver la visibilité review sans faux blocage freshness.
- **2026-05-03** — Étape intermédiaire : `/aic-project-guardrails` était maintenu pour compatibilité, mais le point d'entrée recommandé devenait déjà `/aic-frame`.
- **2026-05-03** — Retrait du skill Claude `/aic-project-guardrails` et déplacement de sa logique dans `.ai/workflows/project-guardrails.md`, consommable par Claude et Codex via `/aic-frame`.
- **2026-05-03** — `README_AI_CONTEXT.md` conserve `/aic-frame` comme cadrage recommandé, mais ajoute une table de workflow quotidien (`status`, `brief`, `review`, `doctor/check`) pour clarifier l'usage après bootstrap.
- **2026-05-03** — La table quotidienne s'étend à `mission`, `document-delta`, `repair` et `ship-report` : le cadrage projet reste `/aic-frame`, tandis que la CLI couvre les gestes Codex/agents non-hookés.
- **2026-05-03** — Le cadrage produit est désormais porté par `scope: product` dans le feature mesh ; les guardrails restent limités aux non-goals/glossaire et ne deviennent pas une roadmap parallèle.
- **2026-05-04** — `first-run` mentionne `/aic-frame` et `.ai/guardrails.md` comme étape possible, sans réintroduire `/aic-project-guardrails` dans l'UX publique.
- **2026-05-04** — La doc d'update ajoute `repair-copier-metadata` et `template-diff`; le cadrage projet reste séparé des métadonnées Copier, mais README_AI_CONTEXT est synchronisé sur la nouvelle surface CLI.
- **2026-05-04** — Lean Codex : la procédure ne demande plus d'ajouter `.ai/guardrails.md` dans Pack A. Elle vérifie au contraire que les guardrails restent on-demand.
- **2026-05-04** — Le template feature renforcé sépare les guardrails projet des décisions de feature : les non-goals/glossaire restent dans `.ai/guardrails.md`, tandis que les décisions fonctionnelles et techniques vivent dans la fiche feature concernée.
