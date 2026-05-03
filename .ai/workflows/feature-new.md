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
2. **Check-before-create** : si `.docs/features/<scope>/<id>.md` existe → STOP, demander s'il faut l'éditer (rediriger vers `.ai/workflows/feature-update.md`).

### Phase 2 — Écriture fiche
Copier `.docs/FEATURE_TEMPLATE.md` vers `.docs/features/<scope>/<id>.md`, remplir :
- `id`, `scope`, `title`
- `status: draft` (par défaut ; `active` si déjà en cours)
- `depends_on`, `touches`
- `progress.phase: spec`, `progress.updated: <YYYY-MM-DD>`, autres champs vides

### Phase 3 — Worklog init
Créer `.docs/features/<scope>/<id>.worklog.md` avec :
```
# Worklog — <scope>/<id>

## <YYYY-MM-DD> — création
- Feature créée via `.ai/workflows/feature-new.md`
- Scope : <scope>
- Intent initial : <titre>
```

### Phase 4 — Validation
Exécuter :
```bash
bash .ai/scripts/build-feature-index.sh --write
bash .ai/scripts/check-features.sh
```
Si rouge → corriger avant de rendre la main.

### Phase 5 — Output
Afficher le chemin créé. Suggérer la suite :
- Remplir la section **Objectif / Contrats** au fur et à mesure
- Mettre à jour `progress.*` via `.ai/workflows/feature-update.md` lors des changements d'intent pour sauver `progress.*`
- Clôturer via `.ai/workflows/feature-done.md` à la fin pour clôturer

## NON-NEGOTIABLE RULES

- Pas de `feat:` commit avant que la fiche existe et que `check-features.sh` passe.
- `id` DOIT être unique dans le scope (refus si collision).
- `scope` DOIT matcher le dossier parent.
- **Jamais** de worklog sans fiche, **jamais** de fiche sans worklog.
