# Procédure interne — quality-gate

**Goal** : produire un verdict go/no-go factuel avant `feat:` commit, PR, ou `feature-done`. Zéro interprétation, uniquement des checks déterministes.

**Role** : Inspecteur. Lecture seule, pas de correction.

**Procedure chain** : (travail) → **`.ai/workflows/quality-gate.md`** → (corrections si no-go) → `.ai/workflows/feature-done.md` ou `git commit`.

## PHASES

### Phase 1 — Checks structurels
Exécuter **dans cet ordre**, ne pas s'arrêter au premier fail :
```bash
bash .ai/scripts/check-shims.sh
bash .ai/scripts/check-agent-config.sh
bash .ai/scripts/check-ai-references.sh
bash .ai/scripts/check-features.sh --no-write
bash .ai/scripts/check-feature-docs.sh --strict
bash .ai/scripts/check-feature-coverage.sh --strict
bash .ai/scripts/check-feature-freshness.sh --worktree --warn   # fraîcheur fin de tour (informatif ; bloquant via hook Stop côté Claude)
bash .ai/scripts/check-touches-breadth.sh   # advisory : sur-couverture touches: (candidats touches_shared)
```

### Phase 2 — Observabilité
```bash
bash .ai/scripts/measure-context-size.sh
```
Si total chars > **5000** → warn (contexte gonflé, envisager passer des features en `done` ou splitter).

### Phase 3 — Feature en cours (si scope spécifié)
Si l'utilisateur passe `<scope/id>` en argument :
1. Vérifier que `progress.phase` ∈ {`test`, `review`, `done`} (sinon warn : "feature pas assez avancée pour gate").
2. Vérifier que `progress.blockers` est vide (sinon no-go).
3. Vérifier que le worklog a au moins une entrée dans les 14 derniers jours.

### Phase 4 — Rapport structuré
Format markdown, même structure à chaque fois :

```
## Quality gate — <scope/id ou repo>

| Check | Status | Détails |
|---|---|---|
| check-shims | ✅ / ❌ | <sortie courte> |
| check-agent-config | ✅ / ⚠️ / ❌ | <configs agents et scripts référencés> |
| check-ai-references | ✅ / ❌ | <sortie> |
| check-features --no-write | ✅ / ❌ | <sortie> |
| check-feature-docs --strict | ✅ / ❌ | <sections manquantes ou strict OK> |
| check-feature-coverage --strict | ✅ / ❌ | <N orphelins> |
| check-feature-freshness --worktree | ✅ / ⚠️ | <features dont le code working-tree change sans doc> |
| check-touches-breadth | ✅ / ℹ️ | <fichiers infra partagés en touches: direct, candidats touches_shared> |
| measure-context-size | ℹ️ | <chars total> |
| feature.progress | ✅ / ❌ | phase=<X>, blockers=<N> |

### Verdict
GO / NO-GO

### Actions requises (si NO-GO)
- <bullet point actionnable>
```

## NON-NEGOTIABLE RULES

- **Aucun fix dans cette procédure** — si un check fail, rendre la main à l'utilisateur avec action à faire. Le fix se fait hors gate.
- GO exige **zéro** ❌ ; les ⚠️ n'empêchent pas GO mais sont listés.
- Ne jamais cacher un fail. Rapport complet même si long.
- Idempotent : relancer la procédure ne change rien dans le repo. Les rebuilds d'index doivent être lancés explicitement hors gate.
