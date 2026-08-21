# Worklog — core/session-injection-dedup

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-08-20 — création + livraison de la dédup par session

- **Constat d'origine** (analyse des transcripts, session `670708a8`, 2529 tours, 197M tokens effectifs) : le poste « reminders & hooks » pèse 46,3 % du coût total, devant les lectures de code. `features-for-path.sh`, câblé en `PreToolUse Write|Edit|MultiEdit`, produit 248 injections de fiches pour seulement **48 payloads distincts** (~87 % de duplication, ~404 500 tokens de doublon). Pire cas : un payload de 2 589 tokens réinjecté 70 fois.
- **Cause** : `seen_feature_key` (`.ai/scripts/features-for-path.sh:108`) ne déduplique qu'à l'intérieur d'un seul appel du script. Aucune mémoire entre appels d'une même session.
- **Vérification préalable de l'API hook** (aucune supposition) : `session_id` n'était utilisé nulle part dans le repo et non documenté. Capture d'un vrai payload `PreToolUse` en instrumentant temporairement le script puis en déclenchant un `Write` réel → le payload expose bien `session_id`, ainsi que `transcript_path`, `cwd`, `prompt_id`, `permission_mode`, `effort`, `hook_event_name`, `tool_name`, `tool_input`, `tool_use_id`. Script restauré à l'identique après capture (`diff` vérifié).
- **Recherche de couverture existante** : `core/graph-aware-injection` porte `AI_CONTEXT_FOCUS` sur `pre-turn-reminder.sh` (autre script, autre variable) ; `quality/features-for-path-ranking-and-matcher-correctness` porte le ranking et le matcher du même script, pas le budget d'injection. Aucune fiche ne couvrait la dédup inter-appels → nouvelle fiche `core/session-injection-dedup`.
- **Implémentation** : marqueur vide par `(session_id, scope/id, mtime)` sous `.ai/.session-injected-docs/<session>/`, aligné sur la convention des états volatils `.ai/.session-*` déjà gitignorés. Corps injecté une fois, puis rappel court actionnable. Purge best-effort des sessions > 2 jours au premier appel de chaque session. Opt-out `AI_CONTEXT_FEATURE_DOC_SESSION_DEDUP=0`.
- **Effet de bord identifié à la première mesure** : l'appel 2 n'avait quasiment pas diminué (10648 → 10590 caractères) parce que le budget libéré par les rappels était immédiatement consommé par des fiches `depends_on` plus profondes, jamais injectées jusque-là. Vérifié que ce n'est pas une fuite mais un transitoire : la clôture atteignable s'épuise en 3 appels, puis la sortie s'effondre à 1846 caractères et y reste. Décision assumée de ne pas brider artificiellement le budget libéré (le volume total converge vers la taille du mesh atteignable au lieu de répéter le même payload).
- **Gain re-mesuré** (taille du `additionalContext`, path `.ai/scripts/features-for-path.sh`, 7 fiches dans la clôture) : avec dédup 10648 → 10590 → 4895 → 1846 ; sans dédup (opt-out) 10648 constant. Régime stable **−82,7 % par appel**.
- **Tests** : `tests/unit/test-features-for-path-session-dedup.sh` créé, 9 assertions vertes (corps puis rappel, isolation entre sessions, invalidation `mtime`, opt-out, mode CLI non dédupliqué et stable, état non inscriptible → fallback sans erreur).
- **Miroir template** : `template/.ai/scripts/features-for-path.sh.jinja` et `template/.ai/.gitignore` alignés (`diff` byte-identique pour le script ; aucune séquence hostile Jinja `{{`/`{%`/`{#` introduite, aucun `${#`).
- **Dogfood** : `.ai/.session-injected-docs` déclaré volatile dans `dogfood-runtime-lib.sh` (tableau `DOGFOOD_VOLATILE_AI_FILES` + `dogfood_is_ai_runtime_extra_ignored`), sinon `check-dogfood-drift.sh` remontait les marqueurs en `extra-runtime`. `check-dogfood-drift.sh` repasse ✅.
- **Risque restant** : après une compaction de contexte, le marqueur survit alors que le corps a disparu du contexte. Mitigé par un rappel actionnable (chemin + « relis-la si la décision en dépend »), pas supprimé — le hook ne reçoit aucun signal de compaction. Pas de TTL ajouté : ce serait un seuil arbitraire non mesuré.
- **Phase** : review. Prochaine étape : observer le comportement sur une vraie session longue et multi-paths, le gain publié étant mesuré sur des appels répétés sur un seul path.

## 2026-08-20 — échéance de relecture posée (2026-09-03)

- La feature reste en `phase: review` volontairement : le gain publié (−82,7 % en régime stable) est mesuré sur des appels répétés sur un **seul** path, pas sur une session longue multi-paths.
- Échéance adossée au mécanisme existant plutôt qu'à un rappel externe : `resume-features.sh` fait ressortir la fiche en `STALE` dès que `progress.updated` dépasse `stale_after_days` (défaut 14) — soit le **2026-09-03**. Aucun nouveau dispositif de suivi créé.
- Critère de passage `review` → `done` écrit dans `resume_hint` et dans la section Risques : (1) re-mesurer défaut contre `AI_CONTEXT_FEATURE_DOC_SESSION_DEDUP=0` sur une session longue multi-paths ; (2) `done` si le gain tient et si aucune perte de corps après compaction n'a gêné ; (3) sinon documenter le cas et arbitrer un TTL de réinjection.

## 2026-08-21 — vocabulaire métier ajouté après retour d'usage

- La fiche avait été créée avant `core/feature-intent-retrieval`, puis retouchée après sa livraison sans renseigner `keywords` : la chronologie « première feature créée après » était inexacte, mais le trou d'adoption à la première touche réelle est confirmé.
- Ajout des formulations « coût du contexte », « doublon d'injection », « budget de tokens » et « réinjection répétée » afin que la fiche soit retrouvée sans connaître son id technique.
- Validation prévue : reconstruction de l'index puis recherche `coût contexte doublon budget tokens` ; la fiche doit sortir en tête.
