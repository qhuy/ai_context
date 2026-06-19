---
frame_id: "2026-06-19-project-overlay-scope-registry"
status: "done"
scope_probable: "workflow"
route: "feature"
level: "high"
evidence: "4 tours de design convergés avec l'utilisateur, vérifiés contre .ai/index.md, .ai/OWNERSHIP.md, .ai/schema/feature.schema.json (scope=string libre), copier.yml (skip_if_exists, pas de _migrations), docs/upgrading.md et la feature core/project-overlay-stable (qui exclut explicitement migration + obligation d'index)."
next_hint: "Décisions confirmées (2026-06-19) : découpage 2 features + rattachement doc accepté ; on démarre par core/project-overlay-scope-registry (contrat) ; skill nommé aic-onboard. Reste : HANDOFF workflow→core puis création de la feature core via feature-new après confirmation du header (scope/id/depends_on/touches)."
created_at: "2026-06-19"
updated_at: "2026-06-19"
---

# Frame 2026-06-19-project-overlay-scope-registry — Overlay projet comme registre de scopes + skill init/sync/migrate

## Intention

Donner à `ai_context` la capacité d'**ingérer un projet brownfield et de peupler/maintenir/migrer son overlay projet** (`.ai/project/**`), pour que chaque scope du projet (app, couche, préoccupation : `bo-front`, `bo-back`, `sql`, `infra`…) porte ses spécificités durables là où elles survivent à `copier update`.

Le problème réel n'est pas « un skill qui analyse l'archi ». C'est que **rien ne peuple `.ai/project/` aujourd'hui** : `_skip_if_exists`, jamais scaffoldé, et le `.ai/config.yml` par défaut (orienté C#/React) scanne 0 fichier sur une autre stack. C'est la plus grosse falaise d'onboarding du template, invisible parce que le repo se dogfood lui-même et n'a jamais vécu une vraie première install sur du code applicatif.

## Niveau de cadrage

Niveau : `high`

Justification :

- Touche un contrat agentique durable (format de l'overlay), un skill/workflow, un schéma, une migration et la compatibilité downstream.
- Étend un invariant possédé par `core/project-overlay-stable` (« pas de chargement récursif de `.ai/project/**` »).
- Cross-scope `workflow` (le skill) → `core` (contrat overlay) → `product` (procédure de migration / upgrading).

## Objectif

- Faire de `.ai/project/**` un **registre de scopes projet** : un scope = un dossier + un `index.md` privé (routeur + manifeste).
- Livrer un skill conversationnel à trois modes — `init` / `sync` / `migrate` — qui **détecte** (inférable du code), **interviewe** (savoir tribal), puis **scaffolde** sous `.ai/project/**` uniquement.
- Définir un **contrat de forme** versionné pour `.ai/project/<scope>/index.md` (discipline `feature.schema.json`).
- Prévoir la **migration paresseuse** des overlays existants vers cette organisation, sans casser les consumers déjà à jour.

## Non-objectifs

- Produire un rapport d'architecture exhaustif (anti-pattern lean ; viole `.ai/context-ignore.md`).
- Écrire ailleurs que dans `.ai/project/**` (interdit : violerait l'ownership et créerait du drift).
- Auto-appliquer une migration (toujours proposer + diff + confirmation, réversible git).
- Re-détecter pendant `migrate` (relocation pure ; l'enrichissement est une passe `sync` séparée et explicite).
- Rendre la migration bloquante à `copier update` (le contrat de chargement reste forward-tolérant).
- Introduire un versioning de package/template (cohérent avec le modèle « pas de bump ») : seul l'**overlay** porte sa propre version de contrat.

## Scope et route

Scope primaire probable : `workflow` (le skill est le livrable tête d'affiche).

Route : `feature`, **avec découpage recommandé** (voir Préconisations) car l'intention traverse 3 scopes et le skill ne peut pas être correct sans que le contrat d'overlay existe d'abord.

## Challenge IA

- **« Exhaustif » est rejeté.** La valeur n'est pas l'exhaustivité mais le **routage** : un overlay lean qui dit *où regarder par path/scope*, pas un dump qui périme. Reformulé en « générateur/mainteneur d'overlay », validé par l'utilisateur.
- **Skill OU workflow est un faux dilemme ici.** Dans ce repo, chaque skill = `SKILL.md` mince → `workflow.md`. Le vrai axe est *jugement piloté modèle* vs *script déterministe*. Classer du code en scopes et relocaliser du contenu curé = inférence + interaction + écriture project-owned avec confirmation ⇒ **skill backé par workflow**, pas script pur.
- **Une feature ou plusieurs ?** Plusieurs. Le contrat d'overlay (core) est prérequis du skill (workflow) ; la procédure de migration se documente dans l'initiative produit existante. Une feature monolithique violerait « un scope primaire par tâche ».
- **Faut-il étendre `core/project-overlay-stable` plutôt qu'une nouvelle feature core ?** Non : cette feature a livré « overlay existe, stable, optionnel » et exclut explicitement migration + index obligatoire. Le nouveau livrable (« overlay = registre de scopes structuré et versionné ») est un cran au-dessus ⇒ nouvelle feature core `depends_on` elle.
- **Angle mort principal** : le design **étend un invariant de `core/project-overlay-stable`** (« pas de chargement récursif »). Notre `.ai/project/<scope>/index.md` impose à l'agent de **descendre d'un niveau** (sur match de path, via pointeur explicite — pas une récursion aveugle). C'est compatible mais c'est une modification de contrat core ⇒ HANDOFF obligatoire.

## Analyse technique approfondie

### Métier / produit

- **Scope = unité de routage + foyer de conventions** d'un projet consommateur. Émerge dès qu'une feature porte `scope: X` (le schéma autorise `scope=string, minLength:1`, pas d'enum).
- `.ai/project/<scope>/` est le **pendant project-owned, divergence-safe, de `.ai/rules/<scope>.md`** (upstream-managed, intouchable sans drift).
- Deux espaces de noms coexistent : meta-scopes du template (`core/quality/workflow/product`) vs domain-scopes du projet (`bo-front`, `sql`…). Décision actée : les domain-scopes deviennent des scopes de premier niveau du consumer (option A du design).

### Technique

- **Structure fractale** : `.ai/index.md` → `.ai/project/index.md` (route path→scope) → `.ai/project/<scope>/index.md` (route path→feuille) → feuilles, chargées à la demande. Lean respecté : le lean punit le *load*, pas l'*existence* sur disque.
- **Contrat de forme** `.ai/project/<scope>/index.md` (routeur+manifeste, pas redirection vide) : sections fixes ou front-matter — `paths:` routés, `conventions:` durables (pointeurs), `derived:` pointeurs volatils, `meta:` (stack, commande test/build, owner), `overlay_contract_version`.
- **Durable vs volatile** : strictement séparés. Convention durable documentée (ex. nommage `NNN_x.sql`, règle données référentielles) ; état volatile (sprint courant) **jamais en prose** → dérivé (détecter le dernier `db/sprints/*`) ou valeur unique dans `.ai/project/config.yml`.
- **Skill 3 modes**, auto-détectés selon l'état de `.ai/project/` : `init` (vide) / `sync` (enrichir/affûter par scope) / `migrate` (réorganiser l'existant).
- **Migration deux temps** : (1) `copier update` livre le nouveau skill + le contrat + le doc d'upgrade ; (2) l'utilisateur lance `migrate` qui réorganise le project-owned. `copier` ne peut pas migrer `.ai/project/**` (skip_if_exists, pas de `_migrations` dans `copier.yml`).
- **Migrate sûr** : préserver (relocation, pas régénération) ; proposer (diff + confirmation) ; idempotent via `overlay_contract_version` → cliquet vN.

### Impacts (fichiers / surfaces probables)

- Skill : `template/.claude/skills/<skill>/` + `.claude/skills/<skill>/` (dogfood) + parité `.agents/skills/<skill>/` (Codex, cf. `workflow/claude-skills`, `workflow/codex-hooks-parity`).
- Workflow : `.ai/workflows/<skill>.md` (+ jinja template).
- Contrat overlay : `.ai/templates/project-overlay/README.md(.jinja)`, possiblement un `.ai/schema/overlay-scope.schema.*`, et extension du chargement dans `.ai/index.md(.jinja)` + `.ai/OWNERSHIP.md(.jinja)`.
- Doc migration : `docs/upgrading.md`, `CHANGELOG.md`.
- Checks : `check-dogfood-drift.sh` / `check-ai-references.sh` doivent tolérer la nouvelle arborescence `.ai/project/<scope>/**`.

### Compatibilité

- **Claude + Codex** : l'overlay est consommé par le contrat de chargement (markdown routé), agent-agnostique. Le skill doit avoir sa parité Codex.
- **Templates** : contrat + skill livrés via `template/**.jinja`.
- **Downstream** : consumers sans overlay ou en overlay plat **continuent de fonctionner** (contrat forward-tolérant) ⇒ migration opt-in.

## Scénario nominal

1. Sur un consumer multi-app (`bo-front`, `bo-back`, `sql`…) fraîchement mis à jour, l'utilisateur lance le skill.
2. Mode auto-détecté `init` (pas d'overlay). Le skill détecte apps/couches/roots, propose la liste de scopes + le routing des paths.
3. Il interviewe sur le non-inférable (« toute modif SQL → script du sprint courant, nommage `NNN_x.sql` »).
4. Il propose l'arborescence `.ai/project/<scope>/index.md` conforme au contrat, sépare durable/volatile, stampe `overlay_contract_version`.
5. Après confirmation, il écrit **uniquement** sous `.ai/project/**`. L'overlay est désormais le registre de scopes du projet.

## Cas limites

1. **Overlay config-only** (ce repo dogfood : juste `.ai/project/config.yml`) → `migrate` quasi no-op ; ne **pas** inventer de domain-scopes là où il n'y en a pas. Fixture de test gratuite.
2. **Overlay plat curé à la main** (prose riche dans `.ai/project/payments.md`) → `migrate` relocalise sans perte ; si un fichier plat mappe sur plusieurs scopes de façon ambiguë → **demander, pas deviner**.
3. **Règles locales noyées dans l'upstream** (`.ai/rules/<scope>.md` ou legacy `L1_*`) → relocation projet ; distinguer lignes spécifiques-projet vs génériques = jugement ⇒ proposer un diff.
4. **Re-run** : `migrate` sur overlay déjà au contrat courant (stamp à jour) → no-op idempotent.
5. **État volatile** : « sprint courant » → dérivé/valeur unique, jamais figé en prose.

## Incertitudes

| Catégorie | Point | Décision |
|---|---|---|
| Bloquant maintenant | Découpage en 2 features (core contrat + workflow skill) + rattachement doc produit : à confirmer avant toute création | Question posée ci-dessous |
| Bloquant maintenant | Nom du skill (`aic-onboard` recommandé) et `scope/id` des features | Proposés, à confirmer |
| Hypothèse de travail | Contrat de forme via front-matter YAML + sections fixes (cohérent `feature.schema.json`) | Adopté sauf objection au cadrage technique |
| Hypothèse de travail | Le skill se livre aussi en parité Codex (`.agents/skills/`) comme les autres | Adopté (suit `workflow/claude-skills`) |
| Risque accepté | Étendre l'invariant « pas de chargement récursif » de `core/project-overlay-stable` | Acceptable car descente = pointeur explicite borné, pas récursion ; validé via HANDOFF core |
| À valider plus tard | Faut-il un `.ai/schema/overlay-scope.schema.*` exécutable (validé par un check) ou un contrat documentaire seul ? | À trancher en `aic-dev-plan` du contrat core |
| À valider plus tard | Adaptation exacte de `check-dogfood-drift.sh` / `check-ai-references.sh` à `.ai/project/<scope>/**` | Attaché à l'étape contrat |

## Aspects non couverts / à couvrir

- La **détection automatique des scopes** (heuristiques par stack) : sa profondeur sera cadrée dans le `aic-dev-plan` du skill, pas ici.
- L'**UX d'interview** (questions posées à l'utilisateur) : à concevoir avec le contrat, hors frame.
- La **génération du contenu métier** des conventions : le skill scaffolde le squelette + interviewe ; il ne devine pas les règles métier.

## Préconisations

1. **Découper en 2 features + 1 rattachement** (position ferme) :
   - **`core/project-overlay-scope-registry`** *(prérequis)* — contrat de forme `.ai/project/<scope>/index.md`, `overlay_contract_version`, extension du chargement (descente d'un niveau bornée), adaptation des checks. `depends_on: [core/project-overlay-stable]`.
   - **`workflow/project-overlay-onboarding`** — le skill `init`/`sync`/`migrate`. `depends_on: [core/project-overlay-scope-registry, workflow/intentional-skills, workflow/claude-skills]`.
   - **Rattacher la procédure `migrate`** à `product/ai-context-stability-migration` (possède `docs/upgrading.md` + `CHANGELOG.md`).
2. **Séquencer** : contrat core d'abord, skill ensuite. Le skill produit/migre des fichiers conformes au contrat — le contrat doit exister avant.
3. **HANDOFF cross-scope explicite** `workflow → core → product` avant toute écriture hors scope primaire.
4. **Nom du skill** : `aic-onboard` (verbe tête d'affiche), alternative `aic-project-overlay`. À confirmer.

## Décision de routage : feature

Justification :

- Comportement agent/workflow nouveau + contrat durable ⇒ exige des fiches feature (pas `doc` ni `manual`).
- Le périmètre est clair et actionnable, pas un blocage de compréhension ⇒ pas `diagnose`.
- L'ampleur impose le découpage, pas l'abandon ⇒ pas `dropped`.

## Plan

1. **Confirmer** le découpage, les `scope/id` et le nom du skill (questions ci-dessous).
2. Créer **`core/project-overlay-scope-registry`** via `.ai/workflows/feature-new.md` (avec HANDOFF core).
3. `aic-dev-plan` sur le contrat : forme exacte de `.ai/project/<scope>/index.md`, schéma exécutable ou documentaire, stamp de version, adaptation des checks.
4. Créer **`workflow/project-overlay-onboarding`** (`depends_on` le contrat) ; `aic-dev-plan` sur le skill (3 modes, détection, interview, scaffolding, garde-fous migrate).
5. Rattacher la procédure `migrate` à `product/ai-context-stability-migration` (mise à jour `docs/upgrading.md` + `CHANGELOG.md`).
6. Dogfood sur ce repo (état overlay config-only) comme premier test du mode `migrate` (attendu : quasi no-op).

## Validation

- **Acceptance** :
  - Un consumer sans overlay obtient, après `init` + confirmation, un `.ai/project/` registre de scopes conforme au contrat, écrit uniquement sous `.ai/project/**`.
  - `migrate` relocalise un overlay plat sans perte de contenu, est idempotent (stamp), et no-op sur un overlay déjà au contrat.
  - Aucun fichier upstream-managed touché par le skill ; `check-dogfood-drift` reste vert.
  - Consumers existants (sans overlay / overlay plat) fonctionnent sans lancer `migrate`.
- **Checks** : `check-dogfood-drift.sh`, `check-ai-references.sh`, quality gate, smoke-test ; validation du contrat (schéma si exécutable).
- **Doc impact** : `docs/upgrading.md`, `CHANGELOG.md`, `.ai/templates/project-overlay/README.md`, `.ai/OWNERSHIP.md` (mention registre de scopes), fiches features + worklogs.

## Points à confirmer

- Découpage 2 features + rattachement doc : OK ?
- `scope/id` : `core/project-overlay-scope-registry` puis `workflow/project-overlay-onboarding` : OK ?
- Nom du skill : `aic-onboard` ?
- Démarre-t-on par créer la feature **contrat core** (recommandé) ?
