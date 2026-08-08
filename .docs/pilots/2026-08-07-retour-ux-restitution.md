---
pilot_id: "2026-08-07-retour-ux-restitution"
status: "active"
source: "Retour UX utilisateur multi-projets (session 2026-08-07)"
scope_primary: "workflow"
created_at: "2026-08-07"
updated_at: "2026-08-07"
active_item: "R3"
active_question: "Lancer le diagnostic R3 (aic-diagnose) ? La preuve avant/après R1/R4 reste à consigner en parallèle ; côté Claude, l'ancre a été observée live en session le 2026-08-07."
next_hint: "Chantier A livré (a154772/408193a) et corrections post-review intégrées : parité mécanique du condensé, dogfood de l'output style, limites de shims ciblées, métriques exactes et docs cohérentes. Reprise : R3 → aic-diagnose ; en parallèle, comparer le même prompt dans Claude/Codex sur un projet mis à jour et consigner la preuve R1/R4."
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

## Contexte initial prouvé (avant livraison, 2026-08-07)

- Au démarrage du chantier, le contrat existait dans `.ai/agent/response-style.md` (510 mots ≈ 770 tokens) — synthèse, séparation constat/décision/action/evidence, récap adaptatif, phrases interdites.
- Il avait été démoté du Pack A par `ea1adac` (2026-05-04, « perf(core): alléger le contexte initial des agents »). À l'ouverture du pilotage, seuls `aic-diagnose` (toujours) et `aic-frame` (si style explicite) le chargeaient ; `aic-ship`/`aic-review` ne le chargeaient pas (`rg`, 2026-08-07).
- Le reminder initial (`.ai/reminder.md`, 86 mots ≈ 130 tokens, hooks UserPromptSubmit Claude + Codex) ne contenait aucune règle de restitution.
- Mécanismes vérifiés (docs officielles, 2026-08-07) :
  - Output styles Claude Code : actifs (commande standalone retirée v2.1.91, feature via `/config` ou `outputStyle` dans settings ; fichiers `.claude/output-styles/*.md`, frontmatter `keep-coding-instructions`). Canal officiellement recommandé pour le format de réponse. System prompt, une fois par session, prompt-caché. <https://code.claude.com/docs/en/output-styles.md>
  - CLAUDE.md/AGENTS.md : chargés une fois par session, prompt-cachés. <https://code.claude.com/docs/en/memory.md>
  - `additionalContext` (UserPromptSubmit) : coût par tour ; interaction cache non documentée explicitement.
- À l'ouverture du pilotage, `enable_codex_hooks` avait `default: false` (option introduite le 2026-07-06, `1be149e`). L'absence d'activation explicite mémorisée sur les projets utilisateur impliquait probablement des hooks Codex absents — candidat causal fort pour R3 et R4. Le défaut a depuis été basculé à `true` pour les nouveaux scaffolds ; les réponses Copier déjà enregistrées restent inchangées.
- Update consommateur documenté : `copier update --conflict=rej` (docs/upgrading.md:9) ; la question est re-posée avec l'ancienne réponse en défaut, ou forçable via `--data enable_codex_hooks=true`.

## Carte des sujets

| ID | Sujet | Statut | Scope probable | Route | Preuve attendue |
|---|---|---|---|---|---|
| R0 | Points forts : mesh, cadrage, qualité livrée | done | — | — | acté (retour utilisateur) |
| R1 | Réponses confuses, sans synthèse, parfois incompréhensibles | review | workflow | fix livré (`a154772` + `408193a`) | ancre observée live en session Claude le 2026-08-07 ; avant/après 2 outils restant |
| R2 | Données techniques imprécises (forme et fond) | done | workflow | livré : volet précision technique du contrat (`a154772`) | section « Précision technique » + exemple avant/après dans response-style.md |
| R3 | Suppositions persistantes malgré la règle injectée | triage | workflow/quality | diagnose (prochain item actif) | causes classées avec evidence par agent et par projet |
| R4 | Claude et Codex ne formulent pas pareil | review | workflow | fix livré : même condensé aux 3 étages des deux côtés | avant/après même prompt dans les deux outils, à consigner ici |
| R5 | Défaut `enable_codex_hooks=false` : Codex tourne sans reminder par tour ni gate Stop | done | workflow | livré (`408193a`) : default true, opt-out conservé | smoke [28d/28] inversé PASS ; manifeste de surface MAJ, bump MINOR acté |

## Design retenu et livré (chantier A)

| Étage | Canal Claude | Canal Codex | Coût estimé | Rôle |
|---|---|---|---|---|
| 1. Contrat condensé (~10 lignes) | Output style `.claude/output-styles/` + `outputStyle` settings | Bloc dans AGENTS.md (shim) | ~0 / tour (session, caché) | Le « à quoi ressemble une bonne réponse » |
| 2. Ancre anti-dérive (1 ligne) | `.ai/reminder.md` (hook existant) | idem (hook partagé) | +146 caractères, ~37–49 tokens / tour | Combattre la dérive en session longue |
| 3. Contrat complet + exemple avant/après | `response-style.md` chargé par aic-ship/aic-review/aic-diagnose | idem (`.agents/skills`) | on-demand | Profondeur près de la clôture |

Contraintes : source unique du condensé dans `response-style.md` ; égalité stricte des blocs AGENTS/output style vérifiée par `check-shims`, alignement runtime/template couvert par `check-dogfood-drift`. L'étage 2 reste débrayable si le coût par tour se révèle inutile après test avant/après.

Écarté : LLM-judge hooks (interdits — `codex-hooks-parity`), fine-tuning, gros reminder par tour.

### Compatibilité Codex (vérifiée 2026-08-07)

- Étage 1 : AGENTS.md est l'entrée **native** de Codex — c'est déjà le canal des hard rules actuelles. Pas d'équivalent output style → le contrat vit en contexte projet, pas en system prompt (asymétrie de position assumée, compensée par l'étage 2). Inversion notable : c'est Claude qui ne lit AGENTS.md que via l'import CLAUDE.md (`.ai/native-context-support.tsv` : claude=pending, issue #6235).
- Étage 2 : contrat UserPromptSubmit Codex **vérifié** (`codex-hooks-parity`, doc officielle OpenAI 2026-07-06 : stdout ajouté comme contexte développeur ; même script `pre-turn-reminder.sh --format=text`). `.codex/hooks.json` est généré par défaut quand `codex` est sélectionné depuis le 2026-08-07 ; `enable_codex_hooks=false` l'exclut et la couche `.codex/` doit toujours être trustée au premier lancement. Les projets existants conservent leur réponse Copier enregistrée.
- Étage 3 : skills Codex générés sous `.agents/skills/aic-*` si `codex` sélectionné (copier.yml:115) ; parité tenue par `check-skills-parity.sh` (resserrée en v1.0.1).

À vérifier : effet live de `keep-coding-instructions: true` sur une session Claude réelle ; état de `enable_codex_hooks` dans chaque projet utilisateur existant. Le portage Copier et les validations statiques de l'output style sont livrés.

## Question active

Contexte affiché :

- Le chantier A est livré et durci après review ; R3 (suppositions) attend son diagnostic, route `aic-diagnose`.

Question à traiter maintenant :

- Lancer le diagnostic R3 ; recueillir en parallèle la preuve avant/après R1/R4 sur le même prompt dans Claude et Codex.

## Décisions actées

| Date | Item | Décision | Raison | Suite |
|---|---|---|---|---|
| 2026-08-07 | R0 | Acté, aucun suivi | Retour positif utilisateur | — |
| 2026-08-07 | R1+R2+R4 | Fusion en chantier A « réactiver + durcir le contrat de restitution » | Même cause racine (contrat démoté par `ea1adac`), même surface (fiche workflow/agent-behavior) | Livré ; R1/R4 restent en review pour la preuve live |
| 2026-08-07 | R1 | Réactivation validée par l'utilisateur (« réactiver oui ») | Contrainte : ne pas (trop) alourdir le contexte | Injection 3 étages livrée |
| 2026-08-07 | R3 | Séparé du chantier A, route diagnose | La règle existe et est injectée : problème d'efficacité, pas d'absence | Lancer aic-diagnose après livraison du chantier A |
| 2026-08-07 | R1+R2+R4 | **GO utilisateur sur le design 3 étages** | Étage 1 session ; étage 2 mesuré à +146 caractères (~37–49 tokens/tour), débrayable | HANDOFF workflow/core exécuté ; implémentation livrée |
| 2026-08-07 | R5 | Recommandation agent : générer `.codex/hooks.json` dès que codex est sélectionné (symétrie avec `.claude/settings.json`) | Le consentement réel est le trust prompt Codex au premier lancement ; l'ancien défaut cassait la parité silencieusement | Arbitrage obtenu puis implémenté |
| 2026-08-07 | R5 | **Validé utilisateur** (« go ») : bascule du défaut actée, question copier conservée pour l'opt-out | Alignement sur la politique hooks Claude | Intégré au cadrage chantier A |

## Handoffs

```text
HANDOFF (confirmé par le GO utilisateur du 2026-08-07)
  from_scope: pilotage (session)
  to_scope: workflow
  status: terminé — cadrage et lots workflow/core livrés (a154772, 408193a)
  files_touched: [.docs/pilots/2026-08-07-retour-ux-restitution.md, .docs/features/workflow/agent-behavior.md]
  pending: [aucun sur ce handoff ; preuves live R1/R4 et diagnostic R3 restent au registre]
  risks: [activation à vérifier sur les projets consommateurs ayant conservé enable_codex_hooks=false]
```

## Suivi d'exécution

| Item | Action liée | Owner | Statut | Validation |
|---|---|---|---|---|
| R1+R2+R4 | Chantier A — injection 3 étages | agent + utilisateur | implémentation livrée ; R1/R4 en review | avant/après sur même prompt, 2 outils |
| R3 | aic-diagnose sur l'inefficacité de la règle evidence | agent | item actif | matrice causes → evidence |

## Validation de clôture

- Tous les items sont `done`, `dropped`, `handoff` ou explicitement reportés.
- Chantier A livré avec preuve avant/après dans les deux outils.
- R3 diagnostiqué avec causes prouvées et fix routé.

## Next hint

Reprise : lancer R3 via `aic-diagnose`. En parallèle, mettre à jour un projet consommateur Claude+Codex, vérifier/activer `enable_codex_hooks`, exécuter le même prompt dans les deux outils et consigner la preuve R1/R4 ici.
