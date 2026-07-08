# Worklog — core/agents-md-shim-canonical

## 2026-07-07 — fix P2 : pairing skills basé sur disque plutôt qu'AGENTS_SELECTED (CI-12)

- Constat (second audit du delta CI-12 non commité) : `require_skill_pairs` dépendait de la seule présence disque des dossiers (`[[ -d ".agents/skills" && -d ".claude/skills" ]]`), jamais de `AGENTS_SELECTED`. Un projet qui désélectionne codex après un scaffold Claude+Codex garde un résidu `.agents/skills/*` (copier update ne supprime pas les fichiers retirés du rendu) que check-shims validait comme "pairé" au lieu de signaler un résidu de migration — trou de couverture pour la nouvelle fonctionnalité de pairing skills, dans la même classe que CI-12.
- Fix : `.ai/scripts/check-shims.sh` (+ template) — nouveau helper `agent_selected()`, `require_skill_pairs` dérivé de `agent_selected "codex" && agent_selected "claude"`, et détection explicite du résidu (root présent mais agent non sélectionné → `ko` dédié, plutôt que validation silencieuse).
- Test ajouté : `tests/unit/test-check-shims-dynamic-agents.sh` (cas `repo_residue` : agents=["claude"] avec résidu `.agents/skills/aic-demo` complet sur disque → doit échouer avec le message de résidu, et `.claude/skills` ne doit pas être rapporté "pairé").
- Validation : `bash tests/unit/test-check-shims-dynamic-agents.sh` PASS ; `bash .ai/scripts/check-shims.sh` PASS (aucune régression sur ce repo) ; `diff .ai/scripts/check-shims.sh template/.ai/scripts/check-shims.sh.jinja` → aucun écart hors variables Jinja attendues ; `bash tests/smoke-test.sh` PASS.

## 2026-06-28 — création (aic-frame, item C1)
- Fiche créée suite au cadrage `aic-frame` de l'item C1 (frame de remédiation 2026-06-28).
- Arbitrages tranchés par l'utilisateur : (a) nouvelle fiche dédiée (vs extension de `aic-surface-canonical`) ; (b) modèle **import `@AGENTS.md` + fallback tailored** (symlink rejeté).
- Phase `spec` : cadrée, non implémentée. Gate d'implémentation explicite = vérifier empiriquement le support `@import` par agent (Claude d'abord, puis Cursor/Gemini/Copilot) AVANT tout code.
- HANDOFF : pitch → `product/readme-positioning` ; génération Copier → `core/template-engine`.

## 2026-06-29 — gate @import PASSE
- Verif 4 plateformes (Claude via claude-code-guide, autres web). Claude @path OK + AGENTS.md natif (a confirmer) ; Gemini @path OK ; Cursor/Copilot pas d'import fiable MAIS lisent AGENTS.md nativement.
- Modele retenu : AGENTS.md base neutre ; CLAUDE.md/GEMINI.md = @AGENTS.md + lignes agent ; Cursor/Copilot = lecture native (pas de shim requis) ou tailored minimal.
- Phase spec -> implement. Etape suivante : rendre AGENTS.md neutre + convertir shims + etendre check-shims.

## 2026-06-29 — import model livre
- AGENTS.md neutralise (base) ; CLAUDE.md = MUST-read + @AGENTS.md + pointeur Claude ; template/GEMINI.md.jinja = @AGENTS.md. Cursor/Copilot laisses tailored (fallback).
- Checks verts : check-shims (AGENTS 15 l. / CLAUDE 7 l.), check-dogfood-drift (parite), smoke-test.
- Reste avant DONE : note migration CHANGELOG/docs/upgrading (forme des shims change a copier update) ; check-shims dynamique par agents actives ; confirmer #34235.
- Fichiers : AGENTS.md, CLAUDE.md, template/AGENTS.md.jinja, template/CLAUDE.md.jinja, template/GEMINI.md.jinja

## 2026-06-30 — check-shims : verrou de self-suffisance d'AGENTS.md (init. core/agents-md-native-collapse-path, P2)
- `check-shims.sh` (surface possédée ici) : nouvelle assertion exigeant les hard rules inline dans `AGENTS.md` — échoue si le shim est réduit à un simple pointeur. Verrouille la précondition du chemin de collapse (AGENTS.md seul suffit aux règles).
- Runtime + `.jinja` (parité). Test dédié `tests/unit/test-agents-md-self-sufficient.sh`. check-shims réel PASS (nouvelle ligne « AGENTS.md auto-suffisant »), dogfood-drift aligné.
- Initiative portée par `core/agents-md-native-collapse-path` (P2, pilot `2026-06-30-ze-solution`) ; recoupe le follow-up « check-shims dynamique par agents activés » listé ci-dessus (non traité ici).

## 2026-07-03 — check-shims dynamique par agents activés
- Intent : fermer le follow-up C1 restant — `check-shims.sh` ne doit plus vérifier seulement `AGENTS.md` + `CLAUDE.md` en dur.
- Fichiers/surfaces : `.ai/scripts/check-shims.sh`, `template/.ai/scripts/check-shims.sh.jinja`, `tests/unit/test-check-shims-dynamic-agents.sh`.
- Décision : lire `agents` depuis `.copier-answers.yml` quand il existe ; fallback dogfood/anciens scaffolds sur les shims présents ; `codex` et `cursor` n'ajoutent pas de root shim dédié.
- Validation : `bash -n` runtime/template, `shellcheck -S error`, `bash tests/unit/test-check-shims-dynamic-agents.sh`, `bash .ai/scripts/check-shims.sh`, rendu Copier ciblé `claude+gemini+copilot`, `bash .ai/scripts/check-dogfood-drift.sh`, `bash .ai/scripts/check-features.sh --no-write`, freshness worktree strict et `bash tests/smoke-test.sh` PASS.
- Next : confirmer séparément la lecture native d'`AGENTS.md` par Claude (#34235) pour décider si `CLAUDE.md` devient optionnel.

## 2026-07-03 — follow-up #34235 transféré au registre natif
- `core/agents-md-native-collapse-path` porte désormais `.ai/native-context-support.tsv` et `check-agent-native-context.sh --require-confirmed <agent>`.
- Impact ici : `check-shims` reste propriétaire des shims activés ; la décision de rendre `CLAUDE.md` optionnel ne vit plus dans cette fiche mais dans le registre natif.

## 2026-07-03 — DONE : clôture du modèle de shims dérivés
- Intent : fermer la fiche C1 après livraison du modèle `AGENTS.md` base + shims dérivés et transfert du kill criterion Claude.
- Fichiers/surfaces : fiche/worklog `core/agents-md-shim-canonical`.
- Evidence : `check-feature-docs --strict core/agents-md-shim-canonical` PASS, `check-shims` PASS, `check-dogfood-drift` PASS ; smoke complet déjà passé dans le commit `9affa45` qui a branché le registre natif.
- Décision : Doc Impact Decision C — fiche feature mise à jour, aucun changement runtime dans ce commit de clôture.
- Risques : pas de breaking change, pas de migration de données, pas d'impact sécurité/auth/tenancy ; compatibilité arrière inchangée.
- Next : aucune action immédiate ; rouvrir seulement si le modèle de shims ou le contrat `.copier-answers.yml` change.

## 2026-07-06 — shim Copilot opt-out (P2, commit ②)
- Intent : cesser de générer par défaut un shim commoditisé par le standard AGENTS.md (Copilot coding agent le lit nativement — registre `confirmed`), sans casser Copilot Chat/review (flag compat).
- Fichiers/surfaces : `copier.yml` (question `enable_copilot_shim` défaut false + `_exclude` conditionnel), `.ai/scripts/check-shims.sh` (+ miroir jinja, identique) — helper `native_confirmed()` sur le registre TSV, skip du shim absent seulement si confirmed ; `tests/unit/test-check-shims-dynamic-agents.sh` (3 nouveaux cas : confirmed+absent=PASS, pending+absent=FAIL, compat présent=validé), `tests/smoke-test.sh` (étape [28e/28]).
- Décision : le mécanisme est générique par agent (piloté par le registre), pas un cas spécial copilot — si claude passe un jour `confirmed`, le même chemin s'ouvre pour CLAUDE.md sans retoucher check-shims.
- Validation : test dynamique PASS, shellcheck PASS, check-shims auto PASS ; smoke complet au commit.
- Next : commit ③ — retrait du shim Cursor redondant (protocol-reminder.mdc).

## 2026-07-06 — retrait du shim Cursor redondant (P2, commit ③)
- Intent : supprimer `protocol-reminder.mdc` (alwaysApply dupliquant les hard rules d'AGENTS.md, que Cursor lit nativement — registre confirmed) ; ne garder que les `.mdc` scopés par globs, seule valeur ajoutée Cursor.
- Fichiers/surfaces : `template/.cursor/rules/protocol-reminder.mdc.jinja` supprimé ; `copier.yml` (`_exclude` : `.cursor` non généré si aucun scope back/front) ; `tests/smoke-test.sh` (bloc [28b] : protocol-reminder absent asserté, cursor+minimal → pas de `.cursor`) ; `check-dogfood-drift.sh` (sanity du profil fullstack-cursor) ; `docs/variables.md` ; `template/README_AI_CONTEXT.md.jinja` (ligne Cursor).
- Validation : smoke complet + drift au commit.
- Next : commit ④ — docs (README table Honnêteté runtime, MIGRATION.md, CHANGELOG).

## 2026-07-06 — docs alignées, chantier P2 shims clos (commit ④)
- Intent : refléter l'élagage dans la doc utilisateur et donner le chemin de migration.
- Fichiers/surfaces : `README.md` (table Honnêteté runtime — ligne « Entrée racine » par agent, conclusion), `MIGRATION.md` (§ « Shims Copilot / Cursor — élagage AGENTS.md natif » : conséquences du copier update, flag compat, rollback), `CHANGELOG.md`.
- Honnêteté préservée : CLAUDE.md/GEMINI.md explicitement inchangés (claude pending au registre) ; la nuance Copilot Chat/review est documentée partout où le flag apparaît.
- Validation : smoke complet + check-shims + check-features + drift au commit.

## 2026-07-06 15:08 — auto
- Fichiers modifiés :
  - .ai/scripts/check-shims.sh
  - tests/unit/test-check-shims-dynamic-agents.sh

## 2026-07-06 — fix post-review BLOQUANT : miroir check-shims dé-templatisé
- Constat (review adversariale, reproduit empiriquement par le reviewer) : le commit du shim Copilot opt-out avait recopié le runtime PAR-DESSUS le miroir jinja — perte de `{{ project_name }}` et de la boucle `{%- for scope in scopes %}` du CANONICAL. Conséquence : un consommateur backend/fullstack perdait la vérification de ses règles de scope (backend + `rm .ai/rules/back.md` → check-shims PASS à tort). Aucun test ne l'attrapait (le drift ne rend que le profil minimal, dont les scopes coïncidaient avec les valeurs codées en dur).
- Fix : miroir restauré depuis main puis ajouts `native_confirmed` portés manuellement (aucun jinja dans les ajouts) ; parité vérifiée par `check-dogfood-drift` (rendu minimal == runtime). Régression smoke [28f/28] ajoutée : rendu backend → project_name attendu dans le script + suppression de back.md → FAIL exigé.
- Leçon de discipline (miroirs) : ne JAMAIS cp runtime → template sans avoir prouvé l'identité préalable ; le garde « diff avant copie » avait échoué silencieusement dans une chaîne `;`.

## 2026-07-06 — fix post-review : la garantie registre devient réelle chez les consommateurs
- Constat (review, reproduit) : les scaffolds n'avaient AUCUN `.copier-answers.yml` (pas de fichier `{{ _copier_answers }}` dans le template) → check-shims retombait sur la détection par présence de fichiers, et un shim absent rendait l'agent indétectable : « pending = shim requis » ne tenait que dans les tests unitaires ; la 1re assertion smoke [28e] était vacueuse (chemin registre jamais exercé).
- Fix : nouveau `template/{{ _copier_conf.answers_file }}.jinja` (contenu canonique copier) — chaque scaffold porte ses réponses, check-shims lit les agents réels, et `copier update` fonctionne sans `repair-copier-metadata`. Smoke [28e] durci : answers file exigé + message « copilot : shim dédié absent » exigé dans la sortie (chemin registre prouvé). Fuites de dossiers temp corrigées sur les chemins d'échec ([28d]/[28e], relance diagnostique sous set -e).
- Registre : doublons d'agent désormais rejetés par `check-agent-native-context.sh` (+ miroir, parité vérifiée par diff avant édition) — un downgrade ajouté en fin de fichier ne peut plus être masqué par une vieille ligne confirmed (native_confirmed est any-match). Cas de test ajouté.

## 2026-07-06 — fix post-review ③ : docs alignées sur le comportement réel
- MIGRATION.md : sémantique `copier update` corrigée sur preuve empirique (review) — l'update ne supprime JAMAIS un chemin `_exclude` ; copilot-instructions.md reste en place non géré (suppression manuelle documentée) ; protocol-reminder.mdc n'est supprimé que si `.cursor` reste géré (profils back/front), nettoyage manuel documenté sinon.
- docs/upgrading.md : « Copilot garde un shim » / « le shim doit exister » remplacés par le contrat registre (confirmed → skip explicite, pending → requis).
- Fiche : section Contrats + description frontmatter alignées sur le comportement livré.
## 2026-07-06 — couverture incidente (workflow/evidence-discipline)
- `AGENTS.md` (+ `template/AGENTS.md.jinja`) : hard rule « Aucune supposition : prouver (code lu, commande, doc) ou marquer Hypothèse » ; « Shim lean » condensé en 1 ligne — AGENTS.md reste à 15 lignes (limite MAX_LINES), auto-suffisance préservée (test PASS). Validation portée par `workflow/evidence-discipline`.

## 2026-07-07 — audit 2026-07-07
- Changement : `check-shims.sh` ajoute une section `Skills ↔ workflows` qui vérifie la parité `.agents/skills` ↔ `.claude/skills`, la présence de `SKILL.md`/`workflow.md`, et l'existence des références `.ai/workflows/*.md`.
- Test : `test-check-shims-dynamic-agents` reste vert sur repos partiels sans skills.
- Validation ciblée : `check-shims`, `test-check-shims-dynamic-agents`.
