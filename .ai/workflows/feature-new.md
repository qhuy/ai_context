# Procédure interne — feature-new

**Goal** : créer une fiche feature complète (frontmatter + worklog init) dans `.docs/features/<scope>/<id>.md`.

**Role** : Scribe. Pas de code applicatif dans cette procédure — uniquement documentation.

**Procedure chain** : `.ai/workflows/feature-new.md` → (travail) → `.ai/workflows/feature-update.md` (au fil du dev) → `.ai/workflows/feature-done.md`.

## PRECONDITION

- Un scope unique est connu (`back | front | architecture | security | ...`). Si ambigu → demander à l'utilisateur.
- Un `id` kebab-case candidat (si non fourni → proposer à partir du titre).

## MANDATORY READS

- `.ai/index.md` (séquence canonique)
- `.docs/FEATURE_TEMPLATE.md`
- Le dossier `.docs/features/<scope>/` — pour éviter un doublon d'id

## PHASES

### Phase 1 — Cadrage
1. Demander (ou valider) : `scope`, `id`, `title`, `depends_on` (liste vide OK), `touches` (globs OK, vide accepté au début).
2. **Check anti fourre-tout** : valider que la fiche représente une intention livrable cohérente, pas un domaine métier générique.
   - Plusieurs fiches peuvent partager un préfixe métier si elles couvrent des étapes ou livrables différents.
   - Réutiliser une fiche existante seulement si le changement garde le même objectif, le même DONE et les mêmes validations.
   - Créer une nouvelle fiche si le flux, l'acteur, l'API, le contrat, le modèle de données, le risque ou la validation diffère.
   - Éviter les ids génériques ou extensibles (`passage`, `global`, `misc`, `common`). Si une vue globale est utile, créer une doc d'architecture ou d'overview non active hors `.docs/features/<scope>/`.
   - Exemple OK : `passage_partner_polling`, `passage_client_grpc_retrieval`, `passage_webhook_restitution`, `partner_passage_storage_slimming`, `platform_passage_event_detail`.
   - À éviter : `passage`, `global`, `misc`, `common`.
3. **Check-before-create** : si `.docs/features/<scope>/<id>.md` existe → STOP, demander s'il faut l'éditer (rediriger vers `.ai/workflows/feature-update.md`).

### Phase 2 — Proposition avant écriture
Présenter une synthèse courte et structurée, puis attendre validation explicite avant toute écriture.

Format attendu :
```md
Proposition feature :
- Cible : <scope>/<id> — <title>
- Intention livrable : <objectif en 1 phrase>
- Tâches à réaliser :
  1. <tâche logique>
  2. <tâche logique>
- Impacts probables : <fichiers/surfaces/docs/checks concernés>
- Risques / points d'attention : <risques ou "aucun identifié">
- Validations prévues : <checks/tests/docs>
- Conseils : <optionnel ; arbitrage ou découpage recommandé>

Réponds `go` / `ok` / `oui` pour créer la fiche, ou corrige le cadrage.
```

Règles :
- Si l'utilisateur corrige le scope, l'id, le titre, le périmètre ou les impacts → reprendre la Phase 1 puis reproposer.
- Si la demande implique plusieurs livrables distincts → conseiller de splitter en plusieurs fiches avant de créer.
- Ne pas créer la fiche, ne pas modifier de worklog et ne pas commencer le développement tant que la validation n'est pas explicite.

### Phase 3 — Écriture fiche
Copier `.docs/FEATURE_TEMPLATE.md` vers `.docs/features/<scope>/<id>.md`, remplir :
- `id`, `scope`, `title`
- `status: draft` (par défaut ; `active` si déjà en cours)
- `depends_on`, `touches`
- `progress.phase: spec`, `progress.updated: <YYYY-MM-DD>`, autres champs vides

### Phase 4 — Worklog init
Créer `.docs/features/<scope>/<id>.worklog.md` avec :
```
# Worklog — <scope>/<id>

## <YYYY-MM-DD> — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : <scope>
- Intent initial : <titre>
```

### Phase 5 — Validation
Exécuter :
```bash
bash .ai/scripts/build-feature-index.sh --write
bash .ai/scripts/check-features.sh
bash .ai/scripts/check-feature-docs.sh <scope>/<id>
```
Si rouge → corriger avant de rendre la main.

### Phase 6 — Output
Afficher le chemin créé. Suggérer la suite :
- Remplir les sections **Objectif / Contrats / Validation** au fur et à mesure
- Mettre à jour `progress.*` via `.ai/workflows/feature-update.md` lors des changements d'intent pour sauver `progress.*`
- Clôturer via `.ai/workflows/feature-done.md` à la fin pour clôturer
- Ne pas démarrer le développement applicatif dans cette procédure ; attendre une demande explicite ou une validation séparée de la suite.

## NON-NEGOTIABLE RULES

- Pas de `feat:` commit avant que la fiche existe et que `check-features.sh` + `check-feature-docs.sh <scope>/<id>` passent.
- Pas d'écriture de fiche sans proposition validée explicitement par l'utilisateur.
- `id` DOIT être unique dans le scope (refus si collision).
- `scope` DOIT matcher le dossier parent.
- **Jamais** de worklog sans fiche, **jamais** de fiche sans worklog.
