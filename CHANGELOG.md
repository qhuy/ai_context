# CHANGELOG

## [Unreleased]

> Profil strict OKF Phase 0 (`core/okf-strict-profile`) : les fiches feature deviennent
> des concepts Open Knowledge Format valides, sans rien perdre du modèle riche.
> **Non-cassant** : `type` optionnel à l'introduction, requis seulement au release d'enforce suivant.

### Nouveau
- Overlay projet **registre de scopes** : `.ai/project/<scope>/index.md` (un dossier + index privé par app/couche/préoccupation), avec un contrat de forme documenté (`paths`, `meta`, `conventions`, `derived`) et un stamp global `overlay_contract_version`. Le contrat de chargement descend d'un niveau, sur match de path, par pointeur explicite. Voir `core/project-overlay-scope-registry`.
- Skill **`aic-onboard`** (Claude + Codex) : peuple, maintient ou migre l'overlay projet (modes `init`/`sync`/`migrate` auto-détectés) — détecte les scopes inférables, interroge les conventions tribales, scaffolde après confirmation, écrit uniquement sous `.ai/project/**`. Procédure canonique `.ai/workflows/project-overlay-sync.md`. Voir `workflow/project-overlay-onboarding`.
- **Gate Stop de fraîcheur documentaire** (`workflow/stop-turn-doc-gate`) : un hook `Stop` (Claude) bloque la fin de tour si du code couvert par une feature est modifié dans le working tree sans mettre à jour sa fiche/worklog. Nouveau mode `check-feature-freshness.sh --worktree` (présence-based), orchestré par `stop-sequence.sh` (sérialise gate puis archivage). Échappatoire `AIC_DOC_GATE=off` ; garantie stable cross-agent = `commit-msg`/CI ; parité Codex opt-in documentée (`workflow/codex-hooks-parity`).
- Profil strict OKF (Phase 0) : frontmatter — nouveaux champs optionnels `type` (enum `feature|contract|workflow|reference`) et `description`. `check-features.sh` avertit (warn, jamais `exit 1`) quand `type` est absent ou hors enum. `build-feature-index.sh` expose `type` (défaut `feature`, pas de bump `schema_version`). Nouvelle commande `aic migrate okf-type [--apply] [--type=…]` (backfill idempotent, bash pur). `FEATURE_TEMPLATE` : `type: feature` par défaut.

### Migration
- Migration de l'overlay vers le registre de scopes : deux temps (`copier update` apporte le skill + le contrat ; `aic-onboard` migre l'overlay project-owned). Opt-in, non bloquant, non destructif, idempotent. Voir `docs/upgrading.md` → « Overlay projet : registre de scopes ».
- Profil strict OKF : après `copier update`, si `check-features` signale des `type` manquants → `bash .ai/scripts/aic.sh migrate okf-type --apply`, puis commit. Rollback = `git revert` (fiches project-owned).

## [0.13.0] — 2026-06-01

> Release de l'initiative `ai-context-stability-migration` (contrat read-only des
> checks, index contract v2, fallback parser sans yq). **Breaking** d'usage sur la
> surface CLI publique — voir ci-dessous et `MIGRATION.md`.

- Breaking : la surface CLI publique devient `aic.sh frame/status/diagnose/document-feature/review/ship`, alignée avec les skills `aic-*`. Les anciens verbes publics de cadrage, brief, document delta et ship report sont supprimés au lieu d'être conservés en aliases.
- `aic-document-feature` est intégré explicitement à la surface utilisateur canonique, côté Claude et Codex.
- Installation Codex : quand `codex` est sélectionné dans `agents`, le template génère désormais `.agents/skills/` avec les wrappers `aic-*`, `aic-feature-*` et `aic-quality-gate`. Les wrappers restent minces et délèguent aux workflows canoniques `.ai/workflows/*`.
- Contrat read-only des checks : `check-features.sh --no-write` valide le mesh sans écrire l'index ; `doctor`, `quality-gate`, la CI, `check-feature-freshness`, `check-feature-coverage`, `review-delta`, `pr-report` et les rapports product consomment un index temporaire ou un cache existant avec warning.
- `build-feature-index.sh --write` ne réécrit plus `.ai/.feature-index.json` quand le contrat JSON est inchangé hors `generated_at`; l'ordre des features est stable et le cas "aucune feature" produit un index vide valide.
- Tests ajoutés : `test-build-feature-index-contract.sh`, `test-read-only-checks-contract.sh`, `test-product-reports-read-only.sh`.
- Fallback sans `yq` : `build-feature-index.sh` extrait maintenant `product.portfolio.{appetite,confidence,expected_impact,urgency,strategic_fit}` pour préserver le scoring product sur environnements minimalistes.
- Remédiation audit prod : suite de tests fiabilisée (clones `cp -R .` → `rsync --exclude=.git`, fixture `review-delta` rebasée pour éviter une explosion O(fichiers)), couverture CI complète via boucle `for t in tests/unit/*.sh` (5 tests auparavant orphelins), `_min_copier_version: "9.0.0"`, ownership `copier.yml` restreint au scope `core`, récupération des locks d'index orphelins dans `with_index_lock`, et alignement du smoke `[9/28]` sur l'écriture idempotente de l'index.

### Migration
- Dans les CI, hooks custom et scripts de diagnostic existants, remplacer `check-features.sh` par `check-features.sh --no-write` si l'étape ne doit pas modifier le workspace.
- Garder `build-feature-index.sh --write` pour les rebuilds explicites du cache, notamment avant des hooks qui lisent `.ai/.feature-index.json`.

## v0.12.0 — 2026-05-04 « Agent UX, product traceability & robust updates »

### Nouveau
- `ai-context.sh status` — état terminal actionnable : features, delta, hooks, checks principaux, budget reminder et prochaine action minimale.
- `ai-context.sh brief <path>` — contexte juste-à-temps pour Codex/agents non-hookés avant édition d'un fichier ; route vers `features-for-path --with-docs`.
- `ai-context.sh mission "<objectif>"`, `document-delta`, `repair`, `ship-report` — UX CLI intentionnelle pour cadrer une tâche, relier delta↔docs, réparer le mesh sans action destructive et préparer la sortie commit/PR. Compatible Claude/Codex sans gonfler le reminder.
- `.ai/agent/response-style.md` — contrat de clôture de tâche compact/structuré : résultat observable, vérifications, risques, recommandation assumée et prochaine action utile. Chargé via Pack A, pas injecté dans le reminder.
- Product Traceability Loop V1 — nouveau scope `product`, règle `.ai/rules/product.md`, champs frontmatter optionnels `product.*` et `external_refs`, scripts read-only `check-product-links.sh`, `product-status.sh`, `product-portfolio.sh`, `product-review.sh` et routes `ai-context.sh product-*`. Objectif : relier initiatives produit, artefacts externes, features dev, evidence et décision suivante sans roadmap parallèle.
- `ai-context.sh first-run` — parcours guidé de 10 minutes après scaffold : activer hooks, vérifier le projet, cadrer la première tâche, créer la première fiche feature et préparer le premier commit.
- `ai-context.sh repair-copier-metadata` — recrée en dry-run les métadonnées `.copier-answers.yml` quand un projet déjà scaffoldé les a perdues ou n'a jamais versionné `_src_path` / `_commit`. Écriture uniquement avec `--apply`.
- `ai-context.sh template-diff` — rend le template dans `/tmp` et liste les fichiers à ajouter/modifier sans toucher au worktree courant. Utile pour prévisualiser une update quand le projet est dirty ou fortement customisé.
- `features-for-path.sh --with-docs` — mode CLI utilisable par Codex pour afficher les fiches feature concernées par un path et leurs dépendances `depends_on`, avec budget borné.
- Skills intentionnels Claude : `/aic-frame`, `/aic-status`, `/aic-review`, `/aic-ship`. La surface recommandée devient orientée intention (`frame/status/diagnose/review/ship`) au lieu d'exposer les primitives procédurales `aic-feature-*`.
- Les primitives procédurales sont retirées de `.claude/skills/` et déplacées vers `.ai/workflows/` pour rester utilisables par Claude et Codex sans apparaître comme commandes utilisateur.
- `.ai/scripts/review-delta.sh` — rapport review-friendly du delta courant (`--staged` ou `--base/--head`) listant fichiers, features directes, features liées via `touches_shared`, risques détectés et checks recommandés. Exposé via `ai-context.sh review`.
- `touches_shared` — champ frontmatter optionnel pour les surfaces transverses utiles au reporting/review mais non bloquantes pour la fraîcheur documentaire staged. `build-feature-index.sh`, `_lib.sh`, `check-features.sh` et `pr-report.sh` le consomment.
- **Cursor MDC scopés** — `.cursor/rules/back.mdc` et `.cursor/rules/front.mdc` générés conditionnellement (si `cursor` dans agents + scope présent) avec frontmatter `globs:` Cursor (auto-attached aux fichiers du scope). Première parité partielle Claude/Cursor sur l'injection contextuelle : Cursor charge automatiquement les règles du scope quand un fichier matché est édité. Globs par défaut couvrent les conventions courantes ; à customiser selon la structure du projet.
- **AGENTS.md.jinja enrichi** — sections « Setup Commands », « Testing Instructions », « Code Style », « PR Instructions », « Resume cross-session » ajoutées (conformes à la spec [agents.md](https://agents.md)). Les agents non-Claude (Codex, etc.) ont désormais les commandes utiles dès le shim, sans devoir naviguer dans le README.
- `progress.history_max_entries` dans `.ai/config.yml` — profondeur configurable du FIFO `.progress-history.jsonl` (défaut 50). `auto-progress.sh` lit la valeur via `read_config`. Permet aux projets actifs (>50 transitions/semaine) de remonter plus loin via `/aic undo`.
- `doctor.sh` étendu — ajoute checks `python3` (warn, pour `tiktoken` exact dans `measure-context-size`), `.claude/settings.json` hooks attendus (UserPromptSubmit/PreToolUse/PostToolUse/Stop), exécutabilité `.githooks/*`. Diagnostic plus complet sur l'écosystème Claude.
- `.ai/scripts/aic-undo.sh` — script headless qui annule la dernière transition auto-progressée listée dans `.ai/.progress-history.jsonl` : restaure phase + status du frontmatter, append au worklog, rebuild l'index. Mode `--dry-run` par défaut, `--apply` explicite. Le skill conversationnel `/aic undo` peut s'appuyer dessus pour la partie execution. Référé dans le README §Scripts runtime.
- CI : workflow PR principal `.github/workflows/ai-context-check.yml` étend désormais sa matrix à `windows-latest` (best-effort, `continue-on-error: true`). `shellcheck` reste sur Linux/macOS uniquement. Couverture Windows désormais informative sur le runtime utilisateur quotidien (check-shims, check-features, etc.).
- `.ai/.feature-index.json` expose désormais `schema_version: "1"` et `project_id` (rendu depuis `project_name` Copier, fallback `basename(repo_root)`). Premier pas vers la fédération cross-project — le format est maintenant un contrat versionné.
- Helper `read_config` dans `_lib.sh` — lit `.ai/config.yml` via `yq` v4, fallback silencieux si absent. Réutilisable par tous les scripts.
- Helper `is_path_within_repo` dans `_lib.sh` — rejette les motifs `touches:` absolus (`/etc/...`, `C:\...`, UNC `\\srv`, backslash `\Windows`), à traversée (`..`, `foo/../bar`), expansion home (`~/...`), et caractères de contrôle (newline/tab/NUL).
- Tests unitaires `tests/unit/test-path-matches-touch.sh` — couvre 18 cas (exact, dossier, glob `*` / `?` / `[]` / `**`, edge cases, Windows-friendly). Lancé en tête de smoke-test.
- Tests unitaires `tests/unit/test-is-path-within-repo.sh` — 30 cas couvrant safe (relatifs, globs, espaces) et unsafe (absolus Unix, Windows lettre+drive, UNC, backslash, traversées, home, NUL/tab/newline, vide). Lancé en tête de smoke-test.
- CI : `windows-latest` ajouté à la matrix `template-smoke-test.yml` en `continue-on-error: true` (best-effort, non-bloquant). `shellcheck` reste Linux/macOS.
- Smoke-test : étape bonus « big-mesh » qui génère 60 features (30 back + 30 front avec dépendances), vérifie que `pre-turn-reminder` reste sous 30 000 chars, que `AI_CONTEXT_FOCUS=back` réduit la taille, et que `context.max_tokens_warn` déclenche bien le warning stderr.
- Scripts source-only de dogfooding : `.ai/scripts/dogfood-update.sh` rend le template dans `/tmp` puis synchronise le runtime du repo source ; `.ai/scripts/check-dogfood-drift.sh` compare le runtime dogfoodé à un rendu Copier minimal en ignorant les fichiers mainteneur source-only.

### Sécurité
- `check-features.sh` rejette désormais les motifs `touches:` hors repo (chemin absolu Unix/Windows, UNC, backslash, traversée `..`, expansion `~`, caractères de contrôle). Bloquant en CI. Voir [SECURITY.md — Trust model du feature mesh](SECURITY.md).
- `check-features.sh` impose désormais une regex stricte sur `id` et `scope` (`^[a-z0-9][a-z0-9_-]*$`). Ferme un vecteur de path traversal latent : ces deux champs servent à construire les chemins worklog (`auto-worklog-flush.sh`) et les clés `scope/id` (`auto-progress.sh`). Un `id="../foo"` ou `scope` avec espace/slash sont désormais rejetés au check.
- `check-features.sh` applique aussi `is_path_within_repo` aux entrées `depends_on:` (auparavant seulement aux `touches:`). Une référence `depends_on: ../../other-project/scope/id` ne traverse plus silencieusement.

### Changé
- `features-for-path.sh` injecte désormais, côté hook Claude `PreToolUse Write/Edit`, un contexte juste-à-temps borné : fiches directes touchées + `depends_on` récursifs. Le `pre-turn-reminder` reste inchangé, donc le coût par prompt ne gonfle pas.
- UX skills : `aic-feature-*`, `aic-quality-gate` et `aic-project-guardrails` ne sont plus exposés comme skills Claude. Les procédures équivalentes vivent sous `.ai/workflows/`, partagées par Claude et Codex. `/aic-frame` devient le point d'entrée de cadrage avec plan, spécificités métier/technique et validation.
- **Promesse multi-agents tempérée** — README + `template/AGENTS.md.jinja` exposent maintenant un tableau « Capacités runtime par agent » : seul Claude bénéficie de l'injection de contexte par tour (UserPromptSubmit, PreToolUse, PostToolUse, Stop). Les autres agents ont les shims statiques + git hooks. Pas de changement de code, juste alignement de la communication.
- **`adoption_mode=strict` réellement renforcé** — la CI ajoute `doctor.sh --strict` + `check-feature-coverage.sh --strict` quand le mode est `strict`. Plus seulement `.github/workflows/` forcé. Label `copier.yml` corrigé.
- **Label `adoption_mode=strict` réaligné** — le choix `copier.yml` annonce maintenant explicitement les deux gates CI activés (`doctor --strict` + `coverage --strict`) et le `_message_after_copy` avertit que sur projet jeune la CI sera rouge tant que la couverture n'est pas raisonnable. Plus de drift entre label et réalité post-renforcement.
- **`progress.auto_transitions.spec_to_implement` consommé** — `auto-progress.sh` lit maintenant cette clé de `.ai/config.yml`. Repasser à `false` désactive l'auto-progression (vraie option d'opt-out, plus un placeholder).
- **`context.max_tokens_warn` consommé** — `pre-turn-reminder.sh` émet un warning stderr quand le contexte injecté dépasse le seuil configuré. `0` = désactivé.
- `docs/getting-started.md` documente explicitement les plateformes : Linux/macOS ✅, WSL2 ✅, Git Bash ⚠️ best-effort, PowerShell pur ❌.
- `SECURITY.md` ajoute une section « Trust model du feature mesh » : ce qui est validé, ce qui ne l'est pas, recommandations PR.
- **Placeholders `auto_transitions.implement_to_review` / `review_to_done` retirés** — ces clés étaient scaffoldées dans `.ai/config.yml` sans être lues par aucun script (« informatif ») et créaient de la confusion utilisateur (« j'active à `true`, rien ne se passe »). Décision d'honnêteté : on retire jusqu'à ce qu'une vraie heuristique soit définie. Les transitions `implement → review` et `review → done` restent **manuelles** via `/aic` (Claude) ou édition directe du frontmatter. Pas un breaking change : ces clés n'avaient aucun effet runtime.
- `doctor.sh --strict` ne considère plus `.githooks/README.md` comme un hook à rendre exécutable. Le contrôle cible uniquement `commit-msg`, `pre-commit` et `post-checkout`.
- `check-feature-freshness.sh --staged` valide maintenant la fraîcheur documentaire par feature candidate, pas seulement par fichier touché. Un fichier couvert par plusieurs features exige donc une fiche/worklog staged pour chacune.
- `dogfood-update.sh --apply` synchronise le runtime avec suppression des fichiers obsolètes (`rsync --delete`) tout en préservant les caches et scripts source-only explicitement exclus.
- `pr-report.sh` distingue maintenant les features impactées directement (`touches`) et les features liées (`touches_shared`) ; les fichiers uniquement shared ne sont plus signalés comme non couverts.
- Les fiches dogfoodées trop larges migrent leurs surfaces globales (`tests/smoke-test.sh`, CHANGELOG/PROJECT_STATE, etc.) vers `touches_shared` quand elles ne possèdent pas directement le fichier.

### Tests
- Smoke-test étendu — assertions `repair-copier-metadata` et `template-diff` : la réparation propose `_src_path`, et la preview externe annonce explicitement qu'elle ne modifie pas le repo courant.
- Smoke-test étendu — assertion Cursor MDC scopés après `[28b/28]` : avec `agents=cursor + fullstack` les fichiers `.cursor/rules/{protocol-reminder,back,front}.mdc` sont rendus avec frontmatter `globs:` ; avec `cursor` absent, pas de `.cursor/` ; avec `cursor + minimal` (sans back/front), seul `protocol-reminder.mdc` reste.
- Smoke-test étendu — étape `[28b/28]` couvre 4 combinaisons additionnelles `scope_profile × tech_profile` (minimal × generic, backend × dotnet-clean-cqrs, minimal × react-next, custom × generic). Couverture matrice porte à 8/16 (les 4 autres via `fullstack × *`). Vérifie : présence/absence des règles tech-* selon profil, présence/absence des scopes métier selon scope_profile, sanity check-shims.
- Smoke-test étendu — étape `[28c/28]` couvre `copier update v0.11.0 → HEAD` : un fichier user (`MY_CUSTOM.md`) hors périmètre template doit être préservé après update, check-shims doit passer, et le nouveau script `aic-undo.sh` (introduit en R2) doit être propagé. Le canal de diffusion des fixes vers les projets existants est désormais testé en CI.
- Smoke-test étendu — étape `[9b/28]` lance 5 `build-feature-index.sh --write` en parallèle et vérifie que le JSON reste valide + qu'aucun tmp orphelin (`*.feature-index.json.XXXXXX`) ne traîne. Le lock atomique `mkdir`-based dans `_lib.sh:with_index_lock` est désormais régressable.
- Smoke-test étendu — assertion E2E `/aic undo` après l'étape `[18/28]` : invoque `aic-undo.sh --apply`, vérifie que la phase est restaurée à `spec`, que le worklog reçoit une ligne `## <ts> — /aic undo`, que `.progress-history.jsonl` est vidé, et que `--apply` sur history vide est idempotent (« Rien à annuler »). La logique du skill `/aic undo` est désormais testable headless.
- Tests unitaires ajoutés — `test-check-feature-freshness.sh` couvre la régression multi-feature du staged freshness ; `test-dogfood-drift-extra.sh` couvre les fichiers runtime destination-only. Tous deux sont lancés en tête de `tests/smoke-test.sh`.
- Test unitaire ajouté — `test-review-delta-shared.sh` vérifie que `touches_shared` reste visible dans `review-delta.sh` sans bloquer `check-feature-freshness --staged`.

### Migration
- Pour suivre le HEAD GitHub plutôt que le dernier tag publié, utiliser `copier update --vcs-ref=HEAD`. Les docs d'upgrade et `README_AI_CONTEXT.md` le documentent explicitement pour éviter les downgrades involontaires quand `main` est en avance sur le tag.
- Si `.copier-answers.yml` manque dans un projet déjà scaffoldé, lancer `bash .ai/scripts/ai-context.sh repair-copier-metadata` puis relire la proposition avant `--apply`.
- Pour évaluer une update sur worktree sale, lancer `bash .ai/scripts/ai-context.sh template-diff`; le rendu temporaire est hors repo et peut être inspecté avec `diff -u`.
- `copier update` propage les changements automatiquement. Les consommateurs qui parsent `feature-index.json` peuvent désormais s'appuyer sur `schema_version` pour détecter les ruptures futures.
- Si tu choisis `adoption_mode=strict` sur un projet existant, la CI peut commencer à échouer (doctor strict + coverage strict). Lance localement avant le commit : `bash .ai/scripts/doctor.sh --strict && bash .ai/scripts/check-feature-coverage.sh --strict`.
- `progress.auto_transitions.implement_to_review` / `review_to_done` retirés du `.ai/config.yml` scaffoldé. Les projets existants qui les avaient peuvent les laisser (ils n'ont jamais eu d'effet) ou les supprimer pour faire propre.
- `progress.history_max_entries` ajouté à `.ai/config.yml` (défaut 50) — un projet existant sans cette clé garde le comportement actuel (50). Pour un mesh très actif, monter à 100-200 prolonge la profondeur d'undo.

## v0.11.0 — 2026-04-28 « Project guardrails & doctor hotfix »

### Nouveau
- Skill `/aic-project-guardrails` (scope `workflow`) — dialogue conversationnel pour cadrer les **non-goals** (hors-scope explicite, ≥1 item obligatoire) et le **glossaire métier** (optionnel) du projet, produit `.ai/guardrails.md`. Idempotent (ré-invocation = mode update). Catalogue passe de 8 à 9 skills, surface utilisateur de 4 à 5 (`/aic`, `/aic-feature-resume`, `/aic-feature-audit`, `/aic-quality-gate`, `/aic-project-guardrails`).
- `.ai/guardrails.md` ajouté à la séquence Pack A dans `template/.ai/index.md.jinja` (chargé en début de session si présent — coût tokens nul à chaque tour, pas d'injection runtime).
- `_message_after_copy` (copier.yml) et `template/README_AI_CONTEXT.md.jinja` mentionnent `/aic-project-guardrails` comme étape recommandée post-scaffold (avant le 1er `feat:`).
- Smoke-test étendu (assertion 9 skills présents + référence `guardrails.md` dans `.ai/index.md`).

### Corrigé
- `doctor.sh` (template) testait la présence des scripts critiques avec `[[ -x ]]` (executable bit) au lieu de `[[ -f ]]` (fichier existant). Faux positifs « missing » sur `check-shims.sh` et `measure-context-size.sh` quand Copier ne préservait pas le bit +x au rendu. Cosmétique (doctor exit 0 par défaut), mais trompeur. Bug pré-existant depuis v0.9, détecté à la sanity check post-tag v0.10.0.

### Pourquoi (project-guardrails)
Les rules (`<scope>.md`) cadrent le « comment travailler » et le feature mesh cadre le « quoi est en cours ». Aucun mécanisme ne capturait *ce que l'agent ne doit PAS proposer* (non-goals) ni le vocabulaire métier précis. Sans non-goals explicites, un agent peut dériver vers des features non souhaitées. Vision/utilisateurs cibles restent intentionnellement délégués au README pour éviter la duplication — ce skill se concentre sur ce qui n'est *jamais* écrit ailleurs.

### Migration
- Aucun breaking depuis v0.10.0. `copier update` ajoute le nouveau skill et rappelle son existence dans le post-copy. Tu peux invoquer `/aic-project-guardrails` quand tu veux pour matérialiser `.ai/guardrails.md` ; sans cette étape, le comportement reste identique à v0.10.0.

## v0.10.0 — 2026-04-28 « Runtime config, diagnostics & agent-agnostic tooling »

> Cette version regroupe les changements accumulés depuis v0.9.0. Voir [`RELEASE.md`](RELEASE.md) pour la checklist appliquée et [`CONTRIBUTING.md`](CONTRIBUTING.md) pour la règle anti-doc-drift désormais documentée.

### Nouveau
- `.ai/config.yml` scaffoldé avec sections `coverage` / `progress` / `context` / `docs_root`. Tableau « Champs actifs » dans `README.md` : `coverage.*` et `progress.stale_after_days` actifs ; `progress.auto_transitions.*`, `context.*` et `docs_root` placeholders pour v0.10+.
- `.ai/schema/feature.schema.json` — contrat frontmatter (status, progress.phase, etc.). Source de vérité des enums lus par `_lib.sh` (`STATUS_ENUM`, `PHASE_ENUM`).
- `.ai/scripts/doctor.sh` — diagnostic non destructif (dépendances, hooks, index, checks). Mode `--strict` opt-in ; en mode par défaut reste informatif (exit 0) pour ne pas casser le smoke-test sur scaffold sain.
- `.ai/scripts/audit-features.sh` — audit agent-agnostique (`discover <scope>`, dry-run par défaut, `--apply` explicite pour créer des fiches draft minimales). MVP : `discover` only, pas de `refresh` ni de mode interactif (voir feature `workflow/feature-audit`). `--help` annonce explicitement le périmètre MVP.
- `.ai/scripts/migrate-features.sh` — normalise les frontmatters legacy (`schema_version`, `status` legacy → enum, `depends_on`/`touches` manquants). Dry-run par défaut, `--apply` explicite.
- `.ai/scripts/pr-report.sh` — rapport d'impact feature depuis un diff git. Options : `--base`, `--head`, `--format=markdown|json`, `--include-docs`. Exclusions par défaut (README/CHANGELOG/.github/.ai/docs/.docs/features) ; warnings enrichis (feature `done` modifiée, fichier multi-couvert, `depends_on` deprecated/archived, feature stale >14j) ; fallback shallow-clone explicite quand `--base` n'est pas atteignable.
- `.ai/scripts/ai-context.sh` — wrapper CLI MVP routant `doctor` / `resume` / `audit` / `migrate` / `pr-report` / `measure` / `check` / `coverage` / `shims` / `index` / `reminder` vers les scripts dédiés. Aucune logique propre, surface stable.
- `_lib.sh` : ajout `is_valid_phase()` (le commentaire d'en-tête le promettait déjà). Suppression du doublon local dans `check-features.sh`.
- `adoption_mode` dans `copier.yml` (`lite`, `standard`, `strict`) pour moduler l'enforcement (hooks/CI) à l'installation. Voir le tableau « Modes d'adoption » dans `README.md` pour la portée exacte de chaque mode.
- Documentation OSS racine du repo source : `CONTRIBUTING.md` (installation dev, sync template/runtime, anti-doc-drift), `SECURITY.md` (politique de logging des hooks, signalement), `RELEASE.md` (checklist tag).

### Changé
- `check-features.sh` exige maintenant `depends_on` et `touches` comme clés frontmatter obligatoires (`[]` accepté, omission rejetée). Aligne la validation Bash sur `feature.schema.json` (Option A). Concerne le template **et** le runtime dogfoodé.
- `audit-features.sh` : refactor des boucles `for f in ${arr[@]+"${arr[@]}"}` (sujettes à word-splitting) vers `if [[ ${#arr[@]} -gt 0 ]]; then for f in "${arr[@]}"; fi`. Préserve la sécurité `set -u` Bash 3.2 ET la fidélité aux chemins avec espaces.
- Workflow `.github/workflows/template-smoke-test.yml` étendu en matrix `ubuntu-latest` + `macos-latest` (au lieu d'Ubuntu seul). Install copier cross-platform (PEP 668 / `--break-system-packages` côté macOS). Déclencheurs étendus à `.ai/scripts/**` et `.ai/schema/**` pour rattraper les changements dogfoodés. Ajout `workflow_dispatch`.
- Centralisation du matching `touches:` dans `_lib.sh` (`path_matches_touch` + `features_matching_path`) et adoption par `features-for-path`, `auto-worklog-log`, `check-feature-coverage` et le hook git `pre-commit`.
- Les scripts runtime utilisent maintenant `AI_CONTEXT_DOCS_ROOT` / `AI_CONTEXT_FEATURES_DIR` depuis `_lib.sh`, ce qui rend `docs_root=docs` fonctionnel au-delà des fichiers scaffoldés.
- Ajout de `tech_profile` pour générer des règles stack optionnelles : `.NET Clean Architecture + CQRS`, `React/Next`, ou contrat fullstack `.NET + React`.
- Documentation synchronisée : nombre d'étapes du smoke-test, défaut `enable_ci_guard`, description des hooks runtime.
- Synchronisation docs/runtime sur l'UX skills et l'auto-progression : distinction commandes exposées (`/aic`, `/aic undo`, `/aic-feature-resume`, `/aic-feature-audit`, `/aic-quality-gate`) vs skills internes (`new/update/handoff/done`) ; clarification explicite que l'auto-progression couvre uniquement `spec → implement`.
- Correction du chemin d'index dans le workflow `aic-feature-audit` (`.ai/.feature-index.json`).
- `PROJECT_STATE.md` mis à jour : roadmap restructurée (P1 stabilisation v0.10, P2 confort UX, P3 extensions) ; ajout d'une règle anti-doc-drift listant les fichiers à revoir à chaque changement.
- Smoke-test ajusté pour vérifier les 8 skills présents (`aic`, `aic-feature-audit` inclus).
- `resume-features.sh` lit désormais `progress.stale_after_days` depuis `.ai/config.yml` (fallback 14 jours) pour calculer le bucket STALE.
- `check-feature-coverage.sh` lit `coverage.roots` / `coverage.extensions` / `coverage.exclude_dirs` depuis `.ai/config.yml` (fallback defaults intégrés).
- Workflows CI durcis : pin `yq` en `v4.44.3` (plus de `latest`) et ajout `shellcheck .ai/scripts/*.sh`.
- Workflow check étendu en matrix `ubuntu-latest` + `macos-latest` avec install cross-platform de `jq`/`shellcheck` et `yq` pin.
- Compatibilité Bash 3.2 améliorée dans les scripts générés : `pr-report.sh` n'utilise plus `mapfile` ni `declare -A`, et `check-feature-coverage.sh` charge la config sans `mapfile`.
- CI : `shellcheck` passe en mode `-S error` dans les workflows check/smoke pour échouer sur les erreurs critiques sans bloquer sur warnings non bloquants.
- Modes d'adoption clarifiés : la documentation `README.md` + `_message_after_copy` du `copier.yml` distinguent maintenant explicitement les git hooks (`.githooks/`) des hooks Claude (`.claude/settings.json`). En `lite + claude`, les hooks Claude restent disponibles mais optionnels (à activer dans `/hooks`) ; le message ne suggère plus que `/hooks` est inutile.

### Corrigé
- Fix Copier : `_message_after_copy` dans `copier.yml` n'utilise plus de blocs Jinja `{% if %}` non quotés (YAML invalide), remplacés par des expressions inline compatibles parsing.
- Fix Copier/CI template : échappement des expressions GitHub Actions `${{ matrix.os }}` / `${{ runner.os }}` dans `template/.github/workflows/ai-context-check.yml.jinja` pour éviter l'erreur Jinja `matrix is undefined` au rendu.
- Fix Copier/template scripts : échappement des expansions Bash `${#...}` dans les templates `.jinja` pour éviter l'erreur Jinja `Missing end of comment tag` pendant `copier copy`.
- Doctor : l'absence de repo git dans un scaffold frais devient un warning non bloquant (au lieu d'une erreur), avec skip explicite du check hooks hors repo.
- Audit discover : prise en compte des fichiers non trackés (`git ls-files --cached --others --exclude-standard`) et suppression de dépendances Bash 4 (`mapfile`, `declare -A`) dans le template script.

### Tests
- Smoke-test étendu à **28 étapes** avec assertions ciblées sur le matching exact/dossier/glob/`/**`, `docs_root=docs` et les rendus conditionnels `tech_profile`.
- `tests/smoke-test.sh` valide désormais un override simple de `coverage.*` via `.ai/config.yml` (sans casser le comportement par défaut).
- `tests/smoke-test.sh` valide aussi l'override `progress.stale_after_days` via `.ai/config.yml` dans `resume-features.sh`.
- `tests/smoke-test.sh` vérifie que `pr-report.sh` généré reste compatible Bash 3.2 (absence de `mapfile`).
- `tests/smoke-test.sh` valide les rendus `adoption_mode=lite` (`.githooks` et `.github/workflows/` exclus) et `adoption_mode=strict + enable_ci_guard=false` (workflows conservés).
- `tests/smoke-test.sh` valide que `check-features.sh` exige `depends_on` et `touches` (acceptent `[]`).
- `tests/smoke-test.sh` valide `audit-features.sh --help` (annonce périmètre MVP) et la robustesse aux chemins avec espaces (`src/with space/file.ts` orphelin détecté).
- `tests/smoke-test.sh` valide `pr-report.sh --format=json` (sortie JSON parseable via `jq`), exclusion par défaut d'un README modifié, et `--include-docs` qui lève l'exclusion.
- `tests/smoke-test.sh` valide le wrapper `ai-context.sh` (`--help` liste les commandes, alias `shims` route vers `check-shims`, commande inconnue rejetée).

### Migration
- Aucun breaking depuis v0.9.0. `copier update` re-applique les nouveaux fichiers (`.ai/config.yml`, `.ai/schema/feature.schema.json`, `.ai/scripts/{doctor,audit-features,migrate-features,pr-report}.sh`) sans toucher au mesh feature existant.
- Si tu utilisais `AI_CONTEXT_DOCS_ROOT` à la main, rien à changer : ce comportement est conservé. Le champ `docs_root` dans `.ai/config.yml` est aujourd'hui informatif (placeholder), pas une nouvelle source de vérité.

## v0.9.0 — 2026-04-24

Graph-aware injection : scale le reminder aux mesh >100 features.

### Nouveau
- **`AI_CONTEXT_FOCUS=<scope>`** (et `--focus=<scope>` en CLI) : `pre-turn-reminder.sh` restreint l'inventaire au scope demandé + ses voisins **1-hop** (features dont on dépend ou qui dépendent de nous, tous scopes confondus). Les reverse deps sont pareillement filtrées (sources dans le focus uniquement). Gain typique : ~5× moins de tokens sur mesh matures.
- **Header focus explicite** : `── Features actives (focus=back, +3 voisin(s) 1-hop) ──` pour rendre le filtre visible et éviter la surprise.
- **Fallback safe** : focus sur un scope inexistant → warn stderr + fallback inventaire complet (jamais de vide silencieux).

### Changé
- Parsing d'arguments refactoré : `pre-turn-reminder.sh` accepte désormais `--format=X` et `--focus=Y` dans n'importe quel ordre.
- `tests/smoke-test.sh` utilise `copier copy --vcs-ref=HEAD` pour tester le working tree plutôt que le dernier tag (bug rencontré : copier utilisait v0.8.0 au lieu de HEAD).

### Tests
- Smoke-test étendu à **24 étapes** : #23 vérifie focus=back inclut back/api + front/ui (1-hop) mais exclut architecture/unrelated ; env var équivalente ; fallback sur focus inconnu.

### Docs
- README : colonne env var + variable `AI_CONTEXT_FOCUS`.
- MIGRATION : mention comme optimisation pour projets à grand mesh.
- copier.yml `_message_after_copy` : `AI_CONTEXT_FOCUS` ajouté à la liste des env vars utiles.

### Philosophie
v0.6 a réduit le bruit par filtrage status. v0.9 réduit le bruit par **topologie** : un scope ne « voit » que ses voisins immédiats, pas le mesh entier. Le graphe de dépendances devient un outil de sélection, pas juste de validation.

### Breaking
- Aucun. Sans `AI_CONTEXT_FOCUS`, le comportement est strictement identique à v0.8.

## v0.8.0 — 2026-04-23

Cohérence du mesh + i18n reminder.

### Nouveau
- **`check-features.sh` — warn deprecated/archived** : si une feature `active` ou `draft` a une entrée `depends_on` pointant vers une feature `deprecated` ou `archived`, un warn explicite s'affiche (non bloquant). Signal de dette : migrer la dépendance avant que la cible soit archivée.
- **Reminder i18n** : `.ai/reminder.md` est généré en anglais si `commit_language=en`, en français sinon. La version EN miroir la version FR, avec "Conventional Commits (en)" dans la règle DoD.

### Tests
- Smoke-test étendu à **23 étapes** :
  - #21 warn deprecated visible quand une feature active dépend d'une deprecated.
  - #22 `copier copy --data commit_language=en` produit un reminder 100% anglais (pas de résidu FR).

### Philosophie
v0.8 ferme deux angles morts : (a) la dette silencieuse cross-status (une feature active qui s'appuie sur du deprecated sans alerte), (b) la règle projet "Conventional Commits en anglais" qui restait contredite par un reminder francophone. Les deux changements sont additifs — pas de breaking.

### Breaking
- Aucun. Les projets existants en FR gardent leur reminder. Les projets en EN bénéficient de la localisation sans action.

## v0.7.2 — 2026-04-23

Durcissement post-audit : corruption silencieuse fermée, docs synchronisées.

### Corrigé
- **`auto-worklog-log.sh`** — JSON échappé via `jq -nc --arg` au lieu de `printf`. Les chemins contenant quotes/backslashes/unicode ne corrompent plus le JSONL (bug silencieux : le flush ignorait les lignes mal formées sans erreur).

### Nouveau
- **Détection de cycles `depends_on`** — `check-features.sh` exécute un DFS en jq sur l'index après rebuild. Un cycle `A → B → A` fait échouer le check avec message explicite (`cycle détecté : scope/A → scope/B → scope/A`). Évitait auparavant un crash silencieux de `group_by` au rebuild suivant.

### Tests
- Smoke-test étendu à **21 étapes** :
  - #19 `check-feature-coverage.sh --strict` exit 1 quand orphelins présents.
  - #20 cycle `A→B→A` dans `depends_on` rejeté par `check-features.sh`.
  - #21 touches morte (renumérotée).

### Docs
- `PROJECT_STATE.md` rafraîchi (était stale à v0.3.0) — pointe vers CHANGELOG pour l'historique, conserve uniquement l'état courant + roadmap.
- `MIGRATION.md` — section **4.4** ajoutée pour les hooks Claude `PostToolUse` + `Stop` (auto-worklog v0.7.1). Rappel : les deux doivent être activés ensemble.

### Breaking
- Aucun. Les projets avec des cycles latents dans `depends_on` verront `check-features.sh` échouer — c'est le comportement souhaité, résoudre en cassant le cycle.

## v0.7.1 — 2026-04-23

Auto-logging des éditions → worklog sans intervention manuelle.

### Nouveau
- `auto-worklog-log.sh` (hook **PostToolUse** Write/Edit/MultiEdit) — résout le fichier édité vers les features impactées via l'index, append une ligne JSONL à `.ai/.session-edits.log`. Silencieux, best-effort, ne bloque jamais un Write.
- `auto-worklog-flush.sh` (hook **Stop**, fin de tour Claude) — groupe le log par feature, append **une** entrée par feature affectée au worklog (`Fichiers modifiés : ...`), bumpe `progress.updated` à la date du jour, rebuild l'index, clear le log.
- `.ai/.session-edits.log` ajouté au `.gitignore` du template.

### Changé
- `/aic-feature-update` redéfini : ne sert plus qu'aux **changements d'intent** (phase, blockers, resume_hint, step). Le log routinier "j'ai modifié tel fichier" est désormais automatique.
- README + skill description mis à jour pour refléter la séparation auto / intent.

### Tests
- Smoke-test étendu à 19 étapes : +assertion auto-worklog (log PostToolUse, flush Stop, worklog créé, `updated` bumpé à today).

### Philosophie
v0.7 a ouvert la continuité entre sessions via `progress:` manuel. **v0.7.1 retire la friction** : le log factuel est invisible, l'utilisateur n'intervient que pour les décisions qui requièrent du jugement. Les hooks deviennent le système nerveux autonome du feature mesh.

### Breaking
- Aucun. Le nouveau hook Stop est no-op si le log est vide. Les features sans bloc `progress:` ne sont pas touchées.

## v0.7.0 — 2026-04-23

Reprise entre sessions + skills `/aic-*` pour encadrer les travaux récurrents.

### Nouveau
- **Frontmatter feature étendu** avec bloc `progress:` optionnel (`phase`, `step`, `blockers`, `resume_hint`, `updated`). Permet de sauvegarder l'état d'avancement et reprendre sans ambiguïté entre sessions.
- **Worklog append-only par feature** : `<id>.worklog.md` à côté de la feature, créé par `/aic-feature-new`, enrichi à chaque `/aic-feature-update`. Exclu de l'index et de check-features.
- `.ai/scripts/resume-features.sh` — scanne l'index, groupe en 4 buckets : **EN COURS** (phase définie, pas de blocker), **BLOQUÉES** (blockers non vide), **STALE** (>14j sans update), **À FAIRE** (progress non initialisé). Mode `--format=json` pour automation, `--scope=<X>` pour filtrage.
- **6 skills `/aic-*`** dans `template/.claude/skills/` — structure `SKILL.md` (frontmatter minimal) + `workflow.md` (phases détaillées) inspirée des skills bobv3 :
  - `/aic-feature-new` — crée fiche + worklog init, valide avant de rendre la main
  - `/aic-feature-resume` — charge le contexte d'une feature interrompue, demande confirmation
  - `/aic-feature-update` — sauve `progress.*` + append worklog (append-only, jamais destructif)
  - `/aic-feature-handoff` — bloc HANDOFF inter-scope formalisé (what delivered / next needs / blockers / status)
  - `/aic-quality-gate` — rapport go/no-go factuel (check-shims + features + coverage + context-size + progress)
  - `/aic-feature-done` — validations evidence, scellage worklog, commit Conventional suggéré

### Changé
- `build-feature-index.sh` extrait désormais `progress.*` du frontmatter (yq v4 ou fallback awk pour `blockers`).
- `build-feature-index.sh` et `check-features.sh` ignorent les fichiers `*.worklog.md` (pattern `find ! -name '*.worklog.md'`).
- `FEATURE_TEMPLATE.md` documente le bloc `progress:` optionnel et la convention worklog.

### Tests
- Smoke-test étendu à 18 étapes : +progress parsé dans l'index, +resume-features buckets (text + json), +skills `aic-*` présents avec frontmatter valide.

### Philosophie
v0.5 = fiabilité, v0.6 = coût maîtrisé, **v0.7 = continuité**. Le travail n'est plus perdu entre sessions. Les skills encadrent les gestes récurrents (create/resume/update/handoff/done) avec une structure identique partout, exécutée dans un ordre stable. Le contexte de reprise est dans l'index (machine-readable) ET dans le worklog (narrative).

### Breaking
- Aucun. Les features existantes sans bloc `progress:` tombent dans le bucket "À FAIRE" de `resume-features.sh`, comportement non bloquant.

## v0.6.0 — 2026-04-23

Optimisation du coût tokens : filtrage par status + observabilité + reminder compressé.

### Nouveau
- `.ai/scripts/measure-context-size.sh` — mesure la taille du contexte injecté par les hooks, avec breakdown (static / inventory / reverse_deps / path matches). Estimation fourchette `chars/4..chars/3`, comptage exact via `tiktoken` si installé.
- `_lib.sh` : helper `visible_statuses_jq` — renvoie la liste JSON des status visibles dans le reminder.

### Changé
- **`pre-turn-reminder.sh` filtre par status** — par défaut n'affiche que `status ∈ {active, draft, ?}`. Les features `done/deprecated/archived` sont masquées avec hint explicite (`N masquée(s)`). Gain typique : 40-60% de tokens sur projets matures.
- **Reverse deps filtrées et alertées** — ne liste que les paires où source ET dépendants sont visibles. Si une feature a **>20 dépendants actifs**, affiche un warning `⚠️` au lieu de la liste (signal de découpage).
- **Override global** : `AI_CONTEXT_SHOW_ALL_STATUS=1` rétablit le comportement v0.5 (tout visible).

### Breaking-ish
- Si tu as des features en `status: done` référencées comme source de vérité → elles n'apparaissent plus dans le reminder. Utilise `AI_CONTEXT_SHOW_ALL_STATUS=1` dans ton env Claude Code, ou repasse la feature en `active` si elle est toujours canonique.

### Changé (suite)
- **`.ai/reminder.md` compressé** — passé de ~14 lignes (1018 chars) à 6 lignes (~450 chars). Seules les hard rules non-négociables restent ; les détails de séquence vivent dans `.ai/index.md` (chargé à la demande). Gain : ~55% sur chaque prompt.

### Tests
- Smoke-test étendu à 15 étapes : +filtrage status (default + override), +measure-context-size.

### Philosophie
v0.5 = fiabilité. **v0.6 = coût maîtrisé sans sacrifier la fiabilité**. Le signal utile (features actives + leurs dépendances directes) reste toujours injecté ; le bruit (historique archivé) devient on-demand. L'utilisateur décide via env var du trade-off exhaustivité vs coût.

## v0.5.0 — 2026-04-23

Durcissement fiabilité : dépendances vérifiées, parsing robuste, observabilité, détection de dérive.

### Nouveau
- `.ai/scripts/_lib.sh` — helpers partagés : `require_cmd` (die si binaire manquant), `log_debug` (stderr si `AI_CONTEXT_DEBUG=1`), `enable_globstar`, `with_index_lock` (lock atomique via `mkdir`, portable macOS/Linux), `is_valid_status` / `STATUS_ENUM`.
- `.ai/scripts/check-feature-coverage.sh` — détecte le **code orphelin** (fichier sous `src/`, `app/`, `lib/` non couvert par aucun `touches:` de feature). Mode `--warn` (défaut) ou `--strict` (exit 1).
- `.githooks/post-checkout` — rebuild automatique de `.ai/.feature-index.json` au switch de branche (évite l'index stale avec features différentes).

### Changé
- **Dépendances vérifiées** — tous les scripts utilisant `jq` échouent proprement avec message lisible si absent (plus de silent failures).
- **Filenames avec espaces** — toutes les boucles utilisent `find -print0` + `read -r -d ''` (plus de `for f in glob`).
- **Lock sur l'index** — `build-feature-index.sh --write` sérialise les rebuilds concurrents (plus de JSON corrompu).
- **Status enum** — `{draft, active, done, deprecated, archived}` validé : warn stderr si hors enum.
- **Globstar** — `shopt -s globstar` activé pour supporter `**` dans `touches:` (bash ≥4 ; fallback propre sur bash 3.2).
- **Debug** — `AI_CONTEXT_DEBUG=1` active les logs détaillés sur `pre-turn-reminder`, `features-for-path`, `build-feature-index`.
- **Dépendances inverses** — `pre-turn-reminder` liste "X ← Y, Z" : si tu modifies X, les features qui en dépendent sont rappelées.
- **Smoke-test portable** — remplacement de `stat -f/-c` par `touch -r` + `-nt` (marche sur macOS et Linux).
- **CI guard activé par défaut** (`enable_ci_guard: true`) — le workflow inclut désormais `check-features` en plus de `check-shims` et `check-ai-references`, et installe `jq` + `yq` v4.
- **`check-features.sh`** — refactorisé : sourced `_lib.sh`, `find -print0`, warn sur status hors enum, erreurs vers stderr.
- **`check-commit-features.sh`** — `require_cmd jq` différé au mode stdin (pas requis pour git hook).

### Tests
- Smoke-test étendu à 13 étapes : +reverse deps, +status enum warn, +coverage script.

### Philosophie
v0.3 = exploitation du maillage. v0.4 = perf. **v0.5 = fiabilité** : les modes d'échec silencieux sont fermés, le parsing est robuste, la dérive (orphelins, index stale sur branche) est détectée.

## v0.4.0 — 2026-04-23

Perf + robustesse du parsing YAML sur le chemin chaud des hooks.

### Nouveau
- `.ai/scripts/build-feature-index.sh` — compile le maillage features en JSON (`.ai/.feature-index.json`). Parse le frontmatter avec `yq` v4 si présent, sinon fallback awk/sed (zéro dépendance nouvelle). Écriture atomique via `mktemp + mv` (`--write`).
- `.ai/.gitignore` — le cache `.feature-index.json` n'est pas versionné.

### Changé
- `.ai/scripts/features-for-path.sh` — lit l'index JSON au lieu de re-parser les `.md` à chaque hook `PreToolUse` Write. Hot path O(N awk) → O(1) lookup jq. Rebuild auto si index manquant ou si un `.md` est plus récent (find -newer).
- `.ai/scripts/pre-turn-reminder.sh` — même refacto pour l'inventaire scope/status injecté à chaque tour (UserPromptSubmit).
- `.ai/scripts/check-features.sh` — rafraîchit l'index à la fin d'un run réussi (source de vérité).
- `tests/smoke-test.sh` — 2 nouvelles assertions : (1) l'index est créé et contient la feature de test, (2) rebuild sur mtime.

### Philosophie
Le feature mesh n'est plus pénalisé par sa taille. À 500+ features, les hooks restent sous 3 s — le coût du scan est amorti par le cache, pas payé à chaque tour.

## v0.3.0 — 2026-04-23

Garantie d'exploitation du maillage feature (pas seulement de création).

### Nouveau
- `.ai/scripts/features-for-path.sh` — lit le `touches:` des features et retourne celles qui concernent un path donné. Mode CLI + mode hook Claude (stdin JSON).
- Hook Claude `PreToolUse` sur `Write|Edit|MultiEdit` → appelle `features-for-path.sh`, injecte en `additionalContext` les features concernées avant toute écriture.
- `pre-turn-reminder.sh` enrichi — liste dynamique des features actives par scope (avec statut) injectée à chaque tour.

### Changé
- `check-features.sh` — valide désormais que chaque entrée `touches:` résout un chemin réel (fichier, dossier, ou glob). Une référence morte fait échouer le check.
- `check-commit-features.sh` — accepte maintenant du JSON Claude sur stdin (extraction robuste du message depuis `-m "..."`, `-m '...'`, ou heredoc `cat <<'EOF'`). Fix d'un bug v0.2.0 où le hook Claude consommait stdin deux fois avec `jq`.
- `.claude/settings.json` — hook Bash simplifié (délégué à `check-commit-features.sh` au lieu d'un inline `jq`).
- `.ai/index.md` et `.ai/reminder.md` — suppression de la wiggle room : "lister `features/<scope>/`" devient obligatoire à chaque tour (plus de "si applicable").

### Philosophie
v0.2 garantissait la **création** du maillage (hooks bloquants). v0.3 garantit son **exploitation** (context dynamique injecté à chaque tour + avant chaque écriture).

## v0.2.0 — 2026-04-23

Feature mesh enforcement — systématique, organisé par scope, cross-refs imposées.

### Nouveau
- `{{ docs_root }}/FEATURE_TEMPLATE.md` — squelette feature (frontmatter `id/scope/title/status/depends_on/touches`).
- `{{ docs_root }}/features/<scope>/` — organisation par scope métier (back, front, architecture, security).
- `.ai/scripts/check-features.sh` — validation du maillage (frontmatter présent, scope == dossier parent, `depends_on` résout).
- `.ai/scripts/check-commit-features.sh` — validation Conventional Commits + blocage `feat:` sans fichier `features/` touché.
- `.githooks/commit-msg` — délégation du check commit-msg (active via `git config core.hooksPath .githooks`).
- Hook Claude `PreToolUse` sur `Bash(git commit*)` — même check sous Claude Code avant l'exécution.

### Changé
- `.ai/quality/QUALITY_GATE.md` — suppression de l'option "C — Skip" (remplacée par Conventional Commits). Ajout des sections **Feature mesh** et **Commits** bloquantes.
- `.ai/rules/{back,front,architecture,security}.md` — obligation feature systématique documentée.
- `.ai/index.md` — table scope avec colonne Features, section Feature mesh, runtime enforcement étendu.
- `README_AI_CONTEXT.md` — étape d'activation des git hooks.

### Philosophie
Pas de dérogation par "taille de projet". Un maillage complet = agents plus puissants. Aucune wiggle room laissée à l'Agent.

## v0.1.0 — 2026-04-23

Initial release. MVP du template copier.

### Inclus
- 4 shims cross-agent (AGENTS, CLAUDE, GEMINI, Copilot) + Cursor `.mdc` opt-in
- `.ai/index.md` (entrée impérative) + `.ai/rules/<scope>.md` (squelettes par scope)
- `.ai/quality/QUALITY_GATE.md` (DoD + Doc Impact Decision)
- `.ai/reminder.md` (contenu extrait, éditable)
- `.ai/scripts/` : `pre-turn-reminder.sh` (dual text/json), `check-shims.sh`, `check-ai-references.sh`
- Hook Claude `UserPromptSubmit` (`.claude/settings.json`)
- `.copier-answers.yml` pour `copier update`
- Profils scope : `minimal`, `backend`, `fullstack`, `custom`
- CI GitHub Actions opt-in (`enable_ci_guard`)

### Prévu v2 (issues à ouvrir)
- Slash commands Claude (`/handoff`, `/plan-task`)
- Hook `PreToolUse` bloquant sur `git commit` quand `.docs/` non maj
- `check-feature-coverage.sh`, `check-workflow-coherence.sh`
- `check-ai-pack-size.sh` avec tokenizer tiktoken
- Mode low-context (exceptions de chargement)
- Stop hook `.ai/state/last-handoff.md`
- Support legacy `.cursorrules`
- Profil `custom` interactif avec liste de scopes
- Pipelines CI : Azure, GitLab
- i18n reminder (EN)
