---
id: feature-audit
scope: workflow
title: Procédure feature-audit — rétro-doc & re-sync des fiches feature
status: draft
depends_on:
  - core/feature-mesh
  - core/feature-index-cache
  - workflow/claude-skills
touches:
  - .ai/workflows/feature-audit.md
  - template/.ai/workflows/feature-audit.md.jinja
  - template/.ai/scripts/audit-features.sh.jinja
touches_shared:
  - tests/smoke-test.sh
progress:
  phase: implement
  step: "procédure déplacée sous .ai/workflows ; modes discover/refresh conservés"
  blockers: []
  resume_hint: "valider que /aic-review peut s'appuyer sur .ai/workflows/feature-audit.md sans exposer de skill procédural"
  updated: 2026-05-03
---

# Procédure feature-audit

## Objectif

Combler le trou entre la création a priori d'une fiche et l'édition consciente de son frontmatter : couvrir deux cas jusqu'ici non outillés du cycle de vie feature.

1. **Rétro-documentation** — du code existe dans un scope sans fiche feature correspondante (legacy, contribution externe, dette accumulée avant l'adoption du mesh).
2. **Re-synchronisation forcée** — une fiche feature existe mais son frontmatter (`touches`, `depends_on`, `status`, `progress`) a dérivé de la réalité du code (renommages, refacto, status non mis à jour).

Ces deux cas sont détectables mais jamais automatisés sans contrôle humain : ce skill outille la détection et propose des patchs, l'utilisateur décide fiche par fiche.

## Comportement attendu

Deux modes explicites (argument obligatoire, pas d'auto-détection) :

### Mode `discover <scope>`

- Collecte les chemins modifiés récemment (git log, window configurable) et la liste des `touches:` de toutes les features actives du scope.
- Calcule les fichiers orphelins (modifiés mais ne matchent aucun `touches:`).
- Pour chaque orphelin (ou groupe cohérent d'orphelins) : propose `id` candidat + `title` inféré du git log + dossier parent.
- Dry-run par défaut : affiche un tableau `fichier(s) → feature suggérée`.
- Avec `--apply` : demande confirmation ligne par ligne, puis applique `.ai/workflows/feature-new.md` pour chaque ligne validée.

### Mode `refresh <scope>/<id>`

- Charge la fiche feature et son worklog.
- Recompare :
  - `touches:` déclarés vs fichiers réellement modifiés via git log sur la fiche
  - `depends_on:` vs features mentionnées dans le worklog
  - `progress.updated` vs date du dernier commit touchant la fiche
  - `status` vs signaux (worklog clôturé ? tests passants ?)
- Dry-run par défaut : affiche un diff frontmatter proposé.
- Avec `--apply` : demande confirmation globale, puis applique `.ai/workflows/feature-update.md` pour écrire les changements.

## Contrats

- **Procédure interne / maintenance mesh** — anciennement exposée directement ; l'UX recommandée passe désormais par `/aic-review` ou une demande naturelle de rétro-doc.
- **Dry-run par défaut** — aucune écriture sans `--apply` explicite.
- **Jamais de batch silencieux** — `--apply` demande toujours confirmation fiche par fiche en `discover`, ou une confirmation globale en `refresh`.
- **Délègue aux procédures internes** — n'écrit pas directement. Passe par `.ai/workflows/feature-new.md` (discover) ou `.ai/workflows/feature-update.md` (refresh) pour préserver les invariants (worklog, progress bump).
- **Validation finale** — appelle `build-feature-index.sh --write` + `check-features.sh` avant de rendre la main.

## Cross-refs

- **`core/feature-mesh`** : fournit le format frontmatter et les règles de validation que l'audit vérifie.
- **`core/feature-index-cache`** : source de vérité pour lister les features actives par scope sans re-parser à chaque run.
- **`workflow/claude-skills`** : catalogue global ; cette logique n'est plus exposée comme skill Claude.

## Historique / décisions

- **2026-04-24** — Création. Origine : lacune identifiée en conversation — aucun skill ne permettait de rattraper du code pré-mesh ou des fiches stale. Choix d'un skill unique à deux modes plutôt que deux skills séparés pour garder la famille `/aic-feature-*` lisible. Dry-run par défaut pour éviter la pollution du mesh par des fiches auto-générées sans contrôle.
- **2026-04-27** — Ajout du script agent-agnostique `audit-features.sh` (MVP `discover <scope>`), dry-run par défaut + `--apply` explicite. Objectif : rendre l'audit utilisable hors Claude skills.
- **2026-04-27** — Correctif discover : l'audit inclut maintenant aussi les fichiers non trackés (`git ls-files --cached --others --exclude-standard`) pour détecter `src/orphan.ts` dans le smoke-test ; retrait de `mapfile`/`declare -A` pour meilleure compatibilité Bash 3.2.
- **2026-04-27** — Correctif discover (smoke-test CI rouge) : fallback `find` quand `audit-features.sh` tourne hors repo git (cas scaffold neuf), et garde `${arr[@]+...}` pour tolérer `tracked`/`touches` vides sous `set -u` en Bash 3.2.
- **2026-04-28** — Robustesse aux paths-with-spaces : refactor des boucles `for f in ${arr[@]+"${arr[@]}"}` (sujettes à word-splitting selon les versions Bash) vers `if [[ ${#arr[@]} -gt 0 ]]; then for f in "${arr[@]}"; fi`. Préserve la sécurité `set -u` Bash 3.2 ET la fidélité des chemins avec espaces. Ajout du sous-mode `--help` (et `-h`) qui annonce explicitement le périmètre `MVP discover only` avec renvoi vers le skill `/aic-feature-audit` pour l'UX riche (refresh, --interactive). Smoke-test [12/28] enrichi : assertion `--help` + cas `src/with space/file.ts` orphelin doit apparaître dans la sortie discover.
- **2026-05-03** — Le smoke-test partagé exécute deux tests unitaires de régression avant les scénarios Copier. Aucun changement sur `audit-features.sh`, mais le fichier `tests/smoke-test.sh` est couvert par cette feature.
- **2026-05-03** — `tests/smoke-test.sh` passe en `touches_shared` pour signaler le lien de review sans bloquer la fraîcheur documentaire de cette feature à chaque ajout de smoke global.
- **2026-05-03** — Retrait du skill Claude `/aic-feature-audit` et déplacement de la logique sous `.ai/workflows/feature-audit.md`, appelée via `/aic-review` ou par Codex en langage naturel.
