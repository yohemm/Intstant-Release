# Inputs :

## Git
- [x] git-user-name
- [x] git-user-email

## Base
- [x] trigger-branches :
- [x] auto-commit : effectuer un commit automatique
- [ ] branch-protection-aware : Si push impossible, créer une PR automatiquement 
- [ ] generate-version-file : Crée `VERSION` ou `.version` file pour CI
- [ ] upload-artifact : Archive changelog/version.json comme artifact CI
- [ ] load-config : Lecture du fichier de config
- [ ] config-strategy : file, input, default(without input/config)
- [ ] config-schema-check : Valide le YAML de config contre un schéma interne
- [ ] bump-multiple : Applique bump pour chaque package impacté

## Stats & Data
- [ ] detect-bump-type : Scanne les commits selon convention (angular, custom) 
- [ ] get-commit-stats : Statistiques sur commits depuis dernier tag
- [ ] extract-breaking-changes : Détecte les commits contenant BREAKING CHANGE
- [ ] detect-changed-packages : Liste des dossiers ayant changé depuis leur dernier tag

## Versionning
- [ ] bump : calculer et appliquer une montée de version (major, minor, patch, auto)
- [ ] version : version spécifique à appliquer (overrides bump)
- [x] major_indicator : indicateur personnalisé pour montée de version majeure
- [x] minor_indicator : indicateur personnalisé pour montée de version mineure
- [x] patch_indicator : indicateur personnalisé pour montée de version patch
- [ ] verify-tag : Vérifie si un tag existe / est signé
- [x] initial : version de départ si aucune version trouvée
- [ ] version-prefix : préfixe à ajouter "v" à la version (ex: v1.2.3)
- [ ] semantic-guard : Vérifie que commits respectent la convention (avant merge)
- [ ] sync-version : Synchroniser un champ version dans plusieurs fichiers (e.g. package.json, chart.yaml)

## Changelog
- [x] changelog-file: chemin du fichier changelog
- [ ] changelog-template : modèle personnalisé pour le changelog
- [x] generate-changelog : générer un changelog à partir des commits
- [ ] append-changelog : ajouter une section à un changelog existant(boolean ajout ou creation)
- [ ] extract-changelog : Renvoie uniquement la dernière entrée (utile pour GitHub Release)

## Tagging & Releases
- [x] create-tag : créer un tag Git
- [ ] delete-tag : Supprime un tag local/distant (sécure, configurable)
- [x] create-release : créer une release GitHub
- [ ] package-release : Crée changelog + tag + release pour chaque package modifié
- [ ] generate-release-metadata Produit JSON complet avec toutes les infos de la release
- [ ] changelog-to-release-notes : convertir le changelog en notes de version

## Security & Validation
- [ ] security-checks : effectuer des vérifications de sécurité avant la release
- [ ] retry-on-failure : réessayer en cas d'échec (max attempts)
- [ ] timeout-on-failure : définir un délai d'attente pour les opérations
- [ ] check-project-security : vérifier la sécurité du projet (dépendances, secrets, etc...)

## Testing & Debug
- [x] dry-run : exécuter en mode simulation (aucun push)
- [x] debug : activer les logs de débogage détaillés
- [ ] idempotent-check : Vérifie et s'arrete si un tag existe déjà
- [ ] validate-token : valider le token d'authentification

# Extended Features :
- [ ] webhook-call : appeler un webhook externe
- [ ] plugin-run : exécuter un plugin (custom script) en post-release

# Detection & Stats :
- [ ] extract-breaking-changes : extraire les changements majeurs
- [ ] get-commit-stats : obtenir des statistiques sur les commits
- [ ] detect-changed-packages : détecter les paquets modifiés
- [ ] generate-release-metadata : générer des métadonnées de release

# Doc : 
- [ ] Auto Docs



Outputs:
- current-version : version actuelle lue
- bump-type: type de montée de version calculée
- tag-created : indique si la version a déjà un tag
- commits-valided : indique si les commits respectent la convention
- dryrun : indique si le mode dry-run est activé
- commits-stats : genere des tats sur les derniers commits
- tag-tats: donne les stats globals du tag

  current-version:
    description: New version created
    value: ${{ steps.bump.outputs.current_version }}
  
  version-bump:
    description: Bump type (major, minor, patch, none)
    value: ${{ steps.bump.outputs.bump_type }}
  
  changelog-generated:
    description: Inicates if changelog was generated/updated
    value: ${{ steps.changelog.outputs.has_changes }}
  
  tag-created:
    description: Indiques if a new tag was created
    value: ${{ steps.tag.outputs.tag_created }}

| Fonction              | Description                                                                           | Inputs possibles | Outputs             |                    |                   |               |

| --------------- | ------------------------------------------------------------------- | ----------------- |----------------- |----------------- |
| `validate-semver`     | Vérifier que le format de version est correct                                         | `version`        | `is_valid`          |                    |                   |               |
| `compare-versions`    | Comparer 2 versions et retourner >, <, =                                              | `v1` `v2`        | `comparison_result` |                    |                   |               |
| `auto-tag`   | Fait un tag automatique basé sur commits + bump      | `bump:auto                 | minor                | major` | `tag_name` |
| `interactive-mode`      | Permet de choisir la version/bump via prompt (utile localement) | —                | `selected_version`   |

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
