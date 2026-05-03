# Procédure interne — feature-handoff

**Goal** : formaliser une passation de travail sur une feature, soit vers un autre scope (cross-scope impose un handoff selon `.ai/index.md`), soit vers une autre session / un autre humain.

**Role** : Scribe de passation. Ne code pas, ne modifie pas la feature applicativement.

**Procedure chain** : `.ai/workflows/feature-update.md` → **`.ai/workflows/feature-handoff.md`** → STOP + confirmation utilisateur → autre session prendra le relais via `.ai/workflows/feature-resume.md`.

## INPUT ATTENDU

- `scope/id` de la feature
- `target_scope` (scope ou entité qui reprend)
- `what_delivered` : ce qui est fait côté source (puces)
- `what_next_needs` : ce que le target doit faire (puces)
- `blockers` : ce qui bloque la suite (vide si rien)

## PHASES

### Phase 1 — Validation préalable
1. Lire la feature + son worklog.
2. Vérifier que `progress.phase` est cohérent (pas `done` — utiliser `feature-done` à la place).
3. Si le scope courant n'a pas d'evidence (build/tests passants) → warn mais autoriser sur confirmation user.

### Phase 2 — Bloc HANDOFF
Ajouter au bas du worklog :
```
## <YYYY-MM-DD HH:MM> — HANDOFF → <target_scope>

### What delivered
- <puces>

### What next needs
- <puces>

### Blockers
- <puces ou "aucun">

### Status
PENDING  <!-- PENDING | IN PROGRESS | DONE, mis à jour par la session cible -->
Source session : <id de session courante si dispo>
```

### Phase 3 — Update frontmatter
- `progress.phase` → `spec` si target va re-spec, `implement` sinon (demander)
- `progress.step` → `"handoff pending → <target_scope>"`
- `progress.resume_hint` → `"voir HANDOFF du <date> dans worklog"`
- `progress.updated` → date du jour

Rebuild l'index :
```bash
bash .ai/scripts/build-feature-index.sh --write
```

### Phase 4 — STOP
Afficher à l'utilisateur :
- Résumé du HANDOFF (1-2 phrases)
- Demande explicite de confirmation pour basculer de scope / session

**Ne pas enchaîner** sur des écritures de code côté target dans le même tour.

## NON-NEGOTIABLE RULES

- Un HANDOFF PENDING qui reste > 7j sans bouger → signalé par `.ai/workflows/feature-resume.md` comme STALE.
- Jamais de HANDOFF sans `what_next_needs` (vide = pas un handoff, juste un update).
- Le status `PENDING → IN PROGRESS → DONE` est mis à jour par la session cible (pas par la procédure source).
- Un HANDOFF est **append**, jamais remplacé. Plusieurs handoffs peuvent coexister si la feature passe par plusieurs scopes.
