# Ownership AI Context

Ce repo sépare les fichiers gérés par le template `ai_context` des fichiers propres au projet.

## Upstream-managed

Ces fichiers viennent du template et peuvent évoluer lors de `copier update` :

- `.ai/index.md`
- `.ai/rules/**`
- `.ai/workflows/**`
- `.ai/scripts/**`
- `.ai/templates/**`
- `.ai/agent/**`
- `.ai/quality/**`
- `.ai/schema/**`
- `.ai/config.yml`
- `.ai/context-ignore.md`
- `.ai/reminder.md`
- Shims générés : `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/**`
- Runtime généré : `.githooks/**`, `.github/workflows/**`, `.claude/**`, `.agents/**`

## Project-owned

Ces fichiers appartiennent au repo consommateur :

- `.ai/project/**`
- `AGENTS.md` si le projet choisit volontairement de diverger du shim généré
- Documentation métier du repo : specs, ADR, docs produit, docs architecture et guides internes hors runtime template
- Fiches feature et worklogs sous `.docs/features/**`

## Comportement attendu avec Copier

`copier update` met à jour les fichiers upstream-managed et laisse `.ai/project/**` au projet. Le template configure `.ai/project/**` en `skip_if_exists` et ne scaffold pas ce dossier par défaut.

Si une règle locale a été écrite dans un ancien fichier template comme `.ai/rules/<scope>.md` ou un fichier legacy de type `.ai/workflow/L1_*`, migrer le contenu spécifique au projet vers `.ai/project/**`, puis garder dans le fichier géré seulement une règle générique ou un pointeur court.

Entrée recommandée :

```text
.ai/project/index.md
```

Les agents lisent `.ai/project/index.md` seulement s'il existe. Ils ne chargent pas récursivement `.ai/project/**` ; l'index projet liste les fichiers locaux utiles selon la tâche.
