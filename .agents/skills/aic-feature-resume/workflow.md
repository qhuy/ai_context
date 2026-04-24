# Workflow — aic-feature-resume

**Goal** : reprendre un travail interrompu (nouvelle session, switch de branche, bascule de scope) sans perdre le fil.

**Role** : Lecteur d'état. Zéro écriture dans ce skill.

**Skill chain** : `/aic-feature-resume` → (travail) → `/aic-feature-update` (à chaque pause) → `/aic-feature-done`.

## PHASES

### Phase 1 — Scan
Exécuter :
```bash
bash .ai/scripts/resume-features.sh
```
Output attendu : 4 buckets (EN COURS / BLOQUÉES / STALE / À FAIRE).

### Phase 2 — Sélection
- Si **un seul** candidat EN COURS → le charger d'office.
- Si **plusieurs** → demander à l'utilisateur laquelle reprendre (ne PAS deviner).
- Si **aucun EN COURS** mais BLOQUÉES → lister les blockers, demander si on débloque.
- Si vide total → suggérer `/aic-feature-new`.

### Phase 3 — Chargement du contexte
Pour la feature choisie (`<scope>/<id>`) :
1. Lire `.docs/features/<scope>/<id>.md` **en entier** (frontmatter + corps).
2. Lire `.docs/features/<scope>/<id>.worklog.md` **en entier** (last-in, last-out : la fin décrit l'état actuel).
3. Lire `.ai/rules/<scope>.md` si pas déjà chargé ce tour.
4. Résumer à l'utilisateur en 3-5 lignes :
   - Où on en est (`progress.phase` + `progress.step`)
   - Dernière entrée du worklog
   - Blockers éventuels
   - Prochaine action recommandée (depuis `progress.resume_hint`)

### Phase 4 — Confirmation
Demander explicitement : "Je reprends ici, d'accord ?" avant toute écriture de code.

## NON-NEGOTIABLE RULES

- **Ne jamais supposer** quelle feature reprendre sans confirmation explicite.
- Si `progress.updated` > 14j → signaler la staleness, demander si la spec est encore valide.
- Si le worklog contredit `progress.phase` → warn et demander arbitrage.
- Après reprise → le prochain `/aic-feature-update` DOIT refléter le fait qu'on a repris (ligne "reprise par <session>").
