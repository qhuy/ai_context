# PROJECT_STATE — ai_context

**But** : template `copier` qui industrialise le setup AI context (multi-agent : Claude / Codex / Cursor / Gemini / Copilot) d'un nouveau projet.
**Remote** : [github.com/qhuy/ai_context](https://github.com/qhuy/ai_context) (public)
**Local** : chemin de développement local, non versionné.
**Dernière version publiée** : v0.14.0 — « Migrations post-Copier, index progressifs, overlay registre de scopes & discipline de preuve » (voir [CHANGELOG.md](CHANGELOG.md))

> Ce fichier est un **point d'entrée rapide** — pas l'historique détaillé (→ [CHANGELOG.md](CHANGELOG.md)), pas l'architecture du code (→ le code et [README.md](README.md)), pas la migration (→ [MIGRATION.md](MIGRATION.md)). Pour les audits historiques clos, [docs/archive/](docs/archive/).

## Notes mainteneur

- 2026-05-07 : ce repo a servi de cible distincte pour un run supervisé depuis `ai_debate`, avec chargement prouvé de ses règles locales.
- 2026-06-29 : audit stratégique (multi-agents) + remédiation. Backlog tracé dans [`.docs/frames/2026-06-28-audit-strategique-remediation.md`](.docs/frames/2026-06-28-audit-strategique-remediation.md).
- 2026-07-24 : pilotage autopilot (`.docs/pilots/2026-07-23-analyse-fonctionnelle-generale.md`) — release v0.14.0, dégraissage de ce fichier (P5 : suppression de la section Architecture redondante avec le code, collapse des rappels de version au profit d'un pointeur CHANGELOG).

## Comment reprendre le dev

1. Ouvrir Claude Code dans le dossier local du dépôt `ai_context`.
2. Lire [CHANGELOG.md](CHANGELOG.md) — les dernières breaking/nouveautés.
3. Lancer le smoke-test : `bash tests/smoke-test.sh` (28 étapes, attendu `✅ PASS`).
4. Consommer le template : `copier copy gh:qhuy/ai_context ./mon-projet`. Mettre à jour : `cd mon-projet && copier update --conflict=rej` (cible le dernier tag par défaut ; `--vcs-ref=HEAD` pour suivre `main`, voir `docs/upgrading.md`).
5. Dogfooder le repo source après évolution du template (pas de `.copier-answers.yml`, jamais de `copier update` sur lui-même) :
   - preview : `bash .ai/scripts/dogfood-update.sh`
   - apply : `bash .ai/scripts/dogfood-update.sh --apply`
   - drift : `bash .ai/scripts/check-dogfood-drift.sh`

## État actuel (v0.14.0)

- **Cockpit de migrations post-Copier** — `aic migrate plan/all --apply` orchestre `okf-type` puis `okf-indexes` avec préflight (`.rej`, `.copier-answers.yml` manquant) ; la migration legacy `aic migrate` reste hors batch.
- **Index Markdown progressifs** — `<docs_root>/features/index.md` + `index.md` par scope, générés déterministes et versionnables ; check warn-only vN / `--strict` prêt pour vN+1.
- **Overlay registre de scopes + `aic-onboard`** — `.ai/project/<scope>/index.md` par app/couche, skill `aic-onboard` (modes init/sync/migrate auto-détectés).
- **Discipline de preuve transverse** (`workflow/evidence-discipline`) — toute affirmation prouvée ou étiquetée Hypothèse ; câblée dans `aic-review`/`aic-diagnose`/`aic-pilot`/`aic-frame`.
- **Hooks Codex natifs opt-in** (`enable_codex_hooks`) — reminder par tour + gate Stop de fraîcheur, parité documentée avec Claude.
- **Provider VCS configurable** (`vcs_provider`) — `git`/`tfvc`/`auto`/`none` ; TFVC best-effort, non testé end-to-end.
- **Gate Stop de fraîcheur documentaire** (`workflow/stop-turn-doc-gate`) — bloque la fin de tour si du code couvert change sans mise à jour de fiche/worklog ; échappatoire `AIC_DOC_GATE=off`.
- **Profil strict OKF Phase 0** — champ `type` optionnel (warn-only), backfill via `aic migrate okf-type --apply`.
- **Élagage des shims commoditisés par AGENTS.md** — Copilot/Cursor confirmés natifs ; kill criterion vérifiable (`check-agent-native-context.sh --require-confirmed`).
- **Reprise de cadence de tags** — `copier update` sans `--vcs-ref` cible de nouveau un tag à jour.
- **Tags versionnés** : `v0.7.2` → `v0.14.0`.

Historique complet des versions précédentes (v0.7 → v0.13) : [CHANGELOG.md](CHANGELOG.md).

## Roadmap — pistes ouvertes

**P1 — stabilisation runtime**
- 🚧 Consommer `context.show_statuses` et `context.default_focus` (aujourd'hui via env vars `AI_CONTEXT_*`).
- Dog-fooding runtime : les workflows CI source restent volontairement hors synchronisation car plus stricts que le rendu downstream.

**P2 — confort UX**
- Pipelines CI hors GitHub Actions (Azure DevOps, GitLab).
- Profil `scope_profile=custom` interactif (liste CSV `custom_scopes` + jinja loop).
- Graphe Mermaid auto-généré du mesh (depuis l'index JSON).
- Site docs statique (mkdocs-material) sourcé depuis README/CHANGELOG/MIGRATION/skills.

**P3 — extensions**
- MCP (Model Context Protocol) côté agents pour pousser le contexte au lieu d'injecter par hook.
- Learning log automatique : Stop hook append patterns récurrents à `.ai/memory/<scope>.md` avec gate de validation manuelle.
- Benchmarks publics (gain tokens / temps de hook) sur projets de référence — premiers runs maintainer-only réalisés, voir `docs/benchmarks/reports/`.
- Repo démo externe consommant `ai_context` à jour.

## Règle anti-doc-drift

Quand une fonctionnalité change, les fichiers suivants **doivent** être revus dans le même chantier (rappelée dans `CONTRIBUTING.md`, bloquée par `tests/smoke-test.sh` quand applicable) :

- `README.md` (référence utilisateur)
- `CHANGELOG.md` (`Unreleased` regroupé par release future)
- `PROJECT_STATE.md` (état + roadmap)
- `MIGRATION.md` (si la migration utilisateur change)
- `copier.yml` (questions + `_message_after_copy`)
- `template/.claude/skills/**/SKILL.md.jinja` + `workflow.md.jinja` (workflows skill alignés)
- `tests/smoke-test.sh` (au moins une assertion)
- Les deux versions des scripts si applicable : `.ai/scripts/<name>` (dogfooding) **et** `template/.ai/scripts/<name>.jinja` (template). Une divergence accidentelle est un bug. `bash .ai/scripts/check-runtime-template-mirror.sh` (advisory) signale un déséquilibre staged sur `.ai/scripts/*.sh` et `.ai/workflows/*.md`.

## Points d'attention

- **Hook Bash `git commit`** — extraction heuristique du message (`-m "..."`, heredoc). Fallback sur `.githooks/commit-msg`.
- **Globs `touches:`** — sémantique centralisée dans `_lib.sh` (`path_matches_touch`) ; utiliser `touches_shared:` pour les surfaces transverses afin d'éviter que des globs trop larges augmentent le bruit de freshness (voir `check-touches-breadth.sh`).

## Tests

- `bash tests/smoke-test.sh` — suite principale end-to-end, requiert `copier` dans le PATH (`pip install --user copier`).
- `bash tests/unit/*.sh` — tests unitaires ciblés (matching `touches:`, freshness, dogfood-drift, etc.), tous lancés par la CI.
- CI GitHub Actions (`enable_ci_guard: true` par défaut) — `check-shims` + `check-features` + `check-ai-references`. Matrix `template-smoke-test.yml` étendue à `windows-latest` (best-effort, non-bloquant).

## Quick refs

- Repo : https://github.com/qhuy/ai_context
- Copier docs : https://copier.readthedocs.io/
- AGENTS.md standard : https://agents.md
