---
id: session-injection-dedup
scope: core
title: Dédup par session du corps des fiches injectées en hook
status: active
type: feature
description: "Le corps d'une fiche n'est injecté qu'une fois par session ; les appels suivants n'émettent qu'un rappel court."
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
touches:
  - .ai/scripts/features-for-path.sh
  - template/.ai/scripts/features-for-path.sh.jinja
  - tests/unit/test-features-for-path-session-dedup.sh
  - .docs/features/core/session-injection-dedup.md
  - .docs/features/core/session-injection-dedup.worklog.md
touches_shared:
  - .ai/.gitignore
  - template/.ai/.gitignore
  - .ai/scripts/dogfood-runtime-lib.sh
product: {}
external_refs: {}
doc:
  level: standard
  requires:
    auth: false
    data: false
    ux: false
    api_contract: false
    rollout: false
    observability: false
progress:
  phase: review
  step: "dédup livrée, 9 cas unitaires verts, gain mesuré -82,7 % en régime stable"
  blockers: []
  resume_hint: "observer sur une vraie session longue ; rouvrir si la perte de corps après compaction devient gênante"
  updated: 2026-08-20
---

# Dédup par session du corps des fiches injectées en hook

## Résumé

En hook `PreToolUse`, `features-for-path.sh` réinjectait le corps entier des mêmes fiches à chaque édition d'un path couvert. Cette feature pose un marqueur par `(session_id, fiche, mtime)` : le corps part une seule fois par session, les appels suivants n'émettent qu'un rappel court avec le chemin de la fiche.

## Objectif

La déduplication existante (`seen_feature_key`) ne vaut qu'à l'intérieur d'un seul appel du script. Il n'existait aucune mémoire entre appels d'une même session, donc chaque édition repayait l'intégralité des fiches concernées.

Mesure sur la session `670708a8` (2529 tours) : 248 injections de fiches pour seulement 48 payloads distincts, soit ~87 % de duplication. Chaque doublon reste résident dans le contexte et est relu à chaque tour suivant, ce qui en fait le premier poste de coût de la session.

## Périmètre

### Inclus

- Un état volatile par session sous `.ai/.session-injected-docs/<session_id>/`, un fichier marqueur vide par `(fiche, mtime)`.
- La lecture de `session_id` depuis le JSON stdin du hook `PreToolUse`.
- Le remplacement du corps par un rappel court (`clé`, chemin, « déjà injectée plus haut dans cette session ») quand le marqueur existe.
- La réinjection automatique quand la fiche change (`mtime` dans la clé du marqueur).
- La purge best-effort des dossiers de sessions mortes (> 2 jours), au premier appel de chaque session.
- L'opt-out `AI_CONTEXT_FEATURE_DOC_SESSION_DEDUP=0`.

### Hors périmètre

- Le mode CLI (`--with-docs`) : sans `session_id`, la dédup est inactive et le corps reste complet. C'est ce que consomment les skills `aic-pilot` et `aic-review` (`.agents/skills/*/workflow.md`), qui gardent donc des fiches entières.
- Les hooks Codex : le seul câblage en hook du script est `PreToolUse` dans `.claude/settings.json` ; `.codex/` ne l'appelle pas.
- Le ranking et le matcher de `features-for-path.sh` : inchangés, portés par `quality/features-for-path-ranking-and-matcher-correctness`.
- La liste des features concernées (bloc `⚠️ Features concernées`) : toujours injectée en entier, elle est courte et sert d'ancrage.
- Le tracker de pertinence : les évènements `inject` restent loggés à l'identique, la feature reste comptée comme injectée.
- `pre-turn-reminder.sh` et `AI_CONTEXT_FOCUS` : autre mécanisme, porté par `core/graph-aware-injection`.

## Invariants

- Le corps d'une fiche donnée n'est injecté qu'une fois par `session_id`, tant que la fiche n'est pas modifiée.
- Une fiche modifiée (`mtime` différent) est réinjectée dans la même session.
- Deux sessions différentes ne partagent jamais d'état.
- Une fiche dédupliquée reste visible en sortie : jamais de disparition silencieuse, toujours chemin + invitation à relire.
- Sans `session_id` (mode CLI), le comportement historique est strictement conservé.
- Tout échec de l'état (dossier non créable, non inscriptible, illisible) retombe silencieusement sur l'injection complète, sans erreur et sans `exit` non nul.
- Les bornes existantes restent actives et inchangées : `AI_CONTEXT_INJECT_FEATURE_DOCS`, `AI_CONTEXT_FEATURE_DOC_MAX_CHARS`, `AI_CONTEXT_FEATURE_DOC_PER_DOC_CHARS`.

## Décisions

- **État sous `.ai/` plutôt que `${TMPDIR}`** : aligné sur la convention déjà en place pour les états volatils de session (`.session-edits.log`, `.context-relevance.jsonl`), gitignoré, et naturellement isolé par worktree. Débogable, contrairement à un chemin temporaire opaque.
- **Un fichier marqueur par fiche plutôt qu'un log unique** : la création de fichier est atomique, donc sûre face à des hooks concurrents, et le test d'existence ne coûte ni `jq` ni `grep`.
- **`mtime` dans la clé du marqueur** plutôt qu'un hash de contenu : suffisant pour invalider, sans lire la fiche.
- **Le budget libéré n'est pas contraint artificiellement** : quand une fiche déjà vue libère de la place, les fiches `depends_on` plus profondes peuvent enfin être injectées. Ce n'est pas une fuite : le volume total converge vers la taille du mesh atteignable (borné) au lieu de répéter le même payload. Mesuré : convergence en 3 appels, puis régime stable à un rappel court par fiche.
- **Le rappel reste actionnable** (chemin complet + « relis-la si la décision en dépend ») : après une compaction de contexte, le corps injecté plus haut peut avoir disparu ; l'agent doit pouvoir rouvrir la fiche seul.
- **Pas de TTL de réinjection** : ce serait un seuil arbitraire non mesuré. Le rappel actionnable couvre le cas de la compaction.
- **Dédup active par défaut**, opt-out explicite : le coût du doublon est mesuré et systématique, l'inverse serait de laisser la régression en place par défaut.

## Comportement attendu

Dans une session Claude, à chaque `Write`/`Edit`/`MultiEdit` sur un path couvert par des `touches:` :

- Premier appel touchant une fiche : corps injecté (borné comme avant), marqueur posé.
- Appels suivants : `--- <scope>/<id> (<chemin>) — fiche déjà injectée plus haut dans cette session ; relis-la si la décision en dépend ---`.
- Après modification de la fiche : corps réinjecté une fois, puis rappel court à nouveau.
- Nouvelle session : état vierge, corps réinjecté.

## Contrats

- Lit `.session_id` du payload `PreToolUse` (vérifié : le payload expose `session_id`, `transcript_path`, `cwd`, `prompt_id`, `hook_event_name`, `tool_name`, `tool_input`, `tool_use_id`).
- Écrit sous `.ai/.session-injected-docs/<session_id sanitisé>/<scope>_<id>.<mtime>` — fichiers vides, gitignorés.
- `session_id` et clés sont sanitisés (`[:alnum:]._-`, tronqués à 120 caractères) avant usage comme chemin.
- Nouvelle borne documentée en tête de script : `AI_CONTEXT_FEATURE_DOC_SESSION_DEDUP=0`.
- `.ai/.session-injected-docs` est déclaré volatile dans `dogfood-runtime-lib.sh` (exclusion rsync + `dogfood_is_ai_runtime_extra_ignored`), sinon `check-dogfood-drift.sh` le signale en `extra-runtime`.

## Validation

Couvert par `tests/unit/test-features-for-path-session-dedup.sh` (9 assertions) :

- premier appel = corps, second appel = rappel court ;
- session différente = corps réinjecté ;
- `mtime` modifié = corps réinjecté, puis rappel à nouveau ;
- `AI_CONTEXT_FEATURE_DOC_SESSION_DEDUP=0` = injection complète ;
- mode CLI `--with-docs` = jamais dédupliqué, stable sur deux appels ;
- état non inscriptible = fallback injection complète, sans erreur.

Gain mesuré sur `.ai/scripts/features-for-path.sh` (7 fiches dans la clôture `depends_on`), taille du `additionalContext` du hook :

| appel | avec dédup | sans dédup (opt-out) |
|---|---|---|
| 1 | 10648 | 10648 |
| 2 | 10590 | 10648 |
| 3 | 4895 | 10648 |
| 4 | 1846 | 10648 |

Régime stable : 1846 contre 10648 caractères, soit **−82,7 % par appel**, atteint au 4ᵉ appel.

Latence du hook (le câblage `.claude/settings.json` impose un `timeout: 3` secondes) : 306 à 364 ms avec dédup contre 266 ms sans, soit +40 à +100 ms pour les `stat`/`tr`/`cut` supplémentaires. Large marge sous la borne.

## Risques

- **Compaction de contexte** : si le contexte est compacté après l'injection du corps, le marqueur survit alors que le corps a disparu ; l'agent ne reçoit plus qu'un rappel. Mitigé par un rappel actionnable (chemin + consigne de relecture), pas supprimé. Le hook ne reçoit aucun signal de compaction.
- **Transitoire de 3 appels** : le budget libéré est d'abord consommé par les fiches `depends_on` profondes avant que la sortie ne s'effondre. Comportement mesuré et borné, pas un état permanent.
- **Sémantique du tracker de pertinence** : une fiche « injectée » peut désormais n'être qu'un rappel. Les évènements `inject` sont volontairement inchangés pour ne pas déplacer le ranking ; à revoir si les pénalités deviennent bruitées.
- À revalider sur une vraie session longue : le gain publié ici est mesuré sur des appels répétés sur un seul path.

## Cross-refs

- `core/feature-mesh` : source des `touches:`/`depends_on` qui déterminent les fiches candidates.
- `core/feature-index-cache` : l'index `.ai/.feature-index.json` d'où sont résolus chemin et dépendances.
- `core/graph-aware-injection` : autre levier de réduction d'injection (`AI_CONTEXT_FOCUS`), appliqué à `pre-turn-reminder.sh`. Complémentaire, aucun recouvrement de variable.
- `quality/features-for-path-ranking-and-matcher-correctness` : couvre le ranking et le matcher du même script ; contrat non modifié ici.
- `quality/context-relevance-tracker` : consomme les évènements `inject` de ce script.
- `core/dogfood-runtime-sync` : impose le miroir `template/*.jinja` et l'exclusion du nouvel état volatile.

## Historique / décisions

- 2026-08-20 : création. Mesure d'origine : 46,3 % du coût de la session `670708a8` en reminders/hooks, dont ~404 500 tokens de pur doublon d'injection de fiches (87 % de duplication sur 248 injections). Dédup par `(session_id, fiche, mtime)` livrée, gain re-mesuré −82,7 % par appel en régime stable.
