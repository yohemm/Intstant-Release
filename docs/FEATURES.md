# Inputs :
## Versionning
bump : calculer et appliquer une montée de version (major, minor, patch, auto)
version : version spécifique à appliquer (overrides bump)
major_indicator : indicateur personnalisé pour montée de version majeure
minor_indicator : indicateur personnalisé pour montée de version mineure
patch_indicator : indicateur personnalisé pour montée de version patch
auto-commit : effectuer un commit automatique
starting_version : version de départ si aucune version trouvée
version-prefix : préfixe à ajouter "v" à la version (ex: v1.2.3)

## Changelog
changelog-path : chemin du fichier changelog
changelog-template : modèle personnalisé pour le changelog
generate-changelog : générer un changelog à partir des commits
append-changelog : ajouter une section à un changelog existant(boolean ajout ou creation)
extract-changelog : extraire le changelog pour une version donnée

## Tagging & Releases
create-tag : créer un tag Git
create-release : créer une release GitHub
package-release : publier un paquet
changelog-to-release-notes : convertir le changelog en notes de version

## Security & Validation
security-checks : effectuer des vérifications de sécurité avant la release
retry-on-failure : réessayer en cas d'échec (max attempts)
timeout-on-failure : définir un délai d'attente pour les opérations
check-project-security : vérifier la sécurité du projet (dépendances, secrets, etc...)

## Testing & Debug
dry-run : exécuter en mode simulation (aucun push)
debug : activer les logs de débogage détaillés
idempotent-check : vérifier l'idempotence
validate-token : valider le token d'authentification

# Extended Features :
webhook-call : appeler un webhook externe
plugin-run : exécuter un plugin (custom script) en post-release

# Detection & Stats :
extract-breaking-changes : extraire les changements majeurs
get-commit-stats : obtenir des statistiques sur les commits
detect-changed-packages : détecter les paquets modifiés
generate-release-metadata : générer des métadonnées de release




Outputs:
- current_version : version actuelle lue
- bump: type de montée de version calculée
- is_tagged : indique si la version a déjà un tag
- is_commit_valid : indique si les commits respectent la convention
- is_dryrun : indique si le mode dry-run est activé

| Fonction              | Description                                                                           | Inputs possibles | Outputs             |                    |                   |               |
| --------------------- | ------------------------------------------------------------------------------------- | ---------------- | ------------------- | ------------------ | ----------------- | ------------- |
| `get-current-version` | Lire la version actuelle depuis fichier, tag ou config                                | `source: tag     | file                | input` `file_path` | `current_version` |               |
| `bump-version`        | Calculer + appliquer une montée de version selon pattern                              | `bump: patch     | minor               | major              | auto`             | `new_version` |
| `validate-semver`     | Vérifier que le format de version est correct                                         | `version`        | `is_valid`          |                    |                   |               |
| `compare-versions`    | Comparer 2 versions et retourner >, <, =                                              | `v1` `v2`        | `comparison_result` |                    |                   |               |
| `sync-version`        | Synchroniser un champ version dans plusieurs fichiers (e.g. package.json, chart.yaml) | `targets[]`      | `updated_files`     |                    |                   |               |
| `generate-changelog`         | Génère changelog à partir des commits                             | `since_tag` `template`    | `CHANGELOG.md`     |       |                 |
| `append-changelog`           | Ajoute une section à un changelog existant                        | `section_title` `content` | `CHANGELOG.md`     |       |                 |
| `extract-changelog`          | Renvoie uniquement la dernière entrée (utile pour GitHub Release) | —                         | `latest_changelog` |       |                 |
| `changelog-to-release-notes` | Convertit changelog → notes prêtes pour `gh release create`       | `format: markdown         | plain              | html` | `release_notes` |
| `create-tag` | Crée un tag `vX.Y.Z` local + distant                 | `tag_prefix` `sign` `push` | `tag_ref`            |        |            |
| `delete-tag` | Supprime un tag local/distant (sécure, configurable) | `tag_name`                 | `deleted: true`      |        |            |
| `verify-tag` | Vérifie si un tag existe / est signé                 | `tag_name`                 | `exists` `is_signed` |        |            |
| `auto-tag`   | Fait un tag automatique basé sur commits + bump      | `bump:auto                 | minor                | major` | `tag_name` |
| `gh-release` | Crée une *GitHub Release* avec changelog + assets    | `upload_assets: true`      | `release_url`        |        |            |
| `detect-bump-type`         | Scanne les commits selon convention (angular, custom) | `pattern_config` | `bump_type`                                     |
| `get-commit-stats`         | Statistiques sur commits depuis dernier tag           | —                | `commit_count`, `contributors`, `files_changed` |
| `extract-breaking-changes` | Détecte les commits contenant BREAKING CHANGE         | —                | `breaking_commits[]`                            |
| `detect-changed-packages` | Liste des dossiers ayant changé depuis leur dernier tag    | `paths_config`   | `changed_packages[]`               |
| `bump-multiple`           | Applique bump pour chaque package impacté                  | `monorepo.yml`   | `{pkg1: new_ver, pkg2: unchanged}` |
| `package-release`         | Crée changelog + tag + release pour chaque package modifié | `monorepo: true` | Multi-tag output                   |
| `dry-run`                 | Simulation complète (aucun push)                         | `enable:true`    | `dryrun_artifact`       |
| `retry-on-failure`        | Réexécute une étape X fois                               | `max_attempts`   | `success/fail`          |
| `idempotent-check`        | Vérifie si un bump/tag existe déjà                       | —                | `is_repeat: true/false` |
| `validate-token`          | Vérifie que `GITHUB_TOKEN` a les permissions nécessaires | —                | `can_push`, `can_tag`   |
| `branch-protection-aware` | Si push impossible, créer une PR automatiquement         | —                | `pr_url`                |
| `auto-commit`             | Commit auto d’un fichier (version, changelog)            | `branch`, `file` | `commit_sha`            |
| `generate-release-metadata` | Produit JSON complet avec toutes les infos de la release | —                | `release-metadata.json` |
| `upload-artifact`           | Archive changelog/version.json comme artifact CI         | —                | `artifact_url`          |
| `notify-slack`              | Notification Slack / Discord / Teams avec résumé         | `webhook_url`    | `status: delivered`     |
| `generate-badge`            | Crée badge SVG dynamique (version, date, stability)      | —                | `badge_url`             |
| `load-config`     | Lire `.instantrelease.yml` ou `instantrelease.json`             | `path`           | `config_object` |
| `merge-config`    | Fusionne config + inputs + defaults                             | —                | `merged_config` |
| `plugin-run`      | Permet à l’utilisateur d’exécuter un script perso après release | `script_path`    | `exit_code`     |
| `schema-validate` | Valide le YAML de config contre un schéma interne               | —                | `is_valid`      |
| `interactive-mode`      | Permet de choisir la version/bump via prompt (utile localement) | —                | `selected_version`   |
| `generate-version-file` | Crée `VERSION` ou `.version` file pour CI                       | —                | `version_file_path`  |
| `auto-doc`              | Génère doc auto du workflow (inputs/outputs)                    | —                | `docs/versioning.md` |
| `semantic-guard`        | Vérifie que commits respectent la convention (avant merge)      | —                | `violations[]`       |

| Type            | Vérification                                                        | Action si échec   |
| --------------- | ------------------------------------------------------------------- | ----------------- |
| GITHUB_TOKEN    | Doit avoir `contents: write`                                        | stop + log erreur |
| SSH key         | Valide la clé publique du bot                                       | warning           |
| GPG             | Vérifie fingerprint et validité                                     | erreur            |
| Repo protection | Vérifie que la branche cible n’est pas protégée contre commits bots | warning           |

| Feature                         | Description                                                             | Exemple                                       |
| ------------------------------- | ----------------------------------------------------------------------- | --------------------------------------------- |
| **ci-status-check**             | Vérifie que tous les jobs précédents sont `success` avant release       | `gh api repos/:owner/:repo/actions/runs`      |
| **coverage-threshold**          | Vérifie un seuil minimal de couverture de test avant release            | lecture d’un fichier `.coverage-summary.json` |
| **performance-benchmark-check** | Compare les perfs du build courant vs release précédente                | script comparant `benchmark.json`             |
| **lint-report-parse**           | Parse les rapports de lint/sonar et bloque la release si score < seuil  | JSON parsing sur artefacts GH                 |
| **environment-lock**            | Empêche les releases simultanées (lockfile GH env)                      | fichier `.release.lock` ou GH environments    |
| **pre-flight-summary**          | Génère un résumé Markdown complet de ce qui va être publié              | `release_plan.md` dans artifacts              |
| **deployment-report**           | Génère un rapport post-release (version, packages, succès/échec, temps) | log + artefact JSON                           |

| Feature                 | Description                                                                                | Utilité                                               |
| ----------------------- | ------------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| **branch-policy-check** | Vérifie que les merges en main respectent une stratégie (squash, merge only, fast-forward) | CI/CD compliant                                       |
| **review-enforcement**  | Bloque la release si PR non approuvée ou tests manquants                                   | API GitHub GraphQL                                    |
| **release-approval**    | Système de validation manuelle (approval gate) avant déploiement prod                      | `workflow_dispatch` input + GH environment protection |
| **commit-policy**       | Vérifie le respect des conventions internes (naming, scope, ticket ID, etc.)               | extension de `semantic-guard`                         |
| **config-lint**         | Analyse le `.instantrelease.yml` pour détecter les incohérences / clés obsolètes           | validator YAML intégré                                |
| **audit-log-export**    | Exporte les logs `[AUDIT]` sous forme JSON pour archivage / traçabilité                    | `tee audit.json`                                      |

| Feature                    | Description                                                                                 | Technique d’intégration                                      |
| -------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| **token-scope-check**      | Vérifie que `GH_TOKEN` dispose des permissions nécessaires (repo, workflow, contents, etc.) | via API GitHub REST `/user` + `/repos/permissions`           |
| **commit-signature-check** | Valide la signature GPG des commits inclus dans la release                                  | `git verify-commit` / `git log --show-signature`             |
| **tag-signature**          | Possibilité de signer cryptographiquement les tags (GPG ou SSH key)                         | `git tag -s vX.Y.Z -m "Signed release"`                      |
| **secret-scan**            | Scan des commits récents à la recherche de secrets/API keys avant release                   | intégration `trufflehog` ou pattern regex custom             |
| **dependency-scan**        | Scan de sécurité sur les dépendances (package.json, requirements.txt, composer.lock)        | via `npm audit`, `pip-audit`, `snyk`, `osv-scanner` si dispo |
| **supply-chain-check**     | Vérifie les dépendances tierces (hash, provenance, mainteneur)                              | API GitHub Advisory Database                                 |
| **SBOM generation**        | Génération d’un Software Bill of Materials (SPDX / CycloneDX) pour chaque release           | `syft` ou script shell pour lister artefacts                 |
| **checksum-metadata**      | Génère un fichier `.checksum` pour tous les fichiers du build                               | `sha256sum > release.sha256`                                 |
| **artifact-signing**       | Signature cryptographique des artefacts (binaire, tar.gz, etc.)                             | `gpg --detach-sign`                                          |
| **compliance-report**      | Génère un rapport d’audit global : versions, commits, dépendances, signatures               | export JSON + Markdown                                       |

| Feature                    | Description                                                                                                       | Implémentation technique (Bash/Action)                            |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **pre-deploy-check**       | Vérifie que le repo est dans un état propre avant release (pas de commit en attente, tag déjà existant, etc.)     | `git status`, `git diff-index --quiet HEAD --`                    |
| **artifact-verification**  | Vérifie la présence et intégrité des artefacts attendus avant release (build, binaire, docker image, etc.)        | checksum ou hash SHA256 des fichiers buildés                      |
| **release-blockers**       | Permet de définir des conditions bloquantes (tests échoués, code scan KO, etc.) avant bump/tag                    | lecture d’un fichier `.release-blockers.yml` ou d’un flag dans GH |
| **deploy-matrix**          | Mode multi-environnements (dev → preprod → prod), avec gestion des versions intermédiaires (`-rc`, `-beta`, etc.) | ajout d’un input `deploy-env` avec mapping version-suffix         |
| **post-deploy-validation** | Vérifie que le déploiement s’est bien effectué (ping endpoint, logs, etc.)                                        | hook `plugin-run` type `./scripts/check_prod_health.sh`           |
| **rollback-support**       | Permet de revenir automatiquement à la version précédente en cas d’échec                                          | `git revert` + réapplication du tag précédent                     |
