# Audit ai_context — 2026-05-01 (re-audit post-corrections)

> **Note** : ce document succède à l'audit du commit [`f9eb6fb`](https://github.com/qhuy/ai_context/commit/f9eb6fb), qui avait identifié et appliqué une roadmap P0+P1+P2.
> Mon objectif ici n'est **pas** de recoucher les findings déjà traités, mais de **vérifier la qualité réelle des corrections appliquées** et de pointer les angles morts que ce premier passage a manqués.
> Méthode : 4 sondes parallèles (sécurité+federation, portabilité+auto-progression, multi-agents+strict, tokens+tests+DX) sur le code template/runtime + docs racine. Cite file:line systématique. Pas de modification, pas de PR.

---

## TL;DR

1. ~~**`project_id` est techniquement mort-né.**~~ **Rétractation** : finding faux. [`template/.ai/config.yml.jinja:2`](template/.ai/config.yml.jinja:2) contient bien `project_id: "{{ project_name }}"`, et [`tests/smoke-test.sh:174-178`](tests/smoke-test.sh:174) asserte que le JSON émis correspond au `project_name` Copier. La correction P1 sur `project_id` est complète. Reste valable : `project_url` absent → deux projets `ai_context` (basename collision sur dossiers différents) restent indistinguables — mais c'est un manque, pas un bug.
2. **`is_path_within_repo` (la nouvelle barrière sécu P2) n'a aucun test unitaire et ne couvre pas Windows.** UNC `\\server\share`, backslash absolu `\Windows\System32`, NUL byte, RTL `‮` passent. [`tests/unit/test-path-matches-touch.sh`](tests/unit/test-path-matches-touch.sh) a 17 cas effectifs (annoncé 18) et ne touche pas le helper de sécu. Précisément l'élément ajouté par P2 n'est pas régressable.
3. **`copier update` n'est JAMAIS exercé en smoke-test.** Le canal de diffusion des corrections P0+P1+P2 vers les projets existants est un trou critique. [`tests/smoke-test.sh`](tests/smoke-test.sh) joue uniquement `copier copy`. Une régression sur `_message_after_update`, sur la résolution de conflits ou sur `migrate-features.sh --apply` casse silencieusement la propagation.
4. **`ai-context-check.yml` (workflow PR principal) reste sans Windows.** P0 a ajouté `windows-latest` à `template-smoke-test.yml` en `continue-on-error: true`, mais le workflow le plus invoqué (sur tout push `.ai/**` et chaque PR) n'a toujours que [`ubuntu-latest, macos-latest`](.github/workflows/ai-context-check.yml:25). Le runtime utilisateur quotidien (check-shims, check-features, pre-turn-reminder) n'est pas validé Windows.
5. **`id` et `scope` acceptent n'importe quoi.** [`build-feature-index.sh.jinja:111`](template/.ai/scripts/build-feature-index.sh.jinja:111) accepte un `id` contenant `/`, `..`, espaces. La clé `scope/id` sert à construire `worklog_path` dans [`auto-worklog-flush.sh`](template/.ai/scripts/auto-worklog-flush.sh.jinja) → écriture sur chemin non-canonique possible via frontmatter. Vecteur d'écriture latent que l'audit précédent n'a pas vu.

---

## Severity matrix

| Finding | Severity | Effort | Type |
|---|---|---|---|
| ~~`project_id` toujours `basename`~~ — finding rétracté (clé bien rendue + asserted) | n/a | — | OK |
| `is_path_within_repo` sans test unit + UNC/Windows abs non couverts | **high** | S | bug correction P2 |
| `copier update` jamais testé en smoke-test | **high** | M | tests |
| `id`/`scope` acceptés sans regex (path traversal worklog) | **high** | S | bug archi |
| `ai-context-check.yml` (PR principal) sans Windows | medium | S | tests |
| `/aic undo` testé seulement plumbing snapshot | medium | M | tests |
| `measure-context-size` mesure `text`, pas le wrapping JSON Claude | medium | S | bug latent |
| `depends_on` non vérifié contre `is_path_within_repo` | medium | S | bug latent |
| Drift `copier.yml:128` label strict (« renforcements en cours » obsolète) | medium | S | doc |
| Aucune note breaking CI strict + projet jeune | medium | S | doc |
| Idempotence/concurrence `ensure_index` non testée | medium | M | tests |
| 11/16 combinaisons `tech_profile × scope_profile` non testées | medium | M | tests |
| FIFO 50 entrées undo non documenté | low | S | doc |
| Cursor MDC scopé (`glob:` auto-attach) jamais exploité | low | M | feature |
| AGENTS.md sans sections « Setup/Testing Commands » | low | S | feature |
| Placeholders `implement_to_review` / `review_to_done` toujours scaffoldés | low | S | doc |
| Doctor aveugle sur `.claude/settings.json` hooks attendus | low | S | feature |
| Symlinks dans le repo non gérés par `path_matches_touch` | low | S | bug latent |
| `extract_scalar_awk` tronque `resume_hint` multi-ligne | low | S | bug latent |
| Pas de script `setup.sh` (suggestion P0 non appliquée) | low | S | DX |

---

## Findings détaillés

### Axe 1 — Portabilité Windows / WSL

**Constat.** P0 a livré : section plateformes dans [`docs/getting-started.md:11-30`](docs/getting-started.md), ajout de `windows-latest` à [`template-smoke-test.yml:27-33`](.github/workflows/template-smoke-test.yml:27) en `continue-on-error: true`, shebangs `#!/bin/bash` portables Git Bash.

**Mais** :
- [`.github/workflows/ai-context-check.yml:25`](.github/workflows/ai-context-check.yml:25) — workflow PR le plus invoqué (chaque push `.ai/**`) — limite encore la matrix à `[ubuntu-latest, macos-latest]`. **Le runtime utilisateur final (check-shims, check-features, pre-turn-reminder) n'est jamais validé Windows.**
- `continue-on-error: ${{ matrix.os == 'windows-latest' }}` signifie qu'une régression Git Bash passe en succès dans l'UI matrix, ne bloque pas le merge. La couverture est informative, pas régressante.
- [`docs/getting-started.md:14`](docs/getting-started.md:14) marque `Git Bash ⚠️ Best-effort` mais n'avertit **pas** que la CI Windows est non-bloquante. Mismatch d'attente.

**Severity** : medium (P0 partiel — la doc dit "best-effort", la CI n'a aucun signal arrêtant).
**Recommandation directionnelle** : étendre `ai-context-check.yml` à Windows (au moins en `continue-on-error: true` pour démarrer, puis `false` une fois la stabilité confirmée). Adapter la note plateformes pour expliciter le caractère non-bloquant.

---

### Axe 2 — Sécurité runtime des hooks

**Constat.** P2 a livré : [`is_path_within_repo`](template/.ai/scripts/_lib.sh.jinja:143-153) qui rejette `/abs`, `[A-Za-z]:`, `~`, `..`, `.. /foo`, `foo/..`. [`check-features.sh.jinja:123-127`](template/.ai/scripts/check-features.sh.jinja:123) appelle ce helper. [`SECURITY.md:40-61`](SECURITY.md:40) ajoute "Trust model du feature mesh".

**Faiblesses** :
- **`is_path_within_repo` ne couvre pas tous les cas Windows** : UNC `\\server\share`, backslash absolu `\Windows\System32`, NUL byte, RTL `‮` passent. Le pattern `[A-Za-z]:` ne matche pas un UNC ; `[[ "$p" == /* ]]` ne matche pas `\foo`.
- **Aucun test unitaire dédié.** [`tests/unit/test-path-matches-touch.sh`](tests/unit/test-path-matches-touch.sh) (17 cas effectifs, malgré l'annonce de 18) couvre `path_matches_touch`, **pas** `is_path_within_repo`. Le helper de sécu ajouté par P2 n'a donc aucune évidence de non-régression.
- **`id`/`scope` acceptés sans regex.** [`build-feature-index.sh.jinja:111-112`](template/.ai/scripts/build-feature-index.sh.jinja:111) : `[[ -z "$id" ]] && id=$(basename "$file" .md)`. Aucune validation `^[a-z0-9-]+$`. Conséquences : un `id: "../etc"` produit `worklog_path="$(dirname feature_path)/../etc.worklog.md"` (chemin non-canonique), et la clé `scope/id` (utilisée comme accumulateur) collisionne (`back/auth` matche soit `scope=back, id=auth`, soit `scope=back/auth, id=` selon où le slash est interprété).
- **`depends_on` non vérifié contre `is_path_within_repo`.** [`check-features.sh.jinja:102`](template/.ai/scripts/check-features.sh.jinja:102) fait `target="$FEATURES_DIR/$dep.md"`. Un `dep: ../../other-project/scope/id` traverse silencieusement (rejeté seulement si la cible n'existe pas).
- **Symlinks** : [`path_matches_touch`](template/.ai/scripts/_lib.sh.jinja:101-121) opère en pure string match, jamais `realpath`. Si un dev commit `src/secrets -> /etc/`, `touches: src/**` matchera puis `[[ -e "$t" ]]` ([`check-features.sh.jinja:130`](template/.ai/scripts/check-features.sh.jinja:130)) suit le symlink → la feature peut "couvrir" hors-repo sans alerte.
- **`extract_scalar_awk`** ([`build-feature-index.sh.jinja:57-61`](template/.ai/scripts/build-feature-index.sh.jinja:57)) tronque silencieusement `resume_hint` multi-ligne à la première ligne. Pas un risque sécu, mais gap fonctionnel non documenté.

**Severity** : high pour le path traversal worklog (`id`/`scope`) + l'absence de test sur `is_path_within_repo`, medium pour les autres.
**Recommandation directionnelle** : ajouter regex stricte sur `id`/`scope` au check + au build-index. Étendre `is_path_within_repo` à UNC + backslash absolu. Créer `tests/unit/test-is-path-within-repo.sh`. Appliquer `is_path_within_repo` aussi aux `depends_on`. Réécrire `extract_scalar_awk` pour préserver multi-ligne (ou documenter la troncature).

---

### Axe 3 — Auto-progression spec → implement

**Constat.** P1 a livré : `progress.auto_transitions.spec_to_implement` lu via `read_config` à [`auto-progress.sh.jinja:38`](template/.ai/scripts/auto-progress.sh.jinja:38). **Bonne nouvelle confirmée** : le pre-commit agent-agnostique [`.githooks/pre-commit.jinja:67`](template/.githooks/pre-commit.jinja:67) invoque le même `auto-progress.sh`, donc l'opt-out est unifié pour TOUS les agents.

**Faiblesses** :
- **`/aic undo` testé seulement au niveau plumbing snapshot** ([`smoke-test.sh:686-690`](tests/smoke-test.sh:686)). La logique de restauration vit uniquement dans [`template/.claude/skills/aic/workflow.md.jinja`](template/.claude/skills/aic/workflow.md.jinja) — non testable headless. Un script `aic-undo.sh` extrait du skill faciliterait un test E2E.
- **FIFO 50 entrées non documenté** ([`auto-progress.sh.jinja:101-105`](template/.ai/scripts/auto-progress.sh.jinja:101) — `tail -n 50`). Grep négatif sur README/CHANGELOG/`_message_after_copy` pour `FIFO|50 transitions`. Sur un projet actif (>50 commits/semaine), `/aic undo` à J+10 cible un mauvais snapshot ou répond "rien à annuler" alors que l'utilisateur croit pouvoir remonter.
- **Faux positif intrinsèque non documenté** : refactor d'un fichier déjà couvert par une feature `phase: spec` mais pour autre motif (fix typo cross-cutting) → bascule à tort. Limite assumée mais aucune mention en troubleshooting README.
- **Pattern auto-progress ignore le YAML inline.** [`auto-progress.sh.jinja:113-114`](template/.ai/scripts/auto-progress.sh.jinja:113) ancre `^progress:` et `^  phase: spec[[:space:]]*$`. Un frontmatter `progress: { phase: spec }` n'est jamais matché → ces features ne progressent jamais auto. Régression silencieuse.
- **Placeholders `implement_to_review` / `review_to_done`** toujours dans [`config.yml.jinja:39-40`](template/.ai/config.yml.jinja:39). Statut "informatif" assumé dans [`README.md:703-704`](README.md:703). Confusion utilisateur (croit pouvoir activer `implement_to_review: true` sans effet).

**Severity** : medium.
**Recommandation directionnelle** : extraire un `aic-undo.sh` headless + assertion smoke-test E2E. Documenter FIFO 50 et faux positifs (README troubleshooting). Décider : retirer les placeholders ou les câbler.

---

### Axe 4 — Multi-agents : promesse vs réalité

**Constat.** P0 a livré : tableau "Capacités runtime par agent" dans [`README.md:59-69`](README.md:59) ET [`template/AGENTS.md.jinja:17-26`](template/AGENTS.md.jinja:17), fin de l'ambiguïté multi-agent. Communication tempérée ("Claude-first runtime, multi-agent shims").

**Faiblesses** :
- **Cursor MDC scopé jamais exploité.** [`template/.cursor/rules/protocol-reminder.mdc.jinja`](template/.cursor/rules/protocol-reminder.mdc.jinja) est UN seul MDC global avec `alwaysApply: true`. Cursor permet pourtant `.cursor/rules/<name>.mdc` avec frontmatter `globs: ["src/back/**"]` qui auto-attache uniquement quand le fichier édité matche — l'équivalent natif de `features-for-path.sh` côté Cursor. Un `for scope in scopes: render(.cursor/rules/<scope>.mdc with globs=touches_of(scope))` apporterait une parité partielle Claude/Cursor sur features-for-path. **Effort M, ROI élevé. Pas fait.**
- **AGENTS.md.jinja n'utilise aucune section de la spec agents.md** : pas de "Project Structure", "Setup Commands" (`bash .ai/scripts/check-features.sh`), "Testing Instructions" (`bash tests/smoke-test.sh`), "Code Style", "PR Instructions". Un Codex sans hooks tirerait vraie valeur d'un "Setup Commands" intégré au shim. **Effort S, ROI moyen.**
- **Le tableau coche `Shim racine + lecture .ai/rules/*` ✅ pour Cursor** : techniquement vrai (Cursor lira via le MDC global), mais la nuance scoped vs global est lissée. Pas un mensonge, juste une parité optique non tenue côté capacités natives.

**Severity** : low (communication honnête), medium (sur-engineering "pas fait" sur Cursor MDC qui aurait du ROI).
**Recommandation directionnelle** : générer `.cursor/rules/<scope>.mdc` à partir des `.ai/rules/<scope>.md` + globs des `touches:` du scope. Enrichir AGENTS.md.jinja avec sections spec.

---

### Axe 5 — `adoption_mode=strict` réellement strict

**Constat.** P1 a livré : [`ai-context-check.yml.jinja:65-73`](template/.github/workflows/ai-context-check.yml.jinja:65) ajoute `doctor.sh --strict` + `check-feature-coverage.sh --strict` conditionnellement avec `{%- if adoption_mode == 'strict' %}`. Conditionnement correct, pas inconditionnel. Doctor en strict bloque sur `jq missing`, `.ai/index.md missing`, etc. ([`doctor.sh.jinja:28-35`](template/.ai/scripts/doctor.sh.jinja:28)).

**Faiblesses** :
- **Drift label `copier.yml:128`** : dit toujours `« CI forcée même si enable_ci_guard=false ; renforcements en cours, voir README »`. Le "renforcements en cours" est obsolète post-fix. Devrait dire `« CI forcée + doctor.sh --strict + check-feature-coverage.sh --strict ; échec attendu si orphelins »`. [`README.md:581`](README.md:581) reflète bien la réalité — drift entre les deux.
- **Aucune note breaking pour passage en strict aujourd'hui.** Sur projet jeune, `check-feature-coverage.sh --strict` est garanti d'échouer (orphelins probables). Pas de warning dans `_message_after_copy`, pas de mention "breaking" dans `CHANGELOG.md` (la section "Migration" Unreleased mentionne CI strict, mais sans encadrer le risque CI rouge garantie).

**Severity** : medium (drift doc + bascule comportement non communiquée).
**Recommandation directionnelle** : aligner le label `copier.yml:128`. Ajouter dans `_message_after_copy` un paragraphe « Si tu choisis strict sur projet jeune, attends-toi à CI rouge tant que la couverture n'atteint pas X%. Lance localement avant le 1er commit. ».

---

### Axe 6 — Cross-project & federation

**Constat.** P1 a livré : [`schema_version: "1"` émis dans `.feature-index.json`](template/.ai/scripts/build-feature-index.sh.jinja:165-170), `project_id` censé être lu via `read_config 'project_id' "$(basename "$repo_root")"` ([`build-feature-index.sh.jinja:160`](template/.ai/scripts/build-feature-index.sh.jinja:160)).

**Rectification post-vérif** : la sonde initiale signalait `project_id` non rendu — **erreur**. [`template/.ai/config.yml.jinja:2`](template/.ai/config.yml.jinja:2) le rend bien (`project_id: "{{ project_name }}"`) et [`tests/smoke-test.sh:174-178`](tests/smoke-test.sh:174) l'asserte. La correction P1 sur ce point est solide.

**Manques restants (low/medium)** :
- **Aucun `project_url` ni `commit_sha`** dans le JSON émis. Deux projets `ai_context` (basename collision sur dossiers différents avec même `project_name`) restent indistinguables.
- **`depends_on` cross-project non bloqué** : un `dep: ../../other-project/scope/id` traverse silencieusement (rejeté seulement si la cible n'existe pas, pas par `is_path_within_repo`).
- **`project_id` n'est pas slugifié** : un `project_name: "Mon Projet 2026"` produit un `project_id` avec espaces et chiffres. Pas un bug, mais friction quand le JSON est consommé par un outil tiers.

**Severity** : low (les manques sont des finitions, pas des trous).
**Recommandation directionnelle** : préparer `project_url` (optionnel, pour P3 fédération). Appliquer `is_path_within_repo` aussi aux entrées `depends_on`. Slugifier `project_id` dans le rendu Copier.

---

### Axe 7 — Coût tokens en pratique

**Constat.** P1+P2 ont livré : `context.max_tokens_warn` consommé à [`pre-turn-reminder.sh.jinja:189-194`](template/.ai/scripts/pre-turn-reminder.sh.jinja:189), big-mesh fixture (60 features) avec assertions chars + `AI_CONTEXT_FOCUS` ([`smoke-test.sh:1110-1175`](tests/smoke-test.sh:1110)).

**Faiblesses** :
- **`measure-context-size.sh` mesure le mauvais format.** [`measure-context-size.sh.jinja:85`](template/.ai/scripts/measure-context-size.sh.jinja:85) lance `pre-turn-reminder.sh --format=text`. Mais le hook réel utilise `--format=json` ([`settings.json.jinja:9`](template/.claude/settings.json.jinja:9)) qui wrappe avec `{"hookSpecificOutput":{"hookEventName":"...","additionalContext":"..."}}`. La mesure SOUS-ESTIME le coût réel injecté à Claude.
- **Big-mesh fixture = test guard, pas stress.** 60 features avec dépendances 1-to-1, pas n×n. La branche `≥ 20 reverse deps ⇒ "envisager un découpage"` ([`pre-turn-reminder.sh.jinja:167`](template/.ai/scripts/pre-turn-reminder.sh.jinja:167)) n'est jamais exercée par le fixture. Sur un projet réel à 100+ features avec graph dense, les 30k chars seront dépassés sans alerte CI.
- **`context.show_statuses` et `context.default_focus` toujours non lus** ([`PROJECT_STATE.md:59`](PROJECT_STATE.md:59) explicite). Cohérent avec roadmap, mais le scaffolding rendu donne l'illusion d'une option configurable.
- **Estimation `chars/4..chars/3`** sous-estime sur français accentué (cl100k_base ~0.45 token/char). `tiktoken` optionnel mais le fallback est silencieux.

**Severity** : medium.
**Recommandation directionnelle** : changer `measure-context-size.sh` pour aussi mesurer le `--format=json` (ou expliquer pourquoi text suffit). Étendre big-mesh avec un cas hub (1 feature, 25 reverse deps) pour exercer la branche warning. Aligner le seuil `max_tokens_warn` sur la borne haute, pas basse.

---

### Axe 8 — Tests & robustesse

**Constat.** P2 a livré : [`tests/unit/test-path-matches-touch.sh`](tests/unit/test-path-matches-touch.sh) (17 cas effectifs malgré l'annonce 18), smoke-test étendu avec assertions big-mesh + snapshot from.phase + touches hors repo.

**Lacunes critiques** :
- **`copier update` JAMAIS testé.** [`tests/smoke-test.sh`](tests/smoke-test.sh) joue uniquement `copier copy`. Le canal de diffusion des fixes vers les projets existants est un trou critique. Une régression sur `_message_after_update` ([`copier.yml:96-98`](copier.yml:96)), sur la résolution de conflits sur fichiers générés, ou sur `migrate-features.sh --apply` casse silencieusement la propagation.
- **`/aic undo` E2E absent** (cf. axe 3) — seul le snapshot plumbing est asserté.
- **5/16 combinaisons `tech_profile × scope_profile` testées** : default+fullstack, dotnet+default, react+default, fullstack+fullstack, lite/strict. **11 combinaisons non testées**, dont `minimal × dotnet`, `backend × react-next`, `custom × *`. Risque combinatoire réel sur `_exclude` conditionnels ([`copier.yml:14-41`](copier.yml:14)).
- **Pas de test d'idempotence/concurrence sur `ensure_index`** ([`pre-turn-reminder.sh.jinja:57-67`](template/.ai/scripts/pre-turn-reminder.sh.jinja:57)). Le `mkdir-lock` ([`_lib.sh.jinja:177-197`](template/.ai/scripts/_lib.sh.jinja:177)) existe mais n'est asserté nulle part. En cas de PostToolUse + UserPromptSubmit déclenchés simultanément, risque corruption silencieuse `.feature-index.json`.
- **Pas de test mesh corrompu YAML** (frontmatter malformé). Seuls les `status: typo` et `phase: typo` sont testés.

**Severity** : high pour `copier update`, medium pour le reste.
**Recommandation directionnelle** : ajouter étape smoke-test « copier copy v0.X.0 puis copier update vers HEAD avec un fichier customisé ». Ajouter test concurrence sur `build-feature-index --write` (lancer 2x en parallèle, vérifier JSON valide). Étendre `test-path-matches-touch.sh` avec espaces, glob backslash, et créer `test-is-path-within-repo.sh`.

---

### Axe 9 — DX / friction d'adoption

**Constat.** P0 a livré : section plateformes dans `getting-started.md`, tableau plateformes clair, doc Scoop/Choco pour Windows.

**Lacunes** :
- **`_message_after_copy` toujours 50+ lignes, 10 étapes.** Pas de TL;DR top-3. Probable lecture <30% pour primo-utilisateur.
- **Pas de script `setup.sh`** qui regrouperait `git config core.hooksPath .githooks` + `chmod +x .githooks/*` + `check-shims` + `check-features`. Suggestion de l'audit P0 non appliquée.
- **`getting-started.md` (62 lignes)** sans section troubleshooting (« que faire si check-features échoue après scaffold », « comment activer les hooks Claude sans Claude Code ouvert »).
- **Doctor aveugle sur l'écosystème Claude.** [`doctor.sh.jinja`](template/.ai/scripts/doctor.sh.jinja) couvre jq/yq/copier/git/index/reminder/hooks-path/check-shims/check-features. Manque : `python3` (alors que `measure-context-size` en dépend pour `tiktoken`), présence et structure de `.claude/settings.json` (UserPromptSubmit/PreToolUse/Stop attendus si `claude` dans agents), exécutabilité `.githooks/*`.
- **Messages d'erreur** : `pre-turn-reminder.sh:81` warn `focus=$focus : aucune feature dans ce scope` mais ne liste pas les scopes valides. Friction inutile.

**Severity** : low/medium.
**Recommandation directionnelle** : ajouter `setup.sh` (3-5 commandes consolidées). Étendre `getting-started.md` avec section troubleshooting (5 erreurs fréquentes + remédiation). Élargir `doctor.sh` à `.claude/settings.json` + `python3`.

---

## Roadmap suggérée

### R1 — Réparer les corrections incomplètes (1-2 jours, P0 du re-audit)

Critères d'acceptation :
- [ ] `is_path_within_repo` : étendre à UNC `\\` et backslash absolu `\`. Créer `tests/unit/test-is-path-within-repo.sh` (≥10 cas couvrant Unix abs, Windows `C:`, UNC, traversal mixte, espaces, vide).
- [ ] Appliquer `is_path_within_repo` aussi aux entrées `depends_on` (path traversal cross-project).
- [ ] `check-features.sh` + `build-feature-index.sh` : valider `id` et `scope` avec regex `^[a-z0-9][a-z0-9-]*$`. Reject early.
- [ ] `copier.yml:128` : aligner le label `strict` sur la réalité post-P1 (doctor + coverage). Ajouter dans `_message_after_copy` un avertissement « strict + projet jeune = CI rouge garantie ».

### R2 — Combler les tests critiques (3-5 jours)

Critères d'acceptation :
- [ ] `tests/smoke-test.sh` : étape `copier update` (depuis tag précédent puis vers HEAD) avec fichier customisé conservé.
- [ ] `aic-undo.sh` headless extrait du skill, testé E2E (créer feature spec → édit → flippe → undo → vérif phase + history).
- [ ] Smoke-test étendu à ≥8/16 combinaisons `tech_profile × scope_profile`.
- [ ] Test de concurrence `build-feature-index --write` (2 lancements parallèles, JSON valide attendu).
- [ ] `ai-context-check.yml` : matrix Windows en `continue-on-error: true` au minimum (signal informatif sur le runtime quotidien).

### R3 — Multi-agents ROI + sur-engineering ménagé (1 semaine)

Critères d'acceptation :
- [ ] Cursor MDC scopé : générer `.cursor/rules/<scope>.mdc` avec `globs:` dérivés des `touches:` du scope. Parité partielle features-for-path.
- [ ] AGENTS.md.jinja : ajouter sections « Setup Commands » et « Testing Instructions » conformes à la spec agents.md.
- [ ] Décision sur `implement_to_review` / `review_to_done` : câbler ou retirer du `config.yml.jinja`.
- [ ] FIFO 50 : documenter dans README + CHANGELOG, ou paramétrer via `progress.history_max_entries`.
- [ ] Doctor : ajouter checks `.claude/settings.json` hooks, `python3`, exécutabilité `.githooks/*`.

---

## Hors scope identifié

À ne **pas** fixer maintenant :
- **Federation MCP / signature** — P3, prématuré tant que `project_url` + `commit_sha` ne sont pas exposés.
- **`measure-context-size --json`** — utile pour automation mais non urgent. Le mode informatif suffit pour MVP.
- **`learning log` automatique** — risque pollution mesh, déjà identifié comme P3 dormant.
- **Wrapper PowerShell `.ps1`** — décision « PowerShell pur ❌ » cohérente avec le périmètre. Ne pas réouvrir.
- **Refonte des skills `/aic-*`** — surface stable (5 commandes user-facing), pas de gain immédiat.
- **Site docs (mkdocs)** — P2 historique, pas critique tant que les fichiers racine sont à jour.

---

## Synthèse honnête

L'audit précédent (`f9eb6fb`) a livré du travail solide sur **P0** (communication multi-agents tempérée, label strict corrigé, doc Windows ajoutée, trust model SECURITY.md) et **P2** (validation `touches:` hors repo, tests unitaires path-matches-touch, big-mesh fixture, snapshot from.phase). Aucune dette nouvelle introduite.

Mais **P1+P2 ont un raté concret** : `is_path_within_repo` créé sans test unitaire dédié et sans couverture UNC/Windows abs. Le finding initial sur `project_id` mort-né a été rétracté après vérification (la clé est bien rendue dans `config.yml.jinja:2` et le smoke-test l'asserte).

Et **P0+P2 ont chacun un angle mort persistant** :
- Le workflow PR principal (`ai-context-check.yml`) n'a jamais reçu Windows.
- Le smoke-test ne joue jamais `copier update` — le canal de diffusion des fixes lui-même n'est pas testé.

Le **bon angle d'attaque** : R1 (réparer les corrections incomplètes) avant tout autre chantier. Sans test sur `is_path_within_repo`, la promesse sécu reste creuse ; sans regex sur `id`/`scope`, le path traversal worklog reste latent. R2 (tests `copier update` + `/aic undo` E2E) ferme les angles morts critiques. R3 peut attendre une release majeure.

Le template reste **plus mûr que son numéro de version** (v0.11.0) : design conservateur, opt-out auto-progress vraiment unifié multi-agents (bonne surprise), aucun vecteur d'exécution arbitraire identifié dans le runtime des hooks. Les défauts trouvés sont des **finitions imparfaites**, pas des dettes architecturales.
