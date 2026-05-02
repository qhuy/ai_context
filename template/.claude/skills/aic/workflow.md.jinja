# Workflow — `/aic` (override conversationnel)

**Rôle** : reprendre la main quand l'auto-progression invisible (hook Stop + pre-commit) se trompe ou pour gérer des cas exceptionnels qu'elle n'infère pas.

**Contexte** : depuis `workflow/conversational-skills` v3, le système est en auto-progression par défaut. L'humain prompte librement sans préfixe ; le hook `Stop` bascule les phases et le worklog se remplit tout seul. `/aic` n'est utile QUE quand ce comportement automatique doit être corrigé ou forcé.

**Skill chain** : aucune — `/aic` est terminal (action ou undo, puis STOP).

## MODES

### Mode 1 — `/aic undo` (annulation de la dernière auto-progression)

Revient à l'état `progress` précédant la dernière transition appliquée par le hook.

1. Lire `.ai/.progress-history.jsonl` — récupérer la **dernière ligne** (snapshot le plus récent).
2. Format attendu : `{ts, feature, path, from: {phase, status}, to: {phase, status}}`.
3. Si fichier absent ou vide → répondre « Rien à annuler (aucun snapshot). » et STOP.
4. Montrer à l'utilisateur ce qui va être annulé (feature, from → to, timestamp) et demander confirmation **explicite** (« tape "go" pour annuler, ou "non" pour abandonner »). Pour préview headless : `bash .ai/scripts/aic-undo.sh` (mode `--dry-run` par défaut).
5. Sur confirmation : invoquer `bash .ai/scripts/aic-undo.sh --apply`. Le script s'occupe de tout :
   - Patche le frontmatter de `path` (restaure `progress.phase = from.phase` et `status = from.status`).
   - Append au worklog une ligne `## <ts> — /aic undo` expliquant la restauration.
   - Supprime la **dernière ligne** de `.progress-history.jsonl` (FIFO consume).
   - Rebuild `.ai/.feature-index.json`.
6. Rapporter : feature, état restauré, prochain `/aic undo` pointera sur l'entrée précédente.

> Le script `aic-undo.sh` est testable en CI (smoke-test étape E2E). Si tu dois faire l'undo manuellement (script absent), suis le contrat décrit dans son `--help`.

### Mode 2 — `/aic <phrase libre>` (override explicite)

Exemples valides :
- `/aic non, repasse en spec` → annule une bascule mal inférée
- `/aic marque ça en blocked, j'attends la spec backend` → met `progress.blockers`
- `/aic je rouvre feature-mesh pour ajouter status stable` → réouverture + phase
- `/aic handoff vers quality` → émet HANDOFF vers autre scope
- `/aic force done` → passe `status: done` sans attendre l'inférence evidence

1. **Résoudre la cible** :
   - Si un `<scope>/<id>` est cité explicitement → l'utiliser.
   - Sinon : chercher fuzzy dans `.ai/.feature-index.json` (mots-clés de la phrase matchés sur `id` / `title`).
   - Si ambigu → lister les candidats et demander.
   - Si zéro match et la phrase décrit une création → proposer `/aic-feature-new` (ou créer direct si intent très clair).
2. **Détecter l'intent** (tableau de correspondance indicatif, pas exhaustif) :

   | Vocabulaire | Action |
   |---|---|
   | « repasse en spec / implement / review » | bump `progress.phase` (rollback ou avancée) |
   | « blocked / bloqué / j'attends » | ajouter entrée `progress.blockers` + mettre à jour `resume_hint` |
   | « rouvre / réouvre » | `status: active` + phase régressive |
   | « handoff vers X » | émettre HANDOFF formel + update fiche cible |
   | « done / livré / fini » | forcer `status: done` (skippe l'inférence evidence) |
   | « archive / deprecated » | bump `status` correspondant |

3. **Afficher un plan** (1-3 lignes) :
   ```
   Plan /aic :
     feature : <scope>/<id>
     from    : <phase/status actuels>
     to      : <phase/status cibles>
     action  : <une ligne de description>
   Tape "go" pour appliquer, ou décris une correction.
   ```
4. **Attendre confirmation "go"** (ou variante : "ok", "oui", "y").
5. Sur confirmation :
   - Snapshot dans `.ai/.progress-history.jsonl` (même format que le hook Stop).
   - Patcher le frontmatter via awk (même pattern que `auto-progress.sh`).
   - Appender au worklog une ligne `## <ts> — /aic override` décrivant l'action humaine.
   - Rebuild l'index.
6. **Rapporter** dans la ligne d'état finale.

## NON-NEGOTIABLE RULES

- **Toujours confirmer avant d'écrire** (même sur `/aic undo` : l'utilisateur peut s'être trompé de sens).
- **Ne jamais écrire dans `<docs_root>/features/` sans snapshot préalable** dans `.progress-history.jsonl` (pour permettre un `/aic undo` récursif).
- **Ne jamais éditer le worklog à la main** — toujours par append conforme au format existant (`## <ts> — <source>`).
- Si la phrase est ambiguë ou ne matche aucun intent du tableau → demander reformulation plutôt que deviner.
- `/aic` ne doit jamais contourner les hard rules de `core/feature-mesh` : si `<scope>/<id>` n'existe pas, création explicite demandée.
- Ne pas confondre `/aic undo` (annule une transition auto) avec `git revert` (annule un commit) — si l'utilisateur veut l'un pour l'autre, clarifier.

## TROUBLESHOOTING

- `.progress-history.jsonl` absent → le hook n'a encore rien appliqué ou le repo est neuf. `/aic undo` est no-op.
- Index stale (commit non rebuild) → lancer `bash .ai/scripts/build-feature-index.sh --write` avant résolution fuzzy.
- Conflit (ex: `/aic done` sur une fiche en `phase: spec` sans aucun edit) → warn l'utilisateur, demander confirmation renforcée.
