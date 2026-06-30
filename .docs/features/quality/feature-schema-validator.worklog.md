# Worklog — quality/feature-schema-validator

> Journal append-only. Ne jamais réécrire l'historique ; ajouter en bas.

## 2026-06-30 — création (pilot ze-solution, P3, après HANDOFF product→quality)

- Fiche créée via `aic-pilot` (pilot `.docs/pilots/2026-06-30-ze-solution.md`, item P3).
- Objet : débloquer C2a — vrai validateur JSON-Schema des fiches, en remplacement de l'heuristique bash, avec **fallback bash conservé** (pas de dépendance dure).
- Décisions : validateur réel + fallback ; runtime recommandé `check-jsonschema` (pip, car Python/pip déjà requis par Copier) ; migration warn→fail alignée sur `core/okf-strict-profile`.
- Phase : spec. Décision ouverte : runtime exact (pip vs node vs lib) et emplacement (script dédié vs inline `check-features`).
- Prochaine étape : trancher le runtime, brancher en mode warn dans `check-features`, écrire tests valides/invalides.

## 2026-06-30 — recadrage + incrément 1 (durcir via jq/yq, zéro dép)

- **Recadrage** (via `aic-pilot`, P3, option « durcir via jq/yq ») : le spike a montré que le schéma documente l'éthos « bash/jq/yq, AUCUNE dépendance ajv/check-jsonschema » (`$comment`). La reco initiale `check-jsonschema` est **abandonnée** (contredisait une décision actée). Le « vrai validateur » = lire le schéma comme donnée.
- **Incrément 1 livré** : `check-features.sh` dérive désormais les clés requises du schéma (`.required`) via `read_schema_enum '.required' …` (fallback hardcodé conservé). Avant : liste `id scope title status depends_on touches` codée en dur.
- Surface modifiée = `check-features.sh` (possédée par `core/feature-mesh` → worklog core mis à jour) + `.jinja` (parité) + nouveau test `tests/unit/test-schema-driven-required.sh` (en `touches:` de cette fiche).
- Validation : nouveau test PASS (clé `owner` ajoutée au schéma temp → exigée), `check-features --no-write` réel PASS, `check-dogfood-drift` aligné, régressions check-features (yaml-strict, frontmatter-boundary, id-parity) PASS, freshness staged OK.
- **HANDOFF `quality/smoke-test`** : brancher `test-schema-driven-required.sh` dans `tests/smoke-test.sh` (étape `[0q/28]`) — **non fait ici** pour rester focalisé (même pattern que `test-check-features-yaml-strict` → cf. worklog `core/feature-mesh`). Le test tourne en standalone.
- **Follow-up CHANGELOG** : entrée Unreleased différée (CHANGELOG.md est en `touches:` de 6 features → couplage freshness ; à batcher avec la suite de P3). Illustre directement le constat P6 (taxe de cérémonie).
- Suite : dériver le pattern `id` (`(?:`→`(` pour ERE) et enums imbriqués `product.portfolio` si utile — toujours zéro dépendance externe.
