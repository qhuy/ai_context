---
id: stop-hook-idempotence
scope: workflow
title: Rendre le hook Stop idempotent sur tour sans édit structurel
status: draft
depends_on: []
touches:
  - .ai/scripts/auto-worklog-flush.sh
  - .claude/settings.json
  - tests/smoke-test.sh
touches_shared:
  - .ai/scripts/auto-progress.sh
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
  phase: spec
  step: "draft cadré, à reprendre pour implémentation"
  blockers: []
  resume_hint: "lire auto-worklog-flush.sh, définir le critère « tour sans édit structurel », implémenter le no-op + tests reproductibles"
  updated: 2026-05-06
---

# Rendre le hook Stop idempotent sur tour sans édit structurel

## Résumé

Aujourd'hui, le hook Stop côté Claude (via `auto-worklog-flush.sh`) écrit une entrée `## YYYY-MM-DD HH:MM — auto` dans le worklog de la feature concernée à chaque fin de tour, même si le tour était purement conversationnel ou en lecture seule. Conséquence : `progress.updated` est bumpé sur des tours sans changement réel, le worklog se remplit de bruit, et l'historique perd sa valeur de signal pour `aic-status` et la reprise.

Cette fiche couvre l'idempotence : si zéro fichier matchant un `touches:` direct n'a été édité dans le tour, ne pas écrire dans le worklog ni bumper `progress.updated`.

## Objectif

Restaurer la sémantique de `progress.updated` comme « date du dernier change réel » et alléger les worklogs en supprimant les entrées vides. Sans toucher au contrat append-only ni au mécanisme global d'auto-worklog.

## Périmètre

### Inclus

- Lire le code actuel de `auto-worklog-flush.sh` et identifier le point de décision « écrire ou pas ».
- Définir le critère « tour sans édit structurel » : zéro fichier édité dans le tour ne matche un `touches:` direct de la feature ciblée. Pareil que le filtre de `workflow/auto-progress-file-filter`, mais appliqué à l'écriture worklog plutôt qu'à la transition de phase.
- Implémenter le no-op : si aucun édit structurel, ne pas écrire dans le worklog. Idem pour le bump `progress.updated`.
- Tests reproductibles : tour purement conversationnel → no-op ; tour avec lecture seule → no-op ; tour avec édit `.md` seul → no-op ; tour avec édit fichier source → write+bump.
- Documentation du comportement dans le workflow associé.

### Hors périmètre

- Filtre auto-progression spec→implement (`workflow/auto-progress-file-filter`, Phase 2 #4) — partage le critère mais touche un autre script.
- Couverture du delta uncommitted (`quality/review-delta-uncommitted-coverage`).
- Ranking et matcher correct (`quality/features-for-path-ranking-and-matcher-correctness`) — dépendance pour matcher `touches:` direct fiablement.
- Refonte du modèle worklog (reste append-only, format YYYY-MM-DD HH:MM unchanged).

### Granularité / nommage

Cette fiche couvre **uniquement** le hook Stop / auto-worklog-flush. Le filtre de transition de phase est dans une fiche distincte (Phase 2 #4) car il touche un autre script (`auto-progress.sh`).

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

`auto-worklog-flush.sh` invoqué par le hook Stop :

1. Récupérer la liste des fichiers édités dans le tour.
2. Récupérer la feature ciblée (par scope primaire ou par matching le plus spécifique).
3. Pour chaque fichier, vérifier qu'il matche un `touches:` direct (pas `touches_shared:`) ET n'a pas une extension exclue.
4. Si au moins un fichier passe le filtre → écrire l'entrée worklog + bumper `progress.updated`.
5. Si zéro fichier passe → no-op silencieux. `progress.updated` reste à sa valeur précédente.

## Contrats

- Variables d'env : `AI_CONTEXT_AUTO_WORKLOG_DISABLED=1` désactive complètement (existant probablement).
- Code retour 0 toujours (best-effort).
- Trace : si `AI_CONTEXT_DEBUG=1`, logger la décision write/no-op avec le motif (« 0 fichiers structurels édités, no-op » ou « 3 fichiers structurels, write »).

## Validation

- Test reproductible 1 : tour purement conversationnel (zéro édit) → no-op, worklog inchangé, `progress.updated` inchangé.
- Test reproductible 2 : tour avec lecture seule (Read uniquement) → no-op.
- Test reproductible 3 : tour avec édit `.md` seul (fiche feature, README) → no-op (extension non structurelle).
- Test reproductible 4 : tour avec édit fichier source matchant `touches:` direct → write+bump.
- Test reproductible 5 : tour avec édit fichier `touches_shared:` seul → no-op.
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

- 2026-05-06 : création en draft suite au cross-check Claude/Codex (4 rounds) sur `workflow/intentional-skills`. Bug de signal : `progress.updated` est bumpé même sur tours conversationnels, ce qui dilue sa valeur. Fix : no-op si zéro édit structurel. Indépendant de #1–#4 mais bénéficie du matcher correct (#2). Codex round 2 a explicitement noté que ce fix est utile mais pas le plus dangereux ; placé en #5 par ordre d'impact agent (egress > injection > falsification d'état > hygiène signal).
