# CHANGELOG

## Unreleased

### Changé
- Centralisation du matching `touches:` dans `_lib.sh` (`path_matches_touch` + `features_matching_path`) et adoption par `features-for-path`, `auto-worklog-log`, `check-feature-coverage` et le hook git `pre-commit`.
- Les scripts runtime utilisent maintenant `AI_CONTEXT_DOCS_ROOT` / `AI_CONTEXT_FEATURES_DIR` depuis `_lib.sh`, ce qui rend `docs_root=docs` fonctionnel au-delà des fichiers scaffoldés.
- Documentation synchronisée : nombre d'étapes du smoke-test, défaut `enable_ci_guard`, description des hooks runtime.

### Tests
- Smoke-test étendu à **27 étapes** avec assertions ciblées sur le matching exact/dossier/glob/`/**` et `docs_root=docs`.

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
