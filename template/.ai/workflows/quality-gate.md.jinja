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
bash .ai/scripts/check-features.sh
bash .ai/scripts/check-feature-docs.sh     # warnings par défaut ; --strict <scope/id> près de DONE
bash .ai/scripts/check-feature-coverage.sh   # --warn (défaut)
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
| check-features | ✅ / ❌ | <sortie> |
| check-feature-docs | ✅ / ⚠️ / ❌ | <sections manquantes ou strict OK> |
| check-feature-coverage | ✅ / ⚠️ | <N orphelins> |
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
- Idempotent : relancer la procédure ne change rien dans le repo (lecture seule sauf rebuild éventuel de l'index).
