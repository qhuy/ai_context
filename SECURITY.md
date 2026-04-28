# SECURITY — ai_context

## Périmètre

`ai_context` est un template `copier` qui scaffolde des hooks (Claude Code, git) et des scripts runtime locaux. Il n'expose pas de service réseau ni d'endpoint public ; les vecteurs d'attaque concernent les **données locales** du projet consommateur (worklogs, logs volatiles, index JSON).

## Politique : pas de secrets dans les artefacts feature mesh

Les fichiers suivants sont **versionnés** par défaut :

- `.docs/features/<scope>/<id>.md` (frontmatter + doc métier)
- `.docs/features/<scope>/<id>.worklog.md` (append-only, alimenté par les hooks)

Les fichiers suivants sont **gitignorés** (volatiles ou cache) :

- `.ai/.feature-index.json` (cache)
- `.ai/.session-edits.log` (log volatile, vidé à chaque flush)
- `.ai/.session-edits.flushed` (marqueur)
- `.ai/.progress-history.jsonl` (snapshots des transitions, append-only, 50 dernières)

**Ne mets jamais** dans une feature ou un worklog :
- credentials (tokens, passwords, clés API)
- secrets internes (URLs internes sensibles, identifiants tenant)
- contenus de fichiers sources (les hooks loguent **uniquement** des chemins, jamais le contenu d'un fichier)

Si un secret se retrouve par accident dans un worklog versionné, traite-le comme une fuite : rotate le secret, purge l'historique git si nécessaire (BFG / `git filter-repo`).

## Ce que les hooks loguent

| Hook | Écrit dans | Contenu |
|---|---|---|
| `PostToolUse` Write/Edit | `.ai/.session-edits.log` (volatile) | timestamp + chemin du fichier édité + features impactées (scope/id). **Pas** le contenu. |
| `Stop` (auto-worklog-flush) | `.docs/features/<scope>/<id>.worklog.md` | bloc `Fichiers modifiés` (liste de chemins) + bump `progress.updated`. |
| `Stop` (auto-progress) | `.docs/features/<scope>/<id>.md` + `.ai/.progress-history.jsonl` | transition `phase` (ex: `spec → implement`) + snapshot pour `/aic undo`. |
| `pre-commit` (git) | idem auto-progress | même comportement, version agent-agnostique. |
| `commit-msg` (git) | aucun fichier | rejette les commits non-Conventional ou `feat:` sans feature touchée. |

Aucun hook ne lit/loggue le contenu des fichiers édités.

## Hooks tiers et trust

`copier copy` rend des fichiers Jinja. **Ne charge jamais un template dont tu ne connais pas l'auteur** sans relecture, et préfère `--vcs-ref=<tag>` à `HEAD` pour figer la version. Le flag `--trust` est requis car le template scaffolde des hooks exécutables — vérifie la source avant de l'utiliser.

## Permissions des hooks

Les hooks Claude Code sont configurés via `.claude/settings.json`. **Tu** décides dans `/hooks` ce qui s'active dans ton environnement Claude Code — rien n'est imposé runtime. Désactive ce que tu n'utilises pas.

Les git hooks (`.githooks/*`) ne sont activés que si `git config core.hooksPath .githooks`. Sans cette config, ils restent inertes.

## Signaler une vulnérabilité

Pour un signalement coordonné, ouvre une **GitHub Security Advisory** sur le repo `qhuy/ai_context` plutôt qu'une issue publique. Si l'advisory n'est pas dispo, contacte directement le mainteneur via les coordonnées du repo.

Périmètre des vulnérabilités jugées en scope :
- Exécution de code arbitraire via un template malveillant rendu en confiance
- Fuite de secrets via les hooks par défaut
- Bypass des garde-fous Conventional Commits / feature mesh permettant un commit de feature non documentée

Hors scope :
- Bugs fonctionnels (issues classiques)
- Suggestions UX
- Sécurité spécifique aux projets consommateurs (cf. leur `SECURITY.md` propre)
