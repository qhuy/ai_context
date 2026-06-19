# Workflow — project-overlay-sync (skill aic-onboard)

**Goal** : peupler, maintenir ou migrer l'overlay projet `.ai/project/**` en tant que registre de scopes, conforme au contrat de forme. Détecter ce qui est inférable, interviewer le non-inférable, scaffolder après confirmation.

**Role** : Scaffolder interactif. Écrit **uniquement** sous `.ai/project/**`. Propose toujours avant d'écrire. Ne devine jamais une règle métier : il l'infère du code ou la demande.

## INPUT

- Invocation `aic-onboard`, éventuellement avec un focus de scope explicite.
- Si un état inattendu de `.ai/project/` est rencontré : le décrire et demander avant d'agir.

## MANDATORY READS

- `.ai/index.md`
- `.ai/OWNERSHIP.md` (section « Registre de scopes »)
- `.ai/templates/project-overlay/README.md` — **le contrat de forme** (front-matter, sections, durable vs volatile, stamp de version)
- `.ai/config.yml` (`coverage.roots`, extensions) pour amorcer la détection
- L'overlay existant sous `.ai/project/**` s'il existe

Ne pas précharger d'autres docs sans signal.

## DÉTECTION DU MODE

Inspecter `.ai/project/` et choisir :

- `init` : pas de `.ai/project/index.md` → registre à créer de zéro.
- `sync` : overlay déjà conforme (stamp `overlay_contract_version` présent) → enrichir/affûter par scope.
- `migrate` : overlay ancien — plat (`.ai/project/<x>.md`), config-only (`config.yml` seul), ou règles legacy dans `.ai/rules/<scope>.md` / `L1_*` → réorganiser vers le registre de scopes.

Annoncer le mode détecté et le justifier en une ligne.

## PHASES

### 1. Détection (inférable)

À partir de `coverage.roots` et de la structure du dépôt, proposer une liste de scopes candidats :

- Apps / couches (ex. `bo-front`, `bo-back`, `sql`, `infra`) par répertoires racines et conventions.
- Stack par scope (fichiers manifestes : `package.json`, `*.csproj`, `pom.xml`, `pyproject.toml`…).
- Commandes test/build inférables.
- Globs de paths que chaque scope possède.

Présenter ces scopes comme **proposition**, jamais comme acquis.

### 2. Interview (non-inférable)

Demander uniquement ce que le code ne révèle pas — le savoir tribal :

- Conventions durables (ex. « toute modif SQL → script du sprint courant, nommage `NNN_x.sql` »).
- Éléments volatils à dériver (ex. « le sprint courant = dernier dossier `db/sprints/*` »).
- Propriétaires / contacts par scope si utile.

Grouper les questions par scope. Ne pas inventer de réponse.

### 3. Proposition

Présenter l'arborescence cible conforme au contrat (`.ai/templates/project-overlay/README.md`) :

- `.ai/project/index.md` (front-matter avec `overlay_contract_version`, routage `path → scope`).
- un `.ai/project/<scope>/index.md` par scope (front-matter `scope`/`paths`/`meta`, sections `conventions`/`derived`).

Marquer explicitement durable vs volatile. Attendre validation avant toute écriture.

### 4. Écriture (après confirmation)

- Écrire **uniquement** sous `.ai/project/**`.
- Stamper `overlay_contract_version` une seule fois, dans `.ai/project/index.md`.
- Ne jamais écrire d'état volatile en prose : le dériver ou le pointer vers `.ai/project/config.yml`.

## MODE migrate — garde-fous

- **Préserver, pas régénérer** : relocaliser le contenu curé (`.ai/project/<x>.md` → `.ai/project/<x>/index.md`), sans re-détecter ni écraser. L'enrichissement est le mode `sync`, séparé.
- **Proposer, jamais auto-appliquer** : montrer un diff de relocation, attendre confirmation, rester réversible par git.
- **Idempotent** : lire `overlay_contract_version` ; si déjà à la version courante, no-op.
- **config-only** (overlay réduit à `config.yml`) : quasi no-op ; ne pas inventer de scopes là où il n'y en a pas.
- **Règles legacy** (`.ai/rules/<scope>.md`, `L1_*`) : relocaliser la part spécifique-projet vers `.ai/project/<scope>/`, laisser le générique en amont.

## NON-NEGOTIABLE RULES

- Écriture limitée à `.ai/project/**`. Jamais un fichier upstream-managed.
- Pas d'écriture sans proposition validée explicitement.
- `migrate` ne re-détecte pas : il relocalise.
- Durable vs volatile strictement séparés ; l'état volatile n'est jamais figé en prose.
- Respecter le contrat de forme de `.ai/templates/project-overlay/README.md` ; en cas de doute, le relire avant d'écrire.
- Pas de catalogue : un index de scope est un routeur + manifeste, pas un dump.

## SORTIE

- Mode appliqué, scopes traités, fichiers écrits sous `.ai/project/**`.
- Ce qui a été inféré vs demandé.
- Pour `migrate` : ce qui a été relocalisé, et le diff appliqué.
- Prochaine action suggérée (ex. relancer `sync` après un nouveau sprint, compléter un scope).
