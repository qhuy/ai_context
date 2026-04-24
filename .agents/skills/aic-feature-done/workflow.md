# Workflow — aic-feature-done

**Goal** : clôturer proprement une feature — evidence vérifiée, status `done`, worklog scellé, commit Conventional suggéré.

**Role** : Clôturant. Valide et scelle, ne refactorise pas.

**Skill chain** : `/aic-feature-update` (phase=review) → **`/aic-quality-gate`** → **`/aic-feature-done`** → commit.

## INPUT ATTENDU

- `<scope/id>` de la feature à clôturer

## PHASES

### Phase 1 — Pré-requis
1. Vérifier que `progress.phase` ∈ {`review`, `done`}. Sinon → STOP, demander à l'utilisateur de passer par `/aic-feature-update` d'abord.
2. Vérifier que `progress.blockers` est vide. Sinon → STOP.
3. Lire la fiche et le worklog en entier.

### Phase 2 — Quality gate
Invoquer `/aic-quality-gate` avec `<scope/id>`. Verdict NO-GO → STOP, transférer les actions à l'utilisateur.

### Phase 3 — Evidence
Demander à l'utilisateur (ou lire depuis le worklog récent) :
- Build : commande + résultat (✅ pass)
- Tests : commande + résultat (✅ pass)
- Doc impact : fiche à jour, sections `Contrats` et `Comportement attendu` remplies

Si une evidence manque → STOP.

### Phase 4 — Mise à jour frontmatter
```yaml
status: done
progress:
  phase: done
  step: ""
  blockers: []
  resume_hint: "feature clôturée le <date>"
  updated: <YYYY-MM-DD>
```

### Phase 5 — Scellage worklog
Ajouter l'entrée **finale** :
```
## <YYYY-MM-DD HH:MM> — DONE

### Evidence
- Build : <command> ✅
- Tests : <command> ✅ (<N> passed)

### Résumé livré
- <2-4 bullets du scope final>

### Commit suggéré
feat(<scope>): <titre court>

(Respecte Conventional Commits — fr.)
```

### Phase 6 — Rebuild + suggestion commit
```bash
bash .ai/scripts/build-feature-index.sh --write
bash .ai/scripts/check-features.sh
```

Afficher à l'utilisateur la commande `git commit` prête, **sans l'exécuter** (l'utilisateur la lance).

## NON-NEGOTIABLE RULES

- Pas de `status: done` sans evidence build+tests. Jamais.
- Une feature `done` ne doit plus apparaître dans `/aic-feature-resume` (c'est le but du filtre par status v0.6).
- Le worklog est **scellé** : aucune entrée ultérieure dans ce worklog. Si la feature doit repartir → `/aic-feature-update` la repasse en `status: active` + nouvelle phase (cas rare, à documenter explicitement dans le worklog).
- Commit suggéré, **jamais exécuté** par le skill lui-même.
