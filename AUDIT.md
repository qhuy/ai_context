# Audit ai_context — 2026-05-01

> Audit critique du template Copier `ai_context` (v0.11.0) — staff engineer review.
> Méthode : lecture ciblée du code (template/.ai/scripts, .githooks, .claude, copier.yml, docs racine), comparaison promesse vs implémentation. Pas de modifications de fichiers, pas de PR.

---

## TL;DR

1. **« Multi-agents » est en grande partie marketing.** Seul Claude bénéficie du runtime (injection de contexte par tour, auto-worklog, auto-progress immédiat). Codex/Gemini/Copilot/Cursor n'ont que des **shims statiques** et les git hooks au commit — aucune feature mesh injectée pendant qu'ils travaillent. Le README et le tableau marketing entretiennent l'ambiguïté.
2. **Portabilité Windows non documentée.** Le code est globalement portable (`mkdir`-lock, `mktemp`, `find -print0`), mais aucune mention Windows / Git Bash dans la doc, aucun test CI hors `ubuntu-latest` + `macos-latest`. Pour un dev Windows pur qui n'a pas WSL, l'expérience est un saut dans le vide. **Tu développes pourtant le repo sous Windows** — donc lacune doublement gênante.
3. **`adoption_mode=strict` est cosmétique.** La seule différence concrète avec `standard` est de forcer `.github/workflows` (cf. [copier.yml:39](copier.yml:39)). Le label « garde-fous renforcés » n'est pas tenu — le README l'admet déjà à demi-mot, mais le `choices` de `copier.yml:128` (« CI forcée ») ment encore.
4. **Sécurité runtime : pas de vecteur d'exécution majeur**, mais la validation `touches:` dans [check-features.sh:119](template/.ai/scripts/check-features.sh.jinja) utilise un word-splitting non quoté (`matches=( $t )`) sur du contenu YAML. Le risque réel est faible (frontmatter versionné, pas d'`eval`), mais un mesh importé d'un autre projet via copier-paste mérite défiance — et `SECURITY.md` ne dit rien là-dessus.
5. **`measure-context-size` est décoratif tant qu'on n'a pas un fixture worst-case.** Il mesure le mesh courant ; sur un repo modèle avec 5 features, on ne sait rien sur le comportement à 100+ features. Le filtre `AI_CONTEXT_FOCUS` est élégant mais non chiffré.

---

## Severity matrix

| Finding | Severity | Effort | Type |
|---|---|---|---|
| Multi-agents = inégal Claude vs autres, communication trompeuse | **high** | M (refonte messaging + petite expansion AGENTS.md) | doc/archi |
| Aucune doc/test Windows alors que le mainteneur dév sous Windows | high | S (doc) → M (CI) | doc |
| `adoption_mode=strict` ≈ `standard` | medium | M (définir & implémenter contraintes strictes) | feature/doc |
| Word-split non quoté sur `touches:` dans `check-features.sh` | low | S | bug latent |
| `SECURITY.md` ne traite ni frontmatter malveillant ni injection path | medium | S | doc |
| `measure-context-size` sans fixture worst-case → métrique non actionnable | medium | M (fixture + perf budget en CI) | feature |
| `.ai/config.yml` : 6/12 champs sont placeholders non lus | medium | M (consommer les champs ou les supprimer) | bug archi |
| Pas de tests unitaires sur `path_matches_touch` (helper central) | medium | M (bats ou shunit2) | tests |
| `feature-index.json` non versionné, pas de `project_id` → fédération impossible | low | M | feature |
| 9 skills `/aic-*` + 4 internes — surface importante pour système conceptuellement simple | low (sur-engineering) | M (consolider) | archi |
| `ai-context.sh` wrapper qui ne fait que router | low (surface inutile) | S | sur-engineering |
| Auto-progression conservatrice (spec→implement) sans faux positif notable | n/a (correct) | — | OK |
| Pas de mécanisme de validation `touches:` contre `..` ou paths absolus | low | S | bug latent |
| Undo (`/aic undo`) pas couvert par `tests/smoke-test.sh` | medium | S | tests |

---

## Findings détaillés

### Axe 1 — Portabilité Windows / WSL

**Constat.** Le code est étonnamment portable :
- Lock atomique via `mkdir` plutôt que `flock` ([_lib.sh:144-163](template/.ai/scripts/_lib.sh.jinja:144))
- `mktemp` respecte `$TMPDIR`, pas de `/tmp` hardcodé
- `find -print0` partout pour gérer espaces et chars spéciaux
- Pas de `readlink -f`, pas de `stat`, pas de `realpath`
- Shebang `#!/bin/bash` (pas `#!/usr/bin/env bash`, ce qui est plus contraignant sous certaines distros mais OK Git Bash)

Mais :
- **Dépendance dure à `jq`**, et `yq` v4 fortement recommandé. Sous Windows pur (sans WSL/Git Bash), l'installation n'est pas évidente. La doc parle uniquement `brew install jq yq` ([README.md:217](README.md:217), [copier.yml:46](copier.yml:46)).
- **Aucune CI Windows** — la matrice est `ubuntu-latest` + `macos-latest` ([README.md:749](README.md:749)).
- **Aucune mention Windows / Git Bash / WSL** dans `README.md`, `getting-started.md`, `MIGRATION.md`, `SECURITY.md`. Pourtant le repo est en train d'être audité depuis `F:\Dev\…` — le mainteneur lui-même est sous Windows.
- Les git hooks bash devraient marcher sous Git Bash (Git for Windows embarque bash + jq via `pacman`, mais pas par défaut), mais ce n'est validé nulle part.
- `getting-started.md` ne fait que **38 lignes** et énumère un setup macOS-centric.

**Fichiers concernés.**
- [copier.yml:46-50](copier.yml:46) — `_message_after_copy` mentionne uniquement Linux/macOS
- [README.md:217](README.md:217) — installation
- Absence d'un `tests/smoke-test.windows.ps1` ou équivalent

**Severity.** High — mainteneur sous Windows, public cible (devs polyvalents) très probablement Windows.
**Impact.** Un dev Windows qui clone bute sur `jq`/`yq`, ne sait pas si Git Bash suffit, et le smoke-test ne lui dira pas pourquoi.
**Recommandation directionnelle.**
- Ajouter une section `Windows / Git Bash` dans `getting-started.md` (Chocolatey ou Scoop pour `jq`/`yq`, activation Git Bash, limite éventuelle).
- Ajouter `windows-latest` à la matrice CI principale, ou au moins un job dédié qui exécute `tests/smoke-test.sh` sous Git Bash.
- Décider explicitement : « WSL recommandé, Git Bash supporté best-effort, PowerShell non supporté » — et le dire.

---

### Axe 2 — Sécurité runtime des hooks

**Constat.** L'analyse code n'a trouvé **aucun vecteur d'exécution arbitraire** majeur :
- Aucun `eval`, aucun `bash -c "$var"`.
- `auto-worklog-flush.sh` et `auto-progress.sh` patchent les frontmatters via `awk -v today="$today"` — `-v` échappe correctement.
- `check-commit-features.sh:46-51` extrait le message via regex bash, le passe à `grep` literal sans interpolation.
- `auto-worklog-log.sh:45-46` utilise `jq -nc --arg` — JSON-safe.
- `features_matching_path` lit l'index JSON via `jq | @tsv` — pas d'injection possible via le contenu.

**Faiblesses identifiées :**

1. **`check-features.sh:119-132`** — validation des `touches:` :
   ```bash
   matches=( $t )            # word-split + glob non quotés
   if [[ ! -e "${matches[0]}" ]]
   ```
   `$t` vient de la lecture YAML du frontmatter. Si quelqu'un commit un `touches: ../../somewhere/*.sh` ou un pattern qui glob hors-projet, la *validation* glob bash s'exécute (pas dangereux : pas d'exec). Mais la sémantique « path doit exister dans le repo » n'est pas vérifiée — on accepte un `touches: /etc/passwd` du moment qu'il existe au moment du check.
   - **Pas exploité ailleurs** : `path_matches_touch` ([_lib.sh:104-124](template/.ai/scripts/_lib.sh.jinja:104)) fait du pattern matching pur, sans exec.
   - Risque réel : injection de **bruit** dans le contexte (un `touches: src/**` d'une feature volée d'un autre projet ferait matcher tout le repo et polluerait l'inventaire).

2. **Frontmatter scopable hors-projet.** `touches:` n'est pas validé contre :
   - Paths absolus (`/etc/...`)
   - Traversées (`../../...`)
   - URLs / globs ouverts
   Aucun helper `assert_within_repo` détecté.

3. **`SECURITY.md` est générique.** Il couvre la politique « pas de secrets dans worklogs » et l'avertissement `--trust` Copier, mais **ne dit rien** sur :
   - Risque de mesh importé (PR malveillante posant un `touches:` toxique)
   - Validation des bornes de `touches:`
   - Comportement attendu si une feature a un `id:` avec espaces / `;` / chemins relatifs (le code échappe via jq, mais ce n'est pas explicité)

**Fichiers concernés.**
- [template/.ai/scripts/check-features.sh.jinja:119](template/.ai/scripts/check-features.sh.jinja:119)
- [template/.ai/scripts/_lib.sh.jinja:104](template/.ai/scripts/_lib.sh.jinja:104)
- [SECURITY.md](SECURITY.md) (entier)

**Severity.** Low pour l'exécution arbitraire, medium pour la doc. **Pas de « ContextCrush » exploitable** d'après ce que j'ai vu : les chemins finissent par alimenter des outils JSON, pas des shells.
**Impact.** Importer un mesh externe (ex. cross-project federation future) reste un saut de confiance.
**Recommandation directionnelle.**
- Ajouter un check `path_in_repo` dans `_lib.sh` et l'appliquer dans `check-features.sh` et `path_matches_touch` (rejeter `..`, `/abs`, `~`).
- Étendre `SECURITY.md` avec une section « Trust model du feature mesh » : qui peut écrire, ce qui est validé, ce qui ne l'est pas.

---

### Axe 3 — Auto-progression spec → implement

**Constat.** Le design est **honnête et conservateur** :
- Heuristique unique : `progress.phase == spec` ET ≥1 fichier édité hors fiche/worklog ([auto-progress.sh:59-75](template/.ai/scripts/auto-progress.sh.jinja:59))
- Câblage **PostToolUse Write|Edit|MultiEdit** seulement (cf. `.claude/settings.json:39`) — la lecture (`Read`) ne flippe rien.
- Snapshot avant chaque transition dans `.ai/.progress-history.jsonl`, FIFO 50 entrées → `/aic undo` consommable.
- Transitions `implement → review` et `review → done` **manuelles** — ce qui évite les faux positifs vraiment coûteux (clôturer une feature sur la base d'un commit de doc).

**Faux positifs réalistes (faibles) :**
- Un prompt « ajoute une note dans le worklog avant de commencer » qui modifie un fichier hors-fiche par erreur basculerait `spec → implement`. Vrai mais bénin (undo dispo).
- Un `git checkout -- file.ts` n'est pas trappé par les hooks — pas un problème.

**Faiblesses :**
- **Le pre-commit (universel) et le Stop hook (Claude) partagent `auto-progress.sh`** — bien. Mais si un agent non-Claude édite et fait un commit avant le hook git, il y a un état transitoire où l'index n'est pas à jour. Mineur.
- `/aic undo` n'est pas couvert par `tests/smoke-test.sh` (l'audit factuel ne l'a pas trouvé). Une régression silencieuse est possible.
- Pas d'opt-out documenté côté projet : si tu veux désactiver l'auto-progression, tu dois supprimer la ligne dans `.claude/settings.json` ET commenter le hook `pre-commit`. La config `progress.auto_transitions.spec_to_implement` dans `.ai/config.yml` est explicitement marquée **placeholder non lue** ([README.md:683](README.md:683)). Promesse non tenue.

**Fichiers concernés.**
- [template/.ai/scripts/auto-progress.sh.jinja](template/.ai/scripts/auto-progress.sh.jinja)
- [template/.claude/settings.json.jinja](template/.claude/settings.json.jinja)

**Severity.** Low pour le moteur, medium pour le placeholder dans `config.yml`.
**Impact.** Le placeholder fait croire à un opt-out qui n'existe pas → effet de surprise.
**Recommandation directionnelle.**
- Soit supprimer les champs `progress.auto_transitions.*` du `config.yml` scaffoldé et n'y mettre que ce qui est lu, soit (préférable) câbler la lecture dans `auto-progress.sh` (5-10 lignes de yq).
- Ajouter au moins une assertion smoke-test couvrant `/aic undo` (créer une transition, l'annuler, vérifier `progress-history.jsonl` et le frontmatter).

---

### Axe 4 — Multi-agents : promesse vs réalité

**Constat.** Inégalité massive :

| Capacité runtime | Claude | Codex | Cursor | Gemini | Copilot |
|---|---|---|---|---|---|
| Shim racine (CLAUDE/AGENTS/GEMINI/...) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pre-turn reminder (UserPromptSubmit) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Features-for-path (PreToolUse) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Auto-worklog log (PostToolUse) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Auto-worklog flush (Stop) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Auto-progression spec→impl (immédiat) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Conventional commits + feat: mesh (git commit-msg) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Auto-progression au commit (git pre-commit) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Rebuild index post-checkout | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/aic-*` skills | ✅ | ❌ | ❌ | ❌ | ❌ |

Donc agents non-Claude :
- Lisent les rules/index/QUALITY_GATE comme du markdown (statique).
- Bénéficient des git hooks au moment du commit.
- N'ont **aucun feedback runtime** quand ils éditent (pas d'injection de la feature concernée, pas de logging worklog).

Le README dit pourtant ([README.md:5](README.md:5)) : « qu'un agent IA (Claude, Codex, Gemini, Copilot, Cursor) reprenne un projet mature avec **zéro ambiguïté** » — c'est vrai pour les rules, mais faux pour le **mesh feature in-flight**. Un Codex qui édite `src/auth/service.ts` ne saura jamais qu'une feature `back/auth-session` couvre ce path tant qu'il n'invoque pas `features-for-path.sh` à la main.

Cursor a un système natif de rules (`.cursor/rules/*.mdc`) mais le template ne l'exploite pas (pas de `.cursor/rules/<scope>.mdc.jinja` détecté dans la spec). Idem Codex avec `AGENTS.md` enrichi (le standard agents.md spec permet plus que le shim minimal actuel).

**Fichiers concernés.**
- [copier.yml:15-19](copier.yml:15) — exclusion `.claude` si claude pas activé
- [README.md:5,40-50](README.md:5) — promesses
- [template/AGENTS.md.jinja](template/AGENTS.md.jinja) (shim minimal)

**Severity.** High pour la communication, medium pour la fonctionnalité.
**Impact.** Utilisateurs Codex/Cursor reçoivent ~30% de la valeur tout en croyant en avoir 100%.
**Recommandation directionnelle.**
- Reformuler le pitch : « Claude-first runtime, multi-agent shims » au lieu de « multi-agents » tout court.
- Tableau honnête dans le README de ce qui est runtime-actif par agent.
- Ports possibles, par ordre de ROI :
  1. Cursor MDC : générer `.cursor/rules/<scope>.mdc` à partir des `.ai/rules/<scope>.md` (one-shot, pas de runtime).
  2. AGENTS.md enrichi : injecter dans le shim un résumé de l'index feature + scopes (statique mais utile).
  3. Codex/Gemini : pas d'API hooks équivalente, donc le git hook reste l'unique levier.

---

### Axe 5 — `adoption_mode=strict` réellement strict

**Constat.** Lecture de [copier.yml:39-41](copier.yml:39) :

```yaml
- "{% if adoption_mode == 'lite' or (not enable_ci_guard and adoption_mode != 'strict') %}.github/workflows{% endif %}"
- "{% if adoption_mode == 'lite' %}.githooks{% endif %}"
```

Différences concrètes :
| | `lite` | `standard` | `strict` |
|---|---|---|---|
| `.githooks` | ❌ | ✅ | ✅ |
| `.github/workflows` | ❌ | si `enable_ci_guard=true` | ✅ forcé |

Aucune autre divergence détectée dans `template/`. Donc `strict` ≡ `standard` + `enable_ci_guard=true` forcé. Le label `copier.yml:128` (« garde-fous renforcés, CI forcée ») oversell.

Le README est plus honnête ([README.md:562](README.md:562)) : « La portée actuelle de `strict` se limite à cette garantie CI. Les options renforcées […] sont en réflexion (voir roadmap P1). » — mais le `_message_after_copy` ne reflète pas ça.

**Options renforcées candidates** (pas une recommandation d'implémentation, juste les angles) :
- `doctor.sh --strict` câblé en CI (échec si une dépendance manque).
- `check-feature-coverage.sh --strict` par défaut (au lieu de warn).
- `check-features.sh` avec validation `touches:` plus dure (pas de paths absolus, pas de `..`).
- `commit-msg` avec scope obligatoire.
- `pre-commit` qui rebuild + commit l'index (plutôt que gitignored — décision controversée).
- Garder `.ai/config.yml` synchronisé avec le runtime (refus de placeholders).

**Risque breaking change.** Modeste : aujourd'hui `strict` couvre un sous-ensemble de projets très restreint. Renforcer maintenant n'a presque aucun blast radius (mais bumper minor avec note explicite dans CHANGELOG).

**Severity.** Medium (promesse non tenue mais sans casse).
**Impact.** Un utilisateur qui choisit `strict` croit avoir activé des barrières qui n'existent pas.

**Recommandation directionnelle.**
- Court terme : renommer le choix en `strict-ci` ou aligner le label sur la réalité.
- Moyen terme : implémenter au moins **deux** différences techniques sur les options listées (typiquement `coverage --strict` par défaut + `doctor --strict` en CI). Documenter la transition.

---

### Axe 6 — Cross-project & federation

**Constat.** Federation impossible aujourd'hui :
- Le JSON émis par `build-feature-index.sh` ([build-feature-index.sh:159-162](template/.ai/scripts/build-feature-index.sh.jinja:159)) n'a **ni `version`, ni `project_id`, ni `schema_version`**.
- `depends_on:` accepte des strings libres résolues exclusivement contre `FEATURES_DIR/$dep.md` ([check-features.sh:97-116](template/.ai/scripts/check-features.sh.jinja:97)) — donc impossible de référencer une feature externe sans casser le check.
- La roadmap P3 mentionne MCP comme piste de pilotage cross-project, ce qui est cohérent.

**Severity.** Low (c'est un manque, pas un bug ; en ligne avec la roadmap P3).
**Impact.** Pas de mesh fédéré aujourd'hui ; toute initiative MCP de pilotage demandera de versionner d'abord le format.
**Recommandation directionnelle.**
- Ajouter un champ `schema_version: 1` dans le JSON dès maintenant (no-cost, débloquera les futurs consommateurs).
- Ajouter un champ optionnel `project_id` dérivé du `project_name` dans `build-feature-index.sh`.
- Documenter dans `SECURITY.md` que le format n'est pas un contrat stable tant que `schema_version` n'est pas émis.

---

### Axe 7 — Coût tokens en pratique

**Constat.**
- `measure-context-size.sh` ([template/.ai/scripts/measure-context-size.sh.jinja](template/.ai/scripts/measure-context-size.sh.jinja)) lance **réellement** `pre-turn-reminder.sh --format=text` et compte les chars/tokens — bonne approche.
- Estimation : `chars/4` (borne basse) à `chars/3` (borne haute), ou tiktoken si dispo (`python3 -c "import tiktoken"`).
- Filtrage par `status` : `done|deprecated|archived` masqués sauf `AI_CONTEXT_SHOW_ALL_STATUS=1`.
- `AI_CONTEXT_FOCUS=<scope>` réduit à scope + voisins 1-hop (graph-aware).

**Faiblesses :**
- **Mesure le mesh courant, pas un fixture.** Sur le repo `ai_context` lui-même (mesh maigre), on n'a aucune donnée sur le pire cas (>100 features, scopes interconnectés). La phrase « Gain typique ~5× tokens sur mesh >100 features » du [README.md:706](README.md:706) n'a pas de mesure derrière.
- Pas de budget tokens en CI (`context.max_tokens_warn` est explicitement non lu).
- `reverse_deps` peut exploser sur un hub (« warning auto si une feature a >20 dépendants » ne semble câblé nulle part — à vérifier, l'audit factuel n'a pas confirmé).

**Severity.** Medium (la fonctionnalité existe mais n'est pas chiffrée).
**Impact.** Sur un projet en croissance, on ne sait pas quand intervenir.
**Recommandation directionnelle.**
- Créer un fixture `tests/fixtures/big-mesh/` avec ~100 features synthétiques + une assertion smoke-test qui mesure le rendu et bloque si > seuil.
- Câbler `context.max_tokens_warn` réellement (depuis `.ai/config.yml`) et émettre un warning stderr dépassement.

---

### Axe 8 — Tests & robustesse

**Constat.**
- `tests/smoke-test.sh` : ~28 étapes intégrées (copier copy, check-shims, build-index, features-for-path, ...). Solide pour la détection de régression d'intégration.
- **Aucun test unitaire** sur `path_matches_touch`, helper central qui décide qui voit quoi. Couvert seulement indirectement via `[7/28] features-for-path : silent if no feature`.
- `/aic undo` non couvert (cf. axe 3).
- Pas d'assertion sur l'edge-case `touches: ../escape/path` — le comportement n'est pas testé.

**Severity.** Medium.
**Impact.** Un refactor sur `path_matches_touch` peut introduire un bug subtil non détecté.
**Recommandation directionnelle.**
- Ajouter `tests/unit/test-path-matches-touch.sh` ou (mieux) une suite [bats](https://github.com/bats-core/bats-core) couvrant : globs simples, `**`, paths absolus, `..`, chars spéciaux, casse de feature avec `id:` exotique.
- Ajouter une assertion d'undo dans le smoke-test.

---

### Axe 9 — DX / friction d'adoption

**Constat.**
- `docs/getting-started.md` : 38 lignes. **Court.** Couvre prérequis → scaffold → 10 next steps. Suffisant pour un dev expérimenté qui connaît Copier.
- Les messages d'erreur échantillonnés sont **actionnables** :
  - `check-features.sh:57` : `✗ $f : frontmatter manquant`
  - `check-commit-features.sh:65-70` : énumère les types autorisés + montre le reçu.
  - `build-feature-index.sh:116` : `⚠️ $rel : status='$status' hors enum ($STATUS_ENUM)`
- `doctor.sh` existe et est positionné comme diagnostic non-destructif.

**Faiblesses :**
- Pas de troubleshooting Windows.
- 9 skills `/aic-*` (5 exposés + 4 internes) à mémoriser. Le tableau dans [README.md:629-643](README.md:629) est utile mais le palier d'entrée reste élevé.
- Le `_message_after_copy` (10 étapes !) est **dense**. Un primo-utilisateur va lire en diagonale et oublier `git config core.hooksPath`.

**Severity.** Low/medium.
**Impact.** « Mise en route en <30 min » est plausible pour un sénior, douteux pour un junior.
**Recommandation directionnelle.**
- Garder `_message_after_copy` à 3 étapes critiques + lien vers `docs/getting-started.md` pour le reste.
- Considérer un script `bash .ai/scripts/setup.sh` qui fait `git config core.hooksPath` + `chmod +x .githooks/*` + `check-shims` + `check-features` en un seul appel.

---

## Roadmap suggérée

### P0 — Honnêteté de la communication (1-2 jours)

Critères d'acceptation :
- [ ] README + AGENTS.md : tableau « capacités runtime par agent », fin de l'ambiguïté multi-agent.
- [ ] `copier.yml:128` : label `strict` corrigé (« garde-fous renforcés » → « CI forcée »).
- [ ] `getting-started.md` : section Windows / Git Bash / WSL avec niveau de support clair.
- [ ] `SECURITY.md` : section « Trust model du feature mesh » (qui valide quoi, ce qui n'est pas validé).

### P1 — Combler les promesses techniques creuses (3-5 jours)

Critères d'acceptation :
- [ ] `.ai/config.yml` : `progress.auto_transitions.spec_to_implement` consommé par `auto-progress.sh` (vraie option d'opt-out).
- [ ] `.ai/config.yml` : `context.max_tokens_warn` consommé par `pre-turn-reminder.sh`.
- [ ] `adoption_mode=strict` : implémenter ≥2 différences techniques (suggestions : `coverage --strict` par défaut + `doctor --strict` en CI).
- [ ] `feature-index.json` : ajouter `schema_version: 1` + `project_id`.

### P2 — Robustesse (1 semaine)

Critères d'acceptation :
- [ ] CI matrix : ajouter `windows-latest` (au moins en best-effort, alerte non-bloquante).
- [ ] Tests unitaires `path_matches_touch` (10+ cas, dont edge cases).
- [ ] Validation `touches:` : refuser paths absolus, `..`, `~`. Helper `assert_within_repo` partagé.
- [ ] Smoke-test : assertion `/aic undo`.
- [ ] Fixture `tests/fixtures/big-mesh/` avec budget tokens en CI.

---

## Hors scope identifié

À ne **pas** fixer maintenant :

- **Federation cross-project / MCP** — Roadmap P3, prématuré tant que `schema_version` n'est pas émis. Préparer le terrain (P1) suffit.
- **Refonte des skills `/aic-*`** — la surface est large mais cohérente, et l'utilisateur final n'invoque que 5 skills. Pas de gain immédiat à consolider.
- **Wrapper `ai-context.sh`** — surface en plus mais coût ≈ 0. À reconsidérer si on ajoute des sous-commandes.
- **Auto-progression `implement → review`** — la version conservatrice actuelle est bonne, les faux positifs d'une heuristique plus agressive coûteraient cher en confiance.
- **Site docs (mkdocs)** — roadmap P2, pas critique tant que les fichiers racine sont à jour.
- **`learning log` automatique (P3)** — risque de pollution mesh, à laisser dormir.

---

## Synthèse honnête

Le template est **plus mûr que ne le laisse penser le numéro de version (v0.11.0)** : design conservateur, sécurité runtime sans vecteur exploitable identifié, smoke-test sérieux, dog-fooding visible.

Les vraies dettes sont **du côté communication** (multi-agents, strict, Windows) et **de petits placeholders qui mentent** (`config.yml`). Aucune dette architecturale lourde — pas de réécriture nécessaire.

Le **bon angle d'attaque** pour la prochaine itération est P0 (honnêteté) + 2-3 quick wins de P1, puis évaluer si la fédération MCP devient prioritaire avant ou après la P2 robustesse.
