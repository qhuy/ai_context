---
id: vcs-provider-abstraction
scope: core
title: Abstraction VCS Git / TFVC
status: done
type: feature
description: "Decoupler le runtime ai_context de Git pour supporter les projets TFVC/TFS."
depends_on: []
touches:
  - .ai/config.yml
  - .ai/scripts/_vcs.sh
  - .ai/scripts/check-feature-freshness.sh
  - .ai/scripts/review-delta.sh
  - .ai/scripts/pr-report.sh
  - .ai/scripts/doctor.sh
  - .ai/scripts/stop-doc-gate.sh
  - copier.yml
  - template/.ai/config.yml.jinja
  - template/.ai/scripts/_vcs.sh.jinja
  - template/.ai/scripts/check-feature-freshness.sh.jinja
  - template/.ai/scripts/review-delta.sh.jinja
  - template/.ai/scripts/pr-report.sh.jinja
  - template/.ai/scripts/doctor.sh.jinja
  - template/.ai/scripts/stop-doc-gate.sh.jinja
  - template/README_AI_CONTEXT.md.jinja
  - README_AI_CONTEXT.md
  - tests/unit/test-vcs-provider.sh
  - tests/unit/test-build-feature-index-robust.sh
  - tests/unit/test-build-feature-index-fallback-frontmatter.sh
  - tests/unit/test-build-feature-index-contract.sh
  - tests/unit/test-build-feature-index-fallback.sh
  - tests/unit/test-check-commit-features-relevance.sh
  - tests/unit/test-features-for-path-relevance-ranking.sh
  - tests/unit/test-stop-hook-idempotence.sh
  - tests/unit/test-auto-progress-filter.sh
  - .docs/features/core/vcs-provider-abstraction.md
  - .docs/features/core/vcs-provider-abstraction.worklog.md
touches_shared:
  - .ai/scripts/_lib.sh
  - template/.ai/scripts/_lib.sh.jinja
  - .ai/scripts/aic.sh
  - template/.ai/scripts/aic.sh.jinja
  - .ai/scripts/check-commit-features.sh
  - template/.ai/scripts/check-commit-features.sh.jinja
  - tests/**
  - README.md
  - CHANGELOG.md
product: {}
external_refs: {}
doc:
  level: full
  requires:
    auth: false
    data: false
    ux: false
    api_contract: true
    rollout: true
    observability: false
progress:
  phase: done
  step: "provider VCS livré, testé et dogfoodé"
  blockers: []
  resume_hint: "aucune action immédiate ; rouvrir si un provider VCS supplémentaire ou une intégration TFVC plus stricte est demandée."
  updated: "2026-07-03"
---

# Abstraction VCS Git / TFVC

## Résumé

`ai_context` doit rester pleinement compatible Git tout en pouvant fonctionner dans un workspace TFVC/TFS. Le runtime introduit une couche VCS interne pour remplacer les appels Git directs dans les checks quotidiens par des primitives stables.

## Objectif

Permettre a un projet sous TFVC d'utiliser les fiches feature, la freshness documentaire, la review de delta et le doctor sans installer un depot Git miroir uniquement pour satisfaire `ai_context`.

## Périmètre

### Inclus

- Provider `git` par defaut, sans regression du comportement actuel.
- Provider `tfvc` best-effort base sur `tf.exe` / `tf`.
- Detection explicite via configuration ou auto-detection locale.
- Remplacement progressif des appels Git directs dans les scripts runtime qui lisent le delta courant.
- Documentation des limites TFVC, notamment l'absence d'index Git.

### Hors périmètre

- Integration native Azure DevOps Server ou API REST.
- Creation automatique de shelvesets, branches TFS ou workspaces.
- Remplacement complet des hooks Git par des hooks TFS serveur.
- Migration des historiques Git existants.

## Invariants

- Le provider `git` reste le comportement par defaut.
- Les projets existants sans configuration VCS continuent a passer les checks.
- En TFVC, `--staged` est traite comme un alias de compatibilite pour les pending changes.
- Les scripts doivent rester executables sans dependance lourde additionnelle.

## Décisions

- Introduire `.ai/scripts/_vcs.sh` comme contrat runtime partage.
- Utiliser `AI_CONTEXT_VCS_PROVIDER` puis `.ai/config.yml` pour forcer le provider quand l'auto-detection ne suffit pas.
- Conserver les `.githooks` pour Git et exposer les memes checks en commandes manuelles/CI pour TFVC.

## Comportement attendu

Un utilisateur Git ne voit pas de changement de commande. Un utilisateur TFVC peut lancer les checks `aic`, freshness et review depuis la racine du workspace ; les fichiers pending changes remplacent le staged index Git.

## Contrats

- `vcs_provider` retourne `git`, `tfvc` ou `none`.
- `vcs_root` retourne la racine logique du workspace courant.
- `vcs_pending_paths` liste les fichiers modifies localement, ajoutes, supprimes ou renommes.
- `vcs_staged_paths` retourne l'index Git pour `git`, et les pending changes pour `tfvc`.
- `vcs_diff_paths BASE HEAD` retourne les chemins changes entre deux refs quand le provider le supporte.
- `vcs_has_staging_area` vaut vrai uniquement pour les providers avec index distinct.

## Validation

- Tests unitaires du provider Git existant.
- Tests unitaires TFVC via faux binaire `tf` pour parser les pending changes.
- `check-feature-freshness --staged --strict` continue a passer en Git.
- `check-feature-freshness --worktree --strict` fonctionne via le provider commun.
- `doctor` signale correctement Git, TFVC ou absence de VCS.
- Smoke test complet sans regression.

## Droits / accès

Non requis (`doc.requires.auth: false`). Le provider TFVC lit uniquement les metadonnees du workspace local.

## Données

Non requis (`doc.requires.data: false`). Donnees concernees : chemins de fichiers repo-local/workspace-local et configuration `.ai`.

## UX

Non requis (`doc.requires.ux: false`).

## Observabilité

Non requis (`doc.requires.observability: false`). Les erreurs restent exposees par les sorties shell des checks.

## Déploiement / rollback

- Rollout additif : Git reste le defaut.
- Forcer `AI_CONTEXT_VCS_PROVIDER=git` permet de revenir au comportement Git.
- Les projets TFVC peuvent commencer par utiliser uniquement `--worktree` / `aic review`.
- Rollback : supprimer le branchement `_vcs.sh` et revenir aux commandes Git directes.

## Risques

- Le format de sortie de `tf status` varie selon versions et langues.
- TFVC ne possede pas d'equivalent exact de l'index Git ; les checks `--staged` doivent documenter cette approximation.
- Les hooks pre-checkin TFS ne sont pas normalises comme les hooks Git locaux.
- **Limite assumee (P5, 2026-07-07)** : `vcs_provider=tfvc` n'a jamais ete exerce de bout en bout (aucun scaffold Copier complet + workflow reel testes, contrairement au provider `git`). Seule la couche `_vcs.sh` est testee en isolation avec un faux binaire `tf`. Requalifie explicitement en best-effort dans `copier.yml` et `README_AI_CONTEXT.md` plutot que suppose fiable. Ouvrir un test e2e (scaffold + fake `tf` sur PATH + doctor/check-feature-freshness) reste possible en suivi si un besoin reel TFVC se confirme.

## Cross-refs

Aucune dependance feature declaree.

## Historique / décisions

- 2026-07-03 : cadrage valide pour supporter TFVC/TFS via abstraction VCS sans casser Git.
- 2026-07-03 : `_vcs.sh` ajouté et branché sur les scripts de delta/freshness/review/report/doctor/aic/stop-doc-gate ; `copier.yml`, `.ai/config.yml`, README et miroirs template exposent `vcs.provider`. `_lib.sh` garde un fallback Git pour les fixtures historiques qui le copient seul.
- 2026-07-03 : feature clôturée en `done` après tests unitaires provider/build-index/freshness/review/commit guard, `check-dogfood-drift`, `check-features --no-write`, `check-shims` et `tests/smoke-test.sh` complets. Résiduel accepté : parsing TFVC best-effort dépendant de la sortie `tf status`.
- 2026-07-03 : provider `_vcs.sh` ajoute `git`, `tfvc` et `none`; le provider TFVC expose les pending changes comme alias du mode `--staged`.
- 2026-07-07 (P5, assainissement matrice) : requalification honnête plutôt que suppression — `tfvc` reste une option de premier niveau (contrainte non-négociable : ne pas retirer), mais `copier.yml` et `README_AI_CONTEXT.md` (+ miroir) disent désormais explicitement « best-effort, non testé end-to-end » au lieu de laisser croire à une parité de test avec `git`. Aucun changement de comportement runtime.
