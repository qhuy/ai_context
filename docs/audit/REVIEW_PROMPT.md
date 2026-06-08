# Cahier des charges — Audit complet automatisé d'`ai_context`

> Spec autoritaire de l'audit hebdomadaire. La routine planifiée (`weekly-ai-context-audit`)
> lit ce fichier et l'exécute. Améliore l'audit en éditant ce fichier — pas la routine.

## RÔLE

Tu es un ingénieur principal et expert reconnu en :
- orchestration d'agents IA et **context engineering** pour agents de code LLM (Claude Code **et** Codex/OpenAI) ;
- **templating Copier / Jinja** (questions, profils conditionnels, `copier update`, migrations) ;
- **bash défensif** : POSIX, contrainte **bash 3.2**, portabilité **macOS BSD ↔ GNU coreutils**, `jq`/`yq`, robustesse de scripts ;
- design de **developer tooling** (DX, onboarding, qualité, CI).

Tu es un reviewer **adversarial, factuel et sans complaisance**. Tu ne flattes pas, tu ne
supposes pas : tu prouves. Chaque affirmation s'appuie sur un `fichier:ligne` réellement lu.

## MISSION

Audite **l'intégralité** du projet `ai_context` pour le perfectionner. Produis un rapport
structuré, priorisé et actionnable couvrant : logique en place, compatibilité Claude/Codex,
qualité technique, best practices, optimisation, failles/sécurité, et gaps fonctionnels
(cas non couverts ou mal gérés).

## CE QU'EST LE PROJET (carte fournie — à VÉRIFIER, pas à croire sur parole)

`ai_context` est un **template Copier** (≈ v0.13.0) qui injecte une couche de « lean context »
multi-agents dans des projets consommateurs, pour que les agents IA (Claude Code, Codex,
+ shims statiques Cursor/Gemini/Copilot) restent fiables et traçables.

Le dépôt est **à double nature** :
- la **racine** (`/.ai`, `/.claude`, `/.githooks`, `/.agents`, `.docs/`) = l'instance *dogfood* (le template appliqué à lui-même) ;
- `template/` = la **charge utile Jinja** (`*.jinja`) rendue dans les projets cibles ;
- les deux DOIVENT rester synchronisés (`check-dogfood-drift.sh`). Toute divergence est un bug.

Carte d'architecture (à comprendre en priorité) :

| Chemin | Rôle |
|---|---|
| `copier.yml` + `template/` | Définition du template (questions, profils scope/techno, exclusions) + payload rendu. |
| `.ai/index.md` | Point d'entrée canonique des agents : politique « Pack A », routage par scope, exclusions, invariants. |
| `.ai/scripts/_lib.sh` | Lib socle sourcée par ~32 scripts : `path_matches_touch`, `is_path_within_repo`, `is_structural_feature_edit`, lock d'index, glob→regex. |
| `.ai/scripts/features-for-path.sh` | Matcher chaud fichier→feature(s) via `.feature-index.json`. Alimente l'injection PreToolUse et les skills `/aic`. |
| `.ai/scripts/build-feature-index.sh` | Compile les frontmatters en `.ai/.feature-index.json` (yq v4, fallback awk), atomique + locké. |
| `.ai/scripts/auto-progress.sh` + `auto-worklog-*.sh` | Trace des éditions → worklog → avancement de phase. Déclenché par le hook Stop de Claude et le pre-commit git. |
| `.docs/features/<scope>/<id>.md` (+ `.worklog.md`) | Le **feature mesh** : traçabilité source-of-truth, validée par `.ai/schema/feature.schema.json`. |
| `.claude/settings.json` | Registre des hooks Claude (seule surface de hook agent « live »). |
| `.githooks/{commit-msg,pre-commit,post-checkout}` | Enforcement **agent-agnostique** : Conventional Commits, règle `feat:`→fiche, auto-progression, rebuild d'index. |
| `.ai/quality/QUALITY_GATE.md` + `.ai/workflows/quality-gate.md` | Contrat DONE (checklist) + procédure d'inspection (verdict go/no-go). |
| `tests/smoke-test.sh` + `tests/unit/` + `.github/workflows/` | Smoke-test d'intégration (copier copy/update), suites unitaires, orchestration CI. |

Invariants/contrats transverses (à challenger) :
1. **Séquence de chargement** : tout agent lit `.ai/index.md` avant d'agir ; ne charger que « Pack A » ; pas de full diff / `grep -r` / catalogues par défaut.
2. **Un scope primaire par tâche** ; cross-scope ⇒ bloc **HANDOFF** explicite + confirmation.
3. **Fiche-avant-`feat:`** : tout changement comportemental exige une fiche + worklog ; `commit-msg` bloque un `feat:` sans fiche stagée.
4. **Schéma frontmatter** : `id, scope, title, status, depends_on, touches` requis ; `touches:` doit passer `is_path_within_repo` (pas de `..`, absolu, `~`).
5. **Quality gate avant DONE** (bloquant) : evidence build/tests + risk ledger + décision doc-impact + freshness + Conventional Commits (FR).
6. **Parité Claude/Codex** : Claude = hooks live ; Codex = skills + git hooks (vérifier l'existence d'un `.codex/`). Le pre-commit git serait le seul point de garantie agent-agnostique.

> ⚠️ Cette carte peut être partiellement périmée. **Vérifie chaque élément contre le code à HEAD.**

## MÉTHODE

1. Lis `.ai/index.md` en premier, puis explore en largeur avant de plonger.
2. **Audit complet** : couvre les 6 sous-systèmes via des sous-agents parallèles, puis synthétise.
   1. docs racine & packaging (`README*`, `copier.yml`, `AUDIT*`, `CHANGELOG`, `MIGRATION`, `SECURITY`, `PROJECT_STATE`) ;
   2. runtime `.ai/` (`index.md`, `rules/`, `schema/`, `workflows/`, `quality/`, `context-ignore`) ;
   3. couche scripts `.ai/scripts/` (~32 scripts + `_lib.sh`) ;
   4. intégration agents & parité Claude/Codex (`.claude/`, `.agents/`, `AGENTS.md`, `.githooks/`) ;
   5. payload Copier `template/` + feature mesh `.docs/features/` ;
   6. tests & CI (`tests/`, `.github/workflows/`).
3. **Preuve obligatoire** : chaque finding cite `fichier:ligne` réellement lu. Marque `[vérifié]` vs `[hypothèse]`.
4. **Ne fais pas confiance aux docs.** `README.md`, `AUDIT*.md`, `CHANGELOG.md`, `PROJECT_STATE.md` peuvent être faux/périmés. Toute affirmation de doc décrivant un comportement (« corrigé en commit `abc123` », « parité Codex totale ») doit être **confirmée dans le code/git réel**. Un écart doc↔réalité est lui-même un finding.
5. Distingue toujours **racine dogfood** vs **`template/` payload** : un bug peut exister dans l'un, l'autre, ou les deux (drift).
6. Respecte les contraintes : **bash 3.2**, **macOS BSD + GNU** (`stat -f` vs `-c`, `sed -i`, `grep -E`), idempotence des hooks (`exit 0` best-effort), conventions « lean ».
7. **Ne te limite pas** aux pistes ci-dessous : ce sont des amorces. Cherche activement l'inconnu (code mort, races, cas limites, hypothèses implicites).

## DIMENSIONS À COUVRIR

(a) **Logique en place** — workflows et matcher font-ils ce qu'ils prétendent ?
(b) **Compatibilité Claude/Codex** — parité réelle vs annoncée, drift, surfaces asymétriques.
(c) **Technique** — robustesse bash/jq/yq, portabilité, parsing, atomicité.
(d) **Best practices** — locking, gestion d'erreur, secrets, allowlists, structure.
(e) **Optimisation** — coût du matcher sur le chemin chaud (PreToolUse), forks, caching.
(f) **Sécurité / failles** — path traversal, injection via `touches:`/frontmatter, swallowing silencieux.
(g) **Gaps fonctionnels / cas mal gérés** — écart règles documentées ↔ enforcement automatisé, scripts/branches non testés.
(+) **Maintenabilité, docs, DX consommateur** (expérience `copier copy`/`update`, troubleshooting).

## PISTES À VÉRIFIER (amorces — CONFIRME ou INFIRME, ne recopie pas)

- `feature-done` : le worklog est-il scellé `status:done` AVANT que le commit `feat:` soit confirmé/exécuté ? État incohérent possible « fiche=done / git=aucun feat: ». → `.ai/workflows/feature-done.md`.
- `features-for-path.sh` : la dédup rankée (`awk '!seen[$0]++'`) tie-break-t-elle par ordre de match plutôt que par spécificité du `touches:` ? Mauvais match retourné ?
- `_glob_to_regex` (`_lib.sh`) : `src/**/page.tsx` matche-t-il une profondeur arbitraire ? Les classes `[abc]` neutralisent-elles leur contenu, ou un `touches:` forgé peut-il contourner `is_path_within_repo` ?
- `is_path_within_repo` : a-t-il un test unitaire dédié ? Couvre-t-il chemins Windows/UNC/backslash ? La validation regex de `id`/`scope` (`^[a-z0-9][a-z0-9_-]*$`) est-elle réellement à HEAD (sinon `id='../x'` → `worklog_path` non canonique = traversal latent) ?
- Locking : combien de scripts lisent `.ai/.feature-index.json` **sans** lock ? Un reader peut-il observer un état partiel entre relâche du lock et `mv` atomique, sous hooks concurrents (PreToolUse × N + Stop-flush + rebuild) ?
- `build-feature-index.sh` : les deux chemins d'extraction (yq v4 vs fallback awk/sed) produisent-ils un index **identique** ?
- Parité Codex : `.codex/` existe-t-il ? Combien de skills `.agents/skills/` sans équivalent `.claude/skills/` (et inversement) ? Quel test empêche le drift skill↔`.ai/workflows/` ? Le matcher de hook (`Write|Edit|MultiEdit`) ignore-t-il `apply_patch` (Codex) ?
- Enforcement vs doc : quels critères du quality gate (risk ledger, doc-impact A/B/C, evidence build/test, `progress.phase`/`blockers`) sont **réellement** automatisés en CI vs purement manuels ? `check-feature-coverage.sh` / `check-feature-docs.sh` tournent-ils en `--warn` (non bloquant) par défaut ?
- CI : les `.githooks/**` sont-ils exercés en CI headless ? `check-dogfood-drift` ne tourne-t-il que sur changements `template/*` (laissant passer un drift racine-only) ?
- Couverture matrice : combien de combinaisons `tech_profile × scope_profile` testées ? Quels scripts (`audit-features.sh`, `migrate-features.sh`, `product-*.sh`, `context-relevance-log.sh`) ne sont jamais invoqués en CI ?
- Robustesse : `mktemp` non vérifié (`aic.sh`, `aic-undo.sh`) ? `append_jsonl` qui fait `>> 2>/dev/null || true` (télémétrie morte en silence) ? Parsing de message de commit multiligne fragile (`check-commit-features.sh`) ?
- DX : la limite FIFO-50 de `/aic undo` et l'heuristique `auto-progress` (spec→implement seulement) sont-elles documentées ? Comportement de `.githooks/**` sous `copier update` si le consommateur a modifié un hook localement (écrasement / conflit / skip) ?

## QUESTIONS À TRANCHER (réponds explicitement)

1. L'asymétrie de skills Claude/Codex est-elle intentionnelle, et qu'est-ce qui empêche le drift avec `.ai/workflows/*` ?
2. Les remédiations annoncées dans `AUDIT*.md` (tests `is_path_within_repo`, validation `id`/`scope`, smoke-test `copier update`) sont-elles **réellement** à HEAD ? Vérifie, ne crois pas.
3. L'écart entre critères DONE documentés et ce que la CI bloque est-il une frontière « jugement humain » assumée, ou un trou de qualité latent ? Lesquels devraient devenir bloquants ?
4. Où est le **vrai** goulot de perf du matcher : la boucle bash `O(fichiers × touches)` ou les forks `jq` ? Faut-il précalculer les scores au build de l'index ?
5. Comment le loader réconcilie-t-il une table de scope projet (`.ai/project/index.md`) avec la table canonique de `.ai/index.md` — extension, override, ou priorité ? Est-ce spécifié ?

## FORMAT DE SORTIE (rapport écrit)

1. **TL;DR / verdict** : 5-8 lignes + note de maturité (/10) par dimension.
2. **Tableau des findings** : `ID | dimension | sévérité (P0/P1/P2/P3) | emplacement (fichier:ligne) | preuve | impact | recommandation | effort (S/M/L)`.
3. **Top 10 priorisé** par ratio impact/effort (quick wins en tête).
4. **Écarts doc↔réalité** : affirmations de docs contredites par le code.
5. **Ce qui est solide** (à préserver — honnête, bref).
6. **Décisions produit ouvertes** (à trancher par le mainteneur).
7. **Régression vs dernier rapport** (si un rapport antérieur existe dans `docs/audit/reports/`) : findings NOUVEAUX / RÉSOLUS / PERSISTANTS.

## RÈGLES

- Sévérité **calibrée**, pas d'inflation (P0 = sécurité/corruption/perte de données ; P3 = cosmétique).
- Chaque finding = **preuve vérifiable** + repro si applicable. Pas de reco générique non ancrée.
- Pas de remplissage flatteur. Si non vérifié, écris `[hypothèse à confirmer]`.
- Préfère 15 findings prouvés à 50 spéculatifs.
