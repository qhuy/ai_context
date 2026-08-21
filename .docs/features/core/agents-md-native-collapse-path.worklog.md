# Worklog — core/agents-md-native-collapse-path

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-06-30 — création (pilot ze-solution, P2, après HANDOFF product→core)

- Fiche créée via `aic-pilot` (pilot `.docs/pilots/2026-06-30-ze-solution.md`, item P2).
- Posture tranchée = **hedge** : préparer l'optionnalité de l'indirection `.ai/index.md`, sans la retirer ni pivoter AGENTS.md en source de contenu.
- Cadre : AGENTS.md auto-suffisant = entrée + protocole lean minimal inline (pas de duplication de `.ai/index.md`) ; respect strict de l'invariant `aic-surface-canonical` (`.ai/` source unique).
- Distinct de `agents-md-shim-canonical` qui a mis l'indirection hors-périmètre (« chantier séparé »).
- Phase : spec. Décision ouverte : comment opérationnaliser concrètement le kill_criterion #34235 (veille/check).
- Prochaine étape : définir le contenu inline minimal d'AGENTS.md + le signal kill_criterion.

## 2026-06-30 — incrément 1 : self-suffisance d'AGENTS.md verrouillée (check-shims)

- Constat : runtime `AGENTS.md` et `template/AGENTS.md.jinja` portent DÉJÀ les hard rules inline (self-suffisants). L'incrément = **verrou anti-régression** plutôt que réécriture.
- `check-shims.sh` : nouvelle assertion — `AGENTS.md` doit contenir un bloc `Hard rules` inline, sinon `ko` (« self-suffisance collapse-path, pas un simple pointeur »). Précondition du collapse rendue testable : un agent lisant AGENTS.md seul connaît les règles.
- Runtime + `.jinja` (parité dogfood vérifiée). Test `tests/unit/test-agents-md-self-sufficient.sh` : cas AGENTS.md auto-suffisant → OK, cas pointeur nu → échec + message.
- Surface `check-shims.sh` = possédée par `core/agents-md-shim-canonical` (worklog mis à jour) ; initiative = cette fiche (P2).
- Invariant `aic-surface-canonical` (`.ai/` source unique) préservé : AGENTS.md reste l'ENTRÉE, pas le contenu.
- **HANDOFF `quality/smoke-test`** : brancher `test-agents-md-self-sufficient.sh` dans le smoke — non fait ici (mono-scope core), même pattern que P3.
- Reste : opérationnaliser le kill_criterion #34235 (veille/signal par agent) ; doc migration warn downstream.

## 2026-07-03 — incrément 2 : migration warn + smoke handoff
- Intent : fermer les follow-ups livrables hors kill criterion : doc migration downstream et branchement du test self-sufficiency dans le smoke.
- Fichiers/surfaces : `docs/upgrading.md`, `CHANGELOG.md`, `tests/smoke-test.sh`, fiche/worklog core.
- Décision : documenter un mode prudent — `AGENTS.md` auto-suffisant, shims dérivés vérifiés par agents activés, mais `CLAUDE.md` conservé tant que #34235 n'est pas opérationnalisé.
- HANDOFF `quality/smoke-test` exécuté : `test-agents-md-self-sufficient.sh` devient l'étape `[0h1/28]`.
- Validation : test ciblé PASS, `bash tests/smoke-test.sh` PASS complet, freshness worktree stricte PASS.
- Next : opérationnaliser le kill_criterion #34235 (signal/veille par agent) avant toute optionnalité réelle de `CLAUDE.md`.

## 2026-07-03 — DONE : kill criterion opérationnalisé
- Intent : matérialiser le signal #34235 pour empêcher un collapse implicite de `CLAUDE.md`.
- Fichiers/surfaces : `.ai/native-context-support.tsv`, `template/.ai/native-context-support.tsv`, `.ai/scripts/check-agent-native-context.sh`, `template/.ai/scripts/check-agent-native-context.sh.jinja`, `tests/unit/test-agent-native-context.sh`, `tests/smoke-test.sh`, `docs/upgrading.md`, `CHANGELOG.md`.
- Décision : le statut externe du 2026-07-03 reste `claude=pending` (issues #34235/#6235 ouvertes) ; le collapse devient possible seulement si le registre passe `confirmed` et si `check-agent-native-context.sh --require-confirmed claude` passe.
- HANDOFF `quality/smoke-test` exécuté : `test-agent-native-context.sh` devient l'étape `[0h3/28]`.
- Validation : test ciblé PASS, dogfood drift PASS, `bash tests/smoke-test.sh` PASS complet ; freshness stricte à relancer avant commit.
- Next : aucune action core immédiate ; veille future = mettre à jour le registre si Anthropic confirme le support natif.

## 2026-07-06 — copilot + cursor confirmés au registre (P2, commit ①)
- Intent : matérialiser le kill criterion pour copilot et cursor avant l'élagage de leurs shims dédiés (chantier P2 d'ANALYSE.md).
- Fichiers/surfaces : `.ai/native-context-support.tsv` (+ miroir template, identique).
- Evidence : docs.github.com/copilot (« the nearest AGENTS.md file in the directory tree will take precedence » — coding agent ; Chat/review IDE restent sur copilot-instructions.md) ; cursor.com/docs/context/rules (« AGENTS.md […] Place it in your project root as an alternative to .cursor/rules ») ; agents.md liste les deux. Vérifié le 2026-07-06.
- Validation : `check-agent-native-context.sh` PASS ; `--require-confirmed copilot` PASS ; `--require-confirmed cursor` PASS ; `--require-confirmed claude` échoue toujours (attendu) ; `tests/unit/test-agent-native-context.sh` PASS.
- Next : commit ② — shim Copilot opt-out (`core/agents-md-shim-canonical`).

## 2026-07-06 — couverture incidente (fix post-review, core/agents-md-shim-canonical)
- `check-agent-native-context.sh` (+ miroir) : doublons d'agent rejetés (protège native_confirmed, any-match) ; `tests/unit/test-agent-native-context.sh` : cas doublon. Validation portée par `core/agents-md-shim-canonical`.

## 2026-07-08 — couverture audit strict
- Surfaces couvertes touchées dans le delta d'audit strict : `.ai/native-context-support.tsv` et `template/.ai/native-context-support.tsv`.
- Rattachement documentaire pour le gate `check-feature-freshness --staged --strict`; aucun nouveau changement du contrat propre de cette fiche.
- Validation : gate ship relancée avant commit.

## 2026-08-21 — réouverture : Copilot Code Review lit AGENTS.md

- Source officielle vérifiée le 2026-08-21 : GitHub Changelog du 2026-06-18,
  `https://github.blog/changelog/2026-06-18-copilot-code-review-agents-md-support-and-ui-improvements/`,
  annonce la disponibilité générale et la lecture automatique du `AGENTS.md` racine par Copilot
  Code Review.
- Source officielle complémentaire vérifiée le 2026-08-21 :
  `https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions`
  distingue les instructions repository-wide `.github/copilot-instructions.md` des instructions
  agent `AGENTS.md`, et précise que Code Review lit les deux catégories depuis la branche de tête.
- Décision : conserver `copilot=confirmed`, rafraîchir `checked_at`/`evidence` et remplacer la note
  périmée par le contrat réel. Le shim opt-in garde une valeur comme canal de consignes spécifiques
  Copilot ; il n'est plus présenté comme requis parce que la review ignorerait `AGENTS.md`.
- HANDOFF `core/template-engine` / `core/agents-md-shim-canonical` : reformuler l'aide de
  `enable_copilot_shim` sans modifier son défaut, son rendu ni le comportement d'upgrade.
- Validation prévue : test du registre rendu discriminant sur date/preuve/note, test de surface,
  rendu avec opt-in, drift dogfood.

## 2026-08-21 — implémentation validée, passage en review

- Registre runtime et miroir alignés : `copilot=confirmed`, preuve GitHub Changelog officielle et
  `checked_at=2026-08-21` ; la note sépare explicitement `AGENTS.md` natif du canal Copilot dédié.
- Aide et documentation alignées sans changer le défaut ni le rendu : `copier.yml`,
  `docs/variables.md`, `MIGRATION.md` et `docs/upgrading.md`.
- Tests ciblés : `test-agent-native-context.sh` PASS ; registre PASS ;
  `--require-confirmed copilot` PASS ; `--require-confirmed claude` exit 2 attendu ;
  `test-surface-manifest.sh` PASS ; parité TSV et `git diff --check` PASS.
- Reste avant clôture : rendu Copier avec shim opt-in, drift dogfood et gate globale.

## 2026-08-21 12:09 — DONE

### Evidence

- Build : rendu Copier multi-profils via `bash .ai/scripts/check-dogfood-drift.sh` ✅
- Tests : `bash tests/unit/test-agent-native-context.sh` et `bash tests/smoke-test.sh` ✅
- Contrats externes : Copilot confirmé ; `--require-confirmed claude` reste bloqué avec exit 2 attendu ✅
- Gate : fraîcheur staged stricte, mesh, docs strictes et couverture 118/118 ✅

### Résumé livré

- La preuve officielle Copilot Code Review est datée et verrouillée par test.
- `AGENTS.md` reste l'entrée native commune ; le shim opt-in devient un canal spécifique Copilot.
- Aucune valeur par défaut, logique de rendu ou condition d'upgrade n'est modifiée.
- Les guides de migration et l'aide Copier portent le même contrat.

### Commit suggéré

`docs(core): actualiser le support AGENTS.md de Copilot Code Review`
