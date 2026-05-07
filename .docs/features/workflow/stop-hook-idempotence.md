---
id: stop-hook-idempotence
scope: workflow
title: Rendre le hook Stop idempotent sur tour sans édit structurel
status: draft
depends_on: []
touches:
  - .ai/scripts/auto-worklog-log.sh
  - .ai/scripts/auto-worklog-flush.sh
  - tests/smoke-test.sh
touches_shared:
  - .ai/scripts/auto-progress.sh
  - .claude/settings.json
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
  phase: implement
  step: "draft cadré (diagnostic corrigé post-review Codex), à reprendre pour implémentation"
  blockers: []
  resume_hint: "filtrer les fichiers déjà matchés par features_matching_path par extension structurelle, dans auto-worklog-log.sh ou auto-worklog-flush.sh"
  updated: 2026-05-07
---

# Rendre le hook Stop idempotent sur tour sans édit structurel

## Résumé

**Diagnostic corrigé post-review Codex 2026-05-06** :

Le hook Stop ([auto-worklog-flush.sh:23](.ai/scripts/auto-worklog-flush.sh:23)) est déjà idempotent sur tour conversationnel ou lecture seule : il exit early si `.ai/.session-edits.log` est vide, et le log n'est alimenté que par PostToolUse Write/Edit/MultiEdit ([auto-worklog-log.sh:36](.ai/scripts/auto-worklog-log.sh:36)) sur fichiers matchant un `touches:` direct via `features_matching_path` ([_lib.sh:130](.ai/scripts/_lib.sh:130)).

Le **vrai bruit** vient des édits **non-structurels** qui passent ce filtre car listés dans `touches:` direct : édit d'une fiche feature elle-même (`.docs/features/<scope>/<id>.md`), édit d'un README listé dans `touches:`, édit d'un fichier `.md` de doc, parfois fichiers de tests. Sur ces édits, `auto-worklog-log.sh` enregistre, puis `auto-worklog-flush.sh` écrit dans le worklog et bumpe `progress.updated`. Conséquence : worklog peuplé d'entrées `auto` qui tracent des modifications documentaires plutôt que des changes structurels.

Cette fiche couvre le filtrage par extension structurelle, **après** `features_matching_path` (donc sans toucher au matcher), pour rendre le hook idempotent sur édit non-structurel matchant `touches:`.

## Objectif

Restaurer la sémantique de `progress.updated` comme « date du dernier change réel » (de code structurel) et alléger les worklogs des entrées tracées sur édits documentaires. Sans toucher au contrat append-only, au matcher `features_matching_path`, ni au mécanisme global d'auto-worklog.

## Périmètre

### Inclus

- Filtrer **après** `features_matching_path` les fichiers par extension structurelle. Deux options de placement :
  - (a) dans `auto-worklog-log.sh` : ne pas alimenter `.ai/.session-edits.log` pour les fichiers non-structurels (préféré, court-circuite le flush sans toucher la logique).
  - (b) dans `auto-worklog-flush.sh` : filtrer la liste avant `printf` (plus tardif mais plus localisé).
- Définir la liste « non-structurelle » : par défaut `.md`, `.txt`, `.lock`. À discuter pour `.json`, `.yml`.
- Tests reproductibles : édit fiche feature seule → no-op ; édit README seul (s'il est dans `touches:` d'une fiche) → no-op ; édit fichier source structurel → write+bump ; édit mix structurel+non-structurel → write+bump (au moins un fichier passe, conservateur).
- Tests de non-régression : tour conversationnel → toujours no-op (déjà le cas) ; tour lecture seule → toujours no-op (déjà le cas) ; tour avec édit hors `touches:` direct → toujours no-op (déjà le cas).
- Documentation du comportement dans le workflow associé.

### Hors périmètre

- Filtre auto-progression spec→implement (`workflow/auto-progress-file-filter`, Phase 2 #4) — partage le critère mais touche un autre script.
- Couverture du delta uncommitted (`quality/review-delta-uncommitted-coverage`).
- Ranking et matcher correct (`quality/features-for-path-ranking-and-matcher-correctness`) — dépendance pour matcher `touches:` direct fiablement.
- Refonte du modèle worklog (reste append-only, format YYYY-MM-DD HH:MM unchanged).

### Granularité / nommage

Cette fiche couvre l'idempotence auto-worklog côté Stop, avec **implémentation préférée dans le logger PostToolUse** (`auto-worklog-log.sh`, option a) et **option alternative dans le flush Stop** (`auto-worklog-flush.sh`, option b). Titre `stop-hook-idempotence` conservé : objectif final = idempotence visible côté Stop, peu importe où le filtrage est appliqué en amont. Le filtre de transition de phase est dans une fiche distincte (`workflow/auto-progress-file-filter`, Phase 2 #4) car il touche un autre script (`auto-progress.sh`).

## Invariants

- Append-only : on ne supprime jamais d'entrée existante. On évite juste d'en créer une nouvelle quand il n'y a rien à dire.
- Best-effort : aucune erreur ne doit bloquer le hook Stop. Toute défaillance du critère silencieuse côté logger.
- Comportement déterministe : pour un même set d'édits, la décision write/no-op est reproductible.
- Pas de régression sur les tours avec édit réel : le worklog continue de tracer comme avant.

## Décisions

Ouvertes, à arbitrer en phase implement :

- Critère partagé avec `workflow/auto-progress-file-filter` ou critère spécifique ? Préférence : partagé via une fonction commune dans `_lib.sh` pour éviter la divergence.
- Comportement sur fichiers fiches feature (`.docs/features/<scope>/<id>.md`) : non structurel par définition (la fiche n'est pas l'implémentation), même si elle est dans `touches:` indirectement.
- Comportement sur fichiers de tests : (a) considérer comme structurel ou (b) non. Cohérence avec `workflow/auto-progress-file-filter` à privilégier (probable : structurel).
- Si la feature ciblée n'a pas de `touches:` (cas pathologique), no-op par défaut ou bump par défaut ?
- Doit-on quand même mettre à jour `progress.updated` sur tour purement conversationnel mais avec lecture du contexte feature ? Préférence : non. La date doit refléter un change, pas un attoutchement.

## Comportement attendu

Option (a) recommandée : filtrer dans `auto-worklog-log.sh` ([ligne ~36, après `features_matching_path`](.ai/scripts/auto-worklog-log.sh:36)).

1. Le hook PostToolUse Write/Edit/MultiEdit reçoit `tool_input.file_path`.
2. `features_matching_path` retourne les features dont un `touches:` direct couvre ce path.
3. **Nouveau** : si l'extension du fichier ∈ liste « non-structurelle » (par défaut `.md`, `.txt`, `.lock`), ne pas alimenter `.ai/.session-edits.log`.
4. Conséquence : `auto-worklog-flush.sh` exit déjà early (log vide), aucun changement à faire dans flush.

Cas de régression à préserver :
- Tour conversationnel/lecture seule : zéro PostToolUse Write/Edit → log vide → flush exit 0. Inchangé.
- Édit hors `touches:` direct : `features_matching_path` retourne vide → log vide → flush exit 0. Inchangé.

## Contrats

- Variables d'env : `AI_CONTEXT_AUTO_WORKLOG_DISABLED=1` désactive complètement (existant probablement).
- Code retour 0 toujours (best-effort).
- Trace : si `AI_CONTEXT_DEBUG=1`, logger la décision write/no-op avec le motif (« 0 fichiers structurels édités, no-op » ou « 3 fichiers structurels, write »).

## Validation

Tests de non-régression (déjà passants aujourd'hui, à protéger) :

- Test 1 : tour purement conversationnel (zéro Write/Edit) → no-op. Déjà le cas.
- Test 2 : tour avec lecture seule (Read uniquement) → no-op. Déjà le cas.
- Test 3 : édit fichier hors `touches:` direct → no-op. Déjà le cas.

Tests cibles du fix (à passer après livraison) :

- Test 4 : édit fiche feature `.md` seule (matche `touches:` direct mais extension non-structurelle) → no-op. **Aujourd'hui : write+bump (bruit confirmé en local sur ce repo).**
- Test 5 : édit README seul (s'il est dans `touches:` d'une feature) → no-op.
- Test 6 : édit fichier source `.sh` matchant `touches:` direct → write+bump. Comportement attendu inchangé.
- Test 7 : édit mix structurel+non-structurel matchant `touches:` direct → write+bump (au moins un fichier passe, conservateur).
- `bash tests/smoke-test.sh` PASS après intégration.

## Risques

- Sur-filtrer : risque de manquer un change légitime si le critère est trop strict. Compenser par `/aic` override et logs debug.
- Sous-filtrer : risque de garder le bug actuel (worklog bavard) si critère trop laxiste.
- Le filtre dépend du matcher de `features-for-path.sh` (cf. `quality/features-for-path-ranking-and-matcher-correctness`). Sur bash 3.2 avec matcher buggé, le filtre peut classer un fichier à tort.
- Compatibilité : si la feature n'a pas de `touches:`, le critère retourne toujours « zéro fichier structurel » → toujours no-op, même sur édits réels. À gérer comme cas pathologique avec fallback ou warning.
- Compatibilité historique : les worklogs existants avec entrées « auto » bavardes restent dans l'historique (append-only, on ne purge pas).

## Cross-refs

- `workflow/auto-progress-file-filter` : Phase 2 #4, partenaire naturel sur le hook Stop. Partage le critère « édit structurel » — refactor en fonction commune `_lib.sh` recommandé.
- `quality/features-for-path-ranking-and-matcher-correctness` : Phase 2 #2, le filtre devient fiable après le matcher correct.
- `core/feature-mesh` : modèle `touches:` vs `touches_shared:`, central ici.
- `workflow/auto-worklog` : feature parente du mécanisme. Cette fiche ajoute un raffinement, ne le remplace pas.
- `workflow/intentional-skills` : ordre Phase 2 décidé après cross-check Claude/Codex (round 4).

## Historique / décisions

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`. Bug de signal supposé : `progress.updated` bumpé même sur tours conversationnels.
- 2026-05-06 (post-review Codex) : **diagnostic corrigé**. Le hook Stop est déjà idempotent sur tours conversationnels/lecture seule (early exit `[[ ! -s log_file ]]`). Le vrai bruit vient des édits **non-structurels** matchant `touches:` direct (fiche feature elle-même, README, fichier `.md` de doc). Fix recadré : filtrage par extension structurelle après `features_matching_path`, dans `auto-worklog-log.sh`. Indépendant de #1–#4. Bénéficie du matcher correct (#2) mais pas bloqué par lui.
