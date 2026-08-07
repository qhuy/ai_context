---
pilot_id: "2026-08-07-retour-ux-restitution"
status: "active"
source: "Retour UX utilisateur multi-projets (session 2026-08-07)"
scope_primary: "workflow"
created_at: "2026-08-07"
updated_at: "2026-08-07"
active_item: "R1"
active_question: "GO sur le plan d'exécution chantier A (2 lots : workflow puis core, HANDOFF au milieu) ?"
next_hint: "Plan produit le 2026-08-07 (aic-dev-plan, voir conversation + section Design). Si GO : étape 0 (isoler worklog dirty) puis lot 1 scope workflow (fiche agent-behavior contrat-first → response-style condensé → output style → skills ship/review → contrat parity R5). Ensuite HANDOFF core (AGENTS.md, reminder, settings outputStyle, copier.yml défaut R5, smoke-test 28d). R3 → aic-diagnose après."
---

# Pilot 2026-08-07-retour-ux-restitution — Réactiver le contrat de restitution

## Intention

Traiter le retour UX utilisateur sur les projets consommateurs du framework :
la structure (mesh, cadrage, scope) fonctionne, mais la **restitution** échoue —
réponses confuses, sans synthèse, données techniques imprécises, suppositions
persistantes, et divergence de style entre Claude et Codex.

## Résultat attendu

- Un contrat de restitution **opérant** (réellement chargé) pour Claude et Codex, sans réintroduire le coût de contexte qui l'a fait démoter.
- Les causes de la persistance des suppositions identifiées et traitées.
- Preuve : avant/après sur un même prompt dans les deux outils.

## Contexte prouvé (2026-08-07)

- Le contrat existe : `.ai/agent/response-style.md` (510 mots ≈ 770 tokens) — couvre synthèse, séparation constat/décision/action/evidence, récap adaptatif, phrases interdites.
- Démoté du Pack A par `ea1adac` (2026-05-04, « perf(core): alléger le contexte initial des agents »). Depuis : « `.ai/agent/*` optionnel, jamais Pack A » (`.ai/index.md`). Seuls `aic-diagnose` (toujours) et `aic-frame` (si style explicite) le chargent ; `aic-ship`/`aic-review` ne le chargent pas (rg 2026-08-07).
- Le reminder par tour (`.ai/reminder.md`, 86 mots ≈ 130 tokens, hooks UserPromptSubmit Claude + Codex) ne contient aucune règle de restitution.
- Mécanismes vérifiés (docs officielles, 2026-08-07) :
  - Output styles Claude Code : actifs (commande standalone retirée v2.1.91, feature via `/config` ou `outputStyle` dans settings ; fichiers `.claude/output-styles/*.md`, frontmatter `keep-coding-instructions`). Canal officiellement recommandé pour le format de réponse. System prompt, une fois par session, prompt-caché. <https://code.claude.com/docs/en/output-styles.md>
  - CLAUDE.md/AGENTS.md : chargés une fois par session, prompt-cachés. <https://code.claude.com/docs/en/memory.md>
  - `additionalContext` (UserPromptSubmit) : coût par tour ; interaction cache non documentée explicitement.
- `enable_codex_hooks` : `default: false`, question posée seulement si `codex` sélectionné (copier.yml:240-243) ; option introduite le 2026-07-06 (`1be149e`). Projets utilisateur : aucune activation explicite dont il se souvienne ⇒ hooks Codex absents ⇒ Codex y tourne **sans** le rappel par tour (dont la règle « aucune supposition ») et **sans** le gate Stop, que Claude a — candidat causal fort pour R3 et R4.
- Update consommateur documenté : `copier update --conflict=rej` (docs/upgrading.md:9) ; la question est re-posée avec l'ancienne réponse en défaut, ou forçable via `--data enable_codex_hooks=true`.

## Carte des sujets

| ID | Sujet | Statut | Scope probable | Route | Preuve attendue |
|---|---|---|---|---|---|
| R0 | Points forts : mesh, cadrage, qualité livrée | done | — | — | acté (retour utilisateur) |
| R1 | Réponses confuses, sans synthèse, parfois incompréhensibles | validated | workflow | fix (chantier A : réactiver le contrat) | contrat chargé en flux normal + avant/après sur un même prompt |
| R2 | Données techniques imprécises (forme et fond) | validated | workflow | fusionné chantier A : volet « précision technique » du contrat | règle explicite (fichier:ligne, valeurs exactes, sorties datées) |
| R3 | Suppositions persistantes malgré la règle injectée | triage | workflow/quality | diagnose | causes classées avec evidence par agent et par projet |
| R4 | Claude et Codex ne formulent pas pareil | validated | workflow | fusionné chantier A : injection agent-agnostique | sorties comparables sur un même prompt dans les deux outils |
| R5 | Défaut `enable_codex_hooks=false` : Codex tourne sans reminder par tour ni gate Stop | validated | workflow | décision actée (intégrée chantier A) | copier.yml + contrat `codex-hooks-parity` mis à jour |

## Design proposé (chantier A) — en validation

| Étage | Canal Claude | Canal Codex | Coût estimé | Rôle |
|---|---|---|---|---|
| 1. Contrat condensé (~10 lignes) | Output style `.claude/output-styles/` + `outputStyle` settings | Bloc dans AGENTS.md (shim) | ~0 / tour (session, caché) | Le « à quoi ressemble une bonne réponse » |
| 2. Ancre anti-dérive (1 ligne) | `.ai/reminder.md` (hook existant) | idem (hook partagé) | ~25-30 tokens / tour | Combattre la dérive en session longue |
| 3. Contrat complet + exemple avant/après | `response-style.md` chargé par aic-ship/aic-review/aic-diagnose | idem (`.agents/skills`) | on-demand | Profondeur près de la clôture |

Contraintes : source unique du condensé dans `response-style.md` (rendus vérifiés par les checks de parité — à cadrer) ; étage 2 débrayable si le coût par tour se révèle inutile après test avant/après.

Écarté : LLM-judge hooks (interdits — `codex-hooks-parity`), fine-tuning, gros reminder par tour.

### Compatibilité Codex (vérifiée 2026-08-07)

- Étage 1 : AGENTS.md est l'entrée **native** de Codex — c'est déjà le canal des hard rules actuelles. Pas d'équivalent output style → le contrat vit en contexte projet, pas en system prompt (asymétrie de position assumée, compensée par l'étage 2). Inversion notable : c'est Claude qui ne lit AGENTS.md que via l'import CLAUDE.md (`.ai/native-context-support.tsv` : claude=pending, issue #6235).
- Étage 2 : contrat UserPromptSubmit Codex **vérifié** (`codex-hooks-parity`, doc officielle OpenAI 2026-07-06 : stdout ajouté comme contexte développeur ; même script `pre-turn-reminder.sh --format=text`). **Contrainte : opt-in** — `.codex/hooks.json` généré seulement si `enable_codex_hooks=true` (défaut `false`) et couche `.codex/` trustée au premier lancement. Sans opt-in, Codex n'a que les étages 1+3.
- Étage 3 : skills Codex générés sous `.agents/skills/aic-*` si `codex` sélectionné (copier.yml:115) ; parité tenue par `check-skills-parity.sh` (resserrée en v1.0.1).

Hypothèses restantes : `keep-coding-instructions: true` préserve le comportement code par défaut (à tester) ; portage de l'output style dans le template copier ; état de `enable_codex_hooks` sur les projets de l'utilisateur (à demander).

## Question active

Contexte affiché :

- R3 (suppositions) attend son diagnostic — route `aic-diagnose`, après cadrage du chantier A.

Question à traiter maintenant :

- Valider le design 3 étages ci-dessus pour cadrer le chantier A (fiche `workflow/agent-behavior`).

## Décisions actées

| Date | Item | Décision | Raison | Suite |
|---|---|---|---|---|
| 2026-08-07 | R0 | Acté, aucun suivi | Retour positif utilisateur | — |
| 2026-08-07 | R1+R2+R4 | Fusion en chantier A « réactiver + durcir le contrat de restitution » | Même cause racine (contrat démoté par `ea1adac`), même surface (fiche workflow/agent-behavior) | Design 3 étages en validation |
| 2026-08-07 | R1 | Réactivation validée par l'utilisateur (« réactiver oui ») | Contrainte : ne pas (trop) alourdir le contexte | Design d'injection à valider |
| 2026-08-07 | R3 | Séparé du chantier A, route diagnose | La règle existe et est injectée : problème d'efficacité, pas d'absence | Lancer aic-diagnose après cadrage chantier A |
| 2026-08-07 | R1+R2+R4 | **GO utilisateur sur le design 3 étages** | Coût quasi nul vérifié (étage 1 caché, étage 2 ~30 tokens/tour débrayable) | HANDOFF workflow + cadrage chantier A |
| 2026-08-07 | R5 | Recommandation agent : générer `.codex/hooks.json` dès que codex est sélectionné (symétrie avec `.claude/settings.json`) | Le consentement réel est le trust prompt Codex au premier lancement ; le défaut actuel casse la parité silencieusement (prouvé par le retour UX) | Arbitrage utilisateur en cours |
| 2026-08-07 | R5 | **Validé utilisateur** (« go ») : bascule du défaut actée, question copier conservée pour l'opt-out | Alignement sur la politique hooks Claude | Intégré au cadrage chantier A |

## Handoffs

```text
HANDOFF (confirmé par le GO utilisateur du 2026-08-07)
  from_scope: pilotage (session)
  to_scope: workflow
  status: prêt — cadrage à lancer après arbitrage R5
  files_touched: [.docs/pilots/2026-08-07-retour-ux-restitution.md]
  pending: [cadrage chantier A sur .docs/features/workflow/agent-behavior.md — étages 1-3 + décision R5]
  risks: [drift interne entre les 3 rendus du condensé si la source unique n'est pas outillée ; surfaces multi-scope probables (AGENTS.md shim, reminder, copier.yml) à trancher au cadrage]
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| R1+R2+R4 | Chantier A — design injection 3 étages | agent + utilisateur | design en validation | avant/après sur même prompt, 2 outils |
| R3 | aic-diagnose sur l'inefficacité de la règle evidence | agent | en attente | matrice causes → evidence |

## Validation de clôture

- Tous les items sont `done`, `dropped`, `handoff` ou explicitement reportés.
- Chantier A livré avec preuve avant/après dans les deux outils.
- R3 diagnostiqué avec causes prouvées et fix routé.

## Next hint

Reprise : lire ce registre, puis — si design validé — HANDOFF scope workflow et cadrage du chantier A sur `.docs/features/workflow/agent-behavior.md` (étages 1-3, source unique du condensé, checks de parité). Ensuite router R3 vers `aic-diagnose`.
