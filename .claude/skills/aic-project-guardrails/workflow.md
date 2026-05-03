# Workflow — aic-project-guardrails

**Goal** : produire / mettre à jour `.ai/guardrails.md` avec les **non-goals** et le **glossaire métier** du projet — pour orienter l'agent et éviter qu'il dérive vers des features non souhaitées ou utilise un vocabulaire imprécis.

**Role** : Scribe + design partner. Pas de code applicatif dans ce skill — uniquement documentation d'orientation agent.

**Quand l'invoquer** : 1-2 fois dans la vie d'un projet. Bootstrap après `copier copy`, puis révisions ponctuelles quand les non-goals évoluent (pivot produit, nouveau scope explicitement abandonné).

**Pourquoi pas Vision/Users ici** : ces sections sont déjà dans le README et la `project_description` (copier). Dupliquer = désynchronisation garantie. Ce skill se concentre sur ce qui n'est *jamais* écrit ailleurs.

## PRECONDITION

- Le projet a été scaffoldé par `copier copy` (présence de `.ai/index.md` et `.copier-answers.yml` recommandée mais non obligatoire).
- L'utilisateur a une idée claire d'au moins 1 non-goal. Sinon → demander 2-3 questions de cadrage avant de commencer la rédaction.

## MANDATORY READS

- `.ai/index.md` (séquence canonique — pour vérifier l'état de la référence Pack A vers `guardrails.md`)
- `.ai/guardrails.md` si présent (mode update)
- `.copier-answers.yml` si présent (récupérer `project_name` et `project_description` comme contexte de cadrage)
- `README.md` du projet (rapide scan — pour ne PAS dupliquer ce qui s'y trouve déjà)

## PHASES

### Phase 1 — Cadrage

1. **Détection** : `.ai/guardrails.md` existe-t-il ?
   - **Présent** → afficher son contenu, demander : `update` (modifier interactivement) / `replace` (repartir de zéro) / `cancel`.
   - **Absent** → mode bootstrap, aller en Phase 2.

2. **Pré-remplissage** : si `.copier-answers.yml` présent, lire `project_name` et `project_description` pour cadrer les questions à venir (« Le projet est *<description>*. Qu'est-ce qui est *explicitement* hors-scope ? »).

### Phase 2 — Non-goals (obligatoire, ≥1 item)

Dialogue ciblé. Exemples de questions :
- « Quelles fonctionnalités, types d'utilisateurs ou cas d'usage sont *explicitement* abandonnés ? »
- « Y a-t-il des architectures / technologies / patterns qu'on a *décidé* de ne pas adopter (avec raison documentée) ? »
- « Des sujets que tu as déjà refusés à plusieurs reprises ? »

Pour chaque non-goal recueilli :
- Formuler en 1-ligne actionnable (« pas de SSO entreprise », pas « pas de complexité »).
- Demander une raison courte si non-évidente (« pour éviter que l'agent ne propose `Auth0`/`Okta` à chaque scaffold auth »).

**Refus** : si 0 item après 2 relances, abort avec message :
```
/aic-project-guardrails — abort
Aucun non-goal défini. Sans non-goals explicites, ce skill n'apporte pas de valeur (le glossaire seul peut vivre dans le README).
Reviens quand tu as identifié au moins 1 hors-scope clair, ou édite directement le README pour le glossaire.
```

### Phase 3 — Glossaire métier (optionnel)

Question d'ouverture : « Y a-t-il du vocabulaire métier spécifique que l'agent doit utiliser tel quel (acronymes internes, concepts domaine, noms de produits proches qui prêtent à confusion) ? »

- Si **non** ou liste vide → section omise.
- Si **oui** → recueillir entrées au format `Terme → définition` (1-ligne).

### Phase 4 — Récapitulatif + confirmation

Afficher un récap structuré :
```
À écrire dans .ai/guardrails.md :

Non-goals (N items) :
  - …
  - …

Glossaire (M entrées) :
  - … : …
  - …

OK pour écrire ? [oui / non / ajuster]
```

Si `ajuster` → revenir à la phase concernée. Si `non` → annuler sans écriture.

### Phase 5 — Écriture

Écrire `.ai/guardrails.md` selon le template suivant (omettre la section Glossaire si vide) :

```markdown
# {{ project_name }} — Guardrails agent

> Ce que l'agent doit savoir pour rester dans les rails.
> Pour la vision/utilisateurs/architecture : voir [README](../README.md).
> Ré-exécuter `/aic-project-guardrails` pour réviser.

## Non-goals (explicitement hors-scope)

L'agent ne doit *pas* proposer ou implémenter :
- <item 1> *(raison si non-évidente)*
- <item 2>

## Glossaire métier

Vocabulaire à utiliser tel quel :
- **<terme>** : <définition>
- **<acronyme>** : <développé> — <définition>

---
*Généré/mis à jour par `/aic-project-guardrails` le YYYY-MM-DD.*
```

> Note : utiliser le `project_name` réel du projet courant, pas `{{ project_name }}` littéral. Si non récupérable depuis `.copier-answers.yml`, demander à l'utilisateur.

### Phase 6 — Auto-référence Pack A

Vérifier que `.ai/index.md` mentionne bien `guardrails.md` dans la séquence Pack A.
- **Mention présente** → rien à faire.
- **Mention absente** → proposer à l'utilisateur d'ajouter une ligne du type :
  ```
  3. `.ai/guardrails.md` — non-goals + glossaire métier (si présent)
  ```
  juste après l'étape `QUALITY_GATE.md`. Renuméroter les étapes suivantes.

### Phase 7 — Output

Afficher :
```
✅ .ai/guardrails.md créé/mis à jour (N non-goals, M entrées glossaire)
✅ référence Pack A vérifiée dans .ai/index.md

Prochaine étape : commit `chore(workflow): cadre les guardrails projet (non-goals + glossaire)`
```

## NON-NEGOTIABLE RULES

- **Récap obligatoire avant écriture** : pas de `Write` silencieux.
- **Non-goals : ≥1 item** sinon abort (cf. Phase 2).
- **Glossaire : optionnel** — section omise si vide, pas écrite vide.
- **Pas de section Vision / Users / Roadmap** dans le fichier généré (intentionnel — éviter doublon avec README).
- **Pas de `feat:` commit** déclenché par ce skill : c'est de la doc d'orientation, pas une feature applicative. Suggérer `chore(workflow):` ou `docs(workflow):`.
- **Idempotent** : ré-invocation = mode update sans perte de contenu sauf confirmation explicite (`replace`).
- **Pas d'injection runtime** : ne pas modifier `.ai/scripts/pre-turn-reminder.sh` ni `.ai/reminder.md` (le fichier est lu via Pack A en début de session, coût tokens nul à chaque tour).
