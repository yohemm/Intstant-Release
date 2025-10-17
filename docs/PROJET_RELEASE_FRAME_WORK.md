# 🛠️ **Instant-Release — Architecture Technique & Feature Set Complet**

## 1️⃣ Objectif Technique

* Fournir un **framework GitHub Actions** pour le **versioning sémantique automatisé**, la **gestion des changelogs**, les **tags Git**, et la **création de releases**.
* Architecture **composite + scripts Bash** pour :

  * Modularité : différents modes (`get-version`, `bump`, `changelog`, `tag`, `release`, etc.)
  * Extensibilité via plugins/scripts
  * Mode monorepo / multi-package
* Support complet **CI/CD** : idempotence, retry, dry-run, audit logs.

---

## 2️⃣ Architecture Générale

```
Instant-Release (composite action)
├─ entrypoint.yml  -> dispatch selon `mode`
├─ scripts/
│   ├─ get_version.sh
│   ├─ bump_version.sh
│   ├─ generate_changelog.sh
│   ├─ create_tag.sh
│   ├─ gh_release.sh
│   ├─ detect_changed_packages.sh
│   ├─ auto_commit.sh
│   ├─ validate_token.sh
│   ├─ semantic_guard.sh
│   └─ plugin_runner.sh
├─ .instantrelease.yml (optionnel)
└─ utils/
    ├─ logging.sh
    ├─ git_helpers.sh
    └─ json_helpers.sh
```

* **entrypoint.yml** : centralise la logique, exécute le script correspondant au `mode`.
* **scripts/** : chaque feature = un script indépendant.
* **utils/** : fonctions communes (logs, git wrapper, JSON output).

---

## 3️⃣ Modes / Features Techniques Complètes

| Catégorie                 | Feature                      | Description Technique                           | Inputs                    | Outputs                                       | Script associé                         |                   |                  |       |        |                          |                   |
| ------------------------- | ---------------------------- | ----------------------------------------------- | ------------------------- | --------------------------------------------- | -------------------------------------- | ----------------- | ---------------- | ----- | ------ | ------------------------ | ----------------- |
| Versioning Core           | `get-current-version`        | Lit la version depuis tag Git, fichier ou input | `source:file              | tag                                           | input`                                 | `current_version` | `get_version.sh` |       |        |                          |                   |
|                           | `bump-version`               | Détermine et applique bump (`major              | minor                     | patch                                         | auto`) selon pattern commit            | `bump:auto        | major            | minor | patch` | `new_version, bump_type` | `bump_version.sh` |
|                           | `extract-breaking-changes`   | Liste les commits de type breaking              | `pattern`                 | `breaking_commits[]`                          | intégré dans commit parser             |                   |                  |       |        |                          |                   |
|                           | `get-commit-stats`           | Statistiques commits depuis dernier tag         | —                         | `commit_count, contributors[], files_changed` | utils/git_helpers.sh                   |                   |                  |       |        |                          |                   |
| Changelog                 | `generate-changelog`         | Génère ou met à jour `CHANGELOG.md`             | `since_tag, template`     | `has_changes`                                 | `generate_changelog.sh`                |                   |                  |       |        |                          |                   |
|                           | `append-changelog`           | Ajoute une section au changelog existant        | `section_title, content`  | `updated_changelog`                           | `generate_changelog.sh`                |                   |                  |       |        |                          |                   |
|                           | `extract-changelog`          | Renvoie dernière section pour release notes     | —                         | `latest_changelog`                            | `generate_changelog.sh`                |                   |                  |       |        |                          |                   |
|                           | `changelog-to-release-notes` | Conversion Markdown/HTML                        | `format: md/html/plain`   | `release_notes`                               | `generate_changelog.sh`                |                   |                  |       |        |                          |                   |
| Tag & Release             | `create-tag`                 | Crée/pousse tag Git (signé si demandé)          | `tag_name, sign, push`    | `tag_created`                                 | `create_tag.sh`                        |                   |                  |       |        |                          |                   |
|                           | `gh-release`                 | Crée GH release avec changelog et assets        | `release_notes, assets[]` | `release_url`                                 | `gh_release.sh`                        |                   |                  |       |        |                          |                   |
| Monorepo / Multi-package  | `detect-changed-packages`    | Liste packages ayant changé                     | `package_paths[]`         | `changed_packages[]`                          | `detect_changed_packages.sh`           |                   |                  |       |        |                          |                   |
|                           | `package-release`            | Bump/tag/changelog pour chaque package          | `changed_packages[]`      | `package_version_map`                         | `package_release.sh`                   |                   |                  |       |        |                          |                   |
| CI/CD Utilities           | `dry-run`                    | Simule toutes les opérations                    | `enable:true/false`       | `dryrun_artifact`                             | géré dans chaque script                |                   |                  |       |        |                          |                   |
|                           | `retry-on-failure`           | Réessaye étape X fois en cas d’erreur           | `max_attempts`            | `success/fail`                                | wrapper utils                          |                   |                  |       |        |                          |                   |
|                           | `idempotent-check`           | Vérifie si version/tag existe déjà              | `tag/version`             | `exists:true/false`                           | utils/git_helpers.sh                   |                   |                  |       |        |                          |                   |
|                           | `validate-token`             | Vérifie permissions GH_TOKEN                    | —                         | `can_push, can_tag`                           | `validate_token.sh`                    |                   |                  |       |        |                          |                   |
|                           | `auto-commit`                | Commit automatique du changelog ou version      | `branch, files[]`         | `commit_sha`                                  | `auto_commit.sh`                       |                   |                  |       |        |                          |                   |
| Reporting & Extensibilité | `generate-release-metadata`  | JSON complet release                            | —                         | `release_metadata.json`                       | utils/json_helpers.sh                  |                   |                  |       |        |                          |                   |
|                           | `notify-slack`               | Notification Slack/Discord/Teams                | `webhook_url, message`    | `status`                                      | plugin_runner.sh                       |                   |                  |       |        |                          |                   |
|                           | `plugin-run`                 | Exécution script utilisateur après release      | `script_path`             | `exit_code`                                   | plugin_runner.sh                       |                   |                  |       |        |                          |                   |
| Quality & Guardrails      | `semantic-guard`             | Vérifie conventions commit                      | `patterns[]`              | `violations[]`                                | `semantic_guard.sh`                    |                   |                  |       |        |                          |                   |
| Configuration             | `config-merge`               | Fusion inputs + YAML externe                    | `inputs[], config_file`   | `merged_config`                               | entrypoint.yml + utils/json_helpers.sh |                   |                  |       |        |                          |                   |

---

## 4️⃣ Inputs/Outputs Consolidés (v2 modulaire)

### Inputs

* `mode` : `get-version`, `bump`, `changelog`, `tag`, `release`, `full`
* `trigger-branches` : branches à surveiller
* `dry-run` : true/false
* `retry-attempts` : int, nombre de retry
* `monorepo` : true/false
* `config-file` : chemin fichier YAML
* `plugins` : liste scripts post-release
* `slack-webhook` : URL notification
* Commit pattern configs : `breaking-change-indicators`, `feature-types`, `fix-types`, `refactor-types`
* Git config : `git-user-name`, `git-user-email`
* Changelog : `generate-changelog`, `changelog-file`, `auto-commit`
* Tag & Release : `create-tags`, `create-release`, `tag-prefix`
* Debug/log : `debug`

### Outputs

* `current-version`
* `version-bump`
* `changelog-generated`
* `tag-created`
* `release-url`
* `release-metadata`
* `breaking-changes`
* `commit-stats`
* `package-list`
* `retry-status`
* `config-merged`

---

## 5️⃣ Logique d’exécution (pseudocode composite action)

```bash
# Entrypoint
if [ "$DRY_RUN" == "true" ]; then
  log "[AUDIT] Dry-run mode"
fi

# 1. Merge config file + inputs
merged_config=$(merge_config inputs, .instantrelease.yml)

# 2. Semantic guard
semantic_guard "$merged_config"

# 3. Detect commits
commit_stats=$(get_commit_stats)

# 4. Detect bump type
bump_type=$(detect_bump_type)

# 5. Monorepo check
if [ "$MONOREPO" = "true" ]; then
  changed_packages=$(detect_changed_packages)
  package_release "$changed_packages"
fi

# 6. Version bump
new_version=$(bump_version "$bump_type")

# 7. Generate changelog
generate_changelog "$new_version"

# 8. Create Git tag
create_tag "$new_version"

# 9. Create GitHub release
if [ "$CREATE_RELEASE" = "true" ]; then
  gh_release "$new_version"
fi

# 10. Auto commit / Push
auto_commit "$files_to_commit"

# 11. Plugins
for plugin in ${PLUGINS[@]}; do
  plugin-run "$plugin"
done

# 12. Notify Slack / Teams
notify-slack "$SLACK_WEBHOOK" "$new_version"
```

---

## 6️⃣ Gestion des erreurs et idempotence

* **Retry-on-failure** : wrapper autour de chaque script critique
* **Idempotent-check** : tag ou version existante → skip
* **Dry-run** : simule tous les changements sans push
* **Audit logs** : préfixe `[AUDIT]` sur chaque étape
* **Semantic-guard** : bloque bump si conventions non respectées

---

## 7️⃣ Fichier de config externe `.instantrelease.yml` (exemple)

```yaml
versioning:
  initial: v0.0.1
  tag_prefix: v
  monorepo: true

changelog:
  enabled: true
  file: CHANGELOG.md
  template: default

release:
  create: true
  notify_slack: true

plugins:
  - ./scripts/post-build.sh
  - ./scripts/notify-api.sh
```