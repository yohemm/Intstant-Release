# InstantRelease - Documentation technique (POC)

## 0. Documents lies
- `docs/FULL_DOCS.md` : vision complete (cible long terme)
- `docs/ROADMAP.md` : decisions + backlog avant implementation

---

## 1. Perimetre POC et objectifs

InstantRelease est une GitHub Action (composite) qui automatise le cycle de release d'un projet.
Objectifs du POC :
- prouver le flux de release de bout en bout
- valider le versioning base sur les commits
- generer changelog + tag + release
- garder une config unique via `.instantrelease.yml`

Hors scope POC (reserve a `docs/FULL_DOCS.md`) : monorepo complet, matrices complexes,
reporting avance, SBOM, plugins et webhooks complets.

---

## 2. Architecture & flux d'execution

### 2.1 Vue d'ensemble
L'action lit une configuration, puis orchestre une suite d'etapes conditionnelles.
L'execution est lineaire et peut etre court-circuitee par des validations.

### 2.2 Flux principal (POC)
1) Charger `.instantrelease.yml`
2) Verifier les pre-requis (repo propre, token, branche)
3) Calculer la version
4) Generer changelog
5) Creer tag Git
6) Creer release GitHub

### 2.3 Flux optionnels
- build / tests / lint si actives
- scans de dependances / secrets si actives
- deploiement si active

---

## 3. Configuration `.instantrelease.yml` (champ par champ)

### 3.1 Git
- `git.user-name` : identite pour les commits automatiques
- `git.user-email` : email pour les commits automatiques
- `git.auto-commit` : commit auto des fichiers modifies par le release
- `git.auto-push` : push automatique vers `git.target-branch`
- `git.target-branch` : branche cible pour push

### 3.2 Versioning
- `versioning.initial-version` : version de depart si aucun tag
- `versioning.bump` : mode `auto|major|minor|patch|none`
- `versioning.detect-bump` : activation de la detection via commits
- `versioning.indicators.major` : motifs pour major
- `versioning.indicators.minor` : motifs pour minor
- `versioning.indicators.patch` : motifs pour patch
- `versioning.version-prefix` : prefix de tag (ex: `v`)
- `versioning.verify-tag-exists` : stop si tag deja present

### 3.3 Changelog
- `changelog.generate` : activation generation changelog
- `changelog.file` : chemin du fichier changelog
- `changelog.template` : template Handlebars
- `changelog.append-mode` : `prepend|append|replace`
- `changelog.include-contributors` : ajoute auteurs
- `changelog.include-stats` : ajoute stats commits

### 3.4 Release
- `release.create-tag` : creation de tag Git
- `release.create-release` : creation GitHub Release
- `release.release-draft` : release en brouillon
- `release.release-prerelease` : prerelease
- `release.prerelease-suffix` : suffixe prerelease
- `release.tag-delete-on-failure` : supprime tag si echec

### 3.5 Build
- `build.enabled` : active etape build
- `build.command` : commande build
- `build.artifact-path` : chemin des artefacts
- `build.upload-artifact` : upload artefacts

### 3.6 Tests
- `tests.enabled` : active tests
- `tests.unit-tests-command` : commande tests unitaires
- `tests.coverage-threshold` : seuil couverture
- `tests.lint-enabled` : active lint
- `tests.lint-command` : commande lint

### 3.7 Security
- `security.dependency-scan` : audit dependances
- `security.secret-scan` : scan secrets
- `security.commit-signature-check` : verification signatures

### 3.8 Deployment
- `deployment.enabled` : active deploiement
- `deployment.environment` : env cible
- `deployment.command` : commande deploy
- `deployment.post-deploy-validation` : validation post deploy
- `deployment.post-deploy-check-url` : URL de healthcheck

### 3.9 Webhooks
- `webhooks.pre-flight.enabled` : webhook avant release
- `webhooks.pre-flight.url` : URL pre-flight
- `webhooks.pre-flight.retry-attempts` : retry
- `webhooks.pre-flight.timeout` : timeout
- `webhooks.post-release.enabled` : webhook post release
- `webhooks.post-release.url` : URL post release
- `webhooks.post-release.retry-attempts` : retry
- `webhooks.post-release.timeout` : timeout

### 3.10 Plugins
- `plugins.pre-flight.enabled` : script pre-flight
- `plugins.pre-flight.script` : chemin script
- `plugins.pre-flight.timeout` : timeout
- `plugins.post-release.enabled` : script post-release
- `plugins.post-release.script` : chemin script
- `plugins.post-release.timeout` : timeout

### 3.11 Debug & options
- `debug` : logs detailles
- `dry-run` : simulation (pas de tag/push)

---

## 4. Structure de fichiers cible (POC)

Note : `deploy/` et `reporting/` sont des dossiers freres sous `scripts/`,
pas des sous-elements de `pre-deploy-check.sh`.

```
instantrelease/
|-- action.yml
|-- .instantrelease.yml
|-- scripts/
|   |-- pre-flight.sh
|   |-- webhook-call.sh
|   |-- build/
|   |   |-- build.sh
|   |   |-- generate-checksum.sh
|   |   `-- generate-version-file.sh
|   |-- tests/
|   |   |-- unit-tests.sh
|   |   |-- coverage-check.sh
|   |   `-- lint.sh
|   |-- security/
|   |   |-- dependency-scan.sh
|   |   |-- secret-scan.sh
|   |   `-- commit-signature-check.sh
|   |-- versioning/
|   |   |-- calculate-version.sh
|   |   |-- detect-bump-type.sh
|   |   `-- validate-semver.sh
|   |-- changelog/
|   |   |-- generate-changelog.sh
|   |   `-- extract-changelog.sh
|   |-- release/
|   |   |-- create-tag.sh
|   |   |-- auto-commit.sh
|   |   `-- create-release.sh
|   |-- deploy/
|   |   |-- pre-deploy-check.sh
|   |   |-- post-deploy-validation.sh
|   |   `-- rollback.sh
|   `-- reporting/
|       |-- generate-reports.sh
|       |-- compliance-report.sh
|       `-- audit-log-export.sh
|-- templates/
|   |-- changelog-default.hbs
|   |-- compliance-report.hbs
|   `-- pre-flight-summary.hbs
|-- tests/
    |-- unit/
    `-- integration/
```

---

## 5. Modules / scripts prevus (existant vs a venir)

### 5.1 Existant (POC)
- lecture config YAML
- calcul version basique
- generation changelog basique
- creation tag + release (GitHub API)

### 5.2 A venir (cible `docs/FULL_DOCS.md`)
- validation schema YAML
- systeme plugins pre/post
- scans securite avances
- generation SBOM
- gestion monorepo
- rapports d'audit

---

## 6. Versioning + changelog + release

### 6.1 Versioning
- base sur les commits (convention type Angular)
- priorite : major > minor > patch
- fallback sur `initial-version` si aucun tag

### 6.2 Changelog
- genere a partir des commits depuis le dernier tag
- output en Markdown via template

### 6.3 Release
- creation tag `version-prefix + version`
- creation release avec notes extraites du changelog

---

## 7. Tests / securite / deploiement

### 7.1 Tests
- commande unique, retourne code non zero si echec
- blocage de la release en cas d'echec (sauf `dry-run`)

### 7.2 Securite
- audit dependances si active
- scan secrets si active
- stop si severite au-dessus du seuil (a definir)

### 7.3 Deploiement
- execution commande `deployment.command`
- validation optionnelle via URL

---

## 8. Limites POC + backlog technique

### 8.1 Limites POC
- pas de monorepo
- pas de matrice d'environnements
- pas de reporting avance
- pas de signatures GPG

### 8.2 Backlog technique
Voir `docs/ROADMAP.md` pour la priorisation et les lots.
